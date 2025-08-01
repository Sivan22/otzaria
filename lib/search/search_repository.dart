import 'dart:math' as math;
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
            } else if (hasPrefix) {
              // קידומות רגילות - הגבלה חכמה לפי אורך המילה
              if (baseVariation.length <= 1) {
                // מילה של תו אחד - הגבלה קיצונית (מקסימום 5 תווים קידומת)
                allVariations.add('.{1,5}' + RegExp.escape(baseVariation));
              } else if (baseVariation.length <= 2) {
                // מילה של 2 תווים - הגבלה בינונית (מקסימום 4 תווים קידומת)
                allVariations.add('.{1,4}' + RegExp.escape(baseVariation));
              } else if (baseVariation.length <= 3) {
                // מילה של 3 תווים - הגבלה קלה (מקסימום 3 תווים קידומת)
                allVariations.add('.{1,3}' + RegExp.escape(baseVariation));
              } else {
                // מילה ארוכה - ללא הגבלה
                allVariations.add('.*' + RegExp.escape(baseVariation));
              }
            } else if (hasSuffix) {
              // סיומות רגילות - הגבלה חכמה לפי אורך המילה
              if (baseVariation.length <= 1) {
                // מילה של תו אחד - הגבלה קיצונית (מקסימום 7 תווים סיומת)
                allVariations.add(RegExp.escape(baseVariation) + '.{1,7}');
              } else if (baseVariation.length <= 2) {
                // מילה של 2 תווים - הגבלה בינונית (מקסימום 6 תווים סיומת)
                allVariations.add(RegExp.escape(baseVariation) + '.{1,6}');
              } else if (baseVariation.length <= 3) {
                // מילה של 3 תווים - הגבלה קלה (מקסימום 5 תווים סיומת)
                allVariations.add(RegExp.escape(baseVariation) + '.{1,5}');
              } else {
                // מילה ארוכה - ללא הגבלה
                allVariations.add(RegExp.escape(baseVariation) + '.*');
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
            wordOptions['סיומות דקדוקיות'] == true) {
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
