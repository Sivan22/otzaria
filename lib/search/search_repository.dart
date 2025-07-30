import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/search/utils/hebrew_morphology.dart';
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
    final words = query.trim().split(RegExp(r'\s+'));
    final List<String> regexTerms;
    final int effectiveSlop;

    if (hasAlternativeWords || hasSearchOptions) {
      // יש מילים חילופיות או אפשרויות חיפוש - נבנה queries מתקדמים
      print('🔄 בונה query מתקדם');
      if (hasAlternativeWords) print('🔄 מילים חילופיות: $alternativeWords');
      if (hasSearchOptions) print('🔄 אפשרויות חיפוש: $searchOptions');

      regexTerms = _buildAdvancedQuery(words, alternativeWords, searchOptions);
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
    final int maxExpansions = _calculateMaxExpansions(fuzzy, regexTerms.length);

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
            baseVariations =
                HebrewMorphology.generateFullPartialSpellingVariations(option);
          }

          // עבור כל וריאציה של כתיב, מוסיפים את האפשרויות הדקדוקיות
          for (final baseVariation in baseVariations) {
            if (hasGrammaticalPrefixes && hasGrammaticalSuffixes) {
              // שתי האפשרויות יחד
              allVariations.addAll(
                  HebrewMorphology.generateFullMorphologicalVariations(
                      baseVariation));
            } else if (hasGrammaticalPrefixes) {
              // רק קידומות דקדוקיות
              allVariations.addAll(
                  HebrewMorphology.generatePrefixVariations(baseVariation));
            } else if (hasGrammaticalSuffixes) {
              // רק סיומות דקדוקיות
              allVariations.addAll(
                  HebrewMorphology.generateSuffixVariations(baseVariation));
            } else if (hasPrefix) {
              // קידומות רגילות
              allVariations.add('.*' + RegExp.escape(baseVariation));
            } else if (hasSuffix) {
              // סיומות רגילות
              allVariations.add(RegExp.escape(baseVariation) + '.*');
            } else {
              // ללא אפשרויות מיוחדות - מילה מדויקת
              allVariations.add(RegExp.escape(baseVariation));
            }
          }
        }

        // במקום רגקס מורכב, נוסיף כל וריאציה בנפרד
        final finalPattern = allVariations.length == 1
            ? allVariations.first
            : '(${allVariations.join('|')})';

        regexTerms.add(finalPattern);
        print(
            '🔄 מילה $i: $finalPattern (קידומות: $hasPrefix, סיומות: $hasSuffix, קידומות דקדוקיות: $hasGrammaticalPrefixes, סיומות דקדוקיות: $hasGrammaticalSuffixes, כתיב מלא/חסר: $hasFullPartialSpelling)');
      } else {
        // fallback למילה המקורית
        regexTerms.add(word);
      }
    }

    return regexTerms;
  }

  /// מחשב את maxExpansions בהתבסס על סוג החיפוש
  int _calculateMaxExpansions(bool fuzzy, int termCount) {
    if (fuzzy) {
      return 50; // חיפוש מקורב
    } else if (termCount > 1) {
      return 100; // חיפוש של כמה מילים - צריך expansions גבוה יותר
    } else {
      return 10; // מילה אחת - expansions נמוך
    }
  }
}
