import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:search_engine/search_engine.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:hive/hive.dart';
import 'package:otzaria/search/search_repository.dart';

/// A singleton class that manages search functionality using Tantivy search engine.
///
/// This provider handles the search operations for both text-based and PDF books,
/// maintaining an index for full-text search capabilities.
class TantivyDataProvider {
  /// Instance of the search engine pointing to the index directory
  late Future<SearchEngine> engine;
  late ReferenceSearchEngine refEngine;

  static final TantivyDataProvider _singleton = TantivyDataProvider();
  static TantivyDataProvider instance = _singleton;

  /// Indicates whether the indexing process is currently running
  ValueNotifier<bool> isIndexing = ValueNotifier(false);

  /// Maintains a list of processed books to avoid reindexing
  late List<String> booksDone;

  TantivyDataProvider() {
    reopenIndex();
  }

  void reopenIndex() {
    String indexPath = (Settings.getValue('key-library-path') ?? 'C:/אוצריא') +
        Platform.pathSeparator +
        'index';
    String refIndexPath =
        (Settings.getValue('key-library-path') ?? 'C:/אוצריא') +
            Platform.pathSeparator +
            'ref_index';

    engine = Future.value(SearchEngine(path: indexPath));

    try {
      refEngine = ReferenceSearchEngine(path: refIndexPath);
    } catch (e) {
      if (e.toString() ==
          "PanicException(Failed to create index: SchemaError(\"An index exists but the schema does not match.\"))") {
        resetIndex(indexPath);
        reopenIndex();
      } else {
        rethrow;
      }
    }
    //test the engine
    engine.then((value) {
      try {
        // Test the search engine
        value
            .search(
                regexTerms: ['a'],
                limit: 10,
                slop: 0,
                maxExpansions: 10,
                facets: ["/"],
                order: ResultsOrder.catalogue)
            .then((results) {
          // Engine test successful
        }).catchError((e) {
          // Log engine test error
        });
      } catch (e) {
        // Log sync engine test error
        if (e.toString() ==
            "PanicException(Failed to create index: SchemaError(\"An index exists but the schema does not match.\"))") {
          resetIndex(indexPath);
          reopenIndex();
        } else {
          rethrow;
        }
      }
    });
    try {
      booksDone = Hive.box(
              name: 'books_indexed',
              directory:
                  (Settings.getValue('key-library-path') ?? 'C:/אוצריא') +
                      Platform.pathSeparator +
                      'index')
          .get('key-books-done', defaultValue: [])
          .map<String>((e) => e.toString())
          .toList() as List<String>;
    } catch (e) {
      booksDone = [];
    }
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

  Future<int> countTexts(String query, List<String> books, List<String> facets,
      {bool fuzzy = false, int distance = 2}) async {
    final index = await engine;

    // Debug: CountTexts for "$query"

    // המרת החיפוש הפשוט לפורמט החדש - ללא רגקס אמיתי!
    List<String> regexTerms;
    if (!fuzzy) {
      // חיפוש מדוייק - נפצל למילים אם יש יותר ממילה אחת
      final words = query.trim().split(RegExp(r'\s+'));
      if (words.length > 1) {
        regexTerms = words;
      } else {
        regexTerms = [query];
      }
    } else {
      // חיפוש מקורב - נשתמש במילים בודדות
      regexTerms = query.trim().split(RegExp(r'\s+'));
    }

    // חישוב maxExpansions בהתבסס על סוג החיפוש
    int maxExpansions;
    if (fuzzy) {
      maxExpansions = 50; // חיפוש מקורב
    } else if (regexTerms.length > 1) {
      maxExpansions = 100; // חיפוש של כמה מילים - צריך expansions גבוה יותר
    } else {
      maxExpansions = 10; // מילה אחת - expansions נמוך
    }

    // Debug: RegexTerms: $regexTerms, MaxExpansions: $maxExpansions

    try {
      final count = await index.count(
          regexTerms: regexTerms,
          facets: facets,
          slop: distance,
          maxExpansions: maxExpansions);

      return count;
    } catch (e) {
      // Log error in production
      rethrow;
    }
  }

  Future<void> resetIndex(String indexPath) async {
    Directory indexDirectory = Directory(indexPath);
    Hive.box(name: 'books_indexed', directory: indexPath).close();
    indexDirectory.deleteSync(recursive: true);
    indexDirectory.createSync(recursive: true);
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
      String query, List<String> facets, int limit, bool fuzzy) async* {
    // הפונקציה הזו לא נתמכת במנוע החדש - נחזיר תוצאה חד-פעמית
    final searchRepository = SearchRepository();
    final results =
        await searchRepository.searchTexts(query, facets, limit, fuzzy: fuzzy);
    yield results;
  }

  Future<List<ReferenceSearchResult>> searchRefs(
      String reference, int limit, bool fuzzy) async {
    return refEngine.search(
        query: reference,
        limit: limit,
        fuzzy: fuzzy,
        order: ResultsOrder.relevance);
  }

  /// Clears the index and resets the list of indexed books.
  Future<void> clear() async {
    isIndexing.value = false;
    final index = await engine;
    await index.clear();
    final refIndex = refEngine;
    await refIndex.clear();
    booksDone.clear();
    saveBooksDoneToDisk();
  }
}
