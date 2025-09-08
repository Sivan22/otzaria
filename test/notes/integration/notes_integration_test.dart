import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:otzaria/notes/services/notes_integration_service.dart';
import '../test_helpers/test_setup.dart';
import 'package:otzaria/notes/services/import_export_service.dart';
import 'package:otzaria/notes/services/filesystem_notes_extension.dart';
import 'package:otzaria/notes/models/note.dart';
import 'package:otzaria/notes/models/anchor_models.dart';

void main() {
  setUpAll(() {
    TestSetup.initializeTestEnvironment();
  });

  group('Notes Integration Tests', () {
    late NotesIntegrationService integrationService;
    late ImportExportService importExportService;
    late FileSystemNotesExtension filesystemExtension;

    setUp(() {
      integrationService = NotesIntegrationService.instance;
      importExportService = ImportExportService.instance;
      filesystemExtension = FileSystemNotesExtension.instance;
      
      // Clear caches before each test
      integrationService.clearCache();
      filesystemExtension.clearCanonicalCache();
    });

    group('Notes Integration Service', () {
      test('should load notes for book with empty result', () async {
        const bookId = 'test-book-1';
        const bookText = 'This is a test book with some content for testing.';
        
        final result = await integrationService.loadNotesForBook(bookId, bookText);
        
        expect(result.bookId, equals(bookId));
        expect(result.notes, isEmpty);
        expect(result.fromCache, isFalse);
        expect(result.loadTime.inMilliseconds, greaterThan(0));
      });

      test('should create note from selection', () async {
        const bookId = 'test-book-2';
        const selectedText = 'selected text';
        const noteContent = 'This is a test note';
        
        final note = await integrationService.createNoteFromSelection(
          bookId,
          selectedText,
          10,
          23,
          noteContent,
          tags: ['test', 'integration'],
          privacy: NotePrivacy.private,
        );
        
        expect(note.bookId, equals(bookId));
        expect(note.contentMarkdown, equals(noteContent));
        expect(note.charStart, equals(10));
        expect(note.charEnd, equals(23));
        expect(note.tags, containsAll(['test', 'integration']));
        expect(note.privacy, equals(NotePrivacy.private));
      });

      test('should get notes for visible range', () async {
        const bookId = 'test-book-3';
        
        // Create some test notes
        await integrationService.createNoteFromSelection(
          bookId, 'text1', 10, 15, 'Note 1');
        await integrationService.createNoteFromSelection(
          bookId, 'text2', 50, 55, 'Note 2');
        await integrationService.createNoteFromSelection(
          bookId, 'text3', 100, 105, 'Note 3');
        
        // Test visible range that includes first two notes
        const visibleRange = VisibleCharRange(0, 60);
        final visibleNotes = integrationService.getNotesForVisibleRange(bookId, visibleRange);
        
        expect(visibleNotes.length, equals(2));
        expect(visibleNotes[0].charStart, equals(10));
        expect(visibleNotes[1].charStart, equals(50));
      });

      test('should create highlights for range', () async {
        const bookId = 'test-book-4';
        
        // Create test notes
        await integrationService.createNoteFromSelection(
          bookId, 'text1', 10, 20, 'Note 1');
        await integrationService.createNoteFromSelection(
          bookId, 'text2', 30, 40, 'Note 2');
        
        const visibleRange = VisibleCharRange(5, 45);
        final highlights = integrationService.createHighlightsForRange(bookId, visibleRange);
        
        expect(highlights.length, equals(2));
        expect(highlights[0].start, equals(10));
        expect(highlights[0].end, equals(20));
        expect(highlights[1].start, equals(30));
        expect(highlights[1].end, equals(40));
      });

      test('should update note', () async {
        const bookId = 'test-book-5';
        
        // Create initial note
        final originalNote = await integrationService.createNoteFromSelection(
          bookId, 'original', 10, 18, 'Original content');
        
        // Update the note
        final updatedNote = await integrationService.updateNote(
          originalNote.id,
          'Updated content',
          newTags: ['updated'],
          newPrivacy: NotePrivacy.shared,
        );
        
        expect(updatedNote.id, equals(originalNote.id));
        expect(updatedNote.contentMarkdown, equals('Updated content'));
        expect(updatedNote.tags, contains('updated'));
        expect(updatedNote.privacy, equals(NotePrivacy.shared));
      });

      test('should delete note', () async {
        const bookId = 'test-book-6';
        
        // Create note
        final note = await integrationService.createNoteFromSelection(
          bookId, 'to delete', 10, 19, 'Will be deleted');
        
        // Delete the note
        await integrationService.deleteNote(note.id);
        
        // Verify it's gone from visible range
        const visibleRange = VisibleCharRange(0, 100);
        final visibleNotes = integrationService.getNotesForVisibleRange(bookId, visibleRange);
        
        expect(visibleNotes, isEmpty);
      });

      test('should search notes', () async {
        const bookId = 'test-book-7';
        
        // Create test notes
        await integrationService.createNoteFromSelection(
          bookId, 'apple', 10, 15, 'Note about apples');
        await integrationService.createNoteFromSelection(
          bookId, 'banana', 20, 26, 'Note about bananas');
        await integrationService.createNoteFromSelection(
          bookId, 'cherry', 30, 36, 'Note about cherries');
        
        // Search for notes
        final results = await integrationService.searchNotes('apple', bookId: bookId);
        
        expect(results.length, equals(1));
        expect(results.first.contentMarkdown, contains('apples'));
      });

      test('should handle cache correctly', () async {
        const bookId = 'test-book-8';
        const bookText = 'Test book content for caching';
        
        // First load - should not be from cache
        final result1 = await integrationService.loadNotesForBook(bookId, bookText);
        expect(result1.fromCache, isFalse);
        
        // Second load - should be from cache
        final result2 = await integrationService.loadNotesForBook(bookId, bookText);
        expect(result2.fromCache, isTrue);
        expect(result2.loadTime.inMilliseconds, lessThan(result1.loadTime.inMilliseconds));
        
        // Clear cache and load again - should not be from cache
        integrationService.clearCache(bookId: bookId);
        final result3 = await integrationService.loadNotesForBook(bookId, bookText);
        expect(result3.fromCache, isFalse);
      });

      test('should provide cache statistics', () {
        final stats = integrationService.getCacheStats();
        
        expect(stats.keys, contains('cached_books'));
        expect(stats.keys, contains('total_cached_notes'));
        expect(stats.keys, contains('oldest_cache_age_minutes'));
        expect(stats['cached_books'], isA<int>());
        expect(stats['total_cached_notes'], isA<int>());
      });
    });

    group('Import/Export Service', () {
      test('should export notes to JSON', () async {
        const bookId = 'export-test-book';
        
        // Create test notes
        await integrationService.createNoteFromSelection(
          bookId, 'export1', 10, 17, 'Export note 1', tags: ['export']);
        await integrationService.createNoteFromSelection(
          bookId, 'export2', 20, 27, 'Export note 2', tags: ['export']);
        
        // Export notes
        final result = await importExportService.exportNotes(bookId: bookId);
        
        expect(result.success, isTrue);
        expect(result.notesCount, equals(2));
        expect(result.jsonData, isNotNull);
        expect(result.fileSizeBytes, greaterThan(0));
        
        // Verify JSON structure
        expect(result.jsonData!, contains('"version": "1.0"'));
        expect(result.jsonData!, contains('"notes":'));
        expect(result.jsonData!, contains('Export note 1'));
        expect(result.jsonData!, contains('Export note 2'));
      });

      test('should import notes from JSON', () async {
        // Create test JSON data
        final testJson = '''
        {
          "version": "1.0",
          "exported_at": "2024-01-01T00:00:00.000Z",
          "export_metadata": {
            "book_id": "import-test-book",
            "total_notes": 1,
            "include_orphans": true,
            "include_private": true,
            "app_version": "1.0.0"
          },
          "notes": [
            {
              "id": "import-test-note-1",
              "book_id": "import-test-book",
              "doc_version_id": "version-1",
              "logical_path": null,
              "char_start": 10,
              "char_end": 20,
              "selected_text_normalized": "test text",
              "text_hash": "hash123",
              "context_before": "before",
              "context_after": "after",
              "context_before_hash": "before-hash",
              "context_after_hash": "after-hash",
              "rolling_before": 12345,
              "rolling_after": 67890,
              "status": "anchored",
              "content_markdown": "Imported test note",
              "author_user_id": "test-user",
              "privacy": "private",
              "tags": ["imported", "test"],
              "created_at": "2024-01-01T00:00:00.000Z",
              "updated_at": "2024-01-01T00:00:00.000Z",
              "normalization_config": "norm=v1;nikud=keep;quotes=ascii;unicode=NFKC"
            }
          ]
        }
        ''';
        
        // Import notes
        final result = await importExportService.importNotes(testJson);
        
        expect(result.success, isTrue);
        expect(result.totalNotes, equals(1));
        expect(result.importedCount, equals(1));
        expect(result.skippedCount, equals(0));
        expect(result.errorCount, equals(0));
        expect(result.successRate, equals(100.0));
      });

      test('should handle import errors gracefully', () async {
        // Test with invalid JSON
        final result1 = await importExportService.importNotes('invalid json');
        expect(result1.success, isFalse);
        expect(result1.errorCount, equals(1));
        
        // Test with missing version
        final result2 = await importExportService.importNotes('{"notes": []}');
        expect(result2.success, isFalse);
        expect(result2.errors.first, contains('Missing version field'));
      });

      test('should filter notes during export', () async {
        const bookId = 'filter-test-book';
        
        // Create notes with different statuses and privacy
        await integrationService.createNoteFromSelection(
          bookId, 'private', 10, 17, 'Private note', privacy: NotePrivacy.private);
        await integrationService.createNoteFromSelection(
          bookId, 'public', 20, 26, 'Public note', privacy: NotePrivacy.shared);
        
        // Export without private notes
        final result = await importExportService.exportNotes(
          bookId: bookId,
          includePrivateNotes: false,
        );
        
        expect(result.success, isTrue);
        expect(result.notesCount, equals(1));
        expect(result.jsonData!, contains('Public note'));
        expect(result.jsonData!, isNot(contains('Private note')));
      });
    });

    group('FileSystem Notes Extension', () {
      test('should get canonical document', () async {
        const bookId = 'filesystem-test-book';
        const bookText = 'This is test content for filesystem extension.';
        
        final canonicalDoc = await filesystemExtension.getCanonicalDocument(bookId, bookText);
        
        expect(canonicalDoc.bookId, equals(bookId));
        expect(canonicalDoc.canonicalText, isNotEmpty);
        expect(canonicalDoc.versionId, isNotEmpty);
      });

      test('should detect book content changes', () async {
        const bookId = 'change-test-book';
        const originalText = 'Original book content';
        const modifiedText = 'Modified book content';
        
        // First load
        await filesystemExtension.getCanonicalDocument(bookId, originalText);
        expect(filesystemExtension.hasBookContentChanged(bookId, originalText), isFalse);
        
        // Check with modified content
        expect(filesystemExtension.hasBookContentChanged(bookId, modifiedText), isTrue);
      });

      test('should provide book version info', () async {
        const bookId = 'version-test-book';
        const bookText = 'Book content for version testing';
        
        // Get version info before any canonical document
        final info1 = filesystemExtension.getBookVersionInfo(bookId, bookText);
        expect(info1.isFirstTime, isTrue);
        expect(info1.hasChanged, isFalse);
        
        // Create canonical document
        await filesystemExtension.getCanonicalDocument(bookId, bookText);
        
        // Get version info after canonical document creation
        final info2 = filesystemExtension.getBookVersionInfo(bookId, bookText);
        expect(info2.isFirstTime, isFalse);
        expect(info2.hasChanged, isFalse);
        expect(info2.currentVersion, isNotEmpty);
      });

      test('should cache canonical documents', () async {
        const bookId = 'cache-test-book';
        const bookText = 'Content for cache testing';
        
        // First call - should create new document
        final stopwatch1 = Stopwatch()..start();
        final doc1 = await filesystemExtension.getCanonicalDocument(bookId, bookText);
        stopwatch1.stop();
        
        // Second call - should use cache
        final stopwatch2 = Stopwatch()..start();
        final doc2 = await filesystemExtension.getCanonicalDocument(bookId, bookText);
        stopwatch2.stop();
        
        expect(doc1.versionId, equals(doc2.versionId));
        expect(stopwatch2.elapsedMilliseconds, lessThan(stopwatch1.elapsedMilliseconds));
      });

      test('should provide cache statistics', () {
        final stats = filesystemExtension.getCacheStats();
        
        expect(stats.keys, contains('cached_documents'));
        expect(stats.keys, contains('average_cache_age_minutes'));
        expect(stats.keys, contains('oldest_cache_minutes'));
        expect(stats.keys, contains('cache_memory_estimate_mb'));
        expect(stats['cached_documents'], isA<int>());
      });

      test('should optimize cache', () async {
        // Create multiple cached documents
        for (int i = 0; i < 5; i++) {
          await filesystemExtension.getCanonicalDocument(
            'book-$i', 
            'Content for book $i'
          );
        }
        
        final statsBefore = filesystemExtension.getCacheStats();
        expect(statsBefore['cached_documents'], equals(5));
        
        // Optimize cache
        filesystemExtension.optimizeCache();
        
        final statsAfter = filesystemExtension.getCacheStats();
        expect(statsAfter['cached_documents'], lessThanOrEqualTo(5));
      });

      test('should export and import cache data', () async {
        const bookId = 'export-cache-book';
        const bookText = 'Content for cache export test';
        
        // Create cached document
        await filesystemExtension.getCanonicalDocument(bookId, bookText);
        
        // Export cache data
        final exportData = filesystemExtension.exportCacheData();
        expect(exportData.keys, contains('version'));
        expect(exportData.keys, contains('book_versions'));
        expect(exportData.keys, contains('cache_timestamps'));
        
        // Clear cache
        filesystemExtension.clearCanonicalCache();
        expect(filesystemExtension.getCacheStats()['cached_documents'], equals(0));
        
        // Import cache data
        filesystemExtension.importCacheData(exportData);
        
        // Verify import worked (version should be restored)
        final versionInfo = filesystemExtension.getBookVersionInfo(bookId, bookText);
        expect(versionInfo.cachedVersion, isNotNull);
      });
    });

    group('End-to-End Integration', () {
      test('should handle complete note lifecycle', () async {
        const bookId = 'e2e-test-book';
        const bookText = 'This is a complete end-to-end test book with various content.';
        
        // 1. Load book notes (should be empty initially)
        final initialLoad = await integrationService.loadNotesForBook(bookId, bookText);
        expect(initialLoad.notes, isEmpty);
        
        // 2. Create a note from selection
        final note = await integrationService.createNoteFromSelection(
          bookId,
          'end-to-end test',
          20,
          35,
          'This is an end-to-end test note',
          tags: ['e2e', 'test'],
        );
        expect(note.bookId, equals(bookId));
        
        // 3. Load book notes again (should include the new note)
        final secondLoad = await integrationService.loadNotesForBook(bookId, bookText);
        expect(secondLoad.notes.length, equals(1));
        expect(secondLoad.notes.first.id, equals(note.id));
        
        // 4. Update the note
        final updatedNote = await integrationService.updateNote(
          note.id,
          'Updated end-to-end test note',
          newTags: ['e2e', 'test', 'updated'],
        );
        expect(updatedNote.contentMarkdown, equals('Updated end-to-end test note'));
        expect(updatedNote.tags, contains('updated'));
        
        // 5. Export the note
        final exportResult = await importExportService.exportNotes(bookId: bookId);
        expect(exportResult.success, isTrue);
        expect(exportResult.notesCount, equals(1));
        
        // 6. Delete the note
        await integrationService.deleteNote(note.id);
        
        // 7. Verify note is deleted
        final finalLoad = await integrationService.loadNotesForBook(bookId, bookText);
        expect(finalLoad.notes, isEmpty);
        
        // 8. Import the note back
        final importResult = await importExportService.importNotes(exportResult.jsonData!);
        expect(importResult.success, isTrue);
        expect(importResult.importedCount, equals(1));
        
        // 9. Verify note is back
        final restoredLoad = await integrationService.loadNotesForBook(bookId, bookText);
        expect(restoredLoad.notes.length, equals(1));
        expect(restoredLoad.notes.first.contentMarkdown, equals('Updated end-to-end test note'));
      });

      test('should handle multiple books and cross-book operations', () async {
        const book1Id = 'multi-book-1';
        const book2Id = 'multi-book-2';
        const book1Text = 'Content for first book in multi-book test.';
        const book2Text = 'Content for second book in multi-book test.';
        
        // Create notes in both books
        await integrationService.createNoteFromSelection(
          book1Id, 'book1 note', 10, 20, 'Note in book 1');
        await integrationService.createNoteFromSelection(
          book2Id, 'book2 note', 10, 20, 'Note in book 2');
        
        // Load notes for each book separately
        final book1Notes = await integrationService.loadNotesForBook(book1Id, book1Text);
        final book2Notes = await integrationService.loadNotesForBook(book2Id, book2Text);
        
        expect(book1Notes.notes.length, equals(1));
        expect(book2Notes.notes.length, equals(1));
        expect(book1Notes.notes.first.bookId, equals(book1Id));
        expect(book2Notes.notes.first.bookId, equals(book2Id));
        
        // Search across both books (if supported)
        final searchResults = await integrationService.searchNotes('Note in book');
        expect(searchResults.length, greaterThanOrEqualTo(2));
        
        // Export notes from specific book
        final book1Export = await importExportService.exportNotes(bookId: book1Id);
        expect(book1Export.notesCount, equals(1));
        expect(book1Export.jsonData!, contains('Note in book 1'));
        expect(book1Export.jsonData!, isNot(contains('Note in book 2')));
      });
    });
  });
}