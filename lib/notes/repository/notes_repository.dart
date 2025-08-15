import 'dart:convert';
import '../models/note.dart';
import '../models/anchor_models.dart';
import '../data/notes_data_provider.dart';
import '../services/anchoring_service.dart';
import '../services/canonical_text_service.dart';
import '../services/background_processor.dart';
import '../services/text_normalizer.dart';
import '../config/notes_config.dart';

/// Repository for managing notes with business logic
class NotesRepository {
  static NotesRepository? _instance;
  final NotesDataProvider _dataProvider = NotesDataProvider.instance;
  final AnchoringService _anchoringService = AnchoringService.instance;
  final CanonicalTextService _canonicalService = CanonicalTextService.instance;
  final BackgroundProcessor _backgroundProcessor = BackgroundProcessor.instance;
  
  NotesRepository._();
  
  /// Singleton instance
  static NotesRepository get instance {
    _instance ??= NotesRepository._();
    return _instance!;
  }

  /// Create a new note with automatic anchoring
  Future<Note> createNote(CreateNoteRequest request) async {
    try {
      // Validate input
      _validateCreateRequest(request);
      
      // Create canonical document for the book
      final canonicalDoc = await _canonicalService.createCanonicalDocument(request.bookId);
      
      // Create anchor data
      final anchorData = _anchoringService.createAnchor(
        request.bookId,
        canonicalDoc.canonicalText,
        request.charStart,
        request.charEnd,
      );
      
      // Create note with current normalization config
      final config = TextNormalizer.createConfigFromSettings();
      final note = Note(
        id: _generateNoteId(),
        bookId: request.bookId,
        docVersionId: canonicalDoc.versionId,
        logicalPath: request.logicalPath,
        charStart: anchorData.charStart,
        charEnd: anchorData.charEnd,
        selectedTextNormalized: canonicalDoc.canonicalText.substring(
          anchorData.charStart, 
          anchorData.charEnd,
        ),
        textHash: anchorData.textHash,
        contextBefore: anchorData.contextBefore,
        contextAfter: anchorData.contextAfter,
        contextBeforeHash: anchorData.contextBeforeHash,
        contextAfterHash: anchorData.contextAfterHash,
        rollingBefore: anchorData.rollingBefore,
        rollingAfter: anchorData.rollingAfter,
        status: anchorData.status,
        contentMarkdown: request.contentMarkdown,
        authorUserId: request.authorUserId,
        privacy: request.privacy,
        tags: request.tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        normalizationConfig: config.toConfigString(),
      );
      
      // Save to database
      return await _dataProvider.createNote(note);
    } catch (e) {
      throw RepositoryException('Failed to create note: $e');
    }
  }

  /// Update an existing note
  Future<Note> updateNote(String noteId, UpdateNoteRequest request) async {
    try {
      // Get existing note
      final existingNote = await _dataProvider.getNoteById(noteId);
      if (existingNote == null) {
        throw RepositoryException('Note not found: $noteId');
      }
      
      // Update only provided fields
      final updatedNote = existingNote.copyWith(
        contentMarkdown: request.contentMarkdown ?? existingNote.contentMarkdown,
        privacy: request.privacy ?? existingNote.privacy,
        tags: request.tags ?? existingNote.tags,
        updatedAt: DateTime.now(),
      );
      
      return await _dataProvider.updateNote(updatedNote);
    } catch (e) {
      throw RepositoryException('Failed to update note: $e');
    }
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    try {
      await _dataProvider.deleteNote(noteId);
    } catch (e) {
      throw RepositoryException('Failed to delete note: $e');
    }
  }

  /// Get a note by ID
  Future<Note?> getNoteById(String noteId) async {
    try {
      return await _dataProvider.getNoteById(noteId);
    } catch (e) {
      throw RepositoryException('Failed to get note: $e');
    }
  }

  /// Get all notes for a book
  Future<List<Note>> getNotesForBook(String bookId) async {
    try {
      return await _dataProvider.getNotesForBook(bookId);
    } catch (e) {
      throw RepositoryException('Failed to get notes for book: $e');
    }
  }

  /// Get notes for a visible character range
  Future<List<Note>> getNotesForVisibleRange(String bookId, VisibleCharRange range) async {
    try {
      return await _dataProvider.getNotesForCharRange(bookId, range.start, range.end);
    } catch (e) {
      throw RepositoryException('Failed to get notes for range: $e');
    }
  }

  /// Search notes using full-text search
  Future<List<Note>> searchNotes(String query, {String? bookId}) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }
      
      return await _dataProvider.searchNotes(query, bookId: bookId);
    } catch (e) {
      throw RepositoryException('Failed to search notes: $e');
    }
  }

  /// Get orphan notes that need manual resolution
  Future<List<Note>> getOrphanNotes({String? bookId}) async {
    try {
      return await _dataProvider.getOrphanNotes(bookId: bookId);
    } catch (e) {
      throw RepositoryException('Failed to get orphan notes: $e');
    }
  }

  /// Re-anchor notes for a book (when book content changes)
  Future<ReanchoringResult> reanchorNotesForBook(String bookId) async {
    try {
      // Get all notes for the book
      final notes = await _dataProvider.getNotesForBook(bookId);
      if (notes.isEmpty) {
        return ReanchoringResult(
          totalNotes: 0,
          successCount: 0,
          failureCount: 0,
          orphanCount: 0,
          duration: Duration.zero,
        );
      }
      
      // Create new canonical document
      final canonicalDoc = await _canonicalService.createCanonicalDocument(bookId);
      
      // Process re-anchoring in background
      final stopwatch = Stopwatch()..start();
      final results = await _backgroundProcessor.processReanchoring(notes, canonicalDoc);
      stopwatch.stop();
      
      // Update notes with new anchoring results
      final updatedNotes = <Note>[];
      int successCount = 0;
      int failureCount = 0;
      int orphanCount = 0;
      
      for (int i = 0; i < notes.length; i++) {
        final note = notes[i];
        final result = results[i];
        
        final updatedNote = note.copyWith(
          docVersionId: canonicalDoc.versionId,
          charStart: result.start ?? note.charStart,
          charEnd: result.end ?? note.charEnd,
          status: result.status,
          updatedAt: DateTime.now(),
        );
        
        updatedNotes.add(updatedNote);
        
        switch (result.status) {
          case NoteStatus.anchored:
            successCount++;
            break;
          case NoteStatus.shifted:
            successCount++;
            break;
          case NoteStatus.orphan:
            orphanCount++;
            break;
        }
      }
      
      // Batch update all notes
      await _dataProvider.batchUpdateNotes(updatedNotes);
      
      return ReanchoringResult(
        totalNotes: notes.length,
        successCount: successCount,
        failureCount: failureCount,
        orphanCount: orphanCount,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      throw RepositoryException('Failed to re-anchor notes: $e');
    }
  }

  /// Resolve an orphan note by selecting a candidate position
  Future<Note> resolveOrphanNote(String noteId, AnchorCandidate selectedCandidate) async {
    try {
      final note = await _dataProvider.getNoteById(noteId);
      if (note == null) {
        throw RepositoryException('Note not found: $noteId');
      }
      
      if (note.status != NoteStatus.orphan) {
        throw RepositoryException('Note is not an orphan: $noteId');
      }
      
      // Update note with selected position
      final resolvedNote = note.copyWith(
        charStart: selectedCandidate.start,
        charEnd: selectedCandidate.end,
        status: NoteStatus.shifted, // Mark as shifted since it was manually resolved
        updatedAt: DateTime.now(),
      );
      
      return await _dataProvider.updateNote(resolvedNote);
    } catch (e) {
      throw RepositoryException('Failed to resolve orphan note: $e');
    }
  }

  /// Export notes to JSON format
  Future<String> exportNotes(ExportOptions options) async {
    try {
      List<Note> notes;
      
      if (options.bookId != null) {
        notes = await _dataProvider.getNotesForBook(options.bookId!);
      } else {
        // Get all notes (this would need to be implemented in data provider)
        // For now, return empty JSON - can be implemented later
        return '[]';
      }
      
      final exportData = {
        'version': '1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'book_id': options.bookId,
        'include_orphans': options.includeOrphans,
        'notes': notes
            .where((note) => options.includeOrphans || note.status != NoteStatus.orphan)
            .map((note) => note.toJson())
            .toList(),
      };
      
      return jsonEncode(exportData);
    } catch (e) {
      throw RepositoryException('Failed to export notes: $e');
    }
  }

  /// Import notes from JSON format
  Future<ImportResult> importNotes(String jsonData, ImportOptions options) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      final notesData = data['notes'] as List<dynamic>;
      
      int importedCount = 0;
      int skippedCount = 0;
      int errorCount = 0;
      
      for (final noteData in notesData) {
        try {
          final note = Note.fromJson(noteData as Map<String, dynamic>);
          
          // Check if note already exists
          final existing = await _dataProvider.getNoteById(note.id);
          if (existing != null) {
            if (options.overwriteExisting) {
              await _dataProvider.updateNote(note);
              importedCount++;
            } else {
              skippedCount++;
            }
          } else {
            await _dataProvider.createNote(note);
            importedCount++;
          }
        } catch (e) {
          errorCount++;
        }
      }
      
      return ImportResult(
        totalNotes: notesData.length,
        importedCount: importedCount,
        skippedCount: skippedCount,
        errorCount: errorCount,
      );
    } catch (e) {
      throw RepositoryException('Failed to import notes: $e');
    }
  }

  /// Get repository statistics
  Future<Map<String, dynamic>> getRepositoryStats() async {
    try {
      final dbStats = await _dataProvider.getDatabaseStats();
      final processingStats = _backgroundProcessor.getProcessingStats();
      
      return {
        ...dbStats,
        ...processingStats,
        'repository_version': '1.0',
      };
    } catch (e) {
      throw RepositoryException('Failed to get repository stats: $e');
    }
  }

  /// Validate create note request
  void _validateCreateRequest(CreateNoteRequest request) {
    if (request.bookId.isEmpty) {
      throw RepositoryException('Book ID cannot be empty');
    }
    
    if (request.charStart < 0 || request.charEnd <= request.charStart) {
      throw RepositoryException('Invalid character range');
    }
    
    if (request.contentMarkdown.isEmpty) {
      throw RepositoryException('Note content cannot be empty');
    }
    
    if (request.contentMarkdown.length > NotesConfig.maxNoteSize) {
      throw RepositoryException('Note content exceeds maximum size');
    }
    
    if (request.authorUserId.isEmpty) {
      throw RepositoryException('Author user ID cannot be empty');
    }
  }

  /// Generate unique note ID
  String _generateNoteId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'note_${timestamp}_$random';
  }
}

/// Request for creating a new note
class CreateNoteRequest {
  final String bookId;
  final int charStart;
  final int charEnd;
  final String contentMarkdown;
  final String authorUserId;
  final NotePrivacy privacy;
  final List<String> tags;
  final List<String>? logicalPath;

  const CreateNoteRequest({
    required this.bookId,
    required this.charStart,
    required this.charEnd,
    required this.contentMarkdown,
    required this.authorUserId,
    this.privacy = NotePrivacy.private,
    this.tags = const [],
    this.logicalPath,
  });
}

/// Request for updating an existing note
class UpdateNoteRequest {
  final String? contentMarkdown;
  final NotePrivacy? privacy;
  final List<String>? tags;
  final int? charStart;
  final int? charEnd;
  final NoteStatus? status;

  const UpdateNoteRequest({
    this.contentMarkdown,
    this.privacy,
    this.tags,
    this.charStart,
    this.charEnd,
    this.status,
  });
}

/// Options for exporting notes
class ExportOptions {
  final String? bookId;
  final bool includeOrphans;
  final bool encryptData;

  const ExportOptions({
    this.bookId,
    this.includeOrphans = false,
    this.encryptData = false,
  });
}

/// Options for importing notes
class ImportOptions {
  final bool overwriteExisting;
  final bool validateAnchors;

  const ImportOptions({
    this.overwriteExisting = false,
    this.validateAnchors = true,
  });
}

/// Result of re-anchoring operation
class ReanchoringResult {
  final int totalNotes;
  final int successCount;
  final int failureCount;
  final int orphanCount;
  final Duration duration;

  const ReanchoringResult({
    required this.totalNotes,
    required this.successCount,
    required this.failureCount,
    required this.orphanCount,
    required this.duration,
  });

  double get successRate => totalNotes > 0 ? successCount / totalNotes : 0.0;
  double get orphanRate => totalNotes > 0 ? orphanCount / totalNotes : 0.0;
}

/// Result of import operation
class ImportResult {
  final int totalNotes;
  final int importedCount;
  final int skippedCount;
  final int errorCount;

  const ImportResult({
    required this.totalNotes,
    required this.importedCount,
    required this.skippedCount,
    required this.errorCount,
  });
}

/// Repository exception
class RepositoryException implements Exception {
  final String message;

  const RepositoryException(this.message);

  @override
  String toString() => 'RepositoryException: $message';
}