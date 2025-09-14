import 'dart:math' as math;
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
    int currentIndex, {
    List<String>? bookContent,
  }) async {
    try {
      if (kDebugMode) {
        print('CopyUtils: *** NEW VERSION *** Looking for headers for index $currentIndex in book ${book.title}');
        print('CopyUtils: bookContent is ${bookContent == null ? 'null' : 'available with ${bookContent.length} entries'}');
      }

      // קודם ננסה לחלץ מהתוכן עצמו
      if (kDebugMode) {
        print('CopyUtils: Trying to extract from content first...');
      }
      String contentPath = await _extractPathFromContent(book, currentIndex, bookContent);
      if (contentPath.isNotEmpty) {
        if (kDebugMode) {
          print('CopyUtils: Found path from content: "$contentPath"');
        }
        return contentPath;
      } else if (kDebugMode) {
        print('CopyUtils: No path found from content, trying TOC...');
      }

      // אם לא מצאנו בתוכן, ננסה מה-TOC
      final toc = await book.tableOfContents;
      if (toc.isEmpty) {
        if (kDebugMode) {
          print('CopyUtils: TOC is empty for book ${book.title}');
        }
        return '';
      }

      // מוצא את כל הכותרות הרלוונטיות לאינדקס הנוכחי
      Map<int, String> levelHeaders = {}; // רמה -> כותרת
      
      if (kDebugMode) {
        print('CopyUtils: TOC has ${toc.length} entries');
        for (int i = 0; i < toc.length; i++) {
          final entry = toc[i];
          print('CopyUtils: TOC[$i]: index=${entry.index}, level=${entry.level}, text="${entry.text}"');
        }
      }
      
      // עובר על כל הכותרות ומוצא את אלו שהאינדקס הנוכחי נמצא אחריהן
      for (int i = 0; i < toc.length; i++) {
        final entry = toc[i];
        
        if (kDebugMode) {
          print('CopyUtils: Checking entry $i: index=${entry.index}, currentIndex=$currentIndex');
        }
        
        // בודק אם האינדקס הנוכחי נמצא אחרי הכותרת הזו
        if (currentIndex >= entry.index) {
          if (kDebugMode) {
            print('CopyUtils: Current index >= entry index, checking if active...');
          }
          
          // בודק אם יש כותרת אחרת באותה רמה או נמוכה יותר שמגיעה אחרי האינדקס הנוכחי
          bool isActive = true;
          
          // עבור כותרות רמה גבוהה (2, 3, 4...), נבדוק רק כותרות באותה רמה או נמוכה יותר
          // עבור כותרת רמה 1, נבדוק רק כותרות רמה 1
          for (int j = i + 1; j < toc.length; j++) {
            final nextEntry = toc[j];
            
            // אם הכותרת הבאה מגיעה אחרי האינדקס הנוכחי
            if (nextEntry.index > currentIndex) {
              // אם זו כותרת באותה רמה או נמוכה יותר, היא חוסמת
              if (nextEntry.level <= entry.level) {
                if (kDebugMode) {
                  print('CopyUtils: Found blocking entry at $j: index=${nextEntry.index}, level=${nextEntry.level} (blocks level ${entry.level})');
                }
                isActive = false;
                break;
              }
            }
          }
          
          if (kDebugMode) {
            print('CopyUtils: Entry $i is active: $isActive');
          }
          
          if (isActive) {
            // מנקה את הטקסט מתגי HTML
            String cleanText = entry.text
                .replaceAll(RegExp(r'<[^>]*>'), '')
                .trim();
            
            if (kDebugMode) {
              print('CopyUtils: Clean text: "$cleanText", book title: "${book.title}"');
            }
            
            if (cleanText.isNotEmpty) {
              // נכלול את כל הכותרות, גם אם הן זהות לשם הספר
              levelHeaders[entry.level] = cleanText;
              if (kDebugMode) {
                print('CopyUtils: Found active header at level ${entry.level}: "$cleanText"');
              }
            } else if (kDebugMode) {
              print('CopyUtils: Skipping empty header');
            }
          }
        } else if (kDebugMode) {
          print('CopyUtils: Current index < entry index, skipping');
        }
      }
      
      // בונה את הנתיב מהרמות בסדר עולה
      List<String> pathParts = [];
      final sortedLevels = levelHeaders.keys.toList()..sort();
      
      if (kDebugMode) {
        print('CopyUtils: Found ${levelHeaders.length} active headers:');
        for (final level in sortedLevels) {
          print('CopyUtils: Level $level: "${levelHeaders[level]}"');
        }
      }
      
      for (final level in sortedLevels) {
        final header = levelHeaders[level];
        if (header != null) {
          pathParts.add(header);
        }
      }
      
      // מחבר עם פסיקים לנתיב מסודר
      final result = pathParts.join(', ');
      if (kDebugMode) {
        print('CopyUtils: Final path from TOC: "$result"');
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

    // בונים את הכותרת - רק מהנתיב, בלי שם הקובץ
    String header = '';
    if (copyWithHeaders == 'book_name') {
      // גם כאן נשתמש רק בנתיב אם יש, אחרת בשם הספר
      header = currentPath.isNotEmpty ? currentPath : bookName;
    } else if (copyWithHeaders == 'book_and_path') {
      // רק הנתיב, בלי שם הקובץ
      header = currentPath.isNotEmpty ? currentPath : '';
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
      print('CopyUtils: Final formatted text: "${result.replaceAll('\n', '\\n')}"');
    }

    return result;
  }

  /// מנסה לחלץ נתיב מהתוכן עצמו כשאין TOC מפורט
  static Future<String> _extractPathFromContent(TextBook book, int currentIndex, List<String>? bookContent) async {
    try {
      if (kDebugMode) {
        print('CopyUtils: Trying to extract path from content at index $currentIndex');
      }
      
      if (bookContent == null) {
        if (kDebugMode) {
          print('CopyUtils: bookContent is null');
        }
        return '';
      }
      
      if (currentIndex >= bookContent.length) {
        if (kDebugMode) {
          print('CopyUtils: currentIndex ($currentIndex) >= bookContent.length (${bookContent.length})');
        }
        return '';
      }
      
      if (kDebugMode) {
        print('CopyUtils: bookContent available with ${bookContent.length} entries, currentIndex: $currentIndex');
      }
      
      // לספר השרשים - ננסה לחלץ את האות מהתוכן
      if (book.title.contains('שרשים') || book.title.contains('רדק') || book.title.contains('רד"ק')) {
        if (kDebugMode) {
          print('CopyUtils: Detected Radak book, extracting from Radak content');
        }
        return await _extractFromRadakContent(book, currentIndex, bookContent);
      }
      
      // לספרים אחרים - ננסה לחלץ כותרות כלליות
      return await _extractGeneralHeaders(book, currentIndex, bookContent);
    } catch (e) {
      if (kDebugMode) {
        print('CopyUtils: Error extracting from content: $e');
      }
      return '';
    }
  }

  /// מחלץ מידע מתוכן ספר השרשים לרד"ק
  static Future<String> _extractFromRadakContent(TextBook book, int currentIndex, List<String>? bookContent) async {
    try {
      if (bookContent == null || currentIndex >= bookContent.length) {
        if (kDebugMode) {
          print('CopyUtils: No content available or index out of range');
        }
        return '';
      }
      
      if (kDebugMode) {
        print('CopyUtils: Analyzing Radak content at index $currentIndex');
      }
      
      // נחפש כותרת HTML באינדקסים הקודמים (עד 10 אינדקסים אחורה)
      String? foundHeader;
      for (int i = currentIndex; i >= math.max(0, currentIndex - 10); i--) {
        if (i < bookContent.length) {
          final text = bookContent[i];
          final headerPattern = RegExp(r'<h[1-6][^>]*>([^<]+)</h[1-6]>');
          final headerMatch = headerPattern.firstMatch(text);
          
          if (headerMatch != null) {
            foundHeader = headerMatch.group(1)!.trim();
            if (kDebugMode) {
              print('CopyUtils: Found header "$foundHeader" at index $i');
            }
            break;
          }
        }
      }
      
      if (foundHeader != null && foundHeader.isNotEmpty) {
        final firstLetter = foundHeader.substring(0, 1);
        final letterName = _getHebrewLetterName(firstLetter);
        final path = '${book.title}, $letterName, $foundHeader';
        
        if (kDebugMode) {
          print('CopyUtils: Generated Radak path from header: "$path"');
        }
        
        return path;
      }
      
      if (kDebugMode) {
        print('CopyUtils: No header found in nearby indices, trying current text analysis...');
      }
      
      // אם לא מצאנו כותרת, ננתח את הטקסט הנוכחי
      final currentText = bookContent[currentIndex];
      
      // נחפש את המילה הראשונה המודגשת שמופיעה בתחילת הטקסט
      final boldWordPattern = RegExp(r'<b>([א-ת]+)</b>');
      final firstMatch = boldWordPattern.firstMatch(currentText);
      
      if (firstMatch != null) {
        final word = firstMatch.group(1)!;
        final matchStart = firstMatch.start;
        
        // נבדוק אם המילה מופיעה בתחילת הטקסט (עד 50 תווים מההתחלה)
        if (matchStart < 50) {
          if (word.isNotEmpty) {
            final firstLetter = word.substring(0, 1);
            final letterName = _getHebrewLetterName(firstLetter);
            final path = '${book.title}, $letterName, $word';
            
            if (kDebugMode) {
              print('CopyUtils: Generated Radak path from first bold word: "$path"');
            }
            
            return path;
          }
        }
      }
      
      if (kDebugMode) {
        print('CopyUtils: Could not extract meaningful path from content');
      }
      
      return '';
    } catch (e) {
      if (kDebugMode) {
        print('CopyUtils: Error in _extractFromRadakContent: $e');
      }
      return '';
    }
  }

  /// מחלץ כותרות כלליות מתוכן הספר
  static Future<String> _extractGeneralHeaders(TextBook book, int currentIndex, List<String> bookContent) async {
    try {
      if (kDebugMode) {
        print('CopyUtils: Extracting general headers for index $currentIndex');
      }
      
      List<String> headers = [];
      
      // נוסיף את שם הספר כרמה 1
      headers.add(book.title);
      
      // נחפש כותרות בתוכן הנוכחי ובתוכן הקודם
      for (int i = math.max(0, currentIndex - 10); i <= currentIndex; i++) {
        if (i < bookContent.length) {
          final text = bookContent[i];
          
          // נחפש דפוסים של כותרות (טקסט מודגש, גדול, וכו')
          final headerPatterns = [
            RegExp(r'<h[1-6][^>]*>([^<]+)</h[1-6]>'), // כותרות HTML
            RegExp(r'<b>([^<]{2,30})</b>'), // טקסט מודגש קצר
            RegExp(r'<strong>([^<]{2,30})</strong>'), // טקסט חזק
          ];
          
          for (final pattern in headerPatterns) {
            final matches = pattern.allMatches(text);
            for (final match in matches) {
              final headerText = match.group(1)?.trim();
              if (headerText != null && headerText.isNotEmpty && headerText.length > 1) {
                // נוודא שזו לא מילה רגילה בתוך הטקסט
                if (!headers.contains(headerText) && _isLikelyHeader(headerText)) {
                  headers.add(headerText);
                  if (kDebugMode) {
                    print('CopyUtils: Found potential header: "$headerText"');
                  }
                }
              }
            }
          }
        }
      }
      
      // נחזיר את הכותרות המצטברות
      final result = headers.join(', ');
      if (kDebugMode) {
        print('CopyUtils: Generated general path: "$result"');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('CopyUtils: Error in _extractGeneralHeaders: $e');
      }
      return '';
    }
  }

  /// בודק אם טקסט נראה כמו כותרת
  static bool _isLikelyHeader(String text) {
    // כותרת צריכה להיות קצרה יחסית
    if (text.length > 50) return false;
    
    // לא צריכה להכיל סימני פיסוק רבים
    final punctuationCount = RegExp(r'[.,;:!?]').allMatches(text).length;
    if (punctuationCount > 2) return false;
    
    // לא צריכה להכיל מספרים רבים
    final numberCount = RegExp(r'\d').allMatches(text).length;
    if (numberCount > 3) return false;
    
    return true;
  }

  /// מחזיר שם של אות עברית
  static String _getHebrewLetterName(String letter) {
    const letterNames = {
      'א': 'אות הא\'',
      'ב': 'אות הב\'',
      'ג': 'אות הג\'',
      'ד': 'אות הד\'',
      'ה': 'אות הה\'',
      'ו': 'אות הו\'',
      'ז': 'אות הז\'',
      'ח': 'אות הח\'',
      'ט': 'אות הט\'',
      'י': 'אות הי\'',
      'כ': 'אות הכ\'',
      'ל': 'אות הל\'',
      'מ': 'אות המ\'',
      'נ': 'אות הנ\'',
      'ס': 'אות הס\'',
      'ע': 'אות הע\'',
      'פ': 'אות הפ\'',
      'צ': 'אות הצ\'',
      'ק': 'אות הק\'',
      'ר': 'אות הר\'',
      'ש': 'אות הש\'',
      'ת': 'אות הת\'',
    };
    
    return letterNames[letter] ?? 'אות ה$letter';
  }
}