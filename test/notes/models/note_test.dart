import 'package:flutter_test/flutter_test.dart';
import 'package:otzaria/notes/models/note.dart';

void main() {
  group('Note Model Tests', () {
    late Note testNote;

    setUp(() {
      testNote = Note(
        id: 'test-note-1',
        bookId: 'test-book',
        docVersionId: 'version-1',
        charStart: 100,
        charEnd: 150,
        selectedTextNormalized: 'test text',
        textHash: 'hash123',
        contextBefore: 'before text',
        contextAfter: 'after text',
        contextBeforeHash: 'before-hash',
        contextAfterHash: 'after-hash',
        rollingBefore: 12345,
        rollingAfter: 67890,
        status: NoteStatus.anchored,
        contentMarkdown: 'This is a test note',
        authorUserId: 'user-1',
        privacy: NotePrivacy.private,
        tags: ['test', 'example'],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        normalizationConfig: 'norm=v1;nikud=keep;quotes=ascii;unicode=NFKC',
      );
    });

    test('should create note with all required fields', () {
      expect(testNote.id, equals('test-note-1'));
      expect(testNote.bookId, equals('test-book'));
      expect(testNote.status, equals(NoteStatus.anchored));
      expect(testNote.privacy, equals(NotePrivacy.private));
      expect(testNote.tags, equals(['test', 'example']));
    });

    test('should convert to JSON correctly', () {
      final json = testNote.toJson();
      
      expect(json['note_id'], equals('test-note-1'));
      expect(json['book_id'], equals('test-book'));
      expect(json['status'], equals('anchored'));
      expect(json['privacy'], equals('private'));
      expect(json['tags'], equals('test,example'));
      expect(json['char_start'], equals(100));
      expect(json['char_end'], equals(150));
    });

    test('should create from JSON correctly', () {
      final json = testNote.toJson();
      final recreatedNote = Note.fromJson(json);
      
      expect(recreatedNote.id, equals(testNote.id));
      expect(recreatedNote.bookId, equals(testNote.bookId));
      expect(recreatedNote.status, equals(testNote.status));
      expect(recreatedNote.privacy, equals(testNote.privacy));
      expect(recreatedNote.tags, equals(testNote.tags));
      expect(recreatedNote.charStart, equals(testNote.charStart));
      expect(recreatedNote.charEnd, equals(testNote.charEnd));
    });

    test('should handle empty tags correctly', () {
      final noteWithoutTags = testNote.copyWith(tags: []);
      final json = noteWithoutTags.toJson();
      final recreated = Note.fromJson(json);
      
      expect(recreated.tags, isEmpty);
    });

    test('should handle null logical path correctly', () {
      expect(testNote.logicalPath, isNull);
      
      final json = testNote.toJson();
      expect(json['logical_path'], isNull);
      
      final recreated = Note.fromJson(json);
      expect(recreated.logicalPath, isNull);
    });

    test('should handle logical path correctly', () {
      final noteWithPath = testNote.copyWith(
        logicalPath: ['chapter:1', 'section:2'],
      );
      
      final json = noteWithPath.toJson();
      expect(json['logical_path'], equals('chapter:1,section:2'));
      
      final recreated = Note.fromJson(json);
      expect(recreated.logicalPath, equals(['chapter:1', 'section:2']));
    });

    test('copyWith should update specified fields only', () {
      final updatedNote = testNote.copyWith(
        contentMarkdown: 'Updated content',
        status: NoteStatus.shifted,
      );
      
      expect(updatedNote.contentMarkdown, equals('Updated content'));
      expect(updatedNote.status, equals(NoteStatus.shifted));
      expect(updatedNote.id, equals(testNote.id)); // unchanged
      expect(updatedNote.bookId, equals(testNote.bookId)); // unchanged
    });

    test('should have proper equality', () {
      final identicalNote = Note(
        id: testNote.id,
        bookId: testNote.bookId,
        docVersionId: testNote.docVersionId,
        charStart: testNote.charStart,
        charEnd: testNote.charEnd,
        selectedTextNormalized: testNote.selectedTextNormalized,
        textHash: testNote.textHash,
        contextBefore: testNote.contextBefore,
        contextAfter: testNote.contextAfter,
        contextBeforeHash: testNote.contextBeforeHash,
        contextAfterHash: testNote.contextAfterHash,
        rollingBefore: testNote.rollingBefore,
        rollingAfter: testNote.rollingAfter,
        status: testNote.status,
        contentMarkdown: testNote.contentMarkdown,
        authorUserId: testNote.authorUserId,
        privacy: testNote.privacy,
        tags: testNote.tags,
        createdAt: testNote.createdAt,
        updatedAt: testNote.updatedAt,
        normalizationConfig: testNote.normalizationConfig,
      );
      
      expect(testNote, equals(identicalNote));
    });

    test('toString should provide useful information', () {
      final string = testNote.toString();
      expect(string, contains('test-note-1'));
      expect(string, contains('test-book'));
      expect(string, contains('anchored'));
    });
  });

  group('NoteStatus Tests', () {
    test('should have correct enum values', () {
      expect(NoteStatus.anchored.name, equals('anchored'));
      expect(NoteStatus.shifted.name, equals('shifted'));
      expect(NoteStatus.orphan.name, equals('orphan'));
    });

    test('should parse from string correctly', () {
      expect(NoteStatus.values.byName('anchored'), equals(NoteStatus.anchored));
      expect(NoteStatus.values.byName('shifted'), equals(NoteStatus.shifted));
      expect(NoteStatus.values.byName('orphan'), equals(NoteStatus.orphan));
    });
  });

  group('NotePrivacy Tests', () {
    test('should have correct enum values', () {
      expect(NotePrivacy.private.name, equals('private'));
      expect(NotePrivacy.shared.name, equals('shared'));
    });

    test('should parse from string correctly', () {
      expect(NotePrivacy.values.byName('private'), equals(NotePrivacy.private));
      expect(NotePrivacy.values.byName('shared'), equals(NotePrivacy.shared));
    });
  });
}