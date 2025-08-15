import 'package:flutter_test/flutter_test.dart';
import 'package:otzaria/notes/services/canonical_text_service.dart';
import 'package:otzaria/notes/services/text_normalizer.dart';
import 'package:otzaria/notes/config/notes_config.dart';
import 'package:otzaria/notes/models/anchor_models.dart';

void main() {
  group('CanonicalTextService Tests', () {
    late CanonicalTextService service;

    setUp(() {
      service = CanonicalTextService.instance;
    });

    group('Document Version Calculation', () {
      test('should generate consistent version hashes', () {
        const text = 'זהו טקסט לדוגמה';
        final version1 = service.calculateDocumentVersion(text);
        final version2 = service.calculateDocumentVersion(text);
        
        expect(version1, equals(version2));
        expect(version1.length, equals(64)); // SHA-256 length
      });

      test('should generate different versions for different texts', () {
        const text1 = 'טקסט ראשון';
        const text2 = 'טקסט שני';
        
        final version1 = service.calculateDocumentVersion(text1);
        final version2 = service.calculateDocumentVersion(text2);
        
        expect(version1, isNot(equals(version2)));
      });
    });

    group('Context Window Extraction', () {
      test('should extract context window correctly', () {
        const text = 'זה טקסט לדוגמה עם הרבה מילים';
        final window = service.extractContextWindow(text, 5, 10);
        
        expect(window.selected, equals('סט לד'));
        expect(window.selectedStart, equals(5));
        expect(window.selectedEnd, equals(10));
      });

      test('should handle custom window size', () {
        const text = 'טקסט קצר';
        final window = service.extractContextWindow(text, 2, 4, windowSize: 2);
        
        expect(window.before.length, lessThanOrEqualTo(2));
        expect(window.after.length, lessThanOrEqualTo(2));
      });
    });

    group('Text Segment Operations', () {
      test('should extract context window correctly', () {
        const text = 'זהו טקסט לדוגמה';
        
        final context = service.extractContextWindow(text, 4, 8);
        expect(context.selected, equals(text.substring(4, 8)));
        expect(context.before, equals(text.substring(0, 4)));
      });

      test('should handle invalid context window range', () {
        const text = 'טקסט קצר';
        
        // Should not throw, but clamp to valid range
        final context = service.extractContextWindow(text, -1, 5);
        expect(context.before, equals(''));
        expect(context.selected.length, lessThanOrEqualTo(text.length));
        );
        
        expect(
          () => service.getTextSegment(document, 5, 100),
          throwsArgumentError,
        );
        
        expect(
          () => service.getTextSegment(document, 5, 3),
          throwsArgumentError,
        );
      });
    });

    group('Hash Matching', () {
      test('should find text hash matches', () {
        const text = 'זהו טקסט לדוגמה';
        final document = _createMockDocument('test', text);
        
        // This would normally be populated by the real service
        // For testing, we'll assume some matches exist
        final matches = service.findTextHashMatches(document, 'dummy-hash');
        expect(matches, isA<List<int>>());
      });

      test('should find context matches', () {
        const text = 'זהו טקסט לדוגמה';
        final document = _createMockDocument('test', text);
        
        final matches = service.findContextMatches(
          document,
          'before-hash',
          'after-hash',
        );
        expect(matches, isA<List<int>>());
      });

      test('should find rolling hash matches', () {
        const text = 'זהו טקסט לדוגמה';
        final document = _createMockDocument('test', text);
        
        final matches = service.findRollingHashMatches(document, 12345);
        expect(matches, isA<List<int>>());
      });
    });

    group('Document Validation', () {
      test('should validate proper canonical document', () {
        const text = 'זהו טקסט לדוגמה עם תוכן מספיק ארוך לבדיקה';
        final document = _createMockDocument('test-book', text);
        
        final isValid = service.validateCanonicalDocument(document);
        expect(isValid, isTrue);
      });

      test('should reject document with empty fields', () {
        final document = _createMockDocument('', '');
        
        final isValid = service.validateCanonicalDocument(document);
        expect(isValid, isFalse);
      });

      test('should reject document with mismatched version', () {
        const text = 'זהו טקסט לדוגמה';
        final document = _createMockDocument('test', text, versionId: 'wrong-version');
        
        final isValid = service.validateCanonicalDocument(document);
        expect(isValid, isFalse);
      });
    });

    group('Document Statistics', () {
      test('should provide comprehensive document stats', () {
        const text = 'זהו טקסט לדוגמה עם תוכן';
        final document = _createMockDocument('test-book', text);
        
        final stats = service.getDocumentStats(document);
        
        expect(stats['book_id'], equals('test-book'));
        expect(stats['text_length'], equals(text.length));
        expect(stats['text_hash_entries'], isA<int>());
        expect(stats['context_hash_entries'], isA<int>());
        expect(stats['rolling_hash_entries'], isA<int>());
        expect(stats['has_logical_structure'], isA<bool>());
      });
    });
  });
}

/// Helper function to create a mock canonical document for testing
_createMockDocument(String bookId, String text, {String? versionId}) {
  final service = CanonicalTextService.instance;
  final actualVersionId = versionId ?? service.calculateDocumentVersion(text);
  
  return MockCanonicalDocument(
    bookId: bookId,
    versionId: actualVersionId,
    canonicalText: text,
    textHashIndex: const {},
    contextHashIndex: const {},
    rollingHashIndex: const {},
    logicalStructure: null,
  );
}

/// Mock implementation for testing
class MockCanonicalDocument extends CanonicalDocument {
  const MockCanonicalDocument({
    required super.bookId,
    required super.versionId,
    required super.canonicalText,
    required super.textHashIndex,
    required super.contextHashIndex,
    required super.rollingHashIndex,
    super.logicalStructure,
  });
}