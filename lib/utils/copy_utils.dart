import 'package:flutter/foundation.dart';
import 'package:otzaria/models/books.dart';

class CopyUtils {
  /// מחלץ את שם הספר מהכותרת או מהקובץ
  static String extractBookName(TextBook book) {
    // שם הספר הוא הכותרת של הספר
    return book.title;
  }

  /// מחלץ את הנתיב ההיררכי הנוכחי בספר
  static Future<String> extractCurrentPath(
    TextBook book,
    int currentIndex,
  ) async {
    try {
      final toc = await book.tableOfContents;
      if (toc.isEmpty) {
        if (kDebugMode) {
          print('CopyUtils: TOC is empty for book ${book.title}');
        }
        return _tryExtractFromIndex(book, currentIndex);
      }

      // מוצא את כל הכותרות הרלוונטיות לאינדקס הנוכחי
      Map<int, String> levelHeaders = {}; // רמה -> כותרת

      // אם יש רק כותרת אחת, נבדוק אם היא רלוונטית
      if (toc.length == 1) {
        final entry = toc[0];
        if (currentIndex >= entry.index) {
          String cleanText =
              entry.text.replaceAll(RegExp(r'<[^>]*>'), '').trim();
          if (cleanText.isNotEmpty && cleanText != book.title) {
            levelHeaders[entry.level] = cleanText;
            if (kDebugMode) {
              print(
                  'CopyUtils: Single TOC entry found: level=${entry.level}, text="$cleanText"');
            }
          }
        }
      }

      if (kDebugMode) {
        print(
            'CopyUtils: Looking for headers for index $currentIndex in book ${book.title}');
        print('CopyUtils: TOC has ${toc.length} entries');
        for (int i = 0; i < toc.length; i++) {
          final entry = toc[i];
          print(
              'CopyUtils: TOC[$i]: index=${entry.index}, level=${entry.level}, text="${entry.text}"');
        }
      }

      // עובר על כל הכותרות ומוצא את אלו שהאינדקס הנוכחי נמצא אחריהן
      for (int i = 0; i < toc.length; i++) {
        final entry = toc[i];

        if (kDebugMode) {
          print(
              'CopyUtils: Checking entry $i: index=${entry.index}, currentIndex=$currentIndex');
        }

        // בודק אם האינדקס הנוכחי נמצא אחרי הכותרת הזו
        if (currentIndex >= entry.index) {
          if (kDebugMode) {
            print(
                'CopyUtils: Current index >= entry index, checking if active...');
          }

          // בודק אם יש כותרת אחרת באותה רמה או נמוכה יותר שמגיעה אחרי האינדקס הנוכחי
          bool isActive = true;

          for (int j = i + 1; j < toc.length; j++) {
            final nextEntry = toc[j];
            if (nextEntry.index > currentIndex &&
                nextEntry.level <= entry.level) {
              if (kDebugMode) {
                print(
                    'CopyUtils: Found blocking entry at $j: index=${nextEntry.index}, level=${nextEntry.level}');
              }
              isActive = false;
              break;
            }
          }

          if (kDebugMode) {
            print('CopyUtils: Entry $i is active: $isActive');
          }

          if (isActive) {
            // מנקה את הטקסט מתגי HTML
            String cleanText =
                entry.text.replaceAll(RegExp(r'<[^>]*>'), '').trim();

            if (kDebugMode) {
              print(
                  'CopyUtils: Clean text: "$cleanText", book title: "${book.title}"');
            }

            if (cleanText.isNotEmpty && cleanText != book.title) {
              levelHeaders[entry.level] = cleanText;
              if (kDebugMode) {
                print(
                    'CopyUtils: Found active header at level ${entry.level}: "$cleanText"');
              }
            } else if (kDebugMode) {
              print('CopyUtils: Skipping header (empty or matches book title)');
            }
          }
        } else if (kDebugMode) {
          print('CopyUtils: Current index < entry index, skipping');
        }
      }

      // בונה את הנתיב מהרמות בסדר עולה
      List<String> pathParts = [];
      final sortedLevels = levelHeaders.keys.toList()..sort();

      for (final level in sortedLevels) {
        final header = levelHeaders[level];
        if (header != null) {
          pathParts.add(header);
        }
      }

      final result = pathParts.join(' ');
      if (kDebugMode) {
        print('CopyUtils: Final path: "$result"');
      }

      // אם לא מצאנו נתיב מה-TOC, ננסה לחלץ מהאינדקס
      if (result.isEmpty) {
        if (kDebugMode) {
          print(
              'CopyUtils: No path found in TOC, trying to extract from index');
        }
        return _tryExtractFromIndex(book, currentIndex);
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('CopyUtils: Error extracting path: $e');
      }
      return '';
    }
  }

  /// מעצב את הטקסט עם הכותרות לפי ההגדרות
  static String formatTextWithHeaders({
    required String originalText,
    required String copyWithHeaders,
    required String copyHeaderFormat,
    required String bookName,
    required String currentPath,
  }) {
    if (kDebugMode) {
      print('CopyUtils: formatTextWithHeaders called with:');
      print('  copyWithHeaders: $copyWithHeaders');
      print('  copyHeaderFormat: $copyHeaderFormat');
      print('  bookName: "$bookName"');
      print('  currentPath: "$currentPath"');
    }

    // אם לא רוצים כותרות, מחזירים את הטקסט המקורי
    if (copyWithHeaders == 'none') {
      return originalText;
    }

    // בונים את הכותרת
    String header = '';
    if (copyWithHeaders == 'book_name') {
      header = bookName;
    } else if (copyWithHeaders == 'book_and_path') {
      if (currentPath.isNotEmpty) {
        // בודקים אם הנתיב כבר מכיל את שם הספר
        if (currentPath.startsWith(bookName)) {
          // הנתיב כבר מכיל את שם הספר, לא נוסיף אותו שוב
          header = currentPath;
        } else {
          // הנתיב לא מכיל את שם הספר, נוסיף אותו
          header = '$bookName $currentPath';
        }
      } else {
        header = bookName;
      }
    }

    if (kDebugMode) {
      print('CopyUtils: Generated header: "$header"');
    }

    if (header.isEmpty) {
      return originalText;
    }

    // מעצבים לפי סוג העיצוב
    String result;
    switch (copyHeaderFormat) {
      case 'same_line_after_brackets':
        result = '$originalText ($header)';
        break;
      case 'same_line_after_no_brackets':
        result = '$originalText $header';
        break;
      case 'same_line_before_brackets':
        result = '($header) $originalText';
        break;
      case 'same_line_before_no_brackets':
        result = '$header $originalText';
        break;
      case 'separate_line_after':
        result = '$originalText\n$header';
        break;
      case 'separate_line_before':
        result = '$header\n$originalText';
        break;
      default:
        result = '$originalText ($header)';
        break;
    }

    if (kDebugMode) {
      print(
          'CopyUtils: Final formatted text: "${result.replaceAll('\n', '\\n')}"');
    }

    return result;
  }

  /// מנסה לחלץ מידע מהאינדקס כשאין TOC מפורט
  static String _tryExtractFromIndex(TextBook book, int currentIndex) {
    if (kDebugMode) {
      print(
          'CopyUtils: Trying to extract from index $currentIndex for book ${book.title}');
    }

    // לספרי תלמוד - ננסה לחשב דף לפי אינדקס
    if (book.title.contains('ברכות') ||
        book.title.contains('שבת') ||
        book.title.contains('עירובין') ||
        _isTalmudBook(book.title)) {
      // הנחה: כל דף מכיל בערך 20-30 שורות טקסט
      // זה רק הערכה גסה, אבל יכול לעזור
      final estimatedPage = (currentIndex ~/ 25) + 2; // מתחילים מדף ב'
      final pageText = 'דף ${_numberToHebrew(estimatedPage)}.';

      if (kDebugMode) {
        print('CopyUtils: Estimated page for Talmud: $pageText');
      }

      return pageText;
    }

    // לספרים אחרים - אם האינדקס גדול מ-0, ננסה לתת מידע כללי
    if (currentIndex > 0) {
      return 'פסקה ${currentIndex + 1}';
    }

    return '';
  }

  /// בודק אם זה ספר תלמוד
  static bool _isTalmudBook(String title) {
    final talmudBooks = [
      'ברכות',
      'שבת',
      'עירובין',
      'פסחים',
      'שקלים',
      'יומא',
      'סוכה',
      'ביצה',
      'ראש השנה',
      'תענית',
      'מגילה',
      'מועד קטן',
      'חגיגה',
      'יבמות',
      'כתובות',
      'נדרים',
      'נזיר',
      'סוטה',
      'גיטין',
      'קידושין',
      'בבא קמא',
      'בבא מציעא',
      'בבא בתרא',
      'סנהדרין',
      'מכות',
      'שבועות',
      'עבודה זרה',
      'הוריות',
      'זבחים',
      'מנחות',
      'חולין',
      'בכורות',
      'ערכין',
      'תמורה',
      'כריתות',
      'מעילה',
      'תמיד',
      'מדות',
      'קינים',
      'נדה'
    ];

    return talmudBooks.any((book) => title.contains(book));
  }

  /// ממיר מספר לעברית (פשוט)
  static String _numberToHebrew(int number) {
    if (number <= 0) return '';

    final ones = ['', 'א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ז', 'ח', 'ט'];
    final tens = ['', '', 'כ', 'ל', 'מ', 'נ', 'ס', 'ע', 'פ', 'צ'];
    final hundreds = ['', 'ק', 'ר', 'ש', 'ת'];

    if (number < 10) {
      return ones[number];
    } else if (number < 100) {
      final ten = number ~/ 10;
      final one = number % 10;
      return tens[ten] + ones[one];
    } else if (number < 400) {
      final hundred = number ~/ 100;
      final remainder = number % 100;
      return hundreds[hundred] + _numberToHebrew(remainder);
    }

    return number.toString(); // fallback למספרים גדולים
  }
}
