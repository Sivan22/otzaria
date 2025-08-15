import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../models/note.dart';
import '../repository/notes_repository.dart';
import '../services/notes_telemetry.dart';

/// Service for importing and exporting notes
class ImportExportService {
  static ImportExportService? _instance;
  final NotesRepository _repository = NotesRepository.instance;
  
  ImportExportService._();
  
  /// Singleton instance
  static ImportExportService get instance {
    _instance ??= ImportExportService._();
    return _instance!;
  }

  /// Export notes to JSON format
  Future<ExportResult> exportNotes({
    String? bookId,
    List<String>? noteIds,
    bool includeOrphans = true,
    bool includePrivateNotes = true,
    String? filePath,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Determine which notes to export
      List<Note> notesToExport;
      
      if (noteIds != null && noteIds.isNotEmpty) {
        // Export specific notes
        notesToExport = [];
        for (final noteId in noteIds) {
          final note = await _repository.getNoteById(noteId);
          if (note != null) {
            notesToExport.add(note);
          }
        }
      } else if (bookId != null) {
        // Export all notes for a specific book
        notesToExport = await _repository.getNotesForBook(bookId);
      } else {
        // This would require a method to get all notes across all books
        throw UnsupportedError('Exporting all notes across all books is not yet supported');
      }
      
      // Apply filters
      final filteredNotes = notesToExport.where((note) {
        if (!includeOrphans && note.status == NoteStatus.orphan) {
          return false;
        }
        if (!includePrivateNotes && note.privacy == NotePrivacy.private) {
          return false;
        }
        return true;
      }).toList();
      
      // Create export data structure
      final exportData = {
        'version': '1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'export_metadata': {
          'book_id': bookId,
          'total_notes': filteredNotes.length,
          'include_orphans': includeOrphans,
          'include_private': includePrivateNotes,
          'app_version': '1.0.0', // This should come from package info
        },
        'notes': filteredNotes.map((note) => _noteToExportJson(note)).toList(),
      };
      
      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Save to file if path provided
      String? savedPath;
      if (filePath != null) {
        final file = File(filePath);
        await file.writeAsString(jsonString);
        savedPath = filePath;
      }
      
      // Track export
      NotesTelemetry.trackUserAction('notes_exported', {
        'note_count': filteredNotes.length,
        'book_id_length': bookId?.length ?? 0,
        'include_orphans': includeOrphans,
        'include_private': includePrivateNotes,
      });
      
      return ExportResult(
        success: true,
        notesCount: filteredNotes.length,
        filePath: savedPath,
        jsonData: jsonString,
        duration: stopwatch.elapsed,
      );
      
    } catch (e) {
      NotesTelemetry.trackPerformanceMetric('export_error', stopwatch.elapsed);
      
      return ExportResult(
        success: false,
        notesCount: 0,
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Import notes from JSON format
  Future<ImportResult> importNotes(
    String jsonData, {
    bool overwriteExisting = false,
    bool validateAnchors = true,
    String? targetBookId,
    Function(int current, int total)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Parse JSON
      final Map<String, dynamic> data;
      try {
        data = jsonDecode(jsonData) as Map<String, dynamic>;
      } catch (e) {
        throw ImportException('Invalid JSON format: $e');
      }
      
      // Validate format
      _validateImportFormat(data);
      
      // Extract notes data
      final notesData = data['notes'] as List<dynamic>;
      final totalNotes = notesData.length;
      
      if (totalNotes == 0) {
        return ImportResult(
          success: true,
          totalNotes: 0,
          importedCount: 0,
          skippedCount: 0,
          errorCount: 0,
          duration: stopwatch.elapsed,
        );
      }
      
      // Process notes
      int importedCount = 0;
      int skippedCount = 0;
      int errorCount = 0;
      final errors = <String>[];
      
      for (int i = 0; i < notesData.length; i++) {
        try {
          final noteData = notesData[i] as Map<String, dynamic>;
          
          // Convert to Note object
          final note = _noteFromImportJson(noteData, targetBookId);
          
          // Check if note already exists
          final existingNote = await _repository.getNoteById(note.id);
          
          if (existingNote != null) {
            if (overwriteExisting) {
              await _repository.updateNote(note.id, UpdateNoteRequest(
                contentMarkdown: note.contentMarkdown,
                tags: note.tags,
                privacy: note.privacy,
                charStart: note.charStart,
                charEnd: note.charEnd,
                status: note.status,
              ));
              importedCount++;
            } else {
              skippedCount++;
            }
          } else {
            // Create new note
            await _repository.createNote(CreateNoteRequest(
              bookId: note.bookId,
              charStart: note.charStart,
              charEnd: note.charEnd,
              contentMarkdown: note.contentMarkdown,
              authorUserId: note.authorUserId,
              privacy: note.privacy,
              tags: note.tags,
            ));
            importedCount++;
          }
          
          // Report progress
          onProgress?.call(i + 1, totalNotes);
          
        } catch (e) {
          errorCount++;
          errors.add('Note ${i + 1}: $e');
        }
      }
      
      // Track import
      NotesTelemetry.trackUserAction('notes_imported', {
        'total_notes': totalNotes,
        'imported_count': importedCount,
        'skipped_count': skippedCount,
        'error_count': errorCount,
        'overwrite_existing': overwriteExisting,
      });
      
      return ImportResult(
        success: errorCount < totalNotes, // Success if not all failed
        totalNotes: totalNotes,
        importedCount: importedCount,
        skippedCount: skippedCount,
        errorCount: errorCount,
        errors: errors,
        duration: stopwatch.elapsed,
      );
      
    } catch (e) {
      NotesTelemetry.trackPerformanceMetric('import_error', stopwatch.elapsed);
      
      return ImportResult(
        success: false,
        totalNotes: 0,
        importedCount: 0,
        skippedCount: 0,
        errorCount: 1,
        errors: [e.toString()],
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Import notes from file
  Future<ImportResult> importNotesFromFile(
    String filePath, {
    bool overwriteExisting = false,
    bool validateAnchors = true,
    String? targetBookId,
    Function(int current, int total)? onProgress,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw ImportException('File not found: $filePath');
      }
      
      final jsonData = await file.readAsString();
      
      return await importNotes(
        jsonData,
        overwriteExisting: overwriteExisting,
        validateAnchors: validateAnchors,
        targetBookId: targetBookId,
        onProgress: onProgress,
      );
      
    } catch (e) {
      return ImportResult(
        success: false,
        totalNotes: 0,
        importedCount: 0,
        skippedCount: 0,
        errorCount: 1,
        errors: [e.toString()],
        duration: Duration.zero,
      );
    }
  }

  /// Get export/import statistics
  Map<String, dynamic> getOperationStats() {
    // This would typically be stored in a service or database
    // For now, return empty stats
    return {
      'total_exports': 0,
      'total_imports': 0,
      'last_export': null,
      'last_import': null,
    };
  }

  // Private helper methods

  Map<String, dynamic> _noteToExportJson(Note note) {
    return {
      'id': note.id,
      'book_id': note.bookId,
      'doc_version_id': note.docVersionId,
      'logical_path': note.logicalPath,
      'char_start': note.charStart,
      'char_end': note.charEnd,
      'selected_text_normalized': note.selectedTextNormalized,
      'text_hash': note.textHash,
      'context_before': note.contextBefore,
      'context_after': note.contextAfter,
      'context_before_hash': note.contextBeforeHash,
      'context_after_hash': note.contextAfterHash,
      'rolling_before': note.rollingBefore,
      'rolling_after': note.rollingAfter,
      'status': note.status.name,
      'content_markdown': note.contentMarkdown,
      'author_user_id': note.authorUserId,
      'privacy': note.privacy.name,
      'tags': note.tags,
      'created_at': note.createdAt.toIso8601String(),
      'updated_at': note.updatedAt.toIso8601String(),
      'normalization_config': note.normalizationConfig,
    };
  }

  Note _noteFromImportJson(Map<String, dynamic> data, String? targetBookId) {
    return Note(
      id: data['id'] as String,
      bookId: targetBookId ?? (data['book_id'] as String),
      docVersionId: data['doc_version_id'] as String,
      logicalPath: (data['logical_path'] as List<dynamic>?)?.cast<String>(),
      charStart: data['char_start'] as int,
      charEnd: data['char_end'] as int,
      selectedTextNormalized: data['selected_text_normalized'] as String,
      textHash: data['text_hash'] as String,
      contextBefore: data['context_before'] as String,
      contextAfter: data['context_after'] as String,
      contextBeforeHash: data['context_before_hash'] as String,
      contextAfterHash: data['context_after_hash'] as String,
      rollingBefore: data['rolling_before'] as int,
      rollingAfter: data['rolling_after'] as int,
      status: NoteStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => NoteStatus.orphan,
      ),
      contentMarkdown: data['content_markdown'] as String,
      authorUserId: data['author_user_id'] as String,
      privacy: NotePrivacy.values.firstWhere(
        (p) => p.name == data['privacy'],
        orElse: () => NotePrivacy.private,
      ),
      tags: (data['tags'] as List<dynamic>).cast<String>(),
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
      normalizationConfig: data['normalization_config'] as String,
    );
  }

  void _validateImportFormat(Map<String, dynamic> data) {
    // Check required fields
    if (!data.containsKey('version')) {
      throw ImportException('Missing version field');
    }
    
    if (!data.containsKey('notes')) {
      throw ImportException('Missing notes field');
    }
    
    final version = data['version'] as String;
    if (version != '1.0') {
      throw ImportException('Unsupported version: $version');
    }
    
    final notes = data['notes'];
    if (notes is! List) {
      throw ImportException('Notes field must be an array');
    }
  }
}

/// Result of export operation
class ExportResult {
  final bool success;
  final int notesCount;
  final String? filePath;
  final String? jsonData;
  final Duration duration;
  final String? error;

  const ExportResult({
    required this.success,
    required this.notesCount,
    this.filePath,
    this.jsonData,
    required this.duration,
    this.error,
  });

  /// Get file size in bytes (if data is available)
  int? get fileSizeBytes => jsonData?.length;

  /// Get human-readable file size
  String get fileSizeFormatted {
    final bytes = fileSizeBytes;
    if (bytes == null) return 'Unknown';
    
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

/// Result of import operation
class ImportResult {
  final bool success;
  final int totalNotes;
  final int importedCount;
  final int skippedCount;
  final int errorCount;
  final List<String> errors;
  final Duration duration;

  const ImportResult({
    required this.success,
    required this.totalNotes,
    required this.importedCount,
    required this.skippedCount,
    required this.errorCount,
    this.errors = const [],
    required this.duration,
  });

  /// Get success rate as percentage
  double get successRate {
    if (totalNotes == 0) return 100.0;
    return (importedCount / totalNotes) * 100.0;
  }

  /// Get summary message
  String get summary {
    if (totalNotes == 0) return 'No notes to import';
    
    final parts = <String>[];
    if (importedCount > 0) parts.add('$importedCount imported');
    if (skippedCount > 0) parts.add('$skippedCount skipped');
    if (errorCount > 0) parts.add('$errorCount errors');
    
    return parts.join(', ');
  }
}

/// Exception thrown during import operations
class ImportException implements Exception {
  final String message;

  const ImportException(this.message);

  @override
  String toString() => 'ImportException: $message';
}