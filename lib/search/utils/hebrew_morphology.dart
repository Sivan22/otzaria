import 'package:otzaria/search/utils/regex_patterns.dart';

/// כלים לטיפול בקידומות, סיומות וכתיב מלא/חסר בעברית (גרסה משולבת ומשופרת)
/// 
/// הערה: הרגקסים הבסיסיים עברו לקובץ regex_patterns.dart לארגון טוב יותר
class HebrewMorphology {
  // קידומות דקדוקיות בסיסיות
  static const List<String> _basicPrefixes = [
    'ד',
    'ה',
    'ו',
    'ב',
    'ל',
    'מ',
    'כ',
    'ש'
  ];

  // צירופי קידומות נפוצים
  static const List<String> _combinedPrefixes = [
    // צירופים עם ו'
    'וה', 'וב', 'ול', 'ומ', 'וכ',
    // צירופים עם ש'
    'שה', 'שב', 'של', 'שמ', 'שמה', 'שכ',
    // צירופים עם ד'
    'דה', 'דב', 'דל', 'דמ', 'דמה', 'דכ',
    // צירופים עם כ'
    'כב', 'כל', 'כש', 'כשה',
    // צירופים עם ל'
    'לכ', 'לכש',
    // צירופים מורכבים עם ו'
    'ולכ', 'ולכש', 'ולכשה',
    // צירופים עם מ'
    'מש', 'משה'
  ];

  // סיומות דקדוקיות (מסודרות לפי אורך יורד)
  static const List<String> _allSuffixes = [
    // צירופים לנקבה רבות + שייכות (הארוכים ביותר)
    'ותיהם', 'ותיהן', 'ותיכם', 'ותיכן', 'ותינו',
    'ותֵיהם', 'ותֵיהן', 'ותֵיכם', 'ותֵיכן', 'ותֵינוּ',
    'ותיך', 'ותיו', 'ותיה', 'ותי',
    'ותֶיךָ', 'ותַיִךְ', 'ותָיו', 'ותֶיהָ', 'ותַי',
    // צירופי ריבוי + שייכות
    'יהם', 'יהן', 'יכם', 'יכן', 'ינו', 'יות', 'יי', 'יך', 'יו', 'יה', 'יא',
    'יַי', 'יךָ', 'יִךְ', 'יהָ',
    // סיומות בסיסיות
    'ים', 'ות', 'כם', 'כן', 'נו', 'הּ',
    'י', 'ך', 'ו', 'ה', 'ם', 'ן',
    'ךָ', 'ךְ'
  ];

  // --- מתודות ליצירת Regex (מהקוד הראשון - היעיל יותר) ---

  /// יוצר דפוס רגקס קומפקטי לחיפוש מילה עם קידומות דקדוקיות
  static String createPrefixRegexPattern(String word) {
    return SearchRegexPatterns.createPrefixPattern(word);
  }

  /// יוצר דפוס רגקס קומפקטי לחיפוש מילה עם סיומות דקדוקיות
  static String createSuffixRegexPattern(String word) {
    return SearchRegexPatterns.createSuffixPattern(word);
  }

  /// יוצר דפוס רגקס קומפקטי לחיפוש מילה עם קידומות וסיומות דקדוקיות יחד
  static String createFullMorphologicalRegexPattern(
    String word, {
    bool includePrefixes = true,
    bool includeSuffixes = true,
  }) {
    return SearchRegexPatterns.createFullMorphologicalPattern(word);
  }

  // --- מתודות ליצירת רשימות וריאציות (נשמרו כפי שהן) ---

  /// יוצר רשימה של כל האפשרויות עם קידומות דקדוקיות
  static List<String> generatePrefixVariations(String word) {
    if (word.isEmpty) return [word];
    final variations = <String>{word};
    variations.addAll(_basicPrefixes.map((p) => '$p$word'));
    variations.addAll(_combinedPrefixes.map((p) => '$p$word'));
    return variations.toList();
  }

  /// יוצר רשימה של כל האפשרויות עם סיומות דקדוקיות
  static List<String> generateSuffixVariations(String word) {
    if (word.isEmpty) return [word];
    final variations = <String>{word};
    variations.addAll(_allSuffixes.map((s) => '$word$s'));
    return variations.toList();
  }

  /// יוצר רשימה של כל האפשרויות עם קידומות וסיומות יחד
  static List<String> generateFullMorphologicalVariations(String word) {
    if (word.isEmpty) return [word];
    final variations = <String>{word};
    final allPrefixes = [''] + _basicPrefixes + _combinedPrefixes;
    for (final prefix in allPrefixes) {
      for (final suffix in _allSuffixes) {
        variations.add('$prefix$word$suffix');
      }
    }
    return variations.toList();
  }

  // --- מתודות שירות (נשארו כפי שהן) ---

  /// בודק אם מילה מכילה קידומת דקדוקית
  static bool hasGrammaticalPrefix(String word) {
    return SearchRegexPatterns.hasGrammaticalPrefix(word);
  }

  /// בודק אם מילה מכילה סיומת דקדוקית
  static bool hasGrammaticalSuffix(String word) {
    return SearchRegexPatterns.hasGrammaticalSuffix(word);
  }

  /// מחלץ את השורש של מילה (מסיר קידומות וסיומות)
  static String extractRoot(String word) {
    return SearchRegexPatterns.extractRoot(word);
  }

  /// מחזיר רשימה של קידומות בסיסיות (לתמיכה לאחור)
  static List<String> getBasicPrefixes() => ['ה', 'ו', 'ב', 'ל', 'מ', 'כ', 'ש'];

  /// מחזיר רשימה של סיומות בסיסיות (לתמיכה לאחור)
  static List<String> getBasicSuffixes() =>
      ['ים', 'ות', 'י', 'ך', 'ו', 'ה', 'נו', 'כם', 'כן', 'ם', 'ן'];

  // --- מתודות לכתיב מלא/חסר (מהקוד השני) ---

  /// יוצר דפוס רגקס לכתיב מלא/חסר על בסיס רשימת וריאציות
  static String createFullPartialSpellingPattern(String word) {
    return SearchRegexPatterns.createFullPartialSpellingPattern(word);
  }

  /// יוצר רשימה של וריאציות כתיב מלא/חסר
  static List<String> generateFullPartialSpellingVariations(String word) {
    return SearchRegexPatterns.generateFullPartialSpellingVariations(word);
  }
}
