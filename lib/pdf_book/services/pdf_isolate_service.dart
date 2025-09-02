import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:otzaria/utils/isolate_manager.dart';
import 'package:pdfrx/pdfrx.dart';
import 'dart:ui' as ui;

/// סוגי הודעות לעיבוד PDF
abstract class PdfMessage {}

class LoadPdfTextMessage extends PdfMessage {
  final String filePath;
  final int pageNumber;
  
  LoadPdfTextMessage({
    required this.filePath,
    required this.pageNumber,
  });
}

class SearchPdfMessage extends PdfMessage {
  final String filePath;
  final String query;
  final int maxResults;
  
  SearchPdfMessage({
    required this.filePath,
    required this.query,
    this.maxResults = 100,
  });
}

class GenerateThumbnailMessage extends PdfMessage {
  final String filePath;
  final int pageNumber;
  final double scale;
  
  GenerateThumbnailMessage({
    required this.filePath,
    required this.pageNumber,
    this.scale = 0.3,
  });
}

class LoadOutlineMessage extends PdfMessage {
  final String filePath;
  
  LoadOutlineMessage({required this.filePath});
}

/// תוצאות עיבוד PDF
class PdfTextResult {
  final String text;
  final int pageNumber;
  final String? error;
  
  PdfTextResult({
    required this.text,
    required this.pageNumber,
    this.error,
  });
}

class PdfSearchResult {
  final List<PdfSearchMatch> matches;
  final String? error;
  
  PdfSearchResult({
    required this.matches,
    this.error,
  });
}

class PdfSearchMatch {
  final int pageNumber;
  final String text;
  final int startIndex;
  final int endIndex;
  
  PdfSearchMatch({
    required this.pageNumber,
    required this.text,
    required this.startIndex,
    required this.endIndex,
  });
}

class PdfThumbnailResult {
  final Uint8List? imageData;
  final int pageNumber;
  final String? error;
  
  PdfThumbnailResult({
    this.imageData,
    required this.pageNumber,
    this.error,
  });
}

class PdfOutlineResult {
  final List<PdfOutlineNode>? outline;
  final String? error;
  
  PdfOutlineResult({
    this.outline,
    this.error,
  });
}

/// שירות עיבוד PDF ב-Isolate
class PdfIsolateService {
  static final Map<String, IsolateHandler> _pdfIsolates = {};
  
  /// קבלת או יצירת Isolate לקובץ PDF ספציפי
  static Future<IsolateHandler> _getOrCreateIsolate(String filePath) async {
    final isolateName = 'pdf_${filePath.hashCode}';
    
    if (_pdfIsolates.containsKey(isolateName)) {
      return _pdfIsolates[isolateName]!;
    }
    
    final handler = await IsolateManager.getOrCreate(
      isolateName,
      _pdfIsolateEntry,
      initialData: {'filePath': filePath},
    );
    
    _pdfIsolates[isolateName] = handler;
    return handler;
  }
  
  /// טעינת טקסט מעמוד PDF
  static Future<PdfTextResult> loadPageText(String filePath, int pageNumber) async {
    final isolate = await _getOrCreateIsolate(filePath);
    
    return await isolate.compute<PdfTextResult>(
      LoadPdfTextMessage(
        filePath: filePath,
        pageNumber: pageNumber,
      ),
    );
  }
  
  /// חיפוש טקסט ב-PDF
  static Future<PdfSearchResult> searchInPdf(
    String filePath,
    String query, {
    int maxResults = 100,
  }) async {
    final isolate = await _getOrCreateIsolate(filePath);
    
    return await isolate.compute<PdfSearchResult>(
      SearchPdfMessage(
        filePath: filePath,
        query: query,
        maxResults: maxResults,
      ),
    );
  }
  
  /// יצירת תמונה ממוזערת של עמוד
  static Future<PdfThumbnailResult> generateThumbnail(
    String filePath,
    int pageNumber, {
    double scale = 0.3,
  }) async {
    final isolate = await _getOrCreateIsolate(filePath);
    
    return await isolate.compute<PdfThumbnailResult>(
      GenerateThumbnailMessage(
        filePath: filePath,
        pageNumber: pageNumber,
        scale: scale,
      ),
    );
  }
  
  /// טעינת תוכן העניינים של PDF
  static Future<PdfOutlineResult> loadOutline(String filePath) async {
    final isolate = await _getOrCreateIsolate(filePath);
    
    return await isolate.compute<PdfOutlineResult>(
      LoadOutlineMessage(filePath: filePath),
    );
  }
  
  /// שחרור Isolate של קובץ PDF ספציפי
  static Future<void> disposePdfIsolate(String filePath) async {
    final isolateName = 'pdf_${filePath.hashCode}';
    
    if (_pdfIsolates.containsKey(isolateName)) {
      await _pdfIsolates[isolateName]!.dispose();
      _pdfIsolates.remove(isolateName);
    }
  }
  
  /// שחרור כל ה-Isolates של PDF
  static Future<void> disposeAll() async {
    for (final isolate in _pdfIsolates.values) {
      await isolate.dispose();
    }
    _pdfIsolates.clear();
  }
}

/// נקודת כניסה ל-Isolate של PDF
void _pdfIsolateEntry(IsolateContext context) {
  PdfDocument? document;
  final filePath = context.initialData?['filePath'] as String?;
  
  // טעינת המסמך פעם אחת
  Future<PdfDocument> _getDocument() async {
    document ??= await PdfDocument.openFile(filePath!);
    return document!;
  }
  
  // האזנה להודעות
  context.messages.listen((message) async {
    try {
      if (message is LoadPdfTextMessage) {
        final doc = await _getDocument();
        final pages = doc.pages;
        
        if (message.pageNumber < 0 || message.pageNumber >= pages.length) {
          context.send(PdfTextResult(
            text: '',
            pageNumber: message.pageNumber,
            error: 'Invalid page number',
          ));
          return;
        }
        
        final page = pages[message.pageNumber];
        final textPage = await page.loadText();
        
        context.send(PdfTextResult(
          text: textPage.fullText,
          pageNumber: message.pageNumber,
        ));
        
      } else if (message is SearchPdfMessage) {
        final doc = await _getDocument();
        final pages = doc.pages;
        final matches = <PdfSearchMatch>[];
        
        for (int i = 0; i < pages.length && matches.length < message.maxResults; i++) {
          final textPage = await pages[i].loadText();
          final text = textPage.fullText.toLowerCase();
          final query = message.query.toLowerCase();
          
          int index = 0;
          while ((index = text.indexOf(query, index)) != -1 && 
                 matches.length < message.maxResults) {
            // קח קונטקסט סביב המילה שנמצאה
            final start = (index - 50).clamp(0, text.length);
            final end = (index + query.length + 50).clamp(0, text.length);
            
            matches.add(PdfSearchMatch(
              pageNumber: i,
              text: textPage.fullText.substring(start, end),
              startIndex: index - start,
              endIndex: (index + query.length) - start,
            ));
            
            index += query.length;
          }
          
          // תן לאירועים אחרים לרוץ
          if (i % 10 == 0) {
            await Future.delayed(Duration.zero);
          }
        }
        
        context.send(PdfSearchResult(matches: matches));
        
      } else if (message is GenerateThumbnailMessage) {
        final doc = await _getDocument();
        final pages = doc.pages;
        
        if (message.pageNumber < 0 || message.pageNumber >= pages.length) {
          context.send(PdfThumbnailResult(
            pageNumber: message.pageNumber,
            error: 'Invalid page number',
          ));
          return;
        }
        
        final page = pages[message.pageNumber];

        // יצירת תמונה של העמוד
        final pageImage = await page.render(
          width: (page.width * message.scale).toInt(),
          height: (page.height * message.scale).toInt(),
        );

        // בדיקה שהרינדור הצליח
        if (pageImage == null) {
          context.send(PdfThumbnailResult(
            pageNumber: message.pageNumber,
            error: 'Failed to render page image.',
          ));
          return;
        }

        // המרה ל-PNG
        final uiImage = await pageImage.createImage();
        final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      context.send(PdfThumbnailResult(
        pageNumber: message.pageNumber,
        error: 'Failed to convert image to byte data.',
      ));
      return;
    }

    // 3. המרת ה-ByteData לרשימת בתים (Uint8List)
    final Uint8List pngData = byteData.buffer.asUint8List();

    context.send(PdfThumbnailResult(
      imageData: pngData,
      pageNumber: message.pageNumber,
    ));

        
      } else if (message is LoadOutlineMessage) {
        final doc = await _getDocument();
        final outline = await doc.loadOutline();
        
        context.send(PdfOutlineResult(
          outline: outline,
        ));
      }
    } catch (e) {
      // שליחת שגיאה חזרה
      if (message is LoadPdfTextMessage) {
        context.send(PdfTextResult(
          text: '',
          pageNumber: message.pageNumber,
          error: e.toString(),
        ));
      } else if (message is SearchPdfMessage) {
        context.send(PdfSearchResult(
          matches: [],
          error: e.toString(),
        ));
      } else if (message is GenerateThumbnailMessage) {
        context.send(PdfThumbnailResult(
          pageNumber: message.pageNumber,
          error: e.toString(),
        ));
      } else if (message is LoadOutlineMessage) {
        context.send(PdfOutlineResult(
          error: e.toString(),
        ));
      }
    }
  });
}

/// מחלקת עזר לעבודה עם PDF text search
class PdfTextSearcher {
  final String filePath;
  final Map<int, String> _textCache = {};
  
  PdfTextSearcher({required this.filePath});
  
  /// טעינת טקסט מעמוד עם cache
  Future<PdfPageText?> loadText({required int pageNumber}) async {
    if (_textCache.containsKey(pageNumber)) {
      return PdfPageText(
        fullText: _textCache[pageNumber]!,
        fragments: [],
      );
    }
    
    final result = await PdfIsolateService.loadPageText(filePath, pageNumber);
    
    if (result.error == null) {
      _textCache[pageNumber] = result.text;
      return PdfPageText(
        fullText: result.text,
        fragments: [],
      );
    }
    
    return null;
  }
  
  /// חיפוש טקסט בכל ה-PDF
  Future<List<PdfSearchMatch>> search(String query, {int maxResults = 100}) async {
    final result = await PdfIsolateService.searchInPdf(
      filePath,
      query,
      maxResults: maxResults,
    );
    
    if (result.error == null) {
      return result.matches;
    }
    
    return [];
  }
  
  /// ניקוי ה-cache
  void clearCache() {
    _textCache.clear();
  }
  
  /// שחרור משאבים
  Future<void> dispose() async {
    clearCache();
    await PdfIsolateService.disposePdfIsolate(filePath);
  }
}

/// מחלקת עזר ליצירת PdfPageText (תאימות לקוד קיים)
class PdfPageText {
  final String fullText;
  final List<PdfTextFragment> fragments;
  
  PdfPageText({
    required this.fullText,
    required this.fragments,
  });
}

class PdfTextFragment {
  final String text;
  final int index;
  final int end;
  
  PdfTextFragment({
    required this.text,
    required this.index,
    required this.end,
  });
}
