import 'package:otzaria/notes/models/anchor_models.dart';
import 'package:otzaria/notes/services/text_normalizer.dart';
import 'package:otzaria/notes/services/hash_generator.dart';

/// Mock implementation of CanonicalTextService for testing
class MockCanonicalTextService {
  static MockCanonicalTextService? _instance;
  
  MockCanonicalTextService._();
  
  static MockCanonicalTextService get instance {
    _instance ??= MockCanonicalTextService._();
    return _instance!;
  }

  /// Create a mock canonical document for testing
  Future<CanonicalDocument> createCanonicalDocument(String bookId) async {
    // Generate mock book text
    final mockText = _generateMockBookText(bookId);
    
    // Create normalization config
    final config = TextNormalizer.createConfigFromSettings();
    
    // Normalize the text
    final normalizedText = TextNormalizer.normalize(mockText, config);
    
    // Generate version ID
    final versionId = 'mock-version-${mockText.hashCode}';
    
    // Create mock indexes
    final textHashIndex = <String, List<int>>{};
    final contextHashIndex = <String, List<int>>{};
    final rollingHashIndex = <int, List<int>>{};
    
    // Generate some mock hash entries
    final words = normalizedText.split(' ');
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isNotEmpty) {
        final hash = HashGenerator.generateTextHash(word);
        final position = normalizedText.indexOf(word, i > 0 ? normalizedText.indexOf(words[i-1]) + words[i-1].length : 0);
        
        textHashIndex.putIfAbsent(hash, () => <int>[]).add(position);
        
        // Add context hash
        if (i > 0) {
          final contextHash = HashGenerator.generateTextHash('${words[i-1]} $word');
          contextHashIndex.putIfAbsent(contextHash, () => <int>[]).add(position);
        }
        
        // Add rolling hash
        final rollingHash = HashGenerator.generateRollingHash(word);
        rollingHashIndex.putIfAbsent(rollingHash, () => <int>[]).add(position);
      }
    }
    
    return CanonicalDocument(
      id: 'mock-canonical-${bookId}-${DateTime.now().millisecondsSinceEpoch}',
      bookId: bookId,
      versionId: versionId,
      canonicalText: normalizedText,
      textHashIndex: textHashIndex,
      contextHashIndex: contextHashIndex,
      rollingHashIndex: rollingHashIndex,
      logicalStructure: _generateMockLogicalStructure(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Generate mock book text based on book ID
  String _generateMockBookText(String bookId) {
    final baseTexts = {
      'test-book': 'This is a test book with sample content for testing notes functionality.',
      'hebrew-book': 'זהו ספר בעברית עם תוכן לדוגמה לבדיקת פונקציונליות ההערות.',
      'mixed-book': 'This is mixed content עם טקסט בעברית and English together.',
      'performance-book': _generatePerformanceText(),
    };
    
    // Return specific text for known book IDs, or generate based on ID
    if (baseTexts.containsKey(bookId)) {
      return baseTexts[bookId]!;
    }
    
    // Generate text based on book ID pattern
    if (bookId.contains('hebrew')) {
      return 'טקסט בעברית לספר $bookId עם תוכן מגוון לבדיקות.';
    } else if (bookId.contains('performance') || bookId.contains('perf')) {
      return _generatePerformanceText();
    } else if (bookId.contains('large')) {
      return _generateLargeText();
    }
    
    // Default text
    return 'Mock book content for $bookId with various text for testing purposes. '
           'This content includes different words and phrases to test anchoring functionality.';
  }

  /// Generate performance test text
  String _generatePerformanceText() {
    final buffer = StringBuffer();
    final sentences = [
      'This is a performance test sentence with various words.',
      'Another sentence for testing search and anchoring performance.',
      'Text content with different patterns and structures.',
      'Sample content for measuring system performance metrics.',
      'Additional text to create a larger document for testing.',
    ];
    
    for (int i = 0; i < 100; i++) {
      buffer.write('${sentences[i % sentences.length]} ');
    }
    
    return buffer.toString();
  }

  /// Generate large text for stress testing
  String _generateLargeText() {
    final buffer = StringBuffer();
    final paragraph = 'This is a large text document created for stress testing the notes system. '
                     'It contains multiple paragraphs with various content to test performance '
                     'and functionality under load conditions. The text includes different words, '
                     'phrases, and structures to provide comprehensive testing coverage. ';
    
    for (int i = 0; i < 1000; i++) {
      buffer.write('$paragraph ');
      if (i % 10 == 0) {
        buffer.write('\n\n'); // Add paragraph breaks
      }
    }
    
    return buffer.toString();
  }

  /// Generate mock logical structure
  List<String> _generateMockLogicalStructure() {
    return [
      'chapter_1',
      'section_1_1',
      'paragraph_1',
      'paragraph_2',
      'section_1_2',
      'paragraph_3',
      'chapter_2',
      'section_2_1',
      'paragraph_4',
    ];
  }

  /// Calculate document version for mock text
  String calculateDocumentVersion(String text) {
    return 'mock-version-${text.hashCode}';
  }

  /// Check if document version has changed
  bool hasDocumentChanged(String bookId, String currentVersion) {
    final mockText = _generateMockBookText(bookId);
    final expectedVersion = calculateDocumentVersion(mockText);
    return currentVersion != expectedVersion;
  }

  /// Get mock document statistics
  Map<String, dynamic> getDocumentStats(String bookId) {
    final mockText = _generateMockBookText(bookId);
    final words = mockText.split(' ').where((w) => w.isNotEmpty).toList();
    
    return {
      'book_id': bookId,
      'character_count': mockText.length,
      'word_count': words.length,
      'paragraph_count': mockText.split('\n').length,
      'unique_words': words.toSet().length,
      'version_id': calculateDocumentVersion(mockText),
    };
  }
}