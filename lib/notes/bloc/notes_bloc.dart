import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/notes_repository.dart';
import '../services/anchoring_service.dart';
import '../services/canonical_text_service.dart';
import '../services/background_processor.dart';
import '../config/notes_config.dart';
import 'notes_event.dart';
import 'notes_state.dart';

/// BLoC for managing notes state and coordinating business logic.
/// 
/// This is the central state management component for the notes system.
/// It coordinates between the UI layer and the service layer, handling
/// all user interactions and maintaining the current state of notes.
/// 
/// ## Responsibilities
/// 
/// - **State Management**: Maintain current notes state and emit updates
/// - **Event Handling**: Process user actions and system events
/// - **Service Coordination**: Orchestrate calls to multiple services
/// - **Error Handling**: Provide user-friendly error states and recovery
/// - **Performance**: Optimize operations and prevent UI blocking
/// 
/// ## Event Processing
/// 
/// The BLoC handles various types of events:
/// 
/// ### Loading Events
/// - `LoadNotesEvent`: Load all notes for a book
/// - `LoadNotesForRangeEvent`: Load notes for visible text range
/// - `RefreshNotesEvent`: Refresh notes from database
/// 
/// ### CRUD Events
/// - `CreateNoteEvent`: Create new note from text selection
/// - `UpdateNoteEvent`: Update existing note content/metadata
/// - `DeleteNoteEvent`: Delete note and clean up anchoring data
/// 
/// ### Search Events
/// - `SearchNotesEvent`: Search notes with query string
/// - `FilterNotesEvent`: Filter notes by status, tags, etc.
/// 
/// ### Anchoring Events
/// - `ReanchorNotesEvent`: Re-anchor notes after text changes
/// - `ResolveOrphanEvent`: Resolve orphan note with user selection
/// - `FindCandidatesEvent`: Find anchor candidates for orphan
/// 
/// ## State Transitions
/// 
/// ```
/// NotesInitial → NotesLoading → NotesLoaded
///                            ↘ NotesError
/// 
/// NotesLoaded → NotesUpdating → NotesLoaded
///            ↘ NotesSearching → NotesSearchResults
///            ↘ NotesReanchoring → NotesLoaded
/// ```
/// 
/// ## Performance Optimizations
/// 
/// - **Range Loading**: Only load notes for visible text areas
/// - **Background Processing**: Heavy operations run in isolates
/// - **Debouncing**: Prevent rapid-fire events from overwhelming system
/// - **Caching**: Maintain in-memory cache of frequently accessed notes
/// 
/// ## Usage
/// 
/// ```dart
/// // In widget
/// BlocProvider<NotesBloc>(
///   create: (context) => NotesBloc(),
///   child: MyNotesWidget(),
/// )
/// 
/// // Trigger events
/// context.read<NotesBloc>().add(LoadNotesEvent('book-id'));
/// 
/// // Listen to state
/// BlocBuilder<NotesBloc, NotesState>(
///   builder: (context, state) {
///     if (state is NotesLoaded) {
///       return NotesListWidget(notes: state.notes);
///     }
///     return LoadingWidget();
///   },
/// )
/// ```
/// 
/// ## Error Handling
/// 
/// The BLoC provides comprehensive error handling:
/// - Network/database errors are caught and converted to user-friendly messages
/// - Partial failures (some notes load, others fail) are handled gracefully
/// - Recovery actions are suggested when possible
/// - Telemetry is collected for debugging and monitoring
class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final NotesRepository _repository = NotesRepository.instance;
  final AnchoringService _anchoringService = AnchoringService.instance;
  final CanonicalTextService _canonicalService = CanonicalTextService.instance;
  final BackgroundProcessor _backgroundProcessor = BackgroundProcessor.instance;

  // Keep track of current book and operations
  String? _currentBookId;
  final Set<String> _activeOperations = {};

  NotesBloc() : super(const NotesInitial()) {
    // Register event handlers
    on<LoadNotesEvent>(_onLoadNotes);
    on<LoadNotesForRangeEvent>(_onLoadNotesForRange);
    on<CreateNoteEvent>(_onCreateNote);
    on<UpdateNoteEvent>(_onUpdateNote);
    on<DeleteNoteEvent>(_onDeleteNote);
    on<SearchNotesEvent>(_onSearchNotes);
    on<ClearSearchEvent>(_onClearSearch);
    on<LoadOrphansEvent>(_onLoadOrphans);
    on<FindCandidatesEvent>(_onFindCandidates);
    on<ResolveOrphanEvent>(_onResolveOrphan);
    on<ReanchorNotesEvent>(_onReanchorNotes);
    on<ExportNotesEvent>(_onExportNotes);
    on<ImportNotesEvent>(_onImportNotes);
    on<RefreshNotesEvent>(_onRefreshNotes);
    on<SelectNoteEvent>(_onSelectNote);
    on<ToggleHighlightingEvent>(_onToggleHighlighting);
    on<UpdateVisibleRangeEvent>(_onUpdateVisibleRange);
    on<CancelOperationsEvent>(_onCancelOperations);
    on<EditNoteEvent>(_onEditNote);
  }

  /// Handle loading notes for a book
  Future<void> _onLoadNotes(LoadNotesEvent event, Emitter<NotesState> emit) async {
    try {
      emit(const NotesLoading(message: 'טוען הערות...'));
      
      final notes = await _repository.getNotesForBook(event.bookId);
      _currentBookId = event.bookId;
      
      emit(NotesLoaded(
        bookId: event.bookId,
        notes: notes,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(NotesError(
        message: 'שגיאה בטעינת הערות: ${e.toString()}',
        operation: 'load_notes',
        error: e,
      ));
    }
  }

  /// Handle loading notes for a visible range
  Future<void> _onLoadNotesForRange(LoadNotesForRangeEvent event, Emitter<NotesState> emit) async {
    try {
      if (!NotesConfig.enabled) return;

      final notes = await _repository.getNotesForVisibleRange(event.bookId, event.range);
      _currentBookId = event.bookId;
      
      // If we already have a loaded state, update it
      if (state is NotesLoaded) {
        final currentState = state as NotesLoaded;
        emit(currentState.copyWith(
          bookId: event.bookId,
          notes: notes,
          visibleRange: event.range,
          lastUpdated: DateTime.now(),
        ));
      } else {
        emit(NotesLoaded(
          bookId: event.bookId,
          notes: notes,
          visibleRange: event.range,
          lastUpdated: DateTime.now(),
        ));
      }
    } catch (e) {
      emit(NotesError(
        message: 'שגיאה בטעינת הערות לטווח: ${e.toString()}',
        operation: 'load_notes_range',
        error: e,
      ));
    }
  }

  /// Handle creating a new note
  Future<void> _onCreateNote(CreateNoteEvent event, Emitter<NotesState> emit) async {
    try {
      if (!NotesConfig.enabled) {
        emit(const NotesError(message: 'מערכת ההערות מנוטרלת'));
        return;
      }

      emit(const NoteOperationInProgress(operation: 'יוצר הערה...'));
      
      final note = await _repository.createNote(event.request);
      
      emit(NoteCreated(note));
      
      // Refresh the current notes if we're viewing the same book
      if (_currentBookId == event.request.bookId) {
        add(LoadNotesEvent(event.request.bookId));
      }
    } catch (e) {
      emit(NotesError(
        message: 'שגיאה ביצירת הערה: ${e.toString()}',
        operation: 'create_note',
        error: e,
      ));
    }
  }

  /// Handle updating a note
  Future<void> _onUpdateNote(UpdateNoteEvent event, Emitter<NotesState> emit) async {
    try {
      emit(NoteOperationInProgress(
        operation: 'מעדכן הערה...',
        noteId: event.noteId,
      ));
      
      final note = await _repository.updateNote(event.noteId, event.request);
      
      emit(NoteUpdated(note));
      
      // Refresh current notes if needed
      if (_currentBookId != null) {
        add(LoadNotesEvent(_currentBookId!));
      }
    } catch (e) {
      emit(NotesError(
        message: 'שגיאה בעדכון הערה: ${e.toString()}',
        operation: 'update_note',
        error: e,
      ));
    }
  }

  /// Handle deleting a note
  Future<void> _onDeleteNote(DeleteNoteEvent event, Emitter<NotesState> emit) async {
    try {
      emit(NoteOperationInProgress(
        operation: 'מוחק הערה...',
        noteId: event.noteId,
      ));
      
      await _repository.deleteNote(event.noteId);
      
      emit(NoteDeleted(event.noteId));
      
      // Refresh current notes if needed
      if (_currentBookId != null) {
        add(LoadNotesEvent(_currentBookId!));
      }
    } catch (e) {
      emit(NotesError(
        message: 'שגיאה במחיקת הערה: ${e.toString()}',
        operation: 'delete_note',
        error: e,
      ));
    }
  }

  /// Handle searching notes
  Future<void> _onSearchNotes(SearchNotesEvent event, Emitter<NotesState> emit) async {
    try {
      if (event.query.trim().isEmpty) {
        emit(NotesSearchResults(
          query: event.query,
          results: const [],
          bookId: event.bookId,
        ));
        return;
      }

      emit(const NotesLoading(message: 'מחפש הערות...'));
      
      final results = await _repository.searchNotes(event.query, bookId: event.bookId);
      
      emit(NotesSearchResults(
        query: event.query,
        results: results,
        bookId: event.bookId,
      ));
    } catch (e) {
      emit(NotesError(
        message: 'שגיאה בחיפוש הערות: ${e.toString()}',
        operation: 'search_notes',
        error: e,
      ));
    }
  }

  /// Handle clearing search results
  Future<void> _onClearSearch(ClearSearchEvent event, Emitter<NotesState> emit) async {
    // Return to the previous loaded state if available
    if (_currentBookId != null) {
      add(LoadNotesEvent(_currentBookId!));
    } else {
      emit(const NotesInitial());
    }
  }

  /// Handle loading orphan notes
  Future<void> _onLoadOrphans(LoadOrphansEvent event, Emitter<NotesState> emit) async {
    try {
      emit(const NotesLoading(message: 'טוען הערות יתומות...'));
      
      final orphans = await _repository.getOrphanNotes(bookId: event.bookId);
      
      emit(OrphansLoaded(
        orphanNotes: orphans,
        bookId: event.bookId,
      ));
    } catch (e) {
      emit(NotesError(
        message: 'שגיאה בטעינת הערות יתומות: ${e.toString()}',
        operation: 'load_orphans',
        error: e,
      ));
    }
  }

  /// Handle finding candidates for an orphan note
  Future<void> _onFindCandidates(FindCandidatesEvent event, Emitter<NotesState> emit) async {
    try {
      emit(NoteOperationInProgress(
        operation: 'מחפש מועמדים...',
        noteId: event.noteId,
      ));
      
      final note = await _repository.getNoteById(event.noteId);
      if (note == null) {
        emit(const NotesError(message: 'הערה לא נמצאה'));
        return;
      }
      
      // Create canonical document and find candidates
      final canonicalDoc = await _canonicalService.createCanonicalDocument(note.bookId);
      final result = await _anchoringService.reanchorNote(note, canonicalDoc);
      
      emit(CandidatesFound(
        noteId: event.noteId,
        candidates: result.candidates,
      ));
    } catch (e) {
      emit(NotesError(
        message: 'שגיאה בחיפוש מועמדים: ${e.toString()}',
        operation: 'find_candidates',
        error: e,
      ));
    }
  }

  /// Handle resolving an orphan note
  Future<void> _onResolveOrphan(ResolveOrphanEvent event, Emitter<NotesState> emit) async {
    try {
      emit(NoteOperationInProgress(
        operation: 'פותר הערה יתומה...',
        noteId: event.noteId,
      ));
      
      final resolvedNote = await _repository.resolveOrphanNote(
        event.noteId,
        event.selectedCandidate,
      );
      
      emit(OrphanResolved(resolvedNote));
      
      // Refresh orphans list
      if (state is OrphansLoaded) {
        final orphansState = state as OrphansLoaded;
        add(LoadOrphansEvent(bookId: orphansState.bookId));
      }
    } catch (e) {
      emit(NotesError(
        message: 'שגיאה בפתרון הערה יתומה: ${e.toString()}',
        operation: 'resolve_orphan',
        error: e,
      ));
    }
  }

  /// Handle re-anchoring notes for a book
  Future<void> _onReanchorNotes(ReanchorNotesEvent event, Emitter<NotesState> emit) async {
    try {
      emit(ReanchoringInProgress(
        bookId: event.bookId,
        totalNotes: 0,
        processedNotes: 0,
      ));
      
      final result = await _repository.reanchorNotesForBook(event.bookId);
      
      emit(ReanchoringCompleted(result));
      
      // Refresh notes if we're viewing the same book
      if (_currentBookId == event.bookId) {
        add(LoadNotesEvent(event.bookId));
      }
    } catch (e) {
      emit(NotesError(
        message: 'שגיאה בעיגון מחדש: ${e.toString()}',
        operation: 'reanchor_notes',
        error: e,
      ));
    }
  }

  /// Handle exporting notes
  Future<void> _onExportNotes(ExportNotesEvent event, Emitter<NotesState> emit) async {
    try {
      emit(const NoteOperationInProgress(operation: 'מייצא הערות...'));
      
      final exportData = await _repository.exportNotes(event.options);
      
      emit(NotesExported(
        exportData: exportData,
        options: event.options,
      ));
    } catch (e) {
      emit(NotesError(
        message: 'שגיאה בייצוא הערות: ${e.toString()}',
        operation: 'export_notes',
        error: e,
      ));
    }
  }

  /// Handle importing notes
  Future<void> _onImportNotes(ImportNotesEvent event, Emitter<NotesState> emit) async {
    try {
      emit(const NoteOperationInProgress(operation: 'מייבא הערות...'));
      
      final result = await _repository.importNotes(event.jsonData, event.options);
      
      emit(NotesImported(result));
      
      // Refresh current notes if needed
      if (_currentBookId != null) {
        add(LoadNotesEvent(_currentBookId!));
      }
    } catch (e) {
      emit(NotesError(
        message: 'שגיאה בייבוא הערות: ${e.toString()}',
        operation: 'import_notes',
        error: e,
      ));
    }
  }

  /// Handle refreshing notes
  Future<void> _onRefreshNotes(RefreshNotesEvent event, Emitter<NotesState> emit) async {
    if (_currentBookId != null) {
      add(LoadNotesEvent(_currentBookId!));
    }
  }

  /// Handle selecting a note
  Future<void> _onSelectNote(SelectNoteEvent event, Emitter<NotesState> emit) async {
    if (state is NotesLoaded) {
      final currentState = state as NotesLoaded;
      final selectedNote = event.noteId != null
          ? currentState.notes.firstWhere(
              (note) => note.id == event.noteId,
              orElse: () => currentState.notes.first,
            )
          : null;
      
      emit(currentState.copyWith(selectedNote: selectedNote));
    }
  }

  /// Handle toggling highlighting
  Future<void> _onToggleHighlighting(ToggleHighlightingEvent event, Emitter<NotesState> emit) async {
    if (state is NotesLoaded) {
      final currentState = state as NotesLoaded;
      emit(currentState.copyWith(highlightingEnabled: event.enabled));
    }
  }

  /// Handle updating visible range
  Future<void> _onUpdateVisibleRange(UpdateVisibleRangeEvent event, Emitter<NotesState> emit) async {
    if (state is NotesLoaded) {
      final currentState = state as NotesLoaded;
      if (currentState.bookId == event.bookId) {
        emit(currentState.copyWith(visibleRange: event.range));
      }
    }
  }

  /// Handle canceling operations
  Future<void> _onCancelOperations(CancelOperationsEvent event, Emitter<NotesState> emit) async {
    _backgroundProcessor.cancelAllRequests();
    _activeOperations.clear();
    
    // Return to previous state or initial
    if (_currentBookId != null) {
      add(LoadNotesEvent(_currentBookId!));
    } else {
      emit(const NotesInitial());
    }
  }

  /// Handle editing a note (opens editor dialog)
  Future<void> _onEditNote(EditNoteEvent event, Emitter<NotesState> emit) async {
    // This event is handled by the UI layer to open the editor dialog
    // The actual update will come through UpdateNoteEvent
    // We can emit a state to indicate which note is being edited
    if (state is NotesLoaded) {
      final currentState = state as NotesLoaded;
      emit(currentState.copyWith(selectedNote: event.note));
    }
  }

  @override
  Future<void> close() {
    _backgroundProcessor.cancelAllRequests();
    return super.close();
  }
}