import 'package:equatable/equatable.dart';

/// Represents the status of a note's anchoring in the text.
///
/// The anchoring status indicates how well the note's original location
/// has been preserved after text changes in the document.
enum NoteStatus {
  /// Note is anchored to its exact original location.
  ///
  /// This is the ideal state - the text hash matches exactly and the note
  /// appears at its original character positions. No re-anchoring was needed.
  anchored,

  /// Note was re-anchored to a shifted but similar location.
  ///
  /// The original text was not found at the exact position, but the anchoring
  /// system successfully found a highly similar location using context or
  /// fuzzy matching. The note content is still relevant to the new location.
  shifted,

  /// Note could not be anchored and requires manual resolution.
  ///
  /// The anchoring system could not find a suitable location for this note.
  /// This happens when text is significantly changed or deleted. The note
  /// needs manual review through the Orphan Manager.
  orphan,
}

/// Represents the privacy level of a note.
///
/// Controls who can see and access the note content.
enum NotePrivacy {
  /// Note is private to the user.
  ///
  /// Only the user who created the note can see it. This is the default
  /// privacy level for new notes.
  private,

  /// Note can be shared with others.
  ///
  /// The note can be exported and shared with other users. Future versions
  /// may support collaborative note sharing.
  shared,
}

/// Represents a personal note attached to a specific text location.
///
/// A note contains user-generated content (markdown) that is anchored to
/// a specific location in a book's text. The anchoring system ensures
/// notes stay connected to their relevant text even when the book content
/// changes.
///
/// ## Core Properties
///
/// - **Identity**: Unique ID and book association
/// - **Location**: Character positions and anchoring data
/// - **Content**: Markdown text and metadata (tags, privacy)
/// - **Anchoring**: Hashes and context for re-anchoring
/// - **Status**: Current anchoring state (anchored/shifted/orphan)
///
/// ## Anchoring Data
///
/// Each note stores multiple pieces of anchoring information:
/// - Text hash of the selected content
/// - Context hashes (before/after the selection)
/// - Rolling hashes for sliding window matching
/// - Normalization config used when creating hashes
///
/// ## Usage
///
/// ```dart
/// // Create a new note
/// final note = Note(
///   id: 'unique-id',
///   bookId: 'book-id',
///   charStart: 100,
///   charEnd: 150,
///   contentMarkdown: 'My note content',
///   // ... other required fields
/// );
///
/// // Check note status
/// if (note.status == NoteStatus.orphan) {
///   // Handle orphan note
/// }
///
/// // Access note content
/// final content = note.contentMarkdown;
/// final tags = note.tags;
/// ```
///
/// ## Immutability
///
/// Notes are immutable value objects. Use the `copyWith` method to create
/// modified versions:
///
/// ```dart
/// final updatedNote = note.copyWith(
///   contentMarkdown: 'Updated content',
///   status: NoteStatus.shifted,
/// );
/// ```
///
/// ## Equality
///
/// Notes are compared by their ID only. Two notes with the same ID are
/// considered equal regardless of other field differences.
class Note extends Equatable {
  /// Unique identifier for the note
  final String id;

  /// ID of the book this note belongs to
  final String bookId;

  /// Version ID of the document when note was created
  final String docVersionId;

  /// Logical path within the document (e.g., ["chapter:3", "para:12"])
  final List<String>? logicalPath;

  /// Character start position in the canonical text
  final int charStart;

  /// Character end position in the canonical text
  final int charEnd;

  /// Normalized text that was selected when creating the note
  final String selectedTextNormalized;

  /// SHA-256 hash of the selected normalized text
  final String textHash;

  /// Context text before the selection (40 chars)
  final String contextBefore;

  /// Context text after the selection (40 chars)
  final String contextAfter;

  /// SHA-256 hash of the context before
  final String contextBeforeHash;

  /// SHA-256 hash of the context after
  final String contextAfterHash;

  /// Rolling hash of the context before
  final int rollingBefore;

  /// Rolling hash of the context after
  final int rollingAfter;

  /// Current anchoring status of the note
  final NoteStatus status;

  /// The actual note content in markdown format
  final String contentMarkdown;

  /// ID of the user who created the note
  final String authorUserId;

  /// Privacy level of the note
  final NotePrivacy privacy;

  /// Tags associated with the note
  final List<String> tags;

  /// When the note was created
  final DateTime createdAt;

  /// When the note was last updated
  final DateTime updatedAt;

  /// Configuration used for text normalization when creating this note
  final String normalizationConfig;

  const Note({
    required this.id,
    required this.bookId,
    required this.docVersionId,
    this.logicalPath,
    required this.charStart,
    required this.charEnd,
    required this.selectedTextNormalized,
    required this.textHash,
    required this.contextBefore,
    required this.contextAfter,
    required this.contextBeforeHash,
    required this.contextAfterHash,
    required this.rollingBefore,
    required this.rollingAfter,
    required this.status,
    required this.contentMarkdown,
    required this.authorUserId,
    required this.privacy,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.normalizationConfig,
  });

  /// Creates a copy of this note with updated fields
  Note copyWith({
    String? id,
    String? bookId,
    String? docVersionId,
    List<String>? logicalPath,
    int? charStart,
    int? charEnd,
    String? selectedTextNormalized,
    String? textHash,
    String? contextBefore,
    String? contextAfter,
    String? contextBeforeHash,
    String? contextAfterHash,
    int? rollingBefore,
    int? rollingAfter,
    NoteStatus? status,
    String? contentMarkdown,
    String? authorUserId,
    NotePrivacy? privacy,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? normalizationConfig,
  }) {
    return Note(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      docVersionId: docVersionId ?? this.docVersionId,
      logicalPath: logicalPath ?? this.logicalPath,
      charStart: charStart ?? this.charStart,
      charEnd: charEnd ?? this.charEnd,
      selectedTextNormalized:
          selectedTextNormalized ?? this.selectedTextNormalized,
      textHash: textHash ?? this.textHash,
      contextBefore: contextBefore ?? this.contextBefore,
      contextAfter: contextAfter ?? this.contextAfter,
      contextBeforeHash: contextBeforeHash ?? this.contextBeforeHash,
      contextAfterHash: contextAfterHash ?? this.contextAfterHash,
      rollingBefore: rollingBefore ?? this.rollingBefore,
      rollingAfter: rollingAfter ?? this.rollingAfter,
      status: status ?? this.status,
      contentMarkdown: contentMarkdown ?? this.contentMarkdown,
      authorUserId: authorUserId ?? this.authorUserId,
      privacy: privacy ?? this.privacy,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      normalizationConfig: normalizationConfig ?? this.normalizationConfig,
    );
  }

  /// Converts the note to a JSON map for storage
  Map<String, dynamic> toJson() {
    return {
      'note_id': id,
      'book_id': bookId,
      'doc_version_id': docVersionId,
      'logical_path': logicalPath?.join(','),
      'char_start': charStart,
      'char_end': charEnd,
      'selected_text_normalized': selectedTextNormalized,
      'text_hash': textHash,
      'ctx_before': contextBefore,
      'ctx_after': contextAfter,
      'ctx_before_hash': contextBeforeHash,
      'ctx_after_hash': contextAfterHash,
      'rolling_before': rollingBefore,
      'rolling_after': rollingAfter,
      'status': status.name,
      'content_markdown': contentMarkdown,
      'author_user_id': authorUserId,
      'privacy': privacy.name,
      'tags': tags.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'normalization_config': normalizationConfig,
    };
  }

  /// Creates a note from a JSON map
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['note_id'] as String,
      bookId: json['book_id'] as String,
      docVersionId: json['doc_version_id'] as String,
      logicalPath: json['logical_path'] != null
          ? (json['logical_path'] as String).split(',')
          : null,
      charStart: json['char_start'] as int,
      charEnd: json['char_end'] as int,
      selectedTextNormalized: json['selected_text_normalized'] as String,
      textHash: json['text_hash'] as String,
      contextBefore: json['ctx_before'] as String,
      contextAfter: json['ctx_after'] as String,
      contextBeforeHash: json['ctx_before_hash'] as String,
      contextAfterHash: json['ctx_after_hash'] as String,
      rollingBefore: json['rolling_before'] as int,
      rollingAfter: json['rolling_after'] as int,
      status: NoteStatus.values.byName(json['status'] as String),
      contentMarkdown: json['content_markdown'] as String,
      authorUserId: json['author_user_id'] as String,
      privacy: NotePrivacy.values.byName(json['privacy'] as String),
      tags: json['tags'] != null
          ? (json['tags'] as String)
              .split(',')
              .where((t) => t.isNotEmpty)
              .toList()
          : <String>[],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      normalizationConfig: json['normalization_config'] as String,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookId,
        docVersionId,
        logicalPath,
        charStart,
        charEnd,
        selectedTextNormalized,
        textHash,
        contextBefore,
        contextAfter,
        contextBeforeHash,
        contextAfterHash,
        rollingBefore,
        rollingAfter,
        status,
        contentMarkdown,
        authorUserId,
        privacy,
        tags,
        createdAt,
        updatedAt,
        normalizationConfig,
      ];

  @override
  String toString() {
    return 'Note(id: $id, bookId: $bookId, status: $status, content: ${contentMarkdown.length} chars)';
  }
}
