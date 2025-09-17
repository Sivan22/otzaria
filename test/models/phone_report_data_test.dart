import 'package:flutter_test/flutter_test.dart';
import 'package:otzaria/models/phone_report_data.dart';

void main() {
  group('PhoneReportData', () {
    test('should serialize to JSON correctly', () {
      final reportData = PhoneReportData(
        selectedText: 'Test text',
        errorId: 1,
        moreInfo: 'Additional info',
        libraryVersion: '1.0.0',
        bookId: 123,
        lineNumber: 456,
      );

      final json = reportData.toJson();

      expect(json['library_ver'], equals('1.0.0'));
      expect(json['book_id'], equals(123));
      expect(json['line'], equals(456));
      expect(json['error_id'], equals(1));
      expect(json['more_info'], equals('Additional info'));
    });

    test('should create copy with updated fields', () {
      final original = PhoneReportData(
        selectedText: 'Original text',
        errorId: 1,
        moreInfo: 'Original info',
        libraryVersion: '1.0.0',
        bookId: 123,
        lineNumber: 456,
      );

      final updated = original.copyWith(
        errorId: 2,
        moreInfo: 'Updated info',
      );

      expect(updated.selectedText, equals('Original text'));
      expect(updated.errorId, equals(2));
      expect(updated.moreInfo, equals('Updated info'));
      expect(updated.libraryVersion, equals('1.0.0'));
      expect(updated.bookId, equals(123));
      expect(updated.lineNumber, equals(456));
    });
  });

  group('ErrorType', () {
    test('should find error type by ID', () {
      final errorType = ErrorType.getById(1);
      expect(errorType, isNotNull);
      expect(errorType!.id, equals(1));
      expect(errorType.hebrewLabel, equals('שגיאת כתיב'));
    });

    test('should return null for invalid ID', () {
      final errorType = ErrorType.getById(999);
      expect(errorType, isNull);
    });

    test('should have all expected error types', () {
      expect(ErrorType.errorTypes.length, equals(6));
      expect(ErrorType.errorTypes[0].hebrewLabel, equals('שגיאת כתיב'));
      expect(ErrorType.errorTypes[5].hebrewLabel, equals('אחר'));
    });
  });
}
