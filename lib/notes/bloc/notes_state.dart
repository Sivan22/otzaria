import 'package:equatable/equatable.dart';
import '../models/note.dart';
import '../models/anchor_models.dart';
import '../repository/notes_repository.dart';

/// Base class for all notes states.
/// 
/// States represent the current condition of the notes system at any point
/// in time. The UI rebuilds reactively when states change, providing a
/// unidirectional data flow from events to states to UI updates.
/// 
/// ## State Categories
/// 
/// ### Loading States
/// - `NotesInitial`: Starting state before any operations
/// - `NotesLoading`: Data is being fetched or processed
/// - `NotesUpdating`: Existing data is being modified
/// 
/// ### Success States
/// - `NotesLoaded`: Notes successfully loaded and ready for display
/// - `NotesSearchResults`: Search completed with results
/// - `NoteCreated`: New note successfully created
/// - `NoteUpdated`: Existing note successfully updated
/// 
/// ### Error States
/// - `NotesError`: General error with user-friendly message
/// - `NotesValidationError`: Input validation failed
/// - `NotesNetworkError`: Network/database connectivity issues
/// 
/// ### Specialized States
/// - `OrphansFound`: Orphan notes detected and ready for resolution
/// - `CandidatesFound`: Anchor candidates found for orphan resolution
/// - `ReanchoringComplete`: Batch re-anchoring operation finished
/// 
/// ## State Design Principles
/// 
/// - **Immutable**: States cannot be modified after creation
/// - **Complete**: States contain all data needed by the UI
/// - **Efficient**: States use efficient data structures and avoid duplication
/// - **Debuggable**: States provide clear information for debugging
/// 
/// ## Usage
/// 
/// ```dart
/// // Listen to state changes
/// BlocBuilder<NotesBloc, NotesState>(
///   builder: (context, state) {
///     return switch (state) {
///       NotesInitial() => InitialWidget(),
///       NotesLoading() => LoadingWidget(),
///       NotesLoaded() => NotesListWidget(notes: state.notes),
///       NotesError() => ErrorWidget(message: state.message),
///     };
///   },
/// )
/// ```
/// 
/// ## Performance Considerations
/// 
/// - States are compared by value for efficient rebuilds
/// - Large data sets use lazy loading and pagination
/// - Immutable collections prevent accidental mutations
/// - Memory usage is monitored and optimized
abstract class NotesState extends Equatable {
  const NotesState();

  @override
  List<Object?> get props => [];
}

/// Initial state when BLoC is first created
class NotesInitial extends NotesState {
  const NotesInitial();
}

/// State when notes are being loaded
class NotesLoading extends NotesState {
  final String? message;

  const NotesLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// State when notes have been successfully loaded
class NotesLoaded extends NotesState {
  final String bookId;
  final List<Note> notes;
  final VisibleCharRange? visibleRange;
  final Note? selectedNote;
  final bool highlightingEnabled;
  final DateTime lastUpdated;

  const NotesLoaded({
    required this.bookId,
    required this.notes,
    this.visibleRange,
    this.selectedNote,
    this.highlightingEnabled = true,
    required this.lastUpdated,
  });

  /// Create a copy with updated fields
  NotesLoaded copyWith({
    String? bookId,
    List<Note>? notes,
    VisibleCharRange? visibleRange,
    Note? selectedNote,
    bool? highlightingEnabled,
    DateTime? lastUpdated,
  }) {
    return NotesLoaded(
      bookId: bookId ?? this.bookId,
      notes: notes ?? this.notes,
      visibleRange: visibleRange ?? this.visibleRange,
      selectedNote: selectedNote ?? this.selectedNote,
      highlightingEnabled: highlightingEnabled ?? this.highlightingEnabled,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Get notes that are visible in the current range
  List<Note> get visibleNotes {
    if (visibleRange == null) return notes;
    
    return notes.where((note) {
      return visibleRange!.contains(note.charStart) || 
             visibleRange!.contains(note.charEnd) ||
             (note.charStart <= visibleRange!.start && note.charEnd >= visibleRange!.end);
    }).toList();
  }

  /// Get notes by status
  List<Note> getNotesByStatus(NoteStatus status) {
    return notes.where((note) => note.status == status).toList();
  }

  /// Get anchored notes count
  int get anchoredCount => getNotesByStatus(NoteStatus.anchored).length;

  /// Get shifted notes count
  int get shiftedCount => getNotesByStatus(NoteStatus.shifted).length;

  /// Get orphan notes count
  int get orphanCount => getNotesByStatus(NoteStatus.orphan).length;

  @override
  List<Object?> get props => [
        bookId,
        notes,
        visibleRange,
        selectedNote,
        highlightingEnabled,
        lastUpdated,
      ];
}

/// State when a note operation is in progress
class NoteOperationInProgress extends NotesState {
  final String operation;
  final String? noteId;
  final double? progress;

  const NoteOperationInProgress({
    required this.operation,
    this.noteId,
    this.progress,
  });

  @override
  List<Object?> get props => [operation, noteId, progress];
}

/// State when a note has been successfully created
class NoteCreated extends NotesState {
  final Note note;

  const NoteCreated(this.note);

  @override
  List<Object?> get props => [note];
}

/// State when a note has been successfully updated
class NoteUpdated extends NotesState {
  final Note note;

  const NoteUpdated(this.note);

  @override
  List<Object?> get props => [note];
}

/// State when a note has been successfully deleted
class NoteDeleted extends NotesState {
  final String noteId;

  const NoteDeleted(this.noteId);

  @override
  List<Object?> get props => [noteId];
}

/// State when search results are available
class NotesSearchResults extends NotesState {
  final String query;
  final List<Note> results;
  final String? bookId;

  const NotesSearchResults({
    required this.query,
    required this.results,
    this.bookId,
  });

  @override
  List<Object?> get props => [query, results, bookId];
}

/// State when orphan notes are loaded
class OrphansLoaded extends NotesState {
  final List<Note> orphanNotes;
  final String? bookId;

  const OrphansLoaded({
    required this.orphanNotes,
    this.bookId,
  });

  @override
  List<Object?> get props => [orphanNotes, bookId];
}

/// State when anchor candidates are found for an orphan note
class CandidatesFound extends NotesState {
  final String noteId;
  final List<AnchorCandidate> candidates;

  const CandidatesFound({
    required this.noteId,
    required this.candidates,
  });

  @override
  List<Object?> get props => [noteId, candidates];
}

/// State when an orphan note has been resolved
class OrphanResolved extends NotesState {
  final Note resolvedNote;

  const OrphanResolved(this.resolvedNote);

  @override
  List<Object?> get props => [resolvedNote];
}

/// State when re-anchoring is in progress
class ReanchoringInProgress extends NotesState {
  final String bookId;
  final int totalNotes;
  final int processedNotes;

  const ReanchoringInProgress({
    required this.bookId,
    required this.totalNotes,
    required this.processedNotes,
  });

  double get progress => totalNotes > 0 ? processedNotes / totalNotes : 0.0;

  @override
  List<Object?> get props => [bookId, totalNotes, processedNotes];
}

/// State when re-anchoring is completed
class ReanchoringCompleted extends NotesState {
  final ReanchoringResult result;

  const ReanchoringCompleted(this.result);

  @override
  List<Object?> get props => [result];
}

/// State when notes export is completed
class NotesExported extends NotesState {
  final String exportData;
  final ExportOptions options;

  const NotesExported({
    required this.exportData,
    required this.options,
  });

  @override
  List<Object?> get props => [exportData, options];
}

/// State when notes import is completed
class NotesImported extends NotesState {
  final ImportResult result;

  const NotesImported(this.result);

  @override
  List<Object?> get props => [result];
}

/// State when an error occurs
class NotesError extends NotesState {
  final String message;
  final String? operation;
  final dynamic error;

  const NotesError({
    required this.message,
    this.operation,
    this.error,
  });

  @override
  List<Object?> get props => [message, operation, error];
}

/// State when multiple operations are running
class NotesMultipleOperations extends NotesState {
  final List<String> operations;
  final Map<String, double> progress;

  const NotesMultipleOperations({
    required this.operations,
    required this.progress,
  });

  @override
  List<Object?> get props => [operations, progress];
}

/// State when search results are loaded (alias for compatibility)
class SearchResultsLoaded extends NotesSearchResults {
  const SearchResultsLoaded({
    required super.query,
    required super.results,
    super.bookId,
  });
}