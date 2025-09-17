import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:otzaria/notes/services/notes_integration_service.dart';
import '../test_helpers/test_setup.dart';
import 'package:otzaria/notes/services/import_export_service.dart';
import 'package:otzaria/notes/services/advanced_orphan_manager.dart';
import 'package:otzaria/notes/services/text_normalizer.dart';
import 'package:otzaria/notes/services/fuzzy_matcher.dart';
import 'package:otzaria/notes/models/note.dart';
import 'package:otzaria/notes/models/anchor_models.dart';
import 'package:otzaria/notes/config/notes_config.dart';

void main() {
  setUpAll(() {
    TestSetup.initializeTestEnvironment();
  });

  group('Notes Acceptance Tests', () {
    late NotesIntegrationService integrationService;
    late ImportExportService importExportService;
    late AdvancedOrphanManager orphanManager;

    setUp(() {
      integrationService = NotesIntegrationService.instance;
      importExportService = ImportExportService.instance;
      orphanManager = AdvancedOrphanManager.instance;
      
      // Clear caches
      integrationService.clearCache();
    });

    group('User Story: Creating Notes from Text Selection', () {
      test('As a user, I can select text and create a note', () async {
        // Given: A book with text content
        const bookId = 'user-story-create';
        const bookText = 'זהו טקסט לדוגמה בעברית עם תוכן מעניין לבדיקה.';
        const selectedText = 'טקסט לדוגמה';
        const noteContent = 'זוהי הערה על הטקסט הנבחר';
        
        // When: User selects text and creates a note
        final note = await integrationService.createNoteFromSelection(
          bookId,
          selectedText,
          4, // Position of "טקסט לדוגמה" in the text
          16,
          noteContent,
          tags: ['דוגמה', 'בדיקה'],
          privacy: NotePrivacy.private,
        );
        
        // Then: Note is created successfully with correct properties
        expect(note.id, isNotEmpty);
        expect(note.bookId, equals(bookId));
        expect(note.contentMarkdown, equals(noteContent));
        expect(note.charStart, equals(4));
        expect(note.charEnd, equals(16));
        expect(note.tags, containsAll(['דוגמה', 'בדיקה']));
        expect(note.privacy, equals(NotePrivacy.private));
        expect(note.status, equals(NoteStatus.anchored));
        expect(note.selectedTextNormalized, isNotEmpty);
      });

      test('As a user, I can create notes with Hebrew text and nikud', () async {
        const bookId = 'hebrew-nikud-test';
        const bookText = 'בְּרֵאשִׁית בָּרָא אֱלֹהִים אֵת הַשָּׁמַיִם וְאֵת הָאָרֶץ';
        const selectedText = 'בְּרֵאשִׁית בָּרָא';
        const noteContent = 'הערה על פסוק הפתיחה';
        
        final note = await integrationService.createNoteFromSelection(
          bookId,
          selectedText,
          0,
          13,
          noteContent,
        );
        
        expect(note.selectedTextNormalized, isNotEmpty);
        expect(note.textHash, isNotEmpty);
        expect(note.contextBefore, isEmpty); // At beginning of text
        expect(note.contextAfter, isNotEmpty);
      });

      test('As a user, I can create notes with RTL text and special characters', () async {
        const bookId = 'rtl-special-test';
        const bookText = 'טקסט עם "מירכאות" ו־מקף וסימני פיסוק: כמו נקודה, פסיק!';
        const selectedText = '"מירכאות"';
        const noteContent = 'הערה על מירכאות בעברית';
        
        final note = await integrationService.createNoteFromSelection(
          bookId,
          selectedText,
          10,
          20,
          noteContent,
        );
        
        expect(note.selectedTextNormalized, isNotEmpty);
        expect(note.status, equals(NoteStatus.anchored));
      });
    });

    group('User Story: Viewing and Managing Notes', () {
      test('As a user, I can view all my notes for a book', () async {
        const bookId = 'view-notes-test';
        const bookText = 'ספר לדוגמה עם מספר הערות שונות לבדיקת התצוגה.';
        
        // Create multiple notes
        final note1 = await integrationService.createNoteFromSelection(
          bookId, 'ספר לדוגמה', 0, 11, 'הערה ראשונה');
        final note2 = await integrationService.createNoteFromSelection(
          bookId, 'הערות שונות', 25, 37, 'הערה שנייה');
        final note3 = await integrationService.createNoteFromSelection(
          bookId, 'בדיקת התצוגה', 40, 54, 'הערה שלישית');
        
        // Load notes for the book
        final bookNotes = await integrationService.loadNotesForBook(bookId, bookText);
        
        expect(bookNotes.notes.length, equals(3));
        expect(bookNotes.notes.map((n) => n.id), containsAll([note1.id, note2.id, note3.id]));
        
        // Notes should be sorted by position
        expect(bookNotes.notes[0].charStart, lessThan(bookNotes.notes[1].charStart));
        expect(bookNotes.notes[1].charStart, lessThan(bookNotes.notes[2].charStart));
      });

      test('As a user, I can see notes only in the visible text range', () async {
        const bookId = 'visible-range-test';
        
        // Create notes at different positions
        await integrationService.createNoteFromSelection(
          bookId, 'early', 10, 15, 'Early note');
        await integrationService.createNoteFromSelection(
          bookId, 'middle', 500, 506, 'Middle note');
        await integrationService.createNoteFromSelection(
          bookId, 'late', 1000, 1004, 'Late note');
        
        // Test different visible ranges
        final earlyRange = integrationService.getNotesForVisibleRange(
          bookId, const VisibleCharRange(0, 100));
        final middleRange = integrationService.getNotesForVisibleRange(
          bookId, const VisibleCharRange(400, 600));
        final lateRange = integrationService.getNotesForVisibleRange(
          bookId, const VisibleCharRange(900, 1100));
        
        expect(earlyRange.length, equals(1));
        expect(earlyRange.first.charStart, equals(10));
        
        expect(middleRange.length, equals(1));
        expect(middleRange.first.charStart, equals(500));
        
        expect(lateRange.length, equals(1));
        expect(lateRange.first.charStart, equals(1000));
      });

      test('As a user, I can see visual highlights for my notes', () async {
        const bookId = 'highlights-test';
        
        // Create notes with different statuses
        await integrationService.createNoteFromSelection(
          bookId, 'anchored', 10, 18, 'Anchored note');
        
        // Get highlights for visible range
        const visibleRange = VisibleCharRange(0, 100);
        final highlights = integrationService.createHighlightsForRange(bookId, visibleRange);
        
        expect(highlights.length, equals(1));
        expect(highlights.first.start, equals(10));
        expect(highlights.first.end, equals(18));
        expect(highlights.first.status, equals(NoteStatus.anchored));
        expect(highlights.first.color, isNotNull);
        expect(highlights.first.opacity, greaterThan(0));
      });
    });

    group('User Story: Editing and Updating Notes', () {
      test('As a user, I can edit the content of my notes', () async {
        const bookId = 'edit-content-test';
        
        // Create initial note
        final originalNote = await integrationService.createNoteFromSelection(
          bookId, 'original text', 10, 23, 'Original content');
        
        // Update the note content
        final updatedNote = await integrationService.updateNote(
          originalNote.id,
          'Updated content with more details',
        );
        
        expect(updatedNote.id, equals(originalNote.id));
        expect(updatedNote.contentMarkdown, equals('Updated content with more details'));
        expect(updatedNote.charStart, equals(originalNote.charStart)); // Position unchanged
        expect(updatedNote.charEnd, equals(originalNote.charEnd));
        expect(updatedNote.updatedAt.isAfter(originalNote.updatedAt), isTrue);
      });

      test('As a user, I can add and modify tags on my notes', () async {
        const bookId = 'edit-tags-test';
        
        // Create note with initial tags
        final note = await integrationService.createNoteFromSelection(
          bookId, 'tagged text', 5, 16, 'Note with tags',
          tags: ['initial', 'test']);
        
        // Update tags
        final updatedNote = await integrationService.updateNote(
          note.id,
          null, // Don't change content
          newTags: ['updated', 'modified', 'test'], // Keep 'test', add new ones
        );
        
        expect(updatedNote.tags, containsAll(['updated', 'modified', 'test']));
        expect(updatedNote.tags, isNot(contains('initial')));
      });

      test('As a user, I can change the privacy level of my notes', () async {
        const bookId = 'privacy-test';
        
        // Create private note
        final privateNote = await integrationService.createNoteFromSelection(
          bookId, 'private text', 0, 12, 'Private note',
          privacy: NotePrivacy.private);
        
        expect(privateNote.privacy, equals(NotePrivacy.private));
        
        // Change to public
        final publicNote = await integrationService.updateNote(
          privateNote.id,
          null,
          newPrivacy: NotePrivacy.shared,
        );
        
        expect(publicNote.privacy, equals(NotePrivacy.shared));
        expect(publicNote.id, equals(privateNote.id));
      });
    });

    group('User Story: Searching Notes', () {
      test('As a user, I can search for notes by content', () async {
        const bookId = 'search-content-test';
        
        // Create notes with different content
        await integrationService.createNoteFromSelection(
          bookId, 'apple', 10, 15, 'Note about apples and fruit');
        await integrationService.createNoteFromSelection(
          bookId, 'banana', 20, 26, 'Note about bananas');
        await integrationService.createNoteFromSelection(
          bookId, 'cherry', 30, 36, 'Note about cherries and trees');
        
        // Search for specific terms
        final appleResults = await integrationService.searchNotes('apple', bookId: bookId);
        final fruitResults = await integrationService.searchNotes('fruit', bookId: bookId);
        final treeResults = await integrationService.searchNotes('tree', bookId: bookId);
        
        expect(appleResults.length, equals(1));
        expect(appleResults.first.contentMarkdown, contains('apples'));
        
        expect(fruitResults.length, equals(1));
        expect(fruitResults.first.contentMarkdown, contains('fruit'));
        
        expect(treeResults.length, equals(1));
        expect(treeResults.first.contentMarkdown, contains('trees'));
      });

      test('As a user, I can search for notes in Hebrew', () async {
        const bookId = 'search-hebrew-test';
        
        // Create Hebrew notes
        await integrationService.createNoteFromSelection(
          bookId, 'תפוח', 0, 4, 'הערה על תפוחים ופירות');
        await integrationService.createNoteFromSelection(
          bookId, 'בננה', 10, 14, 'הערה על בננות');
        await integrationService.createNoteFromSelection(
          bookId, 'דובדבן', 20, 26, 'הערה על דובדבנים ועצים');
        
        // Search in Hebrew
        final appleResults = await integrationService.searchNotes('תפוח', bookId: bookId);
        final fruitResults = await integrationService.searchNotes('פירות', bookId: bookId);
        
        expect(appleResults.length, equals(1));
        expect(appleResults.first.contentMarkdown, contains('תפוחים'));
        
        expect(fruitResults.length, equals(1));
        expect(fruitResults.first.contentMarkdown, contains('פירות'));
      });

      test('As a user, I can search across multiple books', () async {
        const book1Id = 'search-multi-book1';
        const book2Id = 'search-multi-book2';
        
        // Create notes in different books
        await integrationService.createNoteFromSelection(
          book1Id, 'common term', 0, 11, 'Note in book 1 with common term');
        await integrationService.createNoteFromSelection(
          book2Id, 'common term', 0, 11, 'Note in book 2 with common term');
        await integrationService.createNoteFromSelection(
          book1Id, 'unique term', 20, 31, 'Note with unique term');
        
        // Search across all books
        final commonResults = await integrationService.searchNotes('common term');
        final uniqueResults = await integrationService.searchNotes('unique term');
        
        expect(commonResults.length, equals(2));
        expect(commonResults.map((n) => n.bookId), containsAll([book1Id, book2Id]));
        
        expect(uniqueResults.length, equals(1));
        expect(uniqueResults.first.bookId, equals(book1Id));
      });
    });

    group('User Story: Deleting Notes', () {
      test('As a user, I can delete notes I no longer need', () async {
        const bookId = 'delete-test';
        const bookText = 'Text for deletion testing.';
        
        // Create note
        final note = await integrationService.createNoteFromSelection(
          bookId, 'to delete', 5, 14, 'This note will be deleted');
        
        // Verify note exists
        final beforeDelete = await integrationService.loadNotesForBook(bookId, bookText);
        expect(beforeDelete.notes.length, equals(1));
        expect(beforeDelete.notes.first.id, equals(note.id));
        
        // Delete note
        await integrationService.deleteNote(note.id);
        
        // Verify note is gone
        final afterDelete = await integrationService.loadNotesForBook(bookId, bookText);
        expect(afterDelete.notes, isEmpty);
        
        // Verify note is not in search results
        final searchResults = await integrationService.searchNotes('deleted', bookId: bookId);
        expect(searchResults, isEmpty);
      });

      test('As a user, deleting a note removes it from all views', () async {
        const bookId = 'delete-views-test';
        
        // Create multiple notes
        final note1 = await integrationService.createNoteFromSelection(
          bookId, 'keep this', 0, 9, 'Note to keep');
        final note2 = await integrationService.createNoteFromSelection(
          bookId, 'delete this', 20, 31, 'Note to delete');
        final note3 = await integrationService.createNoteFromSelection(
          bookId, 'keep this too', 40, 52, 'Another note to keep');
        
        // Delete middle note
        await integrationService.deleteNote(note2.id);
        
        // Check visible range
        final visibleNotes = integrationService.getNotesForVisibleRange(
          bookId, const VisibleCharRange(0, 100));
        expect(visibleNotes.length, equals(2));
        expect(visibleNotes.map((n) => n.id), containsAll([note1.id, note3.id]));
        expect(visibleNotes.map((n) => n.id), isNot(contains(note2.id)));
        
        // Check highlights
        final highlights = integrationService.createHighlightsForRange(
          bookId, const VisibleCharRange(0, 100));
        expect(highlights.length, equals(2));
        expect(highlights.map((h) => h.noteId), containsAll([note1.id, note3.id]));
        expect(highlights.map((h) => h.noteId), isNot(contains(note2.id)));
      });
    });

    group('User Story: Import and Export Notes', () {
      test('As a user, I can export my notes to backup them', () async {
        const bookId = 'export-backup-test';
        
        // Create notes to export
        await integrationService.createNoteFromSelection(
          bookId, 'export1', 0, 7, 'First note for export',
          tags: ['export', 'backup']);
        await integrationService.createNoteFromSelection(
          bookId, 'export2', 10, 17, 'Second note for export',
          tags: ['export', 'test']);
        
        // Export notes
        final exportResult = await importExportService.exportNotes(bookId: bookId);
        
        expect(exportResult.success, isTrue);
        expect(exportResult.notesCount, equals(2));
        expect(exportResult.jsonData, isNotNull);
        expect(exportResult.fileSizeBytes, greaterThan(0));
        
        // Verify export contains expected data
        expect(exportResult.jsonData!, contains('First note for export'));
        expect(exportResult.jsonData!, contains('Second note for export'));
        expect(exportResult.jsonData!, contains('"tags": ["export", "backup"]'));
        expect(exportResult.jsonData!, contains('"version": "1.0"'));
      });

      test('As a user, I can import notes from a backup', () async {
        const originalBookId = 'import-original';
        const targetBookId = 'import-target';
        
        // Create and export notes
        await integrationService.createNoteFromSelection(
          originalBookId, 'import test', 0, 11, 'Note for import test',
          tags: ['import', 'test']);
        
        final exportResult = await importExportService.exportNotes(bookId: originalBookId);
        expect(exportResult.success, isTrue);
        
        // Import to different book
        final importResult = await importExportService.importNotes(
          exportResult.jsonData!,
          targetBookId: targetBookId,
        );
        
        expect(importResult.success, isTrue);
        expect(importResult.totalNotes, equals(1));
        expect(importResult.importedCount, equals(1));
        expect(importResult.successRate, equals(100.0));
        
        // Verify imported note
        const targetBookText = 'Target book text for import test.';
        final targetNotes = await integrationService.loadNotesForBook(targetBookId, targetBookText);
        expect(targetNotes.notes.length, equals(1));
        expect(targetNotes.notes.first.bookId, equals(targetBookId));
        expect(targetNotes.notes.first.contentMarkdown, equals('Note for import test'));
        expect(targetNotes.notes.first.tags, containsAll(['import', 'test']));
      });

      test('As a user, I can choose what to include in exports', () async {
        const bookId = 'selective-export-test';
        
        // Create notes with different privacy levels
        await integrationService.createNoteFromSelection(
          bookId, 'public note', 0, 11, 'This is public',
          privacy: NotePrivacy.shared);
        await integrationService.createNoteFromSelection(
          bookId, 'private note', 20, 32, 'This is private',
          privacy: NotePrivacy.private);
        
        // Export only public notes
        final publicOnlyExport = await importExportService.exportNotes(
          bookId: bookId,
          includePrivateNotes: false,
        );
        
        expect(publicOnlyExport.success, isTrue);
        expect(publicOnlyExport.notesCount, equals(1));
        expect(publicOnlyExport.jsonData!, contains('This is public'));
        expect(publicOnlyExport.jsonData!, isNot(contains('This is private')));
        
        // Export all notes
        final allNotesExport = await importExportService.exportNotes(
          bookId: bookId,
          includePrivateNotes: true,
        );
        
        expect(allNotesExport.success, isTrue);
        expect(allNotesExport.notesCount, equals(2));
        expect(allNotesExport.jsonData!, contains('This is public'));
        expect(allNotesExport.jsonData!, contains('This is private'));
      });
    });

    group('User Story: Handling Text Changes and Re-anchoring', () {
      test('As a user, my notes stay accurate when text has minor changes', () async {
        // This test simulates the scenario where book text changes slightly
        // and notes need to be re-anchored
        
        const bookId = 'reanchoring-test';
        const originalText = 'This is the original text with some content.';
        const modifiedText = 'This is the original text with some additional content.';
        
        // Create note on original text
        final note = await integrationService.createNoteFromSelection(
          bookId, 'original text', 12, 25, 'Note on original text');
        
        expect(note.status, equals(NoteStatus.anchored));
        
        // Simulate loading book with modified text (this would trigger re-anchoring)
        final modifiedBookNotes = await integrationService.loadNotesForBook(bookId, modifiedText);
        
        // Note should still be found, possibly with shifted status
        expect(modifiedBookNotes.notes.length, equals(1));
        final reanchoredNote = modifiedBookNotes.notes.first;
        
        // Note should maintain its identity and content
        expect(reanchoredNote.id, equals(note.id));
        expect(reanchoredNote.contentMarkdown, equals('Note on original text'));
        
        // Status might be shifted or anchored depending on the change
        expect([NoteStatus.anchored, NoteStatus.shifted], contains(reanchoredNote.status));
      });

      test('As a user, I am notified when notes become orphaned', () async {
        const bookId = 'orphan-test';
        
        // Create note
        final note = await integrationService.createNoteFromSelection(
          bookId, 'will be orphaned', 10, 26, 'This note will become orphaned');
        
        // Simulate text change that makes the note orphaned
        // (In a real scenario, this would happen when the selected text is completely removed)
        
        // For testing, we'll check the orphan analysis functionality
        final orphanAnalysis = orphanManager.analyzeOrphans([note]);
        
        expect(orphanAnalysis.totalOrphans, equals(1));
        expect(orphanAnalysis.recommendations, isNotEmpty);
      });
    });

    group('Accuracy Requirements Validation', () {
      test('should achieve 98% accuracy after 5% text changes', () async {
        const bookId = 'accuracy-test';
        const originalText = 'This is a test document with multiple sentences. Each sentence contains different words and phrases. The document is used for testing note anchoring accuracy.';
        
        // Create multiple notes
        final notes = <Note>[];
        final selections = [
          {'text': 'test document', 'start': 10, 'end': 23},
          {'text': 'multiple sentences', 'start': 29, 'end': 47},
          {'text': 'different words', 'start': 78, 'end': 93},
          {'text': 'testing note', 'start': 130, 'end': 142},
        ];
        
        for (int i = 0; i < selections.length; i++) {
          final selection = selections[i];
          final note = await integrationService.createNoteFromSelection(
            bookId,
            selection['text'] as String,
            selection['start'] as int,
            selection['end'] as int,
            'Test note $i',
          );
          notes.add(note);
        }
        
        // Simulate 5% text change (add ~8 characters to 160-character text)
        const modifiedText = 'This is a comprehensive test document with multiple sentences. Each sentence contains different words and phrases. The document is used for testing note anchoring accuracy.';
        
        // Load with modified text
        final modifiedBookNotes = await integrationService.loadNotesForBook(bookId, modifiedText);
        
        // Calculate accuracy
        final anchoredCount = modifiedBookNotes.notes.where((n) => 
            n.status == NoteStatus.anchored || n.status == NoteStatus.shifted).length;
        final accuracy = anchoredCount / notes.length;
        
        expect(accuracy, greaterThanOrEqualTo(0.98)); // 98% accuracy requirement
      });

      test('should achieve 100% accuracy for whitespace-only changes', () async {
        const bookId = 'whitespace-accuracy-test';
        const originalText = 'Text with normal spacing between words.';
        const whitespaceModifiedText = 'Text  with   normal    spacing     between      words.';
        
        // Create note
        final note = await integrationService.createNoteFromSelection(
          bookId, 'normal spacing', 10, 24, 'Note about spacing');
        
        expect(note.status, equals(NoteStatus.anchored));
        
        // Load with whitespace changes
        final modifiedBookNotes = await integrationService.loadNotesForBook(bookId, whitespaceModifiedText);
        
        expect(modifiedBookNotes.notes.length, equals(1));
        expect(modifiedBookNotes.notes.first.status, equals(NoteStatus.anchored)); // Should remain anchored
      });

      test('should handle deleted text properly', () async {
        const bookId = 'deletion-test';
        const originalText = 'This text will have a section removed from the middle part.';
        const deletedText = 'This text will have a section removed.'; // "from the middle part" removed
        
        // Create note on the part that will be deleted
        final note = await integrationService.createNoteFromSelection(
          bookId, 'middle part', 45, 56, 'Note on deleted section');
        
        // Load with deleted text
        final modifiedBookNotes = await integrationService.loadNotesForBook(bookId, deletedText);
        
        expect(modifiedBookNotes.notes.length, equals(1));
        expect(modifiedBookNotes.notes.first.status, equals(NoteStatus.orphan)); // Should be orphaned
      });
    });

    group('Text Normalization Consistency', () {
      test('should produce consistent normalization results', () {
        const testTexts = [
          'טקסט עם "מירכאות" שונות',
          'טקסט עם ״מירכאות״ שונות',
          'טקסט עם "מירכאות" שונות',
        ];
        
        final config = TextNormalizer.createConfigFromSettings();
        final normalizedResults = testTexts.map((text) => 
            TextNormalizer.normalize(text, config)).toList();
        
        // All variations should normalize to the same result
        expect(normalizedResults[0], equals(normalizedResults[1]));
        expect(normalizedResults[1], equals(normalizedResults[2]));
      });

      test('should handle Hebrew nikud consistently', () {
        const textWithNikud = 'בְּרֵאשִׁית בָּרָא אֱלֹהִים';
        const textWithoutNikud = 'בראשית ברא אלהים';
        
        final configKeepNikud = const NormalizationConfig(removeNikud: false);
        final configRemoveNikud = const NormalizationConfig(removeNikud: true);
        
        final normalizedWithNikud = TextNormalizer.normalize(textWithNikud, configKeepNikud);
        final normalizedWithoutNikud = TextNormalizer.normalize(textWithNikud, configRemoveNikud);
        final originalWithoutNikud = TextNormalizer.normalize(textWithoutNikud, configRemoveNikud);
        
        expect(normalizedWithNikud, contains('ְ')); // Should contain nikud
        expect(normalizedWithoutNikud, isNot(contains('ְ'))); // Should not contain nikud
        expect(normalizedWithoutNikud, equals(originalWithoutNikud)); // Should match text without nikud
      });
    });

    group('Fuzzy Matching Validation', () {
      test('should meet similarity thresholds', () {
        const originalText = 'This is the original text';
        const similarText = 'This is the original text with addition';
        const differentText = 'Completely different content here';
        
        final similarityHigh = FuzzyMatcher.calculateCombinedSimilarity(originalText, similarText);
        final similarityLow = FuzzyMatcher.calculateCombinedSimilarity(originalText, differentText);
        
        expect(similarityHigh, greaterThan(AnchoringConstants.jaccardThreshold));
        expect(similarityLow, lessThan(AnchoringConstants.jaccardThreshold));
      });

      test('should handle Hebrew text similarity correctly', () {
        const hebrewOriginal = 'זהו טקסט בעברית לבדיקה';
        const hebrewSimilar = 'זהו טקסט בעברית לבדיקת דמיון';
        const hebrewDifferent = 'טקסט שונה לחלוטין בעברית';
        
        final similarityHigh = FuzzyMatcher.calculateCombinedSimilarity(hebrewOriginal, hebrewSimilar);
        final similarityLow = FuzzyMatcher.calculateCombinedSimilarity(hebrewOriginal, hebrewDifferent);
        
        expect(similarityHigh, greaterThan(0.5));
        expect(similarityLow, lessThan(0.5));
      });
    });
  });
}