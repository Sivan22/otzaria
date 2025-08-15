import '../models/anchor_models.dart';
import 'text_normalizer.dart';
import 'hash_generator.dart';
import '../config/notes_config.dart';

/// Service for creating and managing canonical text documents.
class CanonicalTextService {
  static CanonicalTextService? _instance;

  CanonicalTextService._();

  /// Singleton instance
  static CanonicalTextService get instance {
    _instance ??= CanonicalTextService._();
    return _instance!;
  }

  /// Create a canonical document from book text
  Future<CanonicalDocument> createCanonicalDocument(String bookId) async {
    try {
      // Get raw text from book (this would normally come from FileSystemData)
      final rawText = await _getRawTextForBook(bookId);

      // Create normalization config
      final config = TextNormalizer.createConfigFromSettings();

      // Normalize the text
      final canonicalText = TextNormalizer.normalize(rawText, config);

      // Calculate version ID
      final versionId = calculateDocumentVersion(rawText);

      // Create indexes (simplified for now)
      final textHashIndex = <String, List<int>>{};
      final contextHashIndex = <String, List<int>>{};
      final rollingHashIndex = <int, List<int>>{};

      return CanonicalDocument(
        id: 'canonical_${bookId}_${DateTime.now().millisecondsSinceEpoch}',
        bookId: bookId,
        versionId: versionId,
        canonicalText: canonicalText,
        textHashIndex: textHashIndex,
        contextHashIndex: contextHashIndex,
        rollingHashIndex: rollingHashIndex,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      throw CanonicalTextException('Failed to create canonical document: $e');
    }
  }

  /// Extract context window around a text position
  ContextWindow extractContextWindow(
    String text,
    int start,
    int end, {
    int windowSize = AnchoringConstants.contextWindowSize,
  }) {
    return TextNormalizer.extractContextWindow(text, start, end,
        windowSize: windowSize);
  }

  /// Calculate document version ID from raw text
  String calculateDocumentVersion(String rawText) {
    return HashGenerator.generateTextHash(rawText);
  }

  /// Get raw text for a book (placeholder implementation)
  Future<String> _getRawTextForBook(String bookId) async {
    // This is a placeholder - in real implementation this would:
    // 1. Load text from FileSystemData
    // 2. Handle different book formats
    // 3. Cache frequently accessed books

    // For now, return a simple placeholder
    return 'Sample text for book $bookId. This would be the actual book content.';
  }
}

/// Exception thrown by canonical text service
class CanonicalTextException implements Exception {
  final String message;

  const CanonicalTextException(this.message);

  @override
  String toString() => 'CanonicalTextException: $message';
}
