import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// Service for collecting data required for phone error reporting
class DataCollectionService {
  static String get _libraryVersionPath =>
      'אוצריא${Platform.pathSeparator}אודות התוכנה${Platform.pathSeparator}גירסת ספריה.txt';
  static String get _sourceBooksPath =>
      'אוצריא${Platform.pathSeparator}אודות התוכנה${Platform.pathSeparator}SourcesBooks.csv';

  /// Read library version from the version file
  /// Returns "unknown" if file is missing or cannot be read
  Future<String> readLibraryVersion() async {
    try {
      final libraryPath = Settings.getValue('key-library-path');
      if (libraryPath == null || libraryPath.isEmpty) {
        debugPrint('Library path not set');
        return 'unknown';
      }

      final versionFile =
          File('$libraryPath${Platform.pathSeparator}$_libraryVersionPath');

      if (!await versionFile.exists()) {
        debugPrint('Library version file not found: ${versionFile.path}');
        return 'unknown';
      }

      final version = await versionFile.readAsString(encoding: utf8);
      return version.trim();
    } catch (e) {
      debugPrint('Error reading library version: $e');
      return 'unknown';
    }
  }

  /// Find book ID in SourcesBooks.csv by matching the book title
  /// Returns the line number (1-based) if found, null if not found or error
  Future<int?> findBookIdInCsv(String bookTitle) async {
    try {
      final libraryPath = Settings.getValue('key-library-path');
      if (libraryPath == null || libraryPath.isEmpty) {
        debugPrint('Library path not set');
        return null;
      }

      final csvFile =
          File('$libraryPath${Platform.pathSeparator}$_sourceBooksPath');

      if (!await csvFile.exists()) {
        debugPrint('SourcesBooks.csv file not found: ${csvFile.path}');
        return null;
      }

      final inputStream = csvFile.openRead();
      final converter = const CsvToListConverter();

      int lineNumber = 0;
      bool isFirstLine = true;

      await for (final line in inputStream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        lineNumber++;

        // Skip header line
        if (isFirstLine) {
          isFirstLine = false;
          continue;
        }

        try {
          final row = converter.convert(line).first;

          if (row.isNotEmpty) {
            final fileNameRaw = row[0].toString();
            final fileName = fileNameRaw.replaceAll('.txt', '');

            if (fileName == bookTitle) {
              return lineNumber; // Return 1-based line number
            }
          }
        } catch (e) {
          debugPrint('Error parsing CSV line $lineNumber: $line, Error: $e');
          continue;
        }
      }

      debugPrint('Book not found in CSV: $bookTitle');
      return null;
    } catch (e) {
      debugPrint('Error reading SourcesBooks.csv: $e');
      return null;
    }
  }

  /// Get current line number from ItemPosition data
  /// Returns the first visible item index, or 0 if no positions available
  int getCurrentLineNumber(List<ItemPosition> positions) {
    try {
      if (positions.isEmpty) {
        return 0;
      }

      // Sort positions by index and return the first one
      final sortedPositions = positions.toList()
        ..sort((a, b) => a.index.compareTo(b.index));

      return sortedPositions.first.index + 1; // Convert to 1-based
    } catch (e) {
      debugPrint('Error getting current line number: $e');
      return 0;
    }
  }

  /// Check if all required data is available for phone reporting
  /// Returns a map with availability status and error messages
  Future<Map<String, dynamic>> checkDataAvailability(String bookTitle) async {
    final result = <String, dynamic>{
      'available': true,
      'errors': <String>[],
      'libraryVersion': null,
      'bookId': null,
    };

    // Check library version
    final libraryVersion = await readLibraryVersion();
    result['libraryVersion'] = libraryVersion;

    if (libraryVersion == 'unknown') {
      result['available'] = false;
      result['errors'].add('לא ניתן לקרוא את גירסת הספרייה');
    }

    // Check book ID
    final bookId = await findBookIdInCsv(bookTitle);
    result['bookId'] = bookId;

    if (bookId == null) {
      result['available'] = false;
      result['errors'].add('לא ניתן למצוא את הספר במאגר הנתונים');
    }

    return result;
  }
}
