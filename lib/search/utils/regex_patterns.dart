/// מרכז רגקסים לחיפוש - כל הרגקסים במקום אחד
///
/// קובץ זה מרכז את כל הרגקסים המשמשים לחיפוש במערכת
/// כדי לשפר את הארגון ולהקל על התחזוקה.
///
/// הקובץ מחליף רגקסים שהיו מפוזרים בקבצים הבאים:
/// - lib/search/search_repository.dart
/// - lib/search/utils/hebrew_morphology.dart
/// - lib/utils/text_manipulation.dart
/// - lib/search/models/search_terms_model.dart
/// - lib/search/view/enhanced_search_field.dart
///
/// יתרונות הריכוז:
/// 1. קל יותר לתחזק ולעדכן רגקסים
/// 2. מונע כפילויות
/// 3. מבטיח עקביות בין חלקי המערכת השונים
/// 4. מקל על בדיקות ותיקונים
class SearchRegexPatterns {
  // ===== רגקסים בסיסיים =====

  /// רגקס לפיצול מילים לפי רווחים
  static final RegExp wordSplitter = RegExp(r'\s+');

  /// רגקס לסינון רווחים בקלט
  static final RegExp spacesFilter = RegExp(r'\s');

  // ===== רגקסים לעיבוד HTML =====

  /// רגקס להסרת תגי HTML וישויות
  static final RegExp htmlStripper = RegExp(r'<[^>]*>|&[^;]+;');

  // ===== רגקסים לעיבוד עברית =====

  /// רגקס להסרת ניקוד וטעמים
  static final RegExp vowelsAndCantillation = RegExp(r'[\u0591-\u05C7]');

  /// רגקס להסרת טעמים בלבד
  static final RegExp cantillationOnly = RegExp(r'[\u0591-\u05AF]');

  /// רגקס לזיהוי שם הקודש (יהוה) עם ניקוד
  static final RegExp holyName = RegExp(
    r"י([\p{Mn}]*)ה([\p{Mn}]*)ו([\p{Mn}]*)ה([\p{Mn}]*)",
    unicode: true,
  );

  // ===== רגקסים למורפולוגיה עברית =====

  /// רגקס לזיהוי קידומות דקדוקיות
  static final RegExp grammaticalPrefixes = RegExp(r'^(ו|מ|כ|ב|ש|ל|ה)+(.+)');

  /// רגקס לזיהוי סיומות דקדוקיות
  static final RegExp grammaticalSuffixes = RegExp(
      r'(ותי|ותיך|ותיו|ותיה|ותינו|ותיכם|ותיכן|ותיהם|ותיהן|יי|יך|יו|יה|ינו|יכם|יכן|יהם|יהן|י|ך|ו|ה|נו|כם|כן|ם|ן|ים|ות)$');

  // ===== פונקציות ליצירת רגקסים דינמיים =====

  /// יוצר רגקס לחיפוש מילה עם קידומות דקדוקיות
  static String createPrefixPattern(String word) {
    if (word.isEmpty) return word;
    return r'(ו|מ|כש|כ|ב|ש|ל|ה|ד)?(כ|ב|ש|ל|ה|ד)?(ה)?' + RegExp.escape(word);
  }

  /// יוצר רגקס לחיפוש מילה עם סיומות דקדוקיות
  static String createSuffixPattern(String word) {
    if (word.isEmpty) return word;
    const suffixPattern =
        r'(ותי|ותיך|ותיו|ותיה|ותינו|ותיכם|ותיכן|ותיהם|ותיהן|יי|יך|יו|יה|ינו|יכם|יכן|יהם|יהן|י|ך|ו|ה|נו|כם|כן|ם|ן|ים|ות)?';
    return RegExp.escape(word) + suffixPattern;
  }

  /// יוצר רגקס לחיפוש מילה עם קידומות וסיומות יחד
  static String createFullMorphologicalPattern(String word) {
    if (word.isEmpty) return word;
    String pattern = RegExp.escape(word);

    // הוספת קידומות
    pattern = r'(ו|מ|כ|ב|ש|ל|ה|ד)?(כ|ב|ש|ל|ה|ד)?(ה)?' + pattern;

    // הוספת סיומות
    const suffixPattern =
        r'(ותי|ותַי|ותיך|ותֶיךָ|ותַיִךְ|ותיו|ותָיו|ותיה|ותֶיהָ|ותינו|ותֵינוּ|ותיכם|ותֵיכם|ותיכן|ותֵיכן|ותיהם|ותֵיהם|ותיהן|ותֵיהן|יות|יי|יַי|יך|יךָ|יִךְ|יו|יה|יא|תא|יהָ|ינו|יכם|יכן|יהם|יהן|י|ך|ךָ|ךְ|ו|ה|הּ|נו|כם|כן|ם|ן|ים|ות)?';
    pattern = pattern + suffixPattern;

    return pattern;
  }

  /// יוצר רגקס לחיפוש קידומות רגילות (לא דקדוקיות)
  static String createPrefixSearchPattern(String word,
      {int maxPrefixLength = 3}) {
    if (word.isEmpty) return word;

    if (word.length <= 1) {
      return '.{1,5}${RegExp.escape(word)}';
    } else if (word.length <= 2) {
      return '.{1,4}${RegExp.escape(word)}';
    } else if (word.length <= 3) {
      return '.{1,3}${RegExp.escape(word)}';
    } else {
      return '.*${RegExp.escape(word)}';
    }
  }

  /// יוצר רגקס לחיפוש סיומות רגילות (לא דקדוקיות)
  static String createSuffixSearchPattern(String word,
      {int maxSuffixLength = 7}) {
    if (word.isEmpty) return word;

    if (word.length <= 1) {
      return '${RegExp.escape(word)}.{1,7}';
    } else if (word.length <= 2) {
      return '${RegExp.escape(word)}.{1,6}';
    } else if (word.length <= 3) {
      return '${RegExp.escape(word)}.{1,5}';
    } else {
      return '${RegExp.escape(word)}.*';
    }
  }

  /// יוצר רגקס לחיפוש חלק ממילה
  ///
  /// פונקציה זו משמשת גם כאשר המשתמש בוחר גם קידומות וגם סיומות יחד,
  /// מכיוון שהשילוב הזה בעצם מחפש את המילה בכל מקום בתוך מילה אחרת
  static String createPartialWordPattern(String word) {
    if (word.isEmpty) return word;

    if (word.length <= 3) {
      return '.{0,3}${RegExp.escape(word)}.{0,3}';
    } else {
      return '.{0,2}${RegExp.escape(word)}.{0,2}';
    }
  }

  /// יוצר רגקס לכתיב מלא/חסר
  static String createFullPartialSpellingPattern(String word) {
    if (word.isEmpty) return word;
    final variations = generateFullPartialSpellingVariations(word);
    final escapedVariations = variations.map((v) => RegExp.escape(v)).toList();
    return r'(?:^|\s)(' + escapedVariations.join('|') + r')(?=\s|$)';
  }

  // ===== פונקציות עזר =====

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

  /// בודק אם מילה מכילה קידומת דקדוקית
  static bool hasGrammaticalPrefix(String word) {
    if (word.isEmpty) return false;
    return grammaticalPrefixes.hasMatch(word);
  }

  /// בודק אם מילה מכילה סיומת דקדוקית
  static bool hasGrammaticalSuffix(String word) {
    if (word.isEmpty) return false;
    return grammaticalSuffixes.hasMatch(word);
  }

  /// מחלץ את השורש של מילה (מסיר קידומות וסיומות)
  static String extractRoot(String word) {
    if (word.isEmpty) return word;
    String result = word;

    // הסרת קידומות
    result = result.replaceFirst(grammaticalPrefixes, '');

    // הסרת סיומות
    result = result.replaceFirst(grammaticalSuffixes, '');

    return result.isEmpty ? word : result;
  }

  // ===== רגקסים נוספים לעתיד =====

  /// רגקס לזיהוי מספרים עבריים (א', ב', ג' וכו')
  static final RegExp hebrewNumbers = RegExp(r"[א-ת]['״]");

  /// רגקס לזיהוי מספרים לועזיים
  static final RegExp latinNumbers = RegExp(r'\d+');

  /// רגקס לזיהוי כתובות (פרק, פסוק, דף וכו')
  static final RegExp references =
      RegExp(r"(פרק|פסוק|דף|עמוד|סימן|הלכה)\s*[א-ת'״\d]+");

  /// רגקס לזיהוי ציטוטים (טקסט בגרשיים)
  static final RegExp quotations = RegExp(r'"[^"]*"');

  /// רגקס לזיהוי קיצורים נפוצים (רמב"ם, רש"י וכו')
  static final RegExp abbreviations = RegExp(r'[א-ת]+"[א-ת]');

  /// פונקציה לניקוי טקסט מתווים מיוחדים
  static String cleanText(String text) {
    return text
        .replaceAll(
            RegExp(r'[^\u0590-\u05FF\u0020-\u007F]'), '') // רק עברית ואנגלית
        .replaceAll(RegExp(r'\s+'), ' ') // רווחים מרובים לרווח יחיד
        .trim();
  }

  /// פונקציה לזיהוי אם טקסט הוא בעברית
  static bool isHebrew(String text) {
    final hebrewChars = RegExp(r'[\u0590-\u05FF]');
    return hebrewChars.hasMatch(text);
  }

  /// פונקציה לזיהוי אם טקסט הוא באנגלית
  static bool isEnglish(String text) {
    final englishChars = RegExp(r'[a-zA-Z]');
    return englishChars.hasMatch(text);
  }

  /// פונקציה שמחליטה איזה סוג חיפוש להשתמש בהתבסס על אפשרויות המשתמש
  ///
  /// הלוגיקה:
  /// - אם נבחרו גם קידומות וגם סיומות רגילות -> חיפוש "חלק ממילה"
  /// - אם נבחרו קידומות דקדוקיות וסיומות דקדוקיות -> חיפוש מורפולוגי מלא
  /// - אחרת -> חיפוש לפי האפשרות הספציפית שנבחרה
  static String createSearchPattern(
    String word, {
    bool hasPrefix = false,
    bool hasSuffix = false,
    bool hasGrammaticalPrefixes = false,
    bool hasGrammaticalSuffixes = false,
    bool hasPartialWord = false,
  }) {
    if (word.isEmpty) return word;

    // לוגיקה מיוחדת: קידומות + סיומות רגילות = חלק ממילה
    if (hasPrefix && hasSuffix) {
      return createPartialWordPattern(word);
    }

    // קידומות וסיומות דקדוקיות יחד
    if (hasGrammaticalPrefixes && hasGrammaticalSuffixes) {
      return createFullMorphologicalPattern(word);
    }

    // אפשרויות בודדות
    if (hasGrammaticalPrefixes) {
      return createPrefixPattern(word);
    }
    if (hasGrammaticalSuffixes) {
      return createSuffixPattern(word);
    }
    if (hasPrefix) {
      return createPrefixSearchPattern(word);
    }
    if (hasSuffix) {
      return createSuffixSearchPattern(word);
    }
    if (hasPartialWord) {
      return createPartialWordPattern(word);
    }

    // ברירת מחדל - חיפוש מדויק
    return RegExp.escape(word);
  }
}
