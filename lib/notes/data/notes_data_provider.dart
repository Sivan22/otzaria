import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';

import '../config/notes_config.dart';
import 'database_schema.dart';

/// Data provider for notes database operations
class NotesDataProvider {
  static NotesDataProvider? _instance;
  Database? _database;

  NotesDataProvider._();

  /// Singleton instance
  static NotesDataProvider get instance {
    _instance ??= NotesDataProvider._();
    return _instance!;
  }

  /// Get the database instance, creating it if necessary
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the database with schema and optimizations
  Future<Database> _initDatabase() async {
    // Always use persistent database - even in debug mode
    // In-memory database would lose data when app closes
    
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, NotesEnvironment.databasePath);

    return await openDatabase(
      path,
      version: DatabaseConfig.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  /// Create database schema on first run
  Future<void> _onCreate(Database db, int version) async {
    // Execute all schema statements
    for (final statement in DatabaseSchema.allSchemaStatements) {
      await db.execute(statement);
    }

    // Run ANALYZE after schema creation
    await db.execute(DatabaseSchema.analyzeDatabase);
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future database migrations will be handled here
    if (oldVersion < newVersion) {
      // For now, recreate the database
      await _dropAllTables(db);
      await _onCreate(db, newVersion);
    }
  }

  /// Configure database on open
  Future<void> _onOpen(Database db) async {
    // Apply PRAGMA settings (skip problematic ones in testing)
    for (final pragma in DatabaseSchema.pragmaOptimizations) {
      try {
        // Skip synchronous pragma in testing as it can cause issues
        if (NotesEnvironment.debugMode && pragma.contains('synchronous')) {
          continue;
        }
        await db.execute(pragma);
      } catch (e) {
        // Log but don't fail on PRAGMA errors in testing
        if (NotesEnvironment.performanceLogging) {
          // print('PRAGMA warning: $pragma failed with $e');
        }
      }
    }
  }

  /// Drop all tables (for migrations)
  Future<void> _dropAllTables(Database db) async {
    await db.execute('DROP TABLE IF EXISTS notes_fts;');
    await db.execute('DROP TABLE IF EXISTS notes;');
    await db.execute('DROP TABLE IF EXISTS canonical_documents;');
  }

  /// Validate database schema integrity
  Future<bool> validateSchema() async {
    try {
      final db = await database;
      
      for (final entry in DatabaseSchema.validationQueries.entries) {
        final result = await db.rawQuery(entry.value);
        
        switch (entry.key) {
          case 'notes_table_exists':
          case 'canonical_docs_table_exists':
          case 'fts_table_exists':
            if (result.isEmpty) return false;
            break;
          case 'indexes_count':
            final count = result.first['count'] as int;
            if (count < 7) return false; // Expected number of indexes
            break;
          case 'triggers_count':
            final count = result.first['count'] as int;
            if (count < 3) return false; // Expected number of triggers
            break;
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Create a new note
  Future<Note> createNote(Note note) async {
    final db = await database;
    
    await db.transaction((txn) async {
      await txn.insert(
        DatabaseConfig.notesTable,
        note.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    
    return note;
  }

  /// Get a note by ID
  Future<Note?> getNoteById(String noteId) async {
    final db = await database;
    
    final result = await db.query(
      DatabaseConfig.notesTable,
      where: 'note_id = ?',
      whereArgs: [noteId],
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    return Note.fromJson(result.first);
  }

  /// Get all notes for a book
  Future<List<Note>> getNotesForBook(String bookId) async {
    final db = await database;
    
    final result = await db.query(
      DatabaseConfig.notesTable,
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'char_start ASC',
    );
    
    return result.map((json) => Note.fromJson(json)).toList();
  }

  /// Get notes for a specific character range
  Future<List<Note>> getNotesForCharRange(
    String bookId,
    int startChar,
    int endChar,
  ) async {
    final db = await database;
    
    final result = await db.query(
      DatabaseConfig.notesTable,
      where: '''
        book_id = ? AND 
        ((char_start >= ? AND char_start <= ?) OR 
         (char_end >= ? AND char_end <= ?) OR 
         (char_start <= ? AND char_end >= ?))
      ''',
      whereArgs: [bookId, startChar, endChar, startChar, endChar, startChar, endChar],
      orderBy: 'char_start ASC',
    );
    
    return result.map((json) => Note.fromJson(json)).toList();
  }

  /// Update an existing note
  Future<Note> updateNote(Note note) async {
    final db = await database;
    
    final updatedNote = note.copyWith(updatedAt: DateTime.now());
    
    await db.transaction((txn) async {
      await txn.update(
        DatabaseConfig.notesTable,
        updatedNote.toJson(),
        where: 'note_id = ?',
        whereArgs: [note.id],
      );
    });
    
    return updatedNote;
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    final db = await database;
    
    await db.transaction((txn) async {
      await txn.delete(
        DatabaseConfig.notesTable,
        where: 'note_id = ?',
        whereArgs: [noteId],
      );
    });
  }

  /// Search notes using FTS
  Future<List<Note>> searchNotes(String query, {String? bookId}) async {
    final db = await database;
    
    String whereClause = 'notes_fts MATCH ?';
    List<dynamic> whereArgs = [query];
    
    if (bookId != null) {
      whereClause += ' AND notes.book_id = ?';
      whereArgs.add(bookId);
    }
    
    final result = await db.rawQuery('''
      SELECT notes.* FROM notes_fts
      JOIN notes ON notes.rowid = notes_fts.rowid
      WHERE $whereClause
      ORDER BY bm25(notes_fts) ASC
      LIMIT 100
    ''', whereArgs);
    
    return result.map((json) => Note.fromJson(json)).toList();
  }

  /// Get notes by status
  Future<List<Note>> getNotesByStatus(NoteStatus status, {String? bookId}) async {
    final db = await database;
    
    String whereClause = 'status = ?';
    List<dynamic> whereArgs = [status.name];
    
    if (bookId != null) {
      whereClause += ' AND book_id = ?';
      whereArgs.add(bookId);
    }
    
    final result = await db.query(
      DatabaseConfig.notesTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'updated_at DESC',
    );
    
    return result.map((json) => Note.fromJson(json)).toList();
  }

  /// Get orphan notes that need manual resolution
  Future<List<Note>> getOrphanNotes({String? bookId}) async {
    return getNotesByStatus(NoteStatus.orphan, bookId: bookId);
  }

  /// Update note status (for re-anchoring)
  Future<void> updateNoteStatus(String noteId, NoteStatus status, {
    int? newStart,
    int? newEnd,
  }) async {
    final db = await database;
    
    final updateData = <String, dynamic>{
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (newStart != null) updateData['char_start'] = newStart;
    if (newEnd != null) updateData['char_end'] = newEnd;
    
    await db.transaction((txn) async {
      await txn.update(
        DatabaseConfig.notesTable,
        updateData,
        where: 'note_id = ?',
        whereArgs: [noteId],
      );
    });
  }

  /// Batch update multiple notes (for re-anchoring)
  Future<void> batchUpdateNotes(List<Note> notes) async {
    final db = await database;
    
    await db.transaction((txn) async {
      for (final note in notes) {
        await txn.update(
          DatabaseConfig.notesTable,
          note.toJson(),
          where: 'note_id = ?',
          whereArgs: [note.id],
        );
      }
    });
  }

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    
    final notesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM notes'),
    ) ?? 0;
    
    final canonicalDocsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM canonical_documents'),
    ) ?? 0;
    
    final orphanNotesCount = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM notes WHERE status = 'orphan'"),
    ) ?? 0;
    
    return {
      'total_notes': notesCount,
      'canonical_documents': canonicalDocsCount,
      'orphan_notes': orphanNotesCount,
    };
  }

  /// Close the database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Reset the database (for testing)
  Future<void> reset() async {
    await close();
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, NotesEnvironment.databasePath);
    
    if (await File(path).exists()) {
      await File(path).delete();
    }
    
    _database = null;
  }
}