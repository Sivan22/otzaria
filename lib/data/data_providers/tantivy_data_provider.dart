import 'dart:io';
import 'dart:math' as math;
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

  // Global cache for facet counts
  static final Map<String, int> _globalFacetCache = {};
  static String _lastCachedQuery = '';

  // Track ongoing counts to prevent duplicates
  static final Set<String> _ongoingCounts = {};

  /// Clear global cache when starting new search
  static void clearGlobalCache() {
    print(
        '🧹 Clearing global facet cache (${_globalFacetCache.length} entries)');
    _globalFacetCache.clear();
    _ongoingCounts.clear();
    _lastCachedQuery = '';
  }

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
      {bool fuzzy = false,
      int distance = 2,
      Map<String, String>? customSpacing,
      Map<int, List<String>>? alternativeWords,
      Map<String, Map<String, bool>>? searchOptions}) async {
    // Global cache check
    final cacheKey =
        '$query|${facets.join(',')}|$fuzzy|$distance|${customSpacing.toString()}|${alternativeWords.toString()}|${searchOptions.toString()}';

    if (_lastCachedQuery == query && _globalFacetCache.containsKey(cacheKey)) {
      print('🎯 GLOBAL CACHE HIT for $facets: ${_globalFacetCache[cacheKey]}');
      return _globalFacetCache[cacheKey]!;
    }

    // Check if this count is already in progress
    if (_ongoingCounts.contains(cacheKey)) {
      print('⏳ Count already in progress for $facets, waiting...');
      // Wait for the ongoing count to complete
      while (_ongoingCounts.contains(cacheKey)) {
        await Future.delayed(const Duration(milliseconds: 50));
        if (_globalFacetCache.containsKey(cacheKey)) {
          print(
              '🎯 DELAYED CACHE HIT for $facets: ${_globalFacetCache[cacheKey]}');
          return _globalFacetCache[cacheKey]!;
        }
      }
    }

    // Mark this count as in progress
    _ongoingCounts.add(cacheKey);
    final index = await engine;

    // בדיקה אם יש מרווחים מותאמים אישית, מילים חילופיות או אפשרויות חיפוש
    final hasCustomSpacing = customSpacing != null && customSpacing.isNotEmpty;
    final hasAlternativeWords =
        alternativeWords != null && alternativeWords.isNotEmpty;
    final hasSearchOptions = searchOptions != null && searchOptions.isNotEmpty;

    // המרת החיפוש לפורמט המנוע החדש - בדיוק כמו ב-SearchRepository!
    final words = query.trim().split(RegExp(r'\s+'));
    final List<String> regexTerms;
    final int effectiveSlop;

    if (hasAlternativeWords || hasSearchOptions) {
      // יש מילים חילופיות או אפשרויות חיפוש - נבנה queries מתקדמים
      regexTerms =
          _buildAdvancedQueryForCount(words, alternativeWords, searchOptions);
      effectiveSlop = hasCustomSpacing
          ? _getMaxCustomSpacingForCount(customSpacing, words.length)
          : (fuzzy ? distance : 0);
    } else if (fuzzy) {
      // חיפוש מקורב - נשתמש במילים בודדות
      regexTerms = words;
      effectiveSlop = distance;
    } else if (words.length == 1) {
      // מילה אחת - חיפוש פשוט
      regexTerms = [query];
      effectiveSlop = 0;
    } else if (hasCustomSpacing) {
      // מרווחים מותאמים אישית
      regexTerms = words;
      effectiveSlop = _getMaxCustomSpacingForCount(customSpacing, words.length);
    } else {
      // חיפוש מדוייק של כמה מילים
      regexTerms = words;
      effectiveSlop = distance;
    }

    // חישוב maxExpansions בהתבסס על סוג החיפוש
    final int maxExpansions = _calculateMaxExpansionsForCount(
        fuzzy, regexTerms.length,
        searchOptions: searchOptions, words: words);

    try {
      final count = await index.count(
          regexTerms: regexTerms,
          facets: facets,
          slop: effectiveSlop,
          maxExpansions: maxExpansions);

      // Save to global cache
      _lastCachedQuery = query;
      _globalFacetCache[cacheKey] = count;
      _ongoingCounts.remove(cacheKey); // Mark as completed
      print('💾 GLOBAL CACHE SAVE for $facets: $count');

      return count;
    } catch (e) {
      // Remove from ongoing counts even on error
      _ongoingCounts.remove(cacheKey);
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

  /// מחשב את המרווח המקסימלי מהמרווחים המותאמים אישית
  int _getMaxCustomSpacingForCount(
      Map<String, String> customSpacing, int wordCount) {
    int maxSpacing = 0;

    for (int i = 0; i < wordCount - 1; i++) {
      final spacingKey = '$i-${i + 1}';
      final customSpacingValue = customSpacing[spacingKey];

      if (customSpacingValue != null && customSpacingValue.isNotEmpty) {
        final spacingNum = int.tryParse(customSpacingValue) ?? 0;
        maxSpacing = maxSpacing > spacingNum ? maxSpacing : spacingNum;
      }
    }

    return maxSpacing;
  }

  /// בונה query מתקדם עם מילים חילופיות ואפשרויות חיפוש
  List<String> _buildAdvancedQueryForCount(
      List<String> words,
      Map<int, List<String>>? alternativeWords,
      Map<String, Map<String, bool>>? searchOptions) {
    List<String> regexTerms = [];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final wordKey = '${word}_$i';

      // קבלת אפשרויות החיפוש למילה הזו
      final wordOptions = searchOptions?[wordKey] ?? {};
      final hasPrefix = wordOptions['קידומות'] == true;
      final hasSuffix = wordOptions['סיומות'] == true;
      final hasGrammaticalPrefixes = wordOptions['קידומות דקדוקיות'] == true;
      final hasGrammaticalSuffixes = wordOptions['סיומות דקדוקיות'] == true;
      final hasFullPartialSpelling = wordOptions['כתיב מלא/חסר'] == true;
      final hasPartialWord = wordOptions['חלק ממילה'] == true;

      // קבלת מילים חילופיות
      final alternatives = alternativeWords?[i];

      // בניית רשימת כל האפשרויות (מילה מקורית + חלופות)
      final allOptions = [word];
      if (alternatives != null && alternatives.isNotEmpty) {
        allOptions.addAll(alternatives);
      }

      // סינון אפשרויות ריקות
      final validOptions =
          allOptions.where((w) => w.trim().isNotEmpty).toList();

      if (validOptions.isNotEmpty) {
        // בניית רשימת כל האפשרויות לכל מילה
        final allVariations = <String>{};

        for (final option in validOptions) {
          List<String> baseVariations = [option];

          // אם יש כתיב מלא/חסר, נוצר את כל הווריאציות של כתיב
          if (hasFullPartialSpelling) {
            try {
              // הגבלה למילים קצרות - כתיב מלא/חסר יכול ליצור הרבה וריאציות
              if (option.length <= 3) {
                // למילים קצרות, נגביל את מספר הוריאציות
                final allSpellingVariations =
                    _generateFullPartialSpellingVariations(option);
                // נקח רק את ה-5 הראשונות כדי למנוע יותר מדי expansions
                baseVariations = allSpellingVariations.take(5).toList();
              } else {
                baseVariations = _generateFullPartialSpellingVariations(option);
              }
            } catch (e) {
              // אם יש בעיה, נוסיף לפחות את המילה המקורית
              baseVariations = [option];
            }
          }

          // עבור כל וריאציה של כתיב, מוסיפים את האפשרויות הדקדוקיות
          for (final baseVariation in baseVariations) {
            if (hasGrammaticalPrefixes && hasGrammaticalSuffixes) {
              // שתי האפשרויות יחד - הגבלה למילים קצרות
              if (baseVariation.length <= 2) {
                // למילים קצרות, נשתמש ברגקס קומפקטי במקום רשימת וריאציות
                allVariations
                    .add(_createFullMorphologicalRegexPattern(baseVariation));
              } else {
                allVariations.addAll(
                    _generateFullMorphologicalVariations(baseVariation));
              }
            } else if (hasGrammaticalPrefixes) {
              // רק קידומות דקדוקיות - הגבלה למילים קצרות
              if (baseVariation.length <= 2) {
                // למילים קצרות, נשתמש ברגקס קומפקטי
                allVariations.add(_createPrefixRegexPattern(baseVariation));
              } else {
                allVariations.addAll(_generatePrefixVariations(baseVariation));
              }
            } else if (hasGrammaticalSuffixes) {
              // רק סיומות דקדוקיות - הגבלה למילים קצרות
              if (baseVariation.length <= 2) {
                // למילים קצרות, נשתמש ברגקס קומפקטי
                allVariations.add(_createSuffixRegexPattern(baseVariation));
              } else {
                allVariations.addAll(_generateSuffixVariations(baseVariation));
              }
            } else if (hasPrefix) {
              // קידומות רגילות - הגבלה חכמה לפי אורך המילה
              if (baseVariation.length <= 1) {
                // מילה של תו אחד - הגבלה קיצונית (מקסימום 5 תווים קידומת)
                allVariations.add('.{1,5}${RegExp.escape(baseVariation)}');
              } else if (baseVariation.length <= 2) {
                // מילה של 2 תווים - הגבלה בינונית (מקסימום 4 תווים קידומת)
                allVariations.add('.{1,4}${RegExp.escape(baseVariation)}');
              } else if (baseVariation.length <= 3) {
                // מילה של 3 תווים - הגבלה קלה (מקסימום 3 תווים קידומת)
                allVariations.add('.{1,3}${RegExp.escape(baseVariation)}');
              } else {
                // מילה ארוכה - ללא הגבלה
                allVariations.add('.*${RegExp.escape(baseVariation)}');
              }
            } else if (hasSuffix) {
              // סיומות רגילות - הגבלה חכמה לפי אורך המילה
              if (baseVariation.length <= 1) {
                // מילה של תו אחד - הגבלה קיצונית (מקסימום 7 תווים סיומת)
                allVariations.add('${RegExp.escape(baseVariation)}.{1,7}');
              } else if (baseVariation.length <= 2) {
                // מילה של 2 תווים - הגבלה בינונית (מקסימום 6 תווים סיומת)
                allVariations.add('${RegExp.escape(baseVariation)}.{1,6}');
              } else if (baseVariation.length <= 3) {
                // מילה של 3 תווים - הגבלה קלה (מקסימום 5 תווים סיומת)
                allVariations.add('${RegExp.escape(baseVariation)}.{1,5}');
              } else {
                // מילה ארוכה - ללא הגבלה
                allVariations.add('${RegExp.escape(baseVariation)}.*');
              }
            } else if (hasPartialWord) {
              // חלק ממילה - הגבלה חכמה לפי אורך המילה
              if (baseVariation.length <= 3) {
                // מילה קצרה (1-3 תווים) - 3 תווים לפני ו3 אחרי
                allVariations.add('.{0,3}${RegExp.escape(baseVariation)}.{0,3}');
              } else {
                // מילה ארוכה (4+ תווים) - 2 תווים לפני ו2 אחרי
                allVariations.add('.{0,2}${RegExp.escape(baseVariation)}.{0,2}');
              }
            } else {
              // ללא אפשרויות מיוחדות - מילה מדויקת
              allVariations.add(RegExp.escape(baseVariation));
            }
          }
        }

        // הגבלה על מספר הוריאציות הכולל למילה אחת
        final limitedVariations = allVariations.length > 20
            ? allVariations.take(20).toList()
            : allVariations.toList();

        // במקום רגקס מורכב, נוסיף כל וריאציה בנפרד
        final finalPattern = limitedVariations.length == 1
            ? limitedVariations.first
            : '(${limitedVariations.join('|')})';

        regexTerms.add(finalPattern);
      } else {
        // fallback למילה המקורית
        regexTerms.add(word);
      }
    }

    return regexTerms;
  }

  /// מחשב את maxExpansions בהתבסס על סוג החיפוש
  int _calculateMaxExpansionsForCount(bool fuzzy, int termCount,
      {Map<String, Map<String, bool>>? searchOptions, List<String>? words}) {
    // בדיקה אם יש חיפוש עם סיומות או קידומות ואיזה מילים
    bool hasSuffixOrPrefix = false;
    int shortestWordLength = 10; // ערך התחלתי גבוה

    if (searchOptions != null && words != null) {
      for (int i = 0; i < words.length; i++) {
        final word = words[i];
        final wordKey = '${word}_$i';
        final wordOptions = searchOptions[wordKey] ?? {};

        if (wordOptions['סיומות'] == true ||
            wordOptions['קידומות'] == true ||
            wordOptions['קידומות דקדוקיות'] == true ||
            wordOptions['סיומות דקדוקיות'] == true ||
            wordOptions['חלק ממילה'] == true) {
          hasSuffixOrPrefix = true;
          shortestWordLength = math.min(shortestWordLength, word.length);
        }
      }
    }

    if (fuzzy) {
      return 50; // חיפוש מקורב
    } else if (hasSuffixOrPrefix) {
      // התאמת המגבלה לפי אורך המילה הקצרה ביותר עם אפשרויות מתקדמות
      if (shortestWordLength <= 1) {
        return 2000; // מילה של תו אחד - הגבלה קיצונית
      } else if (shortestWordLength <= 2) {
        return 3000; // מילה של 2 תווים - הגבלה בינונית
      } else if (shortestWordLength <= 3) {
        return 4000; // מילה של 3 תווים - הגבלה קלה
      } else {
        return 5000; // מילה ארוכה - הגבלה מלאה
      }
    } else if (termCount > 1) {
      return 100; // חיפוש של כמה מילים - צריך expansions גבוה יותר
    } else {
      return 10; // מילה אחת - expansions נמוך
    }
  }

  // פונקציות עזר ליצירת וריאציות כתיב מלא/חסר ודקדוקיות
  List<String> _generateFullPartialSpellingVariations(String word) {
    if (word.isEmpty) return [word];

    final variations = <String>{word}; // המילה המקורית

    // מוצא את כל המיקומים של י, ו, וגרשיים
    final chars = word.split('');
    final optionalIndices = <int>[];

    // מוצא אינדקסים של תווים שיכולים להיות אופציונליים
    for (int i = 0; i < chars.length; i++) {
      if (chars[i] == 'י' ||
          chars[i] == 'ו' ||
          chars[i] == "'" ||
          chars[i] == '"') {
        optionalIndices.add(i);
      }
    }

    // יוצר את כל הצירופים האפשריים (2^n אפשרויות)
    final numCombinations = 1 << optionalIndices.length; // 2^n

    for (int combination = 0; combination < numCombinations; combination++) {
      final variant = <String>[];

      for (int i = 0; i < chars.length; i++) {
        final optionalIndex = optionalIndices.indexOf(i);

        if (optionalIndex != -1) {
          // זה תו אופציונלי - בודק אם לכלול אותו בצירוף הזה
          final shouldInclude = (combination & (1 << optionalIndex)) != 0;
          if (shouldInclude) {
            variant.add(chars[i]);
          }
        } else {
          // תו רגיל - תמיד כולל
          variant.add(chars[i]);
        }
      }

      variations.add(variant.join(''));
    }

    return variations.toList();
  }

  List<String> _generateFullMorphologicalVariations(String word) {
    // פונקציה פשוטה שמחזירה את המילה עם קידומות וסיומות בסיסיות
    final variations = <String>{word};

    // קידומות בסיסיות
    final prefixes = ['ב', 'ה', 'ו', 'כ', 'ל', 'מ', 'ש'];
    // סיומות בסיסיות
    final suffixes = ['ה', 'ים', 'ות', 'י', 'ך', 'נו', 'כם', 'הם'];

    // הוספת קידומות
    for (final prefix in prefixes) {
      variations.add('$prefix$word');
    }

    // הוספת סיומות
    for (final suffix in suffixes) {
      variations.add('$word$suffix');
    }

    // הוספת קידומות וסיומות יחד
    for (final prefix in prefixes) {
      for (final suffix in suffixes) {
        variations.add('$prefix$word$suffix');
      }
    }

    return variations.toList();
  }

  List<String> _generatePrefixVariations(String word) {
    final variations = <String>{word};
    final prefixes = ['ב', 'ה', 'ו', 'כ', 'ל', 'מ', 'ש'];

    for (final prefix in prefixes) {
      variations.add('$prefix$word');
    }

    return variations.toList();
  }

  List<String> _generateSuffixVariations(String word) {
    final variations = <String>{word};
    final suffixes = ['ה', 'ים', 'ות', 'י', 'ך', 'נו', 'כם', 'הם'];

    for (final suffix in suffixes) {
      variations.add('$word$suffix');
    }

    return variations.toList();
  }

  /// ספירה מקבצת של תוצאות עבור מספר facets בבת אחת - לשיפור ביצועים
  Future<Map<String, int>> countTextsForMultipleFacets(
      String query, List<String> books, List<String> facets,
      {bool fuzzy = false,
      int distance = 2,
      Map<String, String>? customSpacing,
      Map<int, List<String>>? alternativeWords,
      Map<String, Map<String, bool>>? searchOptions}) async {
    print(
        '🔍 TantivyDataProvider: Starting batch count for ${facets.length} facets');
    final stopwatch = Stopwatch()..start();

    final index = await engine;
    final results = <String, int>{};

    // בדיקה אם יש מרווחים מותאמים אישית, מילים חילופיות או אפשרויות חיפוש
    final hasCustomSpacing = customSpacing != null && customSpacing.isNotEmpty;
    final hasAlternativeWords =
        alternativeWords != null && alternativeWords.isNotEmpty;
    final hasSearchOptions = searchOptions != null && searchOptions.isNotEmpty;

    // המרת החיפוש לפורמט המנוע החדש - בדיוק כמו ב-countTexts
    final words = query.trim().split(RegExp(r'\s+'));
    final List<String> regexTerms;
    final int effectiveSlop;

    if (hasAlternativeWords || hasSearchOptions) {
      regexTerms =
          _buildAdvancedQueryForCount(words, alternativeWords, searchOptions);
      effectiveSlop = hasCustomSpacing
          ? _getMaxCustomSpacingForCount(customSpacing, words.length)
          : (fuzzy ? distance : 0);
    } else if (fuzzy) {
      regexTerms = words;
      effectiveSlop = distance;
    } else if (words.length == 1) {
      regexTerms = [query];
      effectiveSlop = 0;
    } else if (hasCustomSpacing) {
      regexTerms = words;
      effectiveSlop = _getMaxCustomSpacingForCount(customSpacing, words.length);
    } else {
      regexTerms = words;
      effectiveSlop = distance;
    }

    final int maxExpansions = _calculateMaxExpansionsForCount(
        fuzzy, regexTerms.length,
        searchOptions: searchOptions, words: words);

    // ביצוע ספירה עבור כל facet - בזה אחר זה (לא במקביל כי זה לא עובד)
    int processedCount = 0;
    int zeroResultsCount = 0;

    for (final facet in facets) {
      try {
        print(
            '🔍 Counting facet: $facet (${processedCount + 1}/${facets.length})');
        final facetStopwatch = Stopwatch()..start();
        final count = await index.count(
            regexTerms: regexTerms,
            facets: [facet],
            slop: effectiveSlop,
            maxExpansions: maxExpansions);
        facetStopwatch.stop();
        print(
            '✅ Facet $facet: $count (${facetStopwatch.elapsedMilliseconds}ms)');
        results[facet] = count;

        processedCount++;
        if (count == 0) {
          zeroResultsCount++;
        }

        // אם יש יותר מדי facets עם 0 תוצאות, נפסיק מוקדם
        if (processedCount >= 10 && zeroResultsCount > processedCount * 0.8) {
          print('⚠️ Too many zero results, stopping early');
          // נמלא את השאר עם 0
          for (int i = processedCount; i < facets.length; i++) {
            results[facets[i]] = 0;
          }
          break;
        }
      } catch (e) {
        print('❌ Error counting facet $facet: $e');
        results[facet] = 0;
        processedCount++;
        zeroResultsCount++;
      }
    }

    stopwatch.stop();
    print(
        '✅ TantivyDataProvider: Batch count completed in ${stopwatch.elapsedMilliseconds}ms');
    print(
        '📊 Results: ${results.entries.where((e) => e.value > 0).map((e) => '${e.key}: ${e.value}').join(', ')}');

    return results;
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

  // פונקציות עזר ליצירת regex קומפקטי לחיפושים דקדוקיים

  /// יוצר דפוס רגקס קומפקטי לחיפוש מילה עם קידומות דקדוקיות
  String _createPrefixRegexPattern(String word) {
    if (word.isEmpty) return word;
    // שימוש בתבנית קבועה ויעילה - מוגבלת לקידומות נפוצות
    return r'(ו|מ|כ|ב|ש|ל|ה|ד)?(כ|ב|ש|ל|ה|ד)?(ה)?' + RegExp.escape(word);
  }

  /// יוצר דפוס רגקס קומפקטי לחיפוש מילה עם סיומות דקדוקיות
  String _createSuffixRegexPattern(String word) {
    if (word.isEmpty) return word;
    // שימוש בתבנית קבועה ויעילה - מוגבלת לסיומות נפוצות
    const suffixPattern =
        r'(ות|ים|יה|יו|יך|ינו|יכם|יכן|יהם|יהן|י|ך|ו|ה|נו|כם|כן|ם|ן)?';
    return RegExp.escape(word) + suffixPattern;
  }

  /// יוצר דפוס רגקס קומפקטי לחיפוש מילה עם קידומות וסיומות דקדוקיות יחד
  String _createFullMorphologicalRegexPattern(String word) {
    if (word.isEmpty) return word;
    // שילוב של קידומות וסיומות - מוגבל לנפוצות ביותר
    const prefixPattern = r'(ו|מ|כ|ב|ש|ל|ה|ד)?(כ|ב|ש|ל|ה|ד)?(ה)?';
    const suffixPattern =
        r'(ות|ים|יה|יו|יך|ינו|יכם|יכן|יהם|יהן|י|ך|ו|ה|נו|כם|כן|ם|ן)?';
    return prefixPattern + RegExp.escape(word) + suffixPattern;
  }
}
