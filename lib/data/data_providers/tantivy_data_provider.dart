import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:search_engine/search_engine.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/library.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:hive/hive.dart';

/// A singleton class that manages text indexing and searching functionality using Tantivy search engine.
///
/// This provider handles both text-based and PDF books, maintaining an index for full-text search
/// capabilities. It supports incremental indexing with progress tracking and allows for both
/// synchronous and asynchronous search operations.
class TantivyDataProvider {
  /// Instance of the search engine pointing to the index directory
  late Future<SearchEngine> engine;

  static final TantivyDataProvider _singleton = TantivyDataProvider();
  static TantivyDataProvider instance = _singleton;

  /// Notifies listeners about the number of books that have been processed during indexing
  ValueNotifier<int?> numOfbooksDone = ValueNotifier(null);

  /// Notifies listeners about the total number of books to be processed
  ValueNotifier<int?> numOfbooksTotal = ValueNotifier(null);

  /// Indicates whether the indexing process is currently running
  ValueNotifier<bool> isIndexing = ValueNotifier(false);

  /// Maintains a list of processed books to avoid reindexing
  late List booksDone;

  /// Initializes the data provider and loads the list of previously indexed books from disk.
  ///
  /// Uses Hive for persistent storage of indexed book records, storing them in the 'index'
  /// subdirectory of the configured library path.
  TantivyDataProvider() {
    String indexPath = (Settings.getValue('key-library-path') ?? 'C:/אוצריא') +
        Platform.pathSeparator +
        'index';

    engine = SearchEngine.newInstance(path: indexPath);

    //test the engine
    searchTexts('בראשית', ['בראשית'], 1);

    booksDone = Hive.box(
            name: 'books_indexed',
            directory: (Settings.getValue('key-library-path') ?? 'C:/אוצריא') +
                Platform.pathSeparator +
                'index')
        .get('key-books-done', defaultValue: []);
  }

  /// Persists the list of indexed books to disk using Hive storage.
  saveBooksDoneToDisk() {
    Hive.box(
            name: 'books_indexed',
            directory: (Settings.getValue('key-library-path') ?? 'C:/אוצריא') +
                Platform.pathSeparator +
                'index')
        .put('key-books-done', booksDone);
  }

  /// Performs a synchronous search operation across indexed texts.
  ///
  /// [query] The search query string
  /// [books] List of book identifiers to search within
  /// [limit] Maximum number of results to return
  /// [fuzzy] Whether to perform fuzzy matching
  ///
  /// Returns a Future containing a list of search results
  Future<List<SearchResult>> searchTexts(
      String query, List<String> books, int limit,
      {bool fuzzy = false, int distance = 2}) async {
    SearchEngine index;
    try {
      index = await engine;
    }
    // in case the schema has changed, reset the index
    catch (e) {
      String indexPath =
          (Settings.getValue('key-library-path') ?? 'C:/אוצריא') +
              Platform.pathSeparator +
              'index';
      if (e.toString() ==
          "PanicException(Failed to create index: SchemaError(\"An index exists but the schema does not match.\"))") {
        Directory indexDirectory = Directory(indexPath);
        Hive.box(name: 'books_indexed', directory: indexPath).close();
        print('Deleting index and creating a new one');
        indexDirectory.deleteSync(recursive: true);
        indexDirectory.createSync(recursive: true);
        engine = SearchEngine.newInstance(path: indexPath);
        index = await engine;
      } else {
        rethrow;
      }
    }
    if (!fuzzy) {
      query = distance > 0 ? '"$query"~$distance' : "query";
    }
    return await index.search(
        query: query, books: books, limit: limit, fuzzy: fuzzy);
  }

  /// Performs an asynchronous stream-based search operation across indexed texts.
  ///
  /// [query] The search query string
  /// [books] List of book identifiers to search within
  /// [limit] Maximum number of results to return
  /// [fuzzy] Whether to perform fuzzy matching
  ///
  /// Returns a Stream of search results that can be listened to for real-time updates
  Stream<List<SearchResult>> searchTextsStream(
      String query, List<String> books, int limit, bool fuzzy) async* {
    final index = await engine;
    yield* index.searchStream(
        query: query, books: books, limit: limit, fuzzy: fuzzy);
  }

  /// Indexes all books in the provided library within the specified range.
  ///
  /// [library] The library containing books to index
  /// [start] Starting index in the library's book list (default: 0)
  /// [end] Ending index in the library's book list (default: 100000)
  ///
  /// Updates progress through numOfbooksDone and numOfbooksTotal notifiers
  addAllTBooksToTantivy(Library library,
      {int start = 0, int end = 100000}) async {
    isIndexing.value = true;
    var allBooks = library.getAllBooks();
    allBooks = allBooks.getRange(start, min(end, allBooks.length)).toList();

    numOfbooksTotal.value = allBooks.length;
    numOfbooksDone.value = 0;

    for (Book book in allBooks) {
      // Check if indexing was cancelled
      if (!isIndexing.value) {
        return;
      }
      print('Adding ${book.title} to index');
      try {
        // Handle different book types appropriately
        if (book is TextBook) {
          await addTextsToTantivy(book);
        } else if (book is PdfBook) {
          await addPdfTextsToTantivy(book);
        }
      } catch (e) {
        print('Error adding ${book.title} to index: $e');
      }
    }

    // Reset progress indicators after completion
    numOfbooksDone.value = null;
    numOfbooksTotal.value = null;
    isIndexing.value = false;
  }

  /// Indexes a text-based book by processing its content and adding it to the search index.
  ///
  /// [book] The TextBook instance to be indexed
  ///
  /// Processes the book's text by:
  /// 1. Computing a hash to check for previous indexing
  /// 2. Stripping HTML and vowel marks
  /// 3. Splitting into lines and indexing each line separately
  addTextsToTantivy(TextBook book) async {
    final index = await engine;
    var text = await book.text;
    final title = book.title;

    // Check if book was already indexed using content hash
    final hash = sha1.convert(utf8.encode(text)).toString();
    if (booksDone.contains(hash)) {
      print('${book.title} already in index');
      numOfbooksDone.value = numOfbooksDone.value! + 1;
      return;
    }

    // Preprocess text by removing HTML and vowel marks

    final texts = text.split('\n');
    List<String> reference = [];
    // Index each line separately
    for (int i = 0; i < texts.length; i++) {
      if (!isIndexing.value) {
        return;
      }
      String line = texts[i];
      // get the reference from the headers
      if (line.startsWith('<h')) {
        if (reference.isNotEmpty &&
            reference.any(
                (element) => element.substring(0, 4) == line.substring(0, 4))) {
          reference.removeRange(
              reference.indexWhere(
                  (element) => element.substring(0, 4) == line.substring(0, 4)),
              reference.length);
        }
        reference.add(line);
      } else {
        line = stripHtmlIfNeeded(line);
        line = removeVolwels(line);
        index.addDocument(
            id: BigInt.from(hashCode + i),
            title: title,
            reference: stripHtmlIfNeeded(reference.join(', ')),
            text: line,
            segment: BigInt.from(i),
            isPdf: false,
            filePath: '');
      }
    }

    await index.commit();
    booksDone.add(hash);
    saveBooksDoneToDisk();
    print('Added ${book.title} to index');
    numOfbooksDone.value = numOfbooksDone.value! + 1;
  }

  /// Indexes a PDF book by extracting and processing text from each page.
  ///
  /// [book] The PdfBook instance to be indexed
  ///
  /// Processes the PDF by:
  /// 1. Computing a hash of the PDF file to check for previous indexing
  /// 2. Extracting text from each page
  /// 3. Splitting page text into lines and indexing each line separately
  addPdfTextsToTantivy(PdfBook book) async {
    final index = await engine;

    // Check if PDF was already indexed using file hash
    final data = await File(book.path).readAsBytes();
    final hash = sha1.convert(data).toString();
    if (booksDone.contains(hash)) {
      print('${book.title} already in index');
      numOfbooksDone.value = numOfbooksDone.value! + 1;
      return;
    }

    // Extract text from each page
    final pages = await PdfDocument.openData(data).then((value) => value.pages);
    final title = book.title;

    // Process each page
    for (int i = 0; i < pages.length; i++) {
      final texts = (await pages[i].loadText()).fullText.split('\n');
      // Index each line from the page
      for (int j = 0; j < texts.length; j++) {
        if (!isIndexing.value) {
          return;
        }
        index.addDocument(
            id: BigInt.from(DateTime.now().microsecondsSinceEpoch),
            title: title,
            reference: '$title, עמוד ${i + 1}',
            text: texts[j],
            segment: BigInt.from(i),
            isPdf: true,
            filePath: book.path);
      }
    }

    await index.commit();
    booksDone.add(hash);
    saveBooksDoneToDisk();
    print('Added ${book.title} to index');
    numOfbooksDone.value = numOfbooksDone.value! + 1;
  }
}
