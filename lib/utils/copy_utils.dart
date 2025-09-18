import 'package:flutter/foundation.dart';
import 'package:otzaria/models/books.dart';
import 'dart:math' as math;

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

      // שומרים רק את האחרונה לכל רמה עד currentIndex
      final Map<int, String> lastByLevel = {};
      for (final entry in toc) {
        if (entry.index <= currentIndex) {
          final clean = _cleanHtml(entry.text);
          if (clean.isNotEmpty) {
            lastByLevel[entry.level] = clean;
          }
        } else {
          // מרגע שעברנו את האינדקס הנוכחי אין טעם להמשיך
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
    required String copyWithHeaders, // 'none' | 'book_name' | 'book_and_path'
    required String copyHeaderFormat, // one of: same_line_* / separate_line_*
    required String bookName,
    required String currentPath,
  }) {
    if (copyWithHeaders == 'none') {
      return originalText;
    }

    String header;

    if (copyWithHeaders == 'book_name') {
      // המשתמש בחר "העתקה עם שם הספר בלבד"
      header = bookName;
    } else if (copyWithHeaders == 'book_and_path') {
      // המשתמש בחר "העתקה עם שם הספר+הנתיב".
      // `currentPath` הוא הנתיב המלא מהכותרות (כולל שם הספר מ-H1).
      // לכן, נשתמש בו ישירות. אם הוא ריק, ניקח את שם הקובץ כגיבוי.
      header = currentPath.isNotEmpty ? currentPath : bookName;
    } else {
      // מצב לא צפוי, אל תוסיף כותרת
      return originalText;
    }

    if (header.trim().isEmpty) {
      return originalText;
    }

    // עיצוב המיקום לפי ההעדפה
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

  /// מוצא את הכותרות האחרוניות <h1..h6> לפני currentIndex בלבד.
  static String _extractPathFromContentStrict(
      List<String>? content, int currentIndex) {
    if (content == null || content.isEmpty) return '';
    if (currentIndex < 0 || currentIndex >= content.length) return '';

    final start = math.max(0, currentIndex - 200);
    final end = currentIndex;

    String? h1, h2, h3, h4; // נשמור את הקרובות ביותר לאינדקס
    final hTag = RegExp(r'<h([1-6])[^>]*>(.*?)</h\1>', dotAll: true);

    for (int i = end; i >= start; i--) {
      final line = content[i];
      for (final m in hTag.allMatches(line)) {
        final levelStr = m.group(1)!;
        final inner = _cleanHtml(m.group(2)!);

        if (inner.isEmpty) continue;

        switch (levelStr) {
          case '1':
            h1 ??= inner;
            break;
          case '2':
            h2 ??= inner;
            break;
          case '3':
            h3 ??= inner;
            break;
          case '4':
            h4 ??= inner;
            break;
          default:
            break;
        }
      }

      if (h1 != null && h2 != null && h3 != null && h4 != null) break;
    }

    final parts = <String>[];
    if (h1 != null && h1.trim().isNotEmpty) parts.add(h1.trim());
    if (h2 != null && h2.trim().isNotEmpty) parts.add(h2.trim());
    if (h3 != null && h3.trim().isNotEmpty) parts.add(h3.trim());
    if (h4 != null && h4.trim().isNotEmpty) parts.add(h4.trim());

    final result = parts.join(', ');
    if (kDebugMode) {
      if (result.isNotEmpty)
        print('CopyUtils: Final path from CONTENT (strict): "$result"');
    }
    return result;
  }

  /// ניקוי תגיות HTML
  static String _cleanHtml(String s) {
    final noTags = s.replaceAll(RegExp(r'<[^>]*>'), '');
    return noTags.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
