/// כלים לטיפול בקידומות, סיומות וכתיב מלא/חסר בעברית (גרסה משולבת ומשופרת)
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
    if (word.isEmpty) return word;
    // שימוש בתבנית קבועה ויעילה
    return r'(ו|מ|כ|ב|ש|ל|ה|ד)?(כ|ב|ש|ל|ה|ד)?(ה)?' + RegExp.escape(word);
  }

  /// יוצר דפוס רגקס קומפקטי לחיפוש מילה עם סיומות דקדוקיות
  static String createSuffixRegexPattern(String word) {
    if (word.isEmpty) return word;

    // שימוש בתבנית קבועה ויעילה, מסודרת לפי אורך
    const suffixPattern =
        r'(ותי|ותַי|ותיך|ותֶיךָ|ותַיִךְ|ותיו|ותָיו|ותיה|ותֶיהָ|ותינו|ותֵינוּ|ותיכם|ותֵיכם|ותיכן|ותֵיכן|ותיהם|ותֵיהם|ותיהן|ותֵיהן|יות|יי|יַי|יך|יךָ|יִךְ|יו|יה|יא|יהָ|ינו|יכם|יכן|יהם|יהן|י|ך|ךָ|ךְ|ו|ה|הּ|נו|כם|כן|ם|ן|ים|ות)?';

    return RegExp.escape(word) + suffixPattern;
  }

  /// יוצר דפוס רגקס קומפקטי לחיפוש מילה עם קידומות וסיומות דקדוקיות יחד
  static String createFullMorphologicalRegexPattern(
    String word, {
    bool includePrefixes = true,
    bool includeSuffixes = true,
  }) {
    if (word.isEmpty) return word;

    String pattern = RegExp.escape(word);

    if (includePrefixes) {
      // שימוש בתבנית קבועה ויעילה
      pattern = r'(ו|מ|כ|ב|ש|ל|ה|ד)?(כ|ב|ש|ל|ה|ד)?(ה)?' + pattern;
    }

    if (includeSuffixes) {
      // שימוש בתבנית קבועה ויעילה
      const suffixPattern =
          r'(ותי|ותַי|ותיך|ותֶיךָ|ותַיִךְ|ותיו|ותָיו|ותיה|ותֶיהָ|ותינו|ותֵינוּ|ותיכם|ותֵיכם|ותיכן|ותֵיכן|ותיהם|ותֵיהם|ותיהן|ותֵיהן|יות|יי|יַי|יך|יךָ|יִךְ|יו|יה|יא|יהָ|ינו|יכם|יכן|יהם|יהן|י|ך|ךָ|ךְ|ו|ה|הּ|נו|כם|כן|ם|ן|ים|ות)?';
      pattern = pattern + suffixPattern;
    }

    return pattern;
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
    final prefixRegex = RegExp(r'^(ו|מ|כ|ב|ש|ל|ה)+');
    result = result.replaceFirst(prefixRegex, '');
    const suffixPattern =
        r'(ותי|ותַי|ותיך|ותֶיךָ|ותַיִךְ|ותיו|ותָיו|ותיה|ותֶיהָ|ותינו|ותֵינוּ|ותיכם|ותֵיכם|ותיכן|ותֵיכן|ותיהם|ותֵיהם|ותיהן|ותֵיהן|יי|יַי|יך|יךָ|יִךְ|יו|יה|יהָ|ינו|יכם|יכן|יהם|יהן|י|ך|ךָ|ךְ|ו|ה|הּ|נו|כם|כן|ם|ן|ים|ות)$';
    final suffixRegex = RegExp(suffixPattern);
    result = result.replaceFirst(suffixRegex, '');
    return result.isEmpty ? word : result;
  }

  /// מחזיר רשימה של קידומות בסיסיות (לתמיכה לאחור)
  static List<String> getBasicPrefixes() => ['ה', 'ו', 'ב', 'ל', 'מ', 'כ', 'ש'];

  /// מחזיר רשימה של סיומות בסיסיות (לתמיכה לאחור)
  static List<String> getBasicSuffixes() =>
      ['ים', 'ות', 'י', 'ך', 'ו', 'ה', 'נו', 'כם', 'כן', 'ם', 'ן'];

  // --- מתודות לכתיב מלא/חסר (מהקוד השני) ---

  /// יוצר דפוס רגקס לכתיב מלא/חסר על בסיס רשימת וריאציות
  static String createFullPartialSpellingPattern(String word) {
    if (word.isEmpty) return word;
    final variations = generateFullPartialSpellingVariations(word);
    final escapedVariations = variations.map((v) => RegExp.escape(v)).toList();
    return r'(?:^|\s)(' + escapedVariations.join('|') + r')(?=\s|$)';
  }

  /// יוצר רשימה של וריאציות כתיב מלא/חסר
  static List<String> generateFullPartialSpellingVariations(String word) {
    if (word.isEmpty) return [word];
    final variations = <String>{};
    final chars = word.split('');
    final optionalIndices = <int>[];

    for (int i = 0; i < chars.length; i++) {
      if (['י', 'ו', "'", '"'].contains(chars[i])) {
        optionalIndices.add(i);
      }
    }

    final numCombinations = 1 << optionalIndices.length; // 2^n
    for (int i = 0; i < numCombinations; i++) {
      final variant = StringBuffer();
      int originalCharIndex = 0;
      for (int optionalCharIndex = 0;
          optionalCharIndex < optionalIndices.length;
          optionalCharIndex++) {
        int nextOptional = optionalIndices[optionalCharIndex];
        variant.write(word.substring(originalCharIndex, nextOptional));
        if ((i & (1 << optionalCharIndex)) != 0) {
          variant.write(chars[nextOptional]);
        }
        originalCharIndex = nextOptional + 1;
      }
      variant.write(word.substring(originalCharIndex));
      variations.add(variant.toString());
    }

    return variations.toList();
  }
}
