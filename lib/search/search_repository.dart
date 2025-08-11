import 'dart:isolate';
import 'dart:math' as math;
import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/search/utils/hebrew_morphology.dart';
import 'package:otzaria/search/utils/regex_patterns.dart';
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
    final index = await TantivyDataProvider.instance.engine;

    // בדיקה אם יש מרווחים מותאמים אישית, מילים חילופיות או אפשרויות חיפוש
    final hasCustomSpacing = customSpacing != null && customSpacing.isNotEmpty;
    final hasAlternativeWords =
        alternativeWords != null && alternativeWords.isNotEmpty;
    final hasSearchOptions = searchOptions != null && searchOptions.isNotEmpty;

    // המרת החיפוש לפורמט המנוע החדש
    // סינון מחרוזות ריקות שנוצרות כאשר יש רווחים בסוף השאילתה
    final words = query
        .trim()
        .split(SearchRegexPatterns.wordSplitter)
        .where((word) => word.isNotEmpty)
        .toList();
    final List<String> regexTerms;
    final int effectiveSlop;

    if (hasAlternativeWords || hasSearchOptions) {
      // יש מילים חילופיות או אפשרויות חיפוש - נבנה queries מתקדמים
      print('🔄 בונה query מתקדם');
      if (hasAlternativeWords) print('🔄 מילים חילופיות: $alternativeWords');
      if (hasSearchOptions) print('🔄 אפשרויות חיפוש: $searchOptions');

      regexTerms = await Isolate.run(
          () => _buildAdvancedQuery(words, alternativeWords, searchOptions));
      print('🔄 RegexTerms מתקדם: $regexTerms');
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

    return await index.search(
        regexTerms: regexTerms,
        facets: facets,
        limit: limit,
        slop: effectiveSlop,
        maxExpansions: maxExpansions,
        order: order);
  }

  /// Streams search results in batches for better performance and user experience
  Stream<List<SearchResult>> searchTextsStream(
      String query, List<String> facets, int totalLimit,
      {ResultsOrder order = ResultsOrder.relevance,
      bool fuzzy = false,
      int distance = 2,
      int batchSize = 20, // Load 20 results at a time
      Map<String, String>? customSpacing,
      Map<int, List<String>>? alternativeWords,
      Map<String, Map<String, bool>>? searchOptions}) async* {
    
    int offset = 0;
    List<SearchResult> allResults = [];
    
    while (offset < totalLimit) {
      final currentBatchSize = math.min(batchSize, totalLimit - offset);
      
      try {
        // Search for current batch
        final batchResults = await _searchBatch(
          query, facets, currentBatchSize, offset,
          order: order,
          fuzzy: fuzzy,
          distance: distance,
          customSpacing: customSpacing,
          alternativeWords: alternativeWords,
          searchOptions: searchOptions,
        );
        
        if (batchResults.isEmpty) {
          break; // No more results
        }
        
        allResults.addAll(batchResults);
        yield List<SearchResult>.from(allResults); // Yield accumulated results
        
        offset += batchResults.length;
        
        // Small delay to prevent overwhelming the UI
        await Future.delayed(const Duration(milliseconds: 50));
        
      } catch (e) {
        print('Error in search batch: $e');
        break;
      }
    }
  }

  /// Helper method to search a specific batch of results
  Future<List<SearchResult>> _searchBatch(
      String query, List<String> facets, int limit, int offset,
      {ResultsOrder order = ResultsOrder.relevance,
      bool fuzzy = false,
      int distance = 2,
      Map<String, String>? customSpacing,
      Map<int, List<String>>? alternativeWords,
      Map<String, Map<String, bool>>? searchOptions}) async {
    
    final index = await TantivyDataProvider.instance.engine;

    // Same logic as original searchTexts but with offset support
    final hasCustomSpacing = customSpacing != null && customSpacing.isNotEmpty;
    final hasAlternativeWords = alternativeWords != null && alternativeWords.isNotEmpty;
    final hasSearchOptions = searchOptions != null && searchOptions.isNotEmpty;

    final words = query.trim().split(SearchRegexPatterns.wordSplitter)
        .where((word) => word.isNotEmpty)
        .toList();
    final List<String> regexTerms;
    final int effectiveSlop;

    if (hasAlternativeWords || hasSearchOptions) {
      regexTerms = await Isolate.run(() => _buildAdvancedQuery(words, alternativeWords, searchOptions));
      effectiveSlop = hasCustomSpacing
          ? _getMaxCustomSpacing(customSpacing, words.length)
          : (fuzzy ? distance : 0);
    } else if (fuzzy) {
      regexTerms = words;
      effectiveSlop = distance;
    } else if (words.length == 1) {
      regexTerms = [query];
      effectiveSlop = 0;
    } else if (hasCustomSpacing) {
      regexTerms = words;
      effectiveSlop = _getMaxCustomSpacing(customSpacing, words.length);
    } else {
      regexTerms = words;
      effectiveSlop = distance;
    }

    final int maxExpansions = _calculateMaxExpansions(fuzzy, regexTerms.length,
        searchOptions: searchOptions, words: words);

    // Use search with offset (if the search engine supports it)
    return await index.search(
        regexTerms: regexTerms,
        facets: facets,
        limit: limit,
        slop: effectiveSlop,
        maxExpansions: maxExpansions,
        order: order);
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
          List<String> baseVariations = [option];

          // אם יש כתיב מלא/חסר, נוצר את כל הווריאציות של כתיב
          if (hasFullPartialSpelling) {
            // הגבלה למילים קצרות - כתיב מלא/חסר יכול ליצור הרבה וריאציות
            if (option.length <= 3) {
              // למילים קצרות, נגביל את מספר הוריאציות
              final allSpellingVariations =
                  HebrewMorphology.generateFullPartialSpellingVariations(
                      option);
              // נקח רק את ה-5 הראשונות כדי למנוע יותר מדי expansions
              baseVariations = allSpellingVariations.take(5).toList();
            } else {
              baseVariations =
                  HebrewMorphology.generateFullPartialSpellingVariations(
                      option);
            }
          }

          // עבור כל וריאציה של כתיב, מוסיפים את האפשרויות הדקדוקיות
          for (final baseVariation in baseVariations) {
            if (hasGrammaticalPrefixes && hasGrammaticalSuffixes) {
              // שתי האפשרויות יחד - הגבלה למילים קצרות
              if (baseVariation.length <= 2) {
                // למילים קצרות, נשתמש ברגקס קומפקטי במקום רשימת וריאציות
                allVariations.add(
                    HebrewMorphology.createFullMorphologicalRegexPattern(
                        baseVariation));
              } else {
                allVariations.addAll(
                    HebrewMorphology.generateFullMorphologicalVariations(
                        baseVariation));
              }
            } else if (hasGrammaticalPrefixes) {
              // רק קידומות דקדוקיות - הגבלה למילים קצרות
              if (baseVariation.length <= 2) {
                // למילים קצרות, נשתמש ברגקס קומפקטי
                allVariations.add(
                    HebrewMorphology.createPrefixRegexPattern(baseVariation));
              } else {
                allVariations.addAll(
                    HebrewMorphology.generatePrefixVariations(baseVariation));
              }
            } else if (hasGrammaticalSuffixes) {
              // רק סיומות דקדוקיות - הגבלה למילים קצרות
              if (baseVariation.length <= 2) {
                // למילים קצרות, נשתמש ברגקס קומפקטי
                allVariations.add(
                    HebrewMorphology.createSuffixRegexPattern(baseVariation));
              } else {
                allVariations.addAll(
                    HebrewMorphology.generateSuffixVariations(baseVariation));
              }
            } else if (hasPrefix && hasSuffix) {
              // קידומות וסיומות יחד - משתמש בחיפוש "חלק ממילה"
              allVariations.add(
                  SearchRegexPatterns.createPartialWordPattern(baseVariation));
            } else if (hasPrefix) {
              // קידומות רגילות - שימוש ברגקס מרכזי
              allVariations.add(
                  SearchRegexPatterns.createPrefixSearchPattern(baseVariation));
            } else if (hasSuffix) {
              // סיומות רגילות - שימוש ברגקס מרכזי
              allVariations.add(
                  SearchRegexPatterns.createSuffixSearchPattern(baseVariation));
            } else if (hasPartialWord) {
              // חלק ממילה - שימוש ברגקס מרכזי
              allVariations.add(
                  SearchRegexPatterns.createPartialWordPattern(baseVariation));
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
