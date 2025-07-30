/// כלים לטיפול בקידומות וסיומות דקדוקיות בעברית
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

  /// יוצר דפוס רגקס לחיפוש מילה עם קידומות דקדוקיות בלבד
  static String createPrefixRegexPattern(String word) {
    if (word.isEmpty) return word;
    return r'(ו|מ|כ|ב|ש|ל|ה|ד)?(כ|ב|ש|ל|ה|ד)?(ה)?' + RegExp.escape(word);
  }

  /// יוצר רשימה של כל האפשרויות עם קידומות דקדוקיות
  static List<String> generatePrefixVariations(String word) {
    if (word.isEmpty) return [word];

    final variations = <String>{word}; // המילה המקורית

    // הוספת קידומות בסיסיות
    for (final prefix in _basicPrefixes) {
      variations.add('$prefix$word');
    }

    // הוספת צירופי קידומות
    for (final prefix in _combinedPrefixes) {
      variations.add('$prefix$word');
    }

    return variations.toList();
  }

  /// יוצר דפוס רגקס לחיפוש מילה עם סיומות דקדוקיות בלבד
  static String createSuffixRegexPattern(String word) {
    if (word.isEmpty) return word;

    // בונים דפוס מאוחד לכל הסיומות (מסודר לפי אורך יורד כדי לתפוס את הארוכות יותר קודם)
    const suffixPattern =
        r'(ותי|ותַי|ותיך|ותֶיךָ|ותַיִךְ|ותיו|ותָיו|ותיה|ותֶיהָ|ותינו|ותֵינוּ|ותיכם|ותֵיכם|ותיכן|ותֵיכן|ותיהם|ותֵיהם|ותיהן|ותֵיהן|יות|יי|יַי|יך|יךָ|יִךְ|יו|יה|יא|יהָ|ינו|יכם|יכן|יהם|יהן|י|ך|ךָ|ךְ|ו|ה|הּ|נו|כם|כן|ם|ן|ים|ות)?';

    return RegExp.escape(word) + suffixPattern;
  }

  /// יוצר רשימה של כל האפשרויות עם סיומות דקדוקיות
  static List<String> generateSuffixVariations(String word) {
    if (word.isEmpty) return [word];

    final variations = <String>{word}; // המילה המקורית

    // הוספת כל הסיומות
    for (final suffix in _allSuffixes) {
      variations.add('$word$suffix');
    }

    return variations.toList();
  }

  /// יוצר דפוס רגקס לחיפוש מילה עם קידומות וסיומות דקדוקיות יחד
  static String createFullMorphologicalRegexPattern(
    String word, {
    bool includePrefixes = true,
    bool includeSuffixes = true,
  }) {
    if (word.isEmpty) return word;

    String pattern = RegExp.escape(word);

    if (includePrefixes) {
      pattern = r'(ו|מ|כ|ב|ש|ל|ה|ד)?(כ|ב|ש|ל|ה|ד)?(ה)?' + pattern;
    }

    if (includeSuffixes) {
      const suffixPattern =
          r'(ותי|ותַי|ותיך|ותֶיךָ|ותַיִךְ|ותיו|ותָיו|ותיה|ותֶיהָ|ותינו|ותֵינוּ|ותיכם|ותֵיכם|ותיכן|ותֵיכן|ותיהם|ותֵיהם|ותיהן|ותֵיהן|יות|יי|יַי|יך|יךָ|יִךְ|יו|יה|יא|יהָ|ינו|יכם|יכן|יהם|יהן|י|ך|ךָ|ךְ|ו|ה|הּ|נו|כם|כן|ם|ן|ים|ות)?';
      pattern = pattern + suffixPattern;
    }

    return pattern;
  }

  /// יוצר רשימה של כל האפשרויות עם קידומות וסיומות יחד
  static List<String> generateFullMorphologicalVariations(String word) {
    if (word.isEmpty) return [word];

    final variations = <String>{word}; // המילה המקורית

    // קידומות בלבד
    final prefixVariations = generatePrefixVariations(word);
    variations.addAll(prefixVariations);

    // סיומות בלבד
    final suffixVariations = generateSuffixVariations(word);
    variations.addAll(suffixVariations);

    // שילובים של קידומות + סיומות
    final allPrefixes = [''] + _basicPrefixes + _combinedPrefixes;
    for (final prefix in allPrefixes) {
      for (final suffix in _allSuffixes) {
        variations.add('$prefix$word$suffix');
      }
    }

    return variations.toList();
  }

  /// בודק אם מילה מכילה קידומת דקדוקית
  static bool hasGrammaticalPrefix(String word) {
    if (word.isEmpty) return false;
    final regex = RegExp(r'^(ו|מ|כ|ב|ש|ל|ה)+(.+)');
    return regex.hasMatch(word);
  }

  /// בודק אם מילה מכילה סיומת דקדוקית
  static bool hasGrammaticalSuffix(String word) {
    if (word.isEmpty) return false;
    const suffixPattern =
        r'(ותי|ותַי|ותיך|ותֶיךָ|ותַיִךְ|ותיו|ותָיו|ותיה|ותֶיהָ|ותינו|ותֵינוּ|ותיכם|ותֵיכם|ותיכן|ותֵיכן|ותיהם|ותֵיהם|ותיהן|ותֵיהן|יי|יַי|יך|יךָ|יִךְ|יו|יה|יהָ|ינו|יכם|יכן|יהם|יהן|י|ך|ךָ|ךְ|ו|ה|הּ|נו|כם|כן|ם|ן|ים|ות)$';
    final regex = RegExp(suffixPattern);
    return regex.hasMatch(word);
  }

  /// מחלץ את השורש של מילה (מסיר קידומות וסיומות)
  static String extractRoot(String word) {
    if (word.isEmpty) return word;

    String result = word;

    // מסירת קידומות
    final prefixRegex = RegExp(r'^(ו|מ|כ|ב|ש|ל|ה)+');
    result = result.replaceFirst(prefixRegex, '');

    // מסירת סיומות
    const suffixPattern =
        r'(ותי|ותַי|ותיך|ותֶיךָ|ותַיִךְ|ותיו|ותָיו|ותיה|ותֶיהָ|ותינו|ותֵינוּ|ותיכם|ותֵיכם|ותיכן|ותֵיכן|ותיהם|ותֵיהם|ותיהן|ותֵיהן|יי|יַי|יך|יךָ|יִךְ|יו|יה|יהָ|ינו|יכם|יכן|יהם|יהן|י|ך|ךָ|ךְ|ו|ה|הּ|נו|כם|כן|ם|ן|ים|ות)$';
    final suffixRegex = RegExp(suffixPattern);
    result = result.replaceFirst(suffixRegex, '');

    return result.isEmpty
        ? word
        : result; // אם נשאר ריק, נחזיר את המילה המקורית
  }

  /// מחזיר רשימה של קידומות בסיסיות (לתמיכה לאחור)
  static List<String> getBasicPrefixes() => ['ה', 'ו', 'ב', 'ל', 'מ', 'כ', 'ש'];

  /// מחזיר רשימה של סיומות בסיסיות (לתמיכה לאחור)
  static List<String> getBasicSuffixes() =>
      ['ים', 'ות', 'י', 'ך', 'ו', 'ה', 'נו', 'כם', 'כן', 'ם', 'ן'];
}
