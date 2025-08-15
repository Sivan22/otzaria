import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:otzaria/notes/bloc/notes_bloc.dart';
import 'package:otzaria/notes/bloc/notes_event.dart';
import 'package:otzaria/notes/bloc/notes_state.dart';
import 'package:otzaria/notes/models/note.dart';
import 'package:otzaria/notes/models/anchor_models.dart';
import 'package:otzaria/notes/repository/notes_repository.dart';

void main() {
  setUpAll(() {
    // Initialize SQLite FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('NotesBloc Tests', () {
    late NotesBloc notesBloc;

    setUp(() {
      notesBloc = NotesBloc();
    });

    tearDown(() {
      notesBloc.close();
    });

    test('initial state is NotesInitial', () {
      expect(notesBloc.state, equals(const NotesInitial()));
    });

    group('LoadNotesEvent', () {
      blocTest<NotesBloc, NotesState>(
        'emits NotesLoading when loading notes',
        build: () => notesBloc,
        act: (bloc) => bloc.add(const LoadNotesEvent('test-book')),
        expect: () => [
          const NotesLoading(message: 'טוען הערות...'),
        ],
        wait: const Duration(milliseconds: 50),
      );
    });

    group('CreateNoteEvent', () {
      blocTest<NotesBloc, NotesState>(
        'emits NoteOperationInProgress when creating note',
        build: () => notesBloc,
        act: (bloc) => bloc.add(CreateNoteEvent(_createTestNoteRequest())),
        expect: () => [
          const NoteOperationInProgress(operation: 'יוצר הערה...'),
          isA<NotesError>(), // Expected to fail without proper setup
        ],
        wait: const Duration(milliseconds: 100),
      );
    });

    group('SearchNotesEvent', () {
      blocTest<NotesBloc, NotesState>(
        'emits NotesLoading when searching',
        build: () => notesBloc,
        act: (bloc) => bloc.add(const SearchNotesEvent('test query')),
        expect: () => [
          const NotesLoading(message: 'מחפש הערות...'),
          isA<NotesSearchResults>(), // Should return empty results
        ],
        wait: const Duration(milliseconds: 100),
      );

      blocTest<NotesBloc, NotesState>(
        'emits empty results for empty query',
        build: () => notesBloc,
        act: (bloc) => bloc.add(const SearchNotesEvent('')),
        expect: () => [
          isA<NotesSearchResults>(),
        ],
        verify: (bloc) {
          final state = bloc.state as NotesSearchResults;
          expect(state.query, equals(''));
          expect(state.results, isEmpty);
        },
      );
    });

    group('ToggleHighlightingEvent', () {
      blocTest<NotesBloc, NotesState>(
        'updates highlighting when in NotesLoaded state',
        build: () => notesBloc,
        seed: () => NotesLoaded(
          bookId: 'test-book',
          notes: const [],
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) => bloc.add(const ToggleHighlightingEvent(false)),
        expect: () => [
          isA<NotesLoaded>(),
        ],
        verify: (bloc) {
          final state = bloc.state as NotesLoaded;
          expect(state.highlightingEnabled, isFalse);
        },
      );
    });

    group('SelectNoteEvent', () {
      final testNote = _createTestNote();
      
      blocTest<NotesBloc, NotesState>(
        'selects note when in NotesLoaded state',
        build: () => notesBloc,
        seed: () => NotesLoaded(
          bookId: 'test-book',
          notes: [testNote],
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) => bloc.add(SelectNoteEvent(testNote.id)),
        expect: () => [
          isA<NotesLoaded>(),
        ],
        verify: (bloc) {
          final state = bloc.state as NotesLoaded;
          expect(state.selectedNote?.id, equals(testNote.id));
        },
      );
    });

    group('UpdateVisibleRangeEvent', () {
      const testRange = VisibleCharRange(100, 200);
      
      blocTest<NotesBloc, NotesState>(
        'updates visible range when in NotesLoaded state',
        build: () => notesBloc,
        seed: () => NotesLoaded(
          bookId: 'test-book',
          notes: const [],
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) => bloc.add(const UpdateVisibleRangeEvent('test-book', testRange)),
        expect: () => [
          isA<NotesLoaded>(),
        ],
        verify: (bloc) {
          final state = bloc.state as NotesLoaded;
          expect(state.visibleRange, equals(testRange));
        },
      );
    });

    group('CancelOperationsEvent', () {
      blocTest<NotesBloc, NotesState>(
        'cancels operations and returns to initial state',
        build: () => notesBloc,
        act: (bloc) => bloc.add(const CancelOperationsEvent()),
        expect: () => [
          const NotesInitial(),
        ],
      );
    });
  });

  group('NotesLoaded State Tests', () {
    late NotesLoaded state;
    late List<Note> testNotes;

    setUp(() {
      testNotes = [
        _createTestNote(id: '1', status: NoteStatus.anchored, charStart: 50, charEnd: 100),
        _createTestNote(id: '2', status: NoteStatus.shifted, charStart: 150, charEnd: 200),
        _createTestNote(id: '3', status: NoteStatus.orphan, charStart: 250, charEnd: 300),
      ];
      
      state = NotesLoaded(
        bookId: 'test-book',
        notes: testNotes,
        visibleRange: const VisibleCharRange(75, 175),
        lastUpdated: DateTime.now(),
      );
    });

    test('should return visible notes correctly', () {
      final visibleNotes = state.visibleNotes;
      expect(visibleNotes.length, equals(2)); // Notes 1 and 2 should be visible
      expect(visibleNotes.map((n) => n.id), containsAll(['1', '2']));
    });

    test('should count notes by status correctly', () {
      expect(state.anchoredCount, equals(1));
      expect(state.shiftedCount, equals(1));
      expect(state.orphanCount, equals(1));
    });

    test('should get notes by status correctly', () {
      final anchoredNotes = state.getNotesByStatus(NoteStatus.anchored);
      expect(anchoredNotes.length, equals(1));
      expect(anchoredNotes.first.id, equals('1'));
    });

    test('copyWith should update specified fields only', () {
      final updatedState = state.copyWith(
        highlightingEnabled: false,
        selectedNote: testNotes.first,
      );
      
      expect(updatedState.highlightingEnabled, isFalse);
      expect(updatedState.selectedNote, equals(testNotes.first));
      expect(updatedState.bookId, equals(state.bookId)); // unchanged
      expect(updatedState.notes, equals(state.notes)); // unchanged
    });
  });
}

/// Helper function to create a test note request
CreateNoteRequest _createTestNoteRequest() {
  return const CreateNoteRequest(
    bookId: 'test-book',
    charStart: 100,
    charEnd: 150,
    contentMarkdown: 'Test note content',
    authorUserId: 'test-user',
    privacy: NotePrivacy.private,
    tags: ['test'],
  );
}

/// Helper function to create a test note
Note _createTestNote({
  String? id,
  NoteStatus? status,
  int? charStart,
  int? charEnd,
}) {
  return Note(
    id: id ?? 'test-note-1',
    bookId: 'test-book',
    docVersionId: 'version-1',
    charStart: charStart ?? 100,
    charEnd: charEnd ?? 150,
    selectedTextNormalized: 'test text',
    textHash: 'hash123',
    contextBefore: 'before',
    contextAfter: 'after',
    contextBeforeHash: 'before-hash',
    contextAfterHash: 'after-hash',
    rollingBefore: 12345,
    rollingAfter: 67890,
    status: status ?? NoteStatus.anchored,
    contentMarkdown: 'Test note content',
    authorUserId: 'test-user',
    privacy: NotePrivacy.private,
    tags: const ['test'],
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    normalizationConfig: 'norm=v1;nikud=keep;quotes=ascii;unicode=NFKC',
  );
}