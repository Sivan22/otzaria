import 'package:equatable/equatable.dart';

/// Enum representing different types of reporting actions
enum ReportAction {
  regular,
  phone,
}

/// Represents an error type with ID and Hebrew label for phone reporting
class ErrorType extends Equatable {
  final int id;
  final String hebrewLabel;

  const ErrorType({
    required this.id,
    required this.hebrewLabel,
  });

  @override
  List<Object?> get props => [id, hebrewLabel];

  /// Static list of common error types with their IDs and Hebrew labels
  static const List<ErrorType> errorTypes = [
    ErrorType(id: 1, hebrewLabel: 'שגיאת כתיב'),
    ErrorType(id: 2, hebrewLabel: 'טקסט חסר'),
    ErrorType(id: 3, hebrewLabel: 'טקסט מיותר'),
    ErrorType(id: 4, hebrewLabel: 'שגיאת עיצוב'),
    ErrorType(id: 5, hebrewLabel: 'שגיאת מקור'),
    ErrorType(id: 6, hebrewLabel: 'אחר'),
  ];

  /// Get error type by ID
  static ErrorType? getById(int id) {
    try {
      return errorTypes.firstWhere((type) => type.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Data model for phone-based error reporting
class PhoneReportData extends Equatable {
  final String selectedText;
  final int errorId;
  final String moreInfo;
  final String libraryVersion;
  final int bookId;
  final int lineNumber;

  const PhoneReportData({
    required this.selectedText,
    required this.errorId,
    required this.moreInfo,
    required this.libraryVersion,
    required this.bookId,
    required this.lineNumber,
  });

  /// Convert to JSON for API submission
  Map<String, dynamic> toJson() => {
        'library_ver': libraryVersion,
        'book_id': bookId,
        'line': lineNumber,
        'error_id': errorId,
        'more_info': moreInfo,
      };

  /// Create from JSON (for testing purposes)
  factory PhoneReportData.fromJson(Map<String, dynamic> json) {
    return PhoneReportData(
      selectedText: '', // Not included in API payload
      errorId: json['error_id'] as int,
      moreInfo: json['more_info'] as String,
      libraryVersion: json['library_ver'] as String,
      bookId: json['book_id'] as int,
      lineNumber: json['line'] as int,
    );
  }

  /// Create a copy with updated fields
  PhoneReportData copyWith({
    String? selectedText,
    int? errorId,
    String? moreInfo,
    String? libraryVersion,
    int? bookId,
    int? lineNumber,
  }) {
    return PhoneReportData(
      selectedText: selectedText ?? this.selectedText,
      errorId: errorId ?? this.errorId,
      moreInfo: moreInfo ?? this.moreInfo,
      libraryVersion: libraryVersion ?? this.libraryVersion,
      bookId: bookId ?? this.bookId,
      lineNumber: lineNumber ?? this.lineNumber,
    );
  }

  @override
  List<Object?> get props => [
        selectedText,
        errorId,
        moreInfo,
        libraryVersion,
        bookId,
        lineNumber,
      ];

  @override
  String toString() {
    return 'PhoneReportData(selectedText: $selectedText, errorId: $errorId, '
        'moreInfo: $moreInfo, libraryVersion: $libraryVersion, '
        'bookId: $bookId, lineNumber: $lineNumber)';
  }
}
