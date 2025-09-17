import 'package:equatable/equatable.dart';
import '../models/note.dart';
import '../models/anchor_models.dart';
import '../repository/notes_repository.dart';

/// Base class for all notes events.
/// 
/// Events represent user actions or system triggers that cause state changes
/// in the notes system. All events extend this base class and implement
/// [Equatable] for efficient comparison and deduplication.
/// 
/// ## Event Categories
/// 
/// ### Loading Events
/// - Load notes for books or specific text ranges
/// - Refresh data from database
/// - Handle cache invalidation
/// 
/// ### CRUD Events  
/// - Create, update, and delete notes
/// - Handle validation and error cases
/// - Manage optimistic updates
/// 
/// ### Search Events
/// - Full-text search across notes
/// - Filter by status, tags, date ranges
/// - Sort and pagination
/// 
/// ### Anchoring Events
/// - Re-anchor notes after text changes
/// - Resolve orphan notes with user input
/// - Find and evaluate anchor candidates
/// 
/// ## Event Design Principles
/// 
/// - **Immutable**: Events cannot be modified after creation
/// - **Serializable**: All data can be converted to/from JSON
/// - **Testable**: Events can be easily created for unit tests
/// - **Traceable**: Events include context for debugging
/// 
/// ## Usage
/// 
/// ```dart
/// // Dispatch events to BLoC
/// bloc.add(LoadNotesEvent('book-id'));
/// bloc.add(CreateNoteEvent(noteRequest));
/// bloc.add(SearchNotesEvent('search query'));
/// ```
abstract class NotesEvent extends Equatable {
  const NotesEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load notes for a specific book
class LoadNotesEvent extends NotesEvent {
  final String bookId;

  const LoadNotesEvent(this.bookId);

  @override
  List<Object?> get props => [bookId];
}

/// Event to load notes for a visible character range
class LoadNotesForRangeEvent extends NotesEvent {
  final String bookId;
  final VisibleCharRange range;

  const LoadNotesForRangeEvent(this.bookId, this.range);

  @override
  List<Object?> get props => [bookId, range];
}

/// Event to create a new note
class CreateNoteEvent extends NotesEvent {
  final CreateNoteRequest request;

  const CreateNoteEvent(this.request);

  @override
  List<Object?> get props => [request];
}

/// Event to update an existing note
class UpdateNoteEvent extends NotesEvent {
  final String noteId;
  final UpdateNoteRequest request;

  const UpdateNoteEvent(this.noteId, this.request);

  @override
  List<Object?> get props => [noteId, request];
}

/// Event to delete a note
class DeleteNoteEvent extends NotesEvent {
  final String noteId;

  const DeleteNoteEvent(this.noteId);

  @override
  List<Object?> get props => [noteId];
}

/// Event to search notes
class SearchNotesEvent extends NotesEvent {
  final String query;
  final String? bookId;

  const SearchNotesEvent(this.query, {this.bookId});

  @override
  List<Object?> get props => [query, bookId];
}

/// Event to clear search results
class ClearSearchEvent extends NotesEvent {
  const ClearSearchEvent();
}

/// Event to load orphan notes
class LoadOrphansEvent extends NotesEvent {
  final String? bookId;

  const LoadOrphansEvent({this.bookId});

  @override
  List<Object?> get props => [bookId];
}

/// Event to find anchor candidates for an orphan note
class FindCandidatesEvent extends NotesEvent {
  final String noteId;

  const FindCandidatesEvent(this.noteId);

  @override
  List<Object?> get props => [noteId];
}

/// Event to resolve an orphan note with a selected candidate
class ResolveOrphanEvent extends NotesEvent {
  final String noteId;
  final AnchorCandidate selectedCandidate;

  const ResolveOrphanEvent(this.noteId, this.selectedCandidate);

  @override
  List<Object?> get props => [noteId, selectedCandidate];
}

/// Event to re-anchor all notes for a book
class ReanchorNotesEvent extends NotesEvent {
  final String bookId;

  const ReanchorNotesEvent(this.bookId);

  @override
  List<Object?> get props => [bookId];
}

/// Event to export notes
class ExportNotesEvent extends NotesEvent {
  final ExportOptions options;

  const ExportNotesEvent(this.options);

  @override
  List<Object?> get props => [options];
}

/// Event to import notes
class ImportNotesEvent extends NotesEvent {
  final String jsonData;
  final ImportOptions options;

  const ImportNotesEvent(this.jsonData, this.options);

  @override
  List<Object?> get props => [jsonData, options];
}

/// Event to refresh notes (reload current state)
class RefreshNotesEvent extends NotesEvent {
  const RefreshNotesEvent();
}

/// Event to select a note for detailed view
class SelectNoteEvent extends NotesEvent {
  final String? noteId;

  const SelectNoteEvent(this.noteId);

  @override
  List<Object?> get props => [noteId];
}

/// Event to toggle note highlighting
class ToggleHighlightingEvent extends NotesEvent {
  final bool enabled;

  const ToggleHighlightingEvent(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Event to update visible range (for performance optimization)
class UpdateVisibleRangeEvent extends NotesEvent {
  final String bookId;
  final VisibleCharRange range;

  const UpdateVisibleRangeEvent(this.bookId, this.range);

  @override
  List<Object?> get props => [bookId, range];
}

/// Event to cancel ongoing operations
class CancelOperationsEvent extends NotesEvent {
  const CancelOperationsEvent();
}

/// Event to edit a note (opens editor dialog)
class EditNoteEvent extends NotesEvent {
  final Note note;

  const EditNoteEvent(this.note);

  @override
  List<Object?> get props => [note];
}

/// Event to find anchor candidates for an orphan note (alias for compatibility)
class FindAnchorCandidatesEvent extends NotesEvent {
  final Note orphanNote;

  const FindAnchorCandidatesEvent(this.orphanNote);

  @override
  List<Object?> get props => [orphanNote];
}