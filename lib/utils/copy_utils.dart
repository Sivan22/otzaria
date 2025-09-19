import 'package:flutter/foundation.dart';
import 'package:otzaria/models/books.dart';

class CopyUtils {
  /// מחלץ את שם הספר
  static String extractBookName(TextBook book) => book.title.trim();

  /// מחלץ את הנתיב ההיררכי הנוכחי:
  /// 1) ניסיון קפדני מתוך התוכן עצמו: רק תגיות <h1>..<h6>
  /// 2) נפילה ל-TOC: לוקחים את הכותרת האחרונה לכל רמה (1..6) עד currentIndex
  static Future<String> extractCurrentPath(
    TextBook book,
    int currentIndex, {
    List<String>? bookContent,
  }) async {
    try {
      // --- שלב 1: ניסיון קפדני מתוך התוכן ---
      final fromContent =
          _extractPathFromContentStrict(bookContent, currentIndex);
      if (fromContent.isNotEmpty) return fromContent;

      // --- שלב 2: נפילה ל-TOC בלבד ---
      final toc = await book.tableOfContents;
      if (toc.isEmpty) return '';

      final Map<int, String> lastByLevel = {};
      for (final entry in toc) {
        if (entry.index <= currentIndex) {
          final clean = _cleanHtml(entry.text);
          if (clean.isNotEmpty) {
            lastByLevel[entry.level] = clean;
          }
        } else {
          break;
        }
      }

      if (lastByLevel.isEmpty) return '';

      final levels = lastByLevel.keys.toList()..sort();
      final parts = <String>[];
      for (final lvl in levels) {
        final txt = lastByLevel[lvl];
        if (txt != null && txt.trim().isNotEmpty) parts.add(txt.trim());
      }
      final result = parts.join(', ');

      if (kDebugMode) {
        print('CopyUtils: Final path (TOC strict): "$result"');
      }
      return result;
    } catch (e, st) {
      if (kDebugMode) {
        print('CopyUtils: ERROR in extractCurrentPath: $e\n$st');
      }
      return '';
    }
  }

  /// מעצב טקסט עם כותרות בהתאם להגדרות
  static String formatTextWithHeaders({
    required String originalText,
    required String copyWithHeaders,
    required String copyHeaderFormat,
    required String bookName,
    required String currentPath,
  }) {
    if (copyWithHeaders == 'none') {
      return originalText;
    }

    String header;

    if (copyWithHeaders == 'book_name') {
      header = bookName;
    } else if (copyWithHeaders == 'book_and_path') {
      header = currentPath.isNotEmpty ? currentPath : bookName;
    } else {
      return originalText;
    }

    if (header.trim().isEmpty) {
      return originalText;
    }

    String result;
    switch (copyHeaderFormat) {
      case 'same_line_after_brackets':
        result = '${originalText.trim()} (${header.trim()})';
        break;
      case 'same_line_after_no_brackets':
        result = '${originalText.trim()} ${header.trim()}';
        break;
      case 'same_line_before_brackets':
        result = '(${header.trim()}) ${originalText.trim()}';
        break;
      case 'same_line_before_no_brackets':
        result = '${header.trim()} ${originalText.trim()}';
        break;
      case 'separate_line_after':
        result = '${originalText.trim()}\n${header.trim()}';
        break;
      case 'separate_line_before':
        result = '${header.trim()}\n${originalText.trim()}';
        break;
      default:
        result = '${originalText.trim()} (${header.trim()})';
        break;
    }
    return result;
  }

  // ------------------------------------------------------------
  //                 HELPERS - STRICT CONTENT PARSING
  // ------------------------------------------------------------

  /// הלוגיקה החדשה: סורקים אחורה מהמיקום הנוכחי עד לתחילת הקובץ,
  /// ואוספים את הכותרת האחרונה (הקרובה ביותר) מכל רמה.
  static String _extractPathFromContentStrict(
      List<String>? content, int currentIndex) {
    if (content == null || content.isEmpty) return '';
    if (currentIndex < 0 || currentIndex >= content.length) return '';

    final Map<int, String> lastHeaderByLevel = {};
    final hTag = RegExp(r'<h([1-6])[^>]*>(.*?)</h\1>', dotAll: true);

    // סריקה מהמיקום הנוכחי אחורה עד להתחלה
    for (int i = currentIndex; i >= 0; i--) {
      // אם כבר מצאנו את כל הרמות הראשיות, אפשר לעצור לטובת יעילות
      if (lastHeaderByLevel.containsKey(1) &&
          lastHeaderByLevel.containsKey(2) &&
          lastHeaderByLevel.containsKey(3)) {
        break;
      }

      final line = content[i];
      for (final match in hTag.allMatches(line)) {
        try {
          final level = int.parse(match.group(1)!);
          final text = _cleanHtml(match.group(2)!);

          // שומרים רק את הכותרת הראשונה שנמצאה עבור כל רמה (כי אנחנו הולכים אחורה)
          if (!lastHeaderByLevel.containsKey(level) && text.isNotEmpty) {
            lastHeaderByLevel[level] = text;
          }
        } catch (_) {
          // התעלם אם תגית ה-h אינה תקינה
        }
      }
    }

    if (lastHeaderByLevel.isEmpty) return '';

    // הרכבת הנתיב לפי סדר הרמות (1, 2, 3...)
    final sortedLevels = lastHeaderByLevel.keys.toList()..sort();
    final parts = <String>[];
    for (final level in sortedLevels) {
      parts.add(lastHeaderByLevel[level]!);
    }

    final result = parts.join(', ');
    if (kDebugMode) {
      if (result.isNotEmpty)
        print(
            'CopyUtils: Final path from CONTENT (strict, full scan): "$result"');
    }
    return result;
  }

  /// ניקוי תגיות HTML
  static String _cleanHtml(String s) {
    final noTags = s.replaceAll(RegExp(r'<[^>]*>'), '');
    return noTags.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
