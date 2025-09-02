import 'dart:math' as math;
import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/search/utils/regex_patterns.dart';
import 'package:otzaria/search/services/search_isolate_service.dart';
import 'package:search_engine/search_engine.dart';

/// Performs a search operation across indexed texts.
///
/// [query] The search query string
/// [facets] List of facets to search within
/// [limit] Maximum number of results to return
/// [order] Sort order for results
/// [fuzzy] Whether to perform fuzzy matching
/// [distance] Default distance between words (slop)
/// [customSpacing] Custom spacing between specific word pairs
/// [alternativeWords] Alternative words for each word position (OR queries)
/// [searchOptions] Search options for each word (prefixes, suffixes, etc.)
///
/// Returns a Future containing a list of search results
///
class SearchRepository {
  Future<List<SearchResult>> searchTexts(
      String query, List<String> facets, int limit,
      {ResultsOrder order = ResultsOrder.relevance,
      bool fuzzy = false,
      int distance = 2,
      Map<String, String>? customSpacing,
      Map<int, List<String>>? alternativeWords,
      Map<String, Map<String, bool>>? searchOptions}) async {
    print('🚀 searchTexts called with query: "$query"');

    // בדיקת וריאציות כתיב מלא/חסר
    print('🔍 Testing spelling variations for "ראשית":');
    final testVariations =
        SearchRegexPatterns.generateFullPartialSpellingVariations('ראשית');
    print('   variations: $testVariations');

    // בדיקת createPrefixPattern עבור כל וריאציה
    for (final variation in testVariations) {
      final prefixPattern = SearchRegexPatterns.createPrefixPattern(variation);
      print('   $variation -> $prefixPattern');
    }

    // בדיקת createSpellingWithPrefixPattern
    final finalPattern =
        SearchRegexPatterns.createSpellingWithPrefixPattern('ראשית');
    print('🔍 Final createSpellingWithPrefixPattern result: $finalPattern');
    // בדיקה אם האינדקס רץ - אם כן, נשתמש ב-Isolate לחיפוש
    final isIndexing = TantivyDataProvider.instance.isIndexing.value;

    if (isIndexing) {
      print('🔄 Indexing in progress, using isolate search service');
      // שימוש ב-SearchIsolateService כשהאינדקס רץ
      final isolateSearchOptions = SearchOptions(
        fuzzy: fuzzy,
        distance: distance,
        customSpacing: customSpacing,
        alternativeWords: alternativeWords,
        searchOptions: searchOptions,
        order: order,
      );

      final resultWrapper = await SearchIsolateService.searchTexts(
        query,
        facets,
        limit,
        isolateSearchOptions,
      );

      if (resultWrapper.error != null) {
        print('❌ Search isolate error: ${resultWrapper.error}');
        // fallback לחיפוש רגיל
        final index = await TantivyDataProvider.instance.engine;
        return await _performDirectSearch(index, query, facets, limit, order,
            fuzzy, distance, customSpacing, alternativeWords, searchOptions);
      }

      print(
          '✅ Isolate search completed, found ${resultWrapper.results.length} results');
      return resultWrapper.results;
    } else {
      // שימוש רגיל כשהאינדקס לא רץ
      final index = await TantivyDataProvider.instance.engine;
      return await _performDirectSearch(index, query, facets, limit, order,
          fuzzy, distance, customSpacing, alternativeWords, searchOptions);
    }
  }

  /// ביצוע חיפוש ישיר (ללא Isolate)
  Future<List<SearchResult>> _performDirectSearch(
    SearchEngine index,
    String query,
    List<String> facets,
    int limit,
    ResultsOrder order,
    bool fuzzy,
    int distance,
    Map<String, String>? customSpacing,
    Map<int, List<String>>? alternativeWords,
    Map<String, Map<String, bool>>? searchOptions,
  ) async {
    // בדיקה אם יש מרווחים מותאמים אישית, מילים חילופיות או אפשרויות חיפוש
    final hasCustomSpacing = customSpacing != null && customSpacing.isNotEmpty;
    final hasAlternativeWords =
        alternativeWords != null && alternativeWords.isNotEmpty;
    final hasSearchOptions = searchOptions != null &&
        searchOptions.isNotEmpty &&
        searchOptions.values.any((wordOptions) =>
            wordOptions.values.any((isEnabled) => isEnabled == true));

    print('🔍 hasSearchOptions: $hasSearchOptions');
    print('🔍 hasAlternativeWords: $hasAlternativeWords');

    // המרת החיפוש לפורמט המנוע החדש
    // סינון מחרוזות ריקות שנוצרות כאשר יש רווחים בסוף השאילתה
    final words = query
        .trim()
        .split(SearchRegexPatterns.wordSplitter)
        .where((word) => word.isNotEmpty)
        .toList();
    final List<String> regexTerms;
    final int effectiveSlop;

    // הודעת דיבוג לבדיקת search options
    if (searchOptions != null && searchOptions.isNotEmpty) {
      print('➡️Debug search options:');
      for (final entry in searchOptions.entries) {
        print('   ${entry.key}: ${entry.value}');
      }
    }

    if (hasAlternativeWords || hasSearchOptions) {
      // יש מילים חילופיות או אפשרויות חיפוש - נבנה queries מתקדמים
      print('🔄 בונה query מתקדם');
      if (hasAlternativeWords) print('🔄 מילים חילופיות: $alternativeWords');
      if (hasSearchOptions) print('🔄 אפשרויות חיפוש: $searchOptions');

      regexTerms = _buildAdvancedQuery(words, alternativeWords, searchOptions);
      print('🔄 RegexTerms מתקדם: $regexTerms');
      print(
          '🔄 effectiveSlop will be: ${hasCustomSpacing ? "custom" : (fuzzy ? distance.toString() : "0")}');
      effectiveSlop = hasCustomSpacing
          ? _getMaxCustomSpacing(customSpacing, words.length)
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
      effectiveSlop = _getMaxCustomSpacing(customSpacing, words.length);
    } else {
      // חיפוש מדוייק של כמה מילים
      regexTerms = words;
      effectiveSlop = distance;
    }

    // חישוב maxExpansions בהתבסס על סוג החיפוש
    final int maxExpansions = _calculateMaxExpansions(fuzzy, regexTerms.length,
        searchOptions: searchOptions, words: words);

    print('🔍 Final search params:');
    print('   regexTerms: $regexTerms');
    print('   facets: $facets');
    print('   limit: $limit');
    print('   slop: $effectiveSlop');
    print('   maxExpansions: $maxExpansions');
    print('🚀 Calling index.search...');

    final results = await index.search(
        regexTerms: regexTerms,
        facets: facets,
        limit: limit,
        slop: effectiveSlop,
        maxExpansions: maxExpansions,
        order: order);

    print('✅ Direct search completed, found ${results.length} results');
    return results;
  }

  /// מחשב את המרווח המקסימלי מהמרווחים המותאמים אישית
  int _getMaxCustomSpacing(Map<String, String> customSpacing, int wordCount) {
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
  List<String> _buildAdvancedQuery(
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
          // השתמש בפונקציה המשולבת החדשה
          final pattern = SearchRegexPatterns.createSearchPattern(
            option,
            hasPrefix: hasPrefix,
            hasSuffix: hasSuffix,
            hasGrammaticalPrefixes: hasGrammaticalPrefixes,
            hasGrammaticalSuffixes: hasGrammaticalSuffixes,
            hasPartialWord: hasPartialWord,
            hasFullPartialSpelling: hasFullPartialSpelling,
          );
          allVariations.add(pattern);
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
        // הודעת דיבוג עם הסבר על הלוגיקה
        final searchType = hasPrefix && hasSuffix
            ? 'קידומות+סיומות (חלק ממילה)'
            : hasGrammaticalPrefixes && hasGrammaticalSuffixes
                ? 'קידומות+סיומות דקדוקיות'
                : hasPrefix
                    ? 'קידומות'
                    : hasSuffix
                        ? 'סיומות'
                        : hasGrammaticalPrefixes
                            ? 'קידומות דקדוקיות'
                            : hasGrammaticalSuffixes
                                ? 'סיומות דקדוקיות'
                                : hasPartialWord
                                    ? 'חלק ממילה'
                                    : hasFullPartialSpelling
                                        ? 'כתיב מלא/חסר'
                                        : 'מדויק';

        print('🔄 מילה $i: $finalPattern (סוג חיפוש: $searchType)');
      } else {
        // fallback למילה המקורית
        regexTerms.add(word);
      }
    }

    return regexTerms;
  }

  /// מחשב את maxExpansions בהתבסס על סוג החיפוש
  int _calculateMaxExpansions(bool fuzzy, int termCount,
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
}
