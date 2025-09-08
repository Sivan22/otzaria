import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Common test setup utilities
class TestSetup {
  /// Initialize test environment
  static void initializeTestEnvironment() {
    // Initialize SQLite FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    // Mock Settings initialization
    _mockSettingsInit();
  }

  /// Mock Settings initialization to avoid dependency issues
  static void _mockSettingsInit() {
    // This is a simplified mock - in a real implementation you might use
    // a proper mocking framework or create a test-specific Settings implementation
    
    // For now, we'll just ensure the tests can run without Settings dependency
    // The actual Settings integration would be handled in the main app
  }

  /// Create test canonical document data
  static Map<String, dynamic> createTestCanonicalDocument(String bookId, String text) {
    return {
      'bookId': bookId,
      'versionId': 'test-version-${text.hashCode}',
      'canonicalText': text,
      'textHashIndex': <String, List<int>>{},
      'contextHashIndex': <String, List<int>>{},
      'rollingHashIndex': <int, List<int>>{},
      'logicalStructure': <String>[],
    };
  }

  /// Create test note data
  static Map<String, dynamic> createTestNote({
    required String id,
    required String bookId,
    required int charStart,
    required int charEnd,
    required String content,
    String selectedText = 'test text',
    List<String> tags = const [],
  }) {
    final now = DateTime.now();
    
    return {
      'id': id,
      'book_id': bookId,
      'doc_version_id': 'test-version',
      'logical_path': null,
      'char_start': charStart,
      'char_end': charEnd,
      'selected_text_normalized': selectedText,
      'text_hash': 'test-hash-${selectedText.hashCode}',
      'context_before': '',
      'context_after': '',
      'context_before_hash': 'before-hash',
      'context_after_hash': 'after-hash',
      'rolling_before': 12345,
      'rolling_after': 67890,
      'status': 'anchored',
      'content_markdown': content,
      'author_user_id': 'test-user',
      'privacy': 'private',
      'tags': tags,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'normalization_config': 'norm=v1;nikud=keep;quotes=ascii;unicode=NFKC',
    };
  }

  /// Generate test book text
  static String generateTestBookText(int length, {String prefix = 'Test book content'}) {
    final buffer = StringBuffer(prefix);
    
    while (buffer.length < length) {
      buffer.write(' Additional content for testing purposes.');
    }
    
    return buffer.toString().substring(0, length);
  }

  /// Create performance test data
  static List<Map<String, dynamic>> createPerformanceTestData(int count) {
    final testData = <Map<String, dynamic>>[];
    
    for (int i = 0; i < count; i++) {
      testData.add({
        'id': 'perf-test-$i',
        'content': 'Performance test note $i',
        'charStart': i * 10,
        'charEnd': i * 10 + 15,
        'tags': ['performance', 'test', 'batch-$i'],
      });
    }
    
    return testData;
  }

  /// Validate test results
  static void validateTestResults(Map<String, dynamic> results) {
    expect(results, isNotNull);
    expect(results, isA<Map<String, dynamic>>());
  }

  /// Clean up test environment
  static void cleanupTestEnvironment() {
    // Clean up any test-specific resources
    // This would be called in tearDown methods
  }
}

/// Test constants
class TestConstants {
  static const String defaultBookId = 'test-book';
  static const String defaultUserId = 'test-user';
  static const String defaultBookText = 'This is a test book with sample content for testing notes functionality.';
  
  static const int performanceTestTimeout = 5000; // 5 seconds
  static const int maxTestNotes = 1000;
  static const int defaultBatchSize = 50;
  
  static const List<String> sampleTags = ['test', 'sample', 'demo', 'example'];
  static const List<String> hebrewSampleText = [
    'זהו טקסט לדוגמה בעברית',
    'הערות אישיות על הטקסט',
    'בדיקת תמיכה בעברית',
    'טקסט עם ניקוד: בְּרֵאשִׁית',
  ];
}

/// Test data generators
class TestDataGenerator {
  /// Generate Hebrew text with various characteristics
  static String generateHebrewText({
    bool includeNikud = false,
    bool includeQuotes = false,
    bool includePunctuation = false,
    int length = 100,
  }) {
    final buffer = StringBuffer();
    final baseText = 'זהו טקסט בעברית לבדיקת המערכת ';
    
    while (buffer.length < length) {
      buffer.write(baseText);
      
      if (includeNikud && buffer.length < length) {
        buffer.write('בְּרֵאשִׁית ');
      }
      
      if (includeQuotes && buffer.length < length) {
        buffer.write('"מירכאות" ');
      }
      
      if (includePunctuation && buffer.length < length) {
        buffer.write('סימני פיסוק: נקודה, פסיק! ');
      }
    }
    
    return buffer.toString().substring(0, length);
  }

  /// Generate mixed language text
  static String generateMixedText(int length) {
    final buffer = StringBuffer();
    final patterns = [
      'English text mixed with ',
      'עברית וגם ',
      'numbers 123 and ',
      'symbols @#\$ and ',
    ];
    
    int patternIndex = 0;
    while (buffer.length < length) {
      buffer.write(patterns[patternIndex % patterns.length]);
      patternIndex++;
    }
    
    return buffer.toString().substring(0, length);
  }

  /// Generate performance test scenarios
  static List<Map<String, dynamic>> generatePerformanceScenarios() {
    return [
      {
        'name': 'Small dataset',
        'noteCount': 10,
        'textLength': 1000,
        'expectedMaxTime': 100,
      },
      {
        'name': 'Medium dataset',
        'noteCount': 100,
        'textLength': 10000,
        'expectedMaxTime': 500,
      },
      {
        'name': 'Large dataset',
        'noteCount': 500,
        'textLength': 50000,
        'expectedMaxTime': 2000,
      },
    ];
  }
}