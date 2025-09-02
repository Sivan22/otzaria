import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:otzaria/library/models/library.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:otzaria/utils/isolate_manager.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:otzaria/utils/ref_helper.dart';
import 'package:search_engine/search_engine.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

/// הודעות לתקשורת עם ה-Isolate
abstract class IndexingMessage {}

class StartIndexingMessage extends IndexingMessage {
  final List<BookData> books;
  final String indexPath;
  final String refIndexPath;
  
  StartIndexingMessage({
    required this.books,
    required this.indexPath,
    required this.refIndexPath,
  });
}

class CancelIndexingMessage extends IndexingMessage {}

class IndexingProgressMessage {
  final int processed;
  final int total;
  final String? currentBook;
  final bool isComplete;
  final String? error;
  
  IndexingProgressMessage({
    required this.processed,
    required this.total,
    this.currentBook,
    this.isComplete = false,
    this.error,
  });
}

/// נתוני ספר לאינדוקס
class BookData {
  final String title;
  final String? path;
  final String topics;
  final BookType type;
  final String? textContent; // לספרי טקסט
  
  BookData({
    required this.title,
    this.path,
    required this.topics,
    required this.type,
    this.textContent,
  });
}

enum BookType { text, pdf }

/// שירות אינדוקס שרץ ב-Isolate
class IndexingIsolateService {
  static IsolateHandler? _isolateHandler;
  static StreamController<IndexingProgressMessage>? _progressController;
  static bool _isIndexing = false;
  
  /// התחלת תהליך האינדוקס ב-Isolate
  static Future<Stream<IndexingProgressMessage>> startIndexing(
    Library library,
  ) async {
    if (_isIndexing) {
      throw Exception('Indexing already in progress');
    }
    
    _isIndexing = true;
    _progressController = StreamController<IndexingProgressMessage>.broadcast();
    
    // הכנת נתוני הספרים
    final books = await _prepareBooksData(library);
    
    // קבלת נתיבי האינדקס
    final indexPath = '${Settings.getValue('key-library-path') ?? 'C:/אוצריא'}${Platform.pathSeparator}index';
    final refIndexPath = '${Settings.getValue('key-library-path') ?? 'C:/אוצריא'}${Platform.pathSeparator}ref_index';
    
    // יצירת ה-Isolate
    _isolateHandler = await IsolateManager.getOrCreate(
      'indexing',
      _indexingIsolateEntry,
    );
    
    // האזנה לתגובות מה-Isolate
    _isolateHandler!.responses.listen((message) {
      if (message is IndexingProgressMessage) {
        _progressController?.add(message);
        
        if (message.isComplete || message.error != null) {
          _isIndexing = false;
          _progressController?.close();
          _progressController = null;
        }
      }
    });
    
    // שליחת הודעת התחלה
    _isolateHandler!.send(StartIndexingMessage(
      books: books,
      indexPath: indexPath,
      refIndexPath: refIndexPath,
    ));
    
    return _progressController!.stream;
  }
  
  /// ביטול תהליך האינדוקס
  static Future<void> cancelIndexing() async {
    if (_isolateHandler != null) {
      _isolateHandler!.send(CancelIndexingMessage());
      await IsolateManager.kill('indexing');
      _isolateHandler = null;
    }
    
    _isIndexing = false;
    _progressController?.close();
    _progressController = null;
  }
  
  /// הכנת נתוני הספרים לאינדוקס
  static Future<List<BookData>> _prepareBooksData(Library library) async {
    final books = <BookData>[];
    final allBooks = library.getAllBooks();
    
    for (final book in allBooks) {
      if (book is TextBook) {
        // טעינת תוכן הטקסט מראש
        final text = await book.text;
        books.add(BookData(
          title: book.title,
          topics: book.topics,
          type: BookType.text,
          textContent: text,
        ));
      } else if (book is PdfBook) {
        books.add(BookData(
          title: book.title,
          path: book.path,
          topics: book.topics,
          type: BookType.pdf,
        ));
      }
    }
    
    return books;
  }
}

/// נקודת הכניסה ל-Isolate של האינדוקס
void _indexingIsolateEntry(IsolateContext context) {
  SearchEngine? searchEngine;
  ReferenceSearchEngine? refEngine;
  bool shouldCancel = false;
  Set<String> booksDone = {};
  
  // האזנה להודעות
  context.messages.listen((message) async {
    if (message is StartIndexingMessage) {
      shouldCancel = false;
      
      try {
        // יצירת מנועי החיפוש עם הרשאות כתיבה
        searchEngine = SearchEngine(path: message.indexPath);
        refEngine = ReferenceSearchEngine(path: message.refIndexPath);
        
        final totalBooks = message.books.length;
        int processedBooks = 0;
        
        for (final book in message.books) {
          if (shouldCancel) break;
          
          try {
            // שליחת עדכון התקדמות
            context.send(IndexingProgressMessage(
              processed: processedBooks,
              total: totalBooks,
              currentBook: book.title,
            ));
            
            // אינדוקס הספר
            if (book.type == BookType.text) {
              await _indexTextBookInIsolate(
                book,
                searchEngine!,
                refEngine!,
                booksDone,
              );
            } else if (book.type == BookType.pdf) {
              await _indexPdfBookInIsolate(
                book,
                searchEngine!,
                booksDone,
              );
            }
            
            processedBooks++;
            
            // ביצוע commit מדי פעם כדי לשחרר לוקים
            if (processedBooks % 10 == 0) {
              await searchEngine?.commit();
              await refEngine?.commit();
            }
          } catch (e) {
            debugPrint('Error indexing ${book.title}: $e');
            processedBooks++;
          }
          
          // תן ל-Isolate לנשום
          await Future.delayed(Duration.zero);
        }
        
        // סיום מוצלח
        await searchEngine?.commit();
        await refEngine?.commit();
        
        context.send(IndexingProgressMessage(
          processed: processedBooks,
          total: totalBooks,
          isComplete: true,
        ));
      } catch (e) {
        context.send(IndexingProgressMessage(
          processed: 0,
          total: 0,
          error: e.toString(),
        ));
      }
    } else if (message is CancelIndexingMessage) {
      shouldCancel = true;
    }
  });
}

/// אינדוקס ספר טקסט בתוך ה-Isolate
Future<void> _indexTextBookInIsolate(
  BookData book,
  SearchEngine searchEngine,
  ReferenceSearchEngine refEngine,
  Set<String> booksDone,
) async {
  // בדיקה אם כבר אונדקס
  final bookKey = "${book.title}textBook";
  if (booksDone.contains(bookKey)) return;
  
  final text = book.textContent ?? '';
  final title = book.title;
  final topics = "/${book.topics.replaceAll(', ', '/')}";
  
  final texts = text.split('\n');
  List<String> reference = [];
  
  for (int i = 0; i < texts.length; i++) {
    // תן לאירועים אחרים לרוץ
    if (i % 100 == 0) {
      await Future.delayed(Duration.zero);
    }
    
    String line = texts[i];
    
    if (line.startsWith('<h')) {
      // עדכון הרפרנס
      if (reference.isNotEmpty &&
          reference.any((element) => 
              element.substring(0, 4) == line.substring(0, 4))) {
        reference.removeRange(
            reference.indexWhere((element) => 
                element.substring(0, 4) == line.substring(0, 4)),
            reference.length);
      }
      reference.add(line);
      
      // אינדוקס כרפרנס
      String refText = stripHtmlIfNeeded(reference.join(" "));
      final shortref = replaceParaphrases(removeSectionNames(refText));
      
      refEngine.addDocument(
          id: BigInt.from(DateTime.now().microsecondsSinceEpoch),
          title: title,
          reference: refText,
          shortRef: shortref,
          segment: BigInt.from(i),
          isPdf: false,
          filePath: '');
    } else {
      line = stripHtmlIfNeeded(line);
      line = removeVolwels(line);
      
      // הוספה לאינדקס
      searchEngine.addDocument(
          id: BigInt.from(DateTime.now().microsecondsSinceEpoch),
          title: title,
          reference: stripHtmlIfNeeded(reference.join(', ')),
          topics: '$topics/$title',
          text: line,
          segment: BigInt.from(i),
          isPdf: false,
          filePath: '');
    }
  }
  
  booksDone.add(bookKey);
}

/// אינדוקס ספר PDF בתוך ה-Isolate
Future<void> _indexPdfBookInIsolate(
  BookData book,
  SearchEngine searchEngine,
  Set<String> booksDone,
) async {
  // בדיקה אם כבר אונדקס
  final bookKey = "${book.title}pdfBook";
  if (booksDone.contains(bookKey)) return;
  
  final document = await PdfDocument.openFile(book.path!);
  final pages = document.pages;
  final outline = await document.loadOutline();
  final title = book.title;
  final topics = "/${book.topics.replaceAll(', ', '/')}";
  
  for (int i = 0; i < pages.length; i++) {
    final texts = (await pages[i].loadText()).fullText.split('\n');
    
    for (int j = 0; j < texts.length; j++) {
      // תן לאירועים אחרים לרוץ
      if (j % 50 == 0) {
        await Future.delayed(Duration.zero);
      }
      
      final bookmark = await refFromPageNumber(i + 1, outline, title);
      final ref = bookmark.isNotEmpty
          ? '$title, $bookmark, עמוד ${i + 1}'
          : '$title, עמוד ${i + 1}';
      
      searchEngine.addDocument(
          id: BigInt.from(DateTime.now().microsecondsSinceEpoch),
          title: title,
          reference: ref,
          topics: '$topics/$title',
          text: texts[j],
          segment: BigInt.from(i),
          isPdf: true,
          filePath: book.path!);
    }
  }
  
  booksDone.add(bookKey);
}

/// מחלקת עזר לגישת קריאה בלבד לאינדקס (לחיפוש במקביל לאינדוקס)
class ReadOnlySearchEngine {
  late SearchEngine _engine;
  final String indexPath;
  
  ReadOnlySearchEngine({required this.indexPath}) {
    // פתיחת האינדקס במצב קריאה בלבד
    _initEngine();
  }
  
  void _initEngine() {
    try {
      // ניסיון לפתוח במצב קריאה
      _engine = SearchEngine(path: indexPath);
    } catch (e) {
      debugPrint('Failed to open search engine in read-only mode: $e');
      rethrow;
    }
  }
  
  /// חיפוש באינדקס (קריאה בלבד)
  Future<List<SearchResult>> search({
    required List<String> regexTerms,
    required List<String> facets,
    required int limit,
    int slop = 0,
    int maxExpansions = 10,
    ResultsOrder order = ResultsOrder.relevance,
  }) async {
    try {
      return await _engine.search(
        regexTerms: regexTerms,
        facets: facets,
        limit: limit,
        slop: slop,
        maxExpansions: maxExpansions,
        order: order,
      );
    } catch (e) {
      // אם יש בעיה בגישה, ננסה לפתוח מחדש
      _initEngine();
      return await _engine.search(
        regexTerms: regexTerms,
        facets: facets,
        limit: limit,
        slop: slop,
        maxExpansions: maxExpansions,
        order: order,
      );
    }
  }
  
  /// ספירת תוצאות (קריאה בלבד)
  Future<int> count({
    required List<String> regexTerms,
    required List<String> facets,
    int slop = 0,
    int maxExpansions = 10,
  }) async {
    try {
      return await _engine.count(
        regexTerms: regexTerms,
        facets: facets,
        slop: slop,
        maxExpansions: maxExpansions,
      );
    } catch (e) {
      // אם יש בעיה בגישה, ננסה לפתוח מחדש
      _initEngine();
      return await _engine.count(
        regexTerms: regexTerms,
        facets: facets,
        slop: slop,
        maxExpansions: maxExpansions,
      );
    }
  }
}
