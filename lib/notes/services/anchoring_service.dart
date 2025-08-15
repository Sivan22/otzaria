import '../models/note.dart';
import '../models/anchor_models.dart';
import 'text_normalizer.dart';
import 'hash_generator.dart';
import 'canonical_text_service.dart';
import 'notes_telemetry.dart';

/// Service for anchoring notes to text locations using multi-strategy approach.
class AnchoringService {
  static AnchoringService? _instance;
  final CanonicalTextService _canonicalService = CanonicalTextService.instance;

  AnchoringService._();

  /// Singleton instance
  static AnchoringService get instance {
    _instance ??= AnchoringService._();
    return _instance!;
  }

  /// Create an anchor for a new note
  AnchorData createAnchor(
    String bookId,
    String canonicalText,
    int charStart,
    int charEnd,
  ) {
    try {
      // Create normalization config
      final config = TextNormalizer.createConfigFromSettings();

      // Extract and normalize the selected text
      final selectedText = canonicalText.substring(charStart, charEnd);
      final normalizedSelected = TextNormalizer.normalize(selectedText, config);

      // Extract context window
      final contextWindow = _canonicalService.extractContextWindow(
        canonicalText,
        charStart,
        charEnd,
      );

      // Normalize context
      final normalizedContext =
          TextNormalizer.normalizeContextWindow(contextWindow, config);

      // Generate hashes
      final textHashes = HashGenerator.generateTextHashes(normalizedSelected);
      final contextHashes = HashGenerator.generateContextHashes(
        normalizedContext.before,
        normalizedContext.after,
      );

      return AnchorData(
        charStart: charStart,
        charEnd: charEnd,
        textHash: textHashes.textHash,
        contextBefore: normalizedContext.before,
        contextAfter: normalizedContext.after,
        contextBeforeHash: contextHashes.beforeHash,
        contextAfterHash: contextHashes.afterHash,
        rollingBefore: contextHashes.beforeRollingHash,
        rollingAfter: contextHashes.afterRollingHash,
        status: NoteStatus.anchored,
      );
    } catch (e) {
      throw AnchoringException(
        AnchoringError.corruptedAnchor,
        'Failed to create anchor: $e',
      );
    }
  }

  /// Re-anchor a note to a new document version
  Future<AnchorResult> reanchorNote(
      Note note, CanonicalDocument document) async {
    final stopwatch = Stopwatch()..start();
    final requestId = 'reanchor_${DateTime.now().millisecondsSinceEpoch}';

    try {
      // Step 1: Check if document version is the same (O(1) operation)
      if (note.docVersionId == document.versionId) {
        final result = AnchorResult(
          NoteStatus.anchored,
          start: note.charStart,
          end: note.charEnd,
        );

        // Track telemetry if available
        try {
          NotesTelemetry.trackAnchoringResult(
            requestId,
            NoteStatus.anchored,
            stopwatch.elapsed,
            'version_match',
          );
        } catch (e) {
          // Telemetry failure shouldn't break anchoring
        }

        return result;
      }

      // For now, just mark as orphan - full implementation will come later
      final result = AnchorResult(
        NoteStatus.orphan,
        errorMessage: 'Re-anchoring not fully implemented yet',
      );

      try {
        NotesTelemetry.trackAnchoringResult(
          requestId,
          NoteStatus.orphan,
          stopwatch.elapsed,
          'failed',
        );
      } catch (e) {
        // Telemetry failure shouldn't break anchoring
      }

      return result;
    } catch (e) {
      final result = AnchorResult(
        NoteStatus.orphan,
        errorMessage: 'Re-anchoring failed: $e',
      );

      return result;
    } finally {
      stopwatch.stop();
    }
  }
}