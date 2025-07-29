import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
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
      Map<int, List<String>>? alternativeWords}) async {
    final index = await TantivyDataProvider.instance.engine;

    // בדיקה אם יש מרווחים מותאמים אישית או מילים חילופיות
    final hasCustomSpacing = customSpacing != null && customSpacing.isNotEmpty;
    final hasAlternativeWords =
        alternativeWords != null && alternativeWords.isNotEmpty;

    // המרת החיפוש לפורמט המנוע החדש
    final words = query.trim().split(RegExp(r'\s+'));
    final List<String> regexTerms;
    final int effectiveSlop;

    if (hasAlternativeWords) {
      // יש מילים חילופיות - נבנה OR queries
      print('🔄 בונה query עם מילים חילופיות: $alternativeWords');
      regexTerms = _buildAlternativeWordsQuery(words, alternativeWords);
      print('🔄 RegexTerms עם חלופות: $regexTerms');
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

  /// בונה query עם מילים חילופיות באמצעות רגקס
  List<String> _buildAlternativeWordsQuery(
      List<String> words, Map<int, List<String>> alternativeWords) {
    List<String> regexTerms = [];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final alternatives = alternativeWords[i];

      if (alternatives != null && alternatives.isNotEmpty) {
        // יש מילים חילופיות - נבנה רגקס עם OR
        final allOptions =
            [word, ...alternatives].where((w) => w.trim().isNotEmpty).toList();
        if (allOptions.isNotEmpty) {
          // נבנה רגקס: (word1|word2|word3)
          final regexPattern = '(${allOptions.join('|')})';
          regexTerms.add(regexPattern);
          print('🔄 מילה $i עם חלופות: $regexPattern');
        } else {
          // אם כל האפשרויות ריקות, נשתמש במילה המקורית
          regexTerms.add(word);
        }
      } else {
        // אין מילים חילופיות - מילה רגילה
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
