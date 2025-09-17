import 'package:equatable/equatable.dart';
import 'note.dart';

/// Represents a candidate location for anchoring a note.
/// 
/// When the anchoring system cannot find an exact match for a note's original
/// location, it generates a list of candidate locations where the note might
/// belong. Each candidate has a similarity score and the strategy used to find it.
/// 
/// ## Scoring
/// 
/// Candidates are scored from 0.0 to 1.0:
/// - **1.0**: Perfect match (exact text and context)
/// - **0.9-0.99**: Very high confidence (minor changes)
/// - **0.8-0.89**: High confidence (moderate changes)
/// - **0.7-0.79**: Medium confidence (significant changes)
/// - **< 0.7**: Low confidence (major changes)
/// 
/// ## Strategies
/// 
/// Different strategies are used to find candidates:
/// - **"exact"**: Exact text hash match
/// - **"context"**: Context window matching
/// - **"fuzzy"**: Fuzzy text similarity
/// - **"semantic"**: Word-level semantic matching
/// 
/// ## Usage
/// 
/// ```dart
/// // Create a candidate
/// final candidate = AnchorCandidate(100, 150, 0.85, 'fuzzy');
/// 
/// // Check confidence level
/// if (candidate.score > 0.9) {
///   // High confidence - auto-anchor
/// } else if (candidate.score > 0.7) {
///   // Medium confidence - suggest to user
/// } else {
///   // Low confidence - manual review needed
/// }
/// ```
class AnchorCandidate extends Equatable {
  /// Start character position of the candidate
  final int start;
  
  /// End character position of the candidate
  final int end;
  
  /// Similarity score (0.0 to 1.0)
  final double score;
  
  /// Strategy used to find this candidate
  final String strategy;

  const AnchorCandidate(
    this.start,
    this.end,
    this.score,
    this.strategy,
  );

  @override
  List<Object?> get props => [start, end, score, strategy];

  @override
  String toString() {
    return 'AnchorCandidate(start: $start, end: $end, score: ${score.toStringAsFixed(3)}, strategy: $strategy)';
  }
}

/// Represents the result of an anchoring operation
class AnchorResult extends Equatable {
  /// The resulting status of the anchoring
  final NoteStatus status;
  
  /// Start position if successfully anchored
  final int? start;
  
  /// End position if successfully anchored
  final int? end;
  
  /// List of candidate positions found
  final List<AnchorCandidate> candidates;
  
  /// Error message if anchoring failed
  final String? errorMessage;

  const AnchorResult(
    this.status, {
    this.start,
    this.end,
    this.candidates = const [],
    this.errorMessage,
  });

  /// Whether the anchoring was successful
  bool get isSuccess => status != NoteStatus.orphan || candidates.isNotEmpty;
  
  /// Whether multiple candidates were found requiring user choice
  bool get hasMultipleCandidates => candidates.length > 1;

  @override
  List<Object?> get props => [status, start, end, candidates, errorMessage];

  @override
  String toString() {
    return 'AnchorResult(status: $status, candidates: ${candidates.length}, success: $isSuccess)';
  }
}

/// Represents anchor data for a note
class AnchorData extends Equatable {
  /// Character start position
  final int charStart;
  
  /// Character end position
  final int charEnd;
  
  /// Hash of the selected text
  final String textHash;
  
  /// Context before the selection
  final String contextBefore;
  
  /// Context after the selection
  final String contextAfter;
  
  /// Hash of context before
  final String contextBeforeHash;
  
  /// Hash of context after
  final String contextAfterHash;
  
  /// Rolling hash before
  final int rollingBefore;
  
  /// Rolling hash after
  final int rollingAfter;
  
  /// Current status
  final NoteStatus status;

  const AnchorData({
    required this.charStart,
    required this.charEnd,
    required this.textHash,
    required this.contextBefore,
    required this.contextAfter,
    required this.contextBeforeHash,
    required this.contextAfterHash,
    required this.rollingBefore,
    required this.rollingAfter,
    required this.status,
  });

  @override
  List<Object?> get props => [
        charStart,
        charEnd,
        textHash,
        contextBefore,
        contextAfter,
        contextBeforeHash,
        contextAfterHash,
        rollingBefore,
        rollingAfter,
        status,
      ];
}

/// Represents a canonical document with search indexes
class CanonicalDocument extends Equatable {
  /// Document identifier
  final String id;
  
  /// Book identifier
  final String bookId;
  
  /// Version identifier
  final String versionId;
  
  /// The canonical text content
  final String canonicalText;
  
  /// Index mapping text hashes to character positions
  final Map<String, List<int>> textHashIndex;
  
  /// Index mapping context hashes to character positions
  final Map<String, List<int>> contextHashIndex;
  
  /// Index mapping rolling hashes to character positions
  final Map<int, List<int>> rollingHashIndex;
  
  /// Logical structure of the document
  final List<String>? logicalStructure;
  
  /// When the document was created
  final DateTime createdAt;
  
  /// When the document was last updated
  final DateTime updatedAt;

  const CanonicalDocument({
    required this.id,
    required this.bookId,
    required this.versionId,
    required this.canonicalText,
    required this.textHashIndex,
    required this.contextHashIndex,
    required this.rollingHashIndex,
    this.logicalStructure,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        bookId,
        versionId,
        canonicalText,
        textHashIndex,
        contextHashIndex,
        rollingHashIndex,
        logicalStructure,
        createdAt,
        updatedAt,
      ];
}

/// Represents a visible character range in the text
class VisibleCharRange extends Equatable {
  /// Start character position
  final int start;
  
  /// End character position
  final int end;

  const VisibleCharRange(this.start, this.end);

  /// Length of the range
  int get length => end - start;

  /// Whether this range contains the given position
  bool contains(int position) => position >= start && position <= end;

  /// Whether this range overlaps with another range
  bool overlaps(VisibleCharRange other) {
    return start <= other.end && end >= other.start;
  }

  @override
  List<Object?> get props => [start, end];

  @override
  String toString() {
    return 'VisibleCharRange($start-$end)';
  }
}

/// Types of anchoring errors
enum AnchoringError {
  documentNotFound,
  multipleMatches,
  noMatchFound,
  corruptedAnchor,
  versionMismatch,
}

/// Exception thrown during anchoring operations
class AnchoringException implements Exception {
  final AnchoringError type;
  final String message;
  final Note? note;
  final List<AnchorCandidate>? candidates;

  const AnchoringException(
    this.type,
    this.message, {
    this.note,
    this.candidates,
  });

  @override
  String toString() {
    return 'AnchoringException: $type - $message';
  }
}