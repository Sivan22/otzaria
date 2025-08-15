/// SQL schema and configuration for the notes database
class DatabaseSchema {
  /// SQL to create the notes table
  static const String createNotesTable = '''
    CREATE TABLE IF NOT EXISTS notes (
      note_id TEXT PRIMARY KEY,
      book_id TEXT NOT NULL,
      doc_version_id TEXT NOT NULL,
      logical_path TEXT,
      char_start INTEGER NOT NULL,
      char_end INTEGER NOT NULL,
      selected_text_normalized TEXT NOT NULL,
      text_hash TEXT NOT NULL,
      ctx_before TEXT NOT NULL,
      ctx_after TEXT NOT NULL,
      ctx_before_hash TEXT NOT NULL,
      ctx_after_hash TEXT NOT NULL,
      rolling_before INTEGER NOT NULL,
      rolling_after INTEGER NOT NULL,
      status TEXT NOT NULL CHECK (status IN ('anchored', 'shifted', 'orphan')),
      content_markdown TEXT NOT NULL,
      author_user_id TEXT NOT NULL,
      privacy TEXT NOT NULL CHECK (privacy IN ('private', 'shared')),
      tags TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      normalization_config TEXT NOT NULL
    );
  ''';

  /// SQL to create the canonical documents table
  static const String createCanonicalDocsTable = '''
    CREATE TABLE IF NOT EXISTS canonical_documents (
      id TEXT PRIMARY KEY,
      book_id TEXT NOT NULL,
      version_id TEXT NOT NULL,
      canonical_text TEXT NOT NULL,
      text_hash_index TEXT NOT NULL,
      context_hash_index TEXT NOT NULL,
      rolling_hash_index TEXT NOT NULL,
      logical_structure TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      UNIQUE(book_id, version_id)
    );
  ''';

  /// SQL to create performance indexes
  static const List<String> createIndexes = [
    'CREATE INDEX IF NOT EXISTS idx_notes_book_id ON notes(book_id);',
    'CREATE INDEX IF NOT EXISTS idx_notes_doc_version ON notes(doc_version_id);',
    'CREATE INDEX IF NOT EXISTS idx_notes_text_hash ON notes(text_hash);',
    'CREATE INDEX IF NOT EXISTS idx_notes_ctx_hashes ON notes(ctx_before_hash, ctx_after_hash);',
    'CREATE INDEX IF NOT EXISTS idx_notes_author ON notes(author_user_id);',
    'CREATE INDEX IF NOT EXISTS idx_notes_status ON notes(status);',
    'CREATE INDEX IF NOT EXISTS idx_notes_updated ON notes(updated_at);',
    'CREATE INDEX IF NOT EXISTS idx_canonical_book_version ON canonical_documents(book_id, version_id);',
  ];

  /// SQL to create FTS table for Hebrew content search
  static const String createFtsTable = '''
    CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
      content_markdown, 
      tags, 
      selected_text_normalized,
      content='notes', 
      content_rowid='rowid'
    );
  ''';

  /// SQL triggers to sync FTS table
  static const List<String> createFtsTriggers = [
    '''
    CREATE TRIGGER IF NOT EXISTS notes_fts_insert AFTER INSERT ON notes BEGIN
      INSERT INTO notes_fts(rowid, content_markdown, tags, selected_text_normalized)
      VALUES (new.rowid, new.content_markdown, new.tags, new.selected_text_normalized);
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS notes_fts_delete AFTER DELETE ON notes BEGIN
      DELETE FROM notes_fts WHERE rowid = old.rowid;
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS notes_fts_update AFTER UPDATE ON notes BEGIN
      DELETE FROM notes_fts WHERE rowid = old.rowid;
      INSERT INTO notes_fts(rowid, content_markdown, tags, selected_text_normalized)
      VALUES (new.rowid, new.content_markdown, new.tags, new.selected_text_normalized);
    END;
    ''',
  ];

  /// SQLite PRAGMA optimizations
  static const List<String> pragmaOptimizations = [
    'PRAGMA journal_mode=WAL;',
    'PRAGMA synchronous=NORMAL;',
    'PRAGMA temp_store=MEMORY;',
    'PRAGMA cache_size=10000;',
    'PRAGMA foreign_keys=ON;',
    'PRAGMA busy_timeout=5000;',
    'PRAGMA analysis_limit=400;',
  ];

  /// SQL to run ANALYZE after initial data population
  static const String analyzeDatabase = 'ANALYZE;';

  /// Initialize the notes database with all required tables and indexes
  static Future<void> initializeDatabase() async {
    // This is a placeholder - actual implementation would use SQLite
    // For now, we'll just log that initialization was attempted
    // print('Notes database initialization attempted');
    
    // In a real implementation, this would:
    // 1. Open/create the database file
    // 2. Run all schema creation statements
    // 3. Apply PRAGMA optimizations
    // 4. Run ANALYZE for query optimization
    
    // Example implementation structure:
    // final db = await openDatabase('notes.db');
    // for (final statement in allSchemaStatements) {
    //   await db.execute(statement);
    // }
    // for (final pragma in pragmaOptimizations) {
    //   await db.execute(pragma);
    // }
    // await db.execute(analyzeDatabase);
  }

  /// Get all schema creation statements in order (without PRAGMA)
  static List<String> get allSchemaStatements => [
        createNotesTable,
        createCanonicalDocsTable,
        ...createIndexes,
        createFtsTable,
        ...createFtsTriggers,
      ];

  /// Validation queries to check schema integrity
  static const Map<String, String> validationQueries = {
    'notes_table_exists': '''
      SELECT name FROM sqlite_master 
      WHERE type='table' AND name='notes';
    ''',
    'canonical_docs_table_exists': '''
      SELECT name FROM sqlite_master 
      WHERE type='table' AND name='canonical_documents';
    ''',
    'fts_table_exists': '''
      SELECT name FROM sqlite_master 
      WHERE type='table' AND name='notes_fts';
    ''',
    'indexes_count': '''
      SELECT COUNT(*) as count FROM sqlite_master 
      WHERE type='index' AND name LIKE 'idx_notes_%';
    ''',
    'triggers_count': '''
      SELECT COUNT(*) as count FROM sqlite_master 
      WHERE type='trigger' AND name LIKE 'notes_fts_%';
    ''',
  };
}