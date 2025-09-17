import 'dart:async';
import '../models/note.dart';
import '../models/anchor_models.dart';
import '../repository/notes_repository.dart';
import '../services/canonical_text_service.dart';
import '../services/notes_telemetry.dart';

/// Service for integrating notes with the existing book system
class NotesIntegrationService {
  static NotesIntegrationService? _instance;
  final NotesRepository _repository = NotesRepository.instance;
  final CanonicalTextService _canonicalService = CanonicalTextService.instance;
  
  // Cache for loaded notes by book
  final Map<String, List<Note>> _notesCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  NotesIntegrationService._();
  
  /// Singleton instance
  static NotesIntegrationService get instance {
    _instance ??= NotesIntegrationService._();
    return _instance!;
  }

  /// Load notes for a book and integrate with text display
  Future<BookNotesData> loadNotesForBook(String bookId, String bookText) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Check cache first
      final cachedNotes = _getCachedNotes(bookId);
      if (cachedNotes != null) {
        return BookNotesData(
          bookId: bookId,
          notes: cachedNotes,
          visibleRange: null,
          loadTime: stopwatch.elapsed,
          fromCache: true,
        );
      }
      
      // Load notes from repository
      final notes = await _repository.getNotesForBook(bookId);
      
      // Create canonical document for re-anchoring if needed
      final canonicalDoc = await _canonicalService.createCanonicalDocument(bookId);
      
      // Check if re-anchoring is needed
      final needsReanchoring = notes.any((note) => note.docVersionId != canonicalDoc.versionId);
      
      List<Note> finalNotes = notes;
      if (needsReanchoring) {
        finalNotes = await _reanchorNotesIfNeeded(notes, canonicalDoc);
      }
      
      // Cache the results
      _cacheNotes(bookId, finalNotes);
      
      // Track performance
      NotesTelemetry.trackPerformanceMetric('book_notes_load', stopwatch.elapsed);
      
      return BookNotesData(
        bookId: bookId,
        notes: finalNotes,
        visibleRange: null,
        loadTime: stopwatch.elapsed,
        fromCache: false,
        reanchoringPerformed: needsReanchoring,
      );
      
    } catch (e) {
      NotesTelemetry.trackPerformanceMetric('book_notes_load_error', stopwatch.elapsed);
      rethrow;
    }
  }

  /// Get notes for a specific visible range (for performance)
  List<Note> getNotesForVisibleRange(String bookId, VisibleCharRange range) {
    final allNotes = _notesCache[bookId] ?? [];
    
    return allNotes.where((note) {
      // Check if note overlaps with visible range
      return !(note.charEnd < range.start || note.charStart > range.end);
    }).toList();
  }

  /// Create highlight data for text rendering
  List<TextHighlight> createHighlightsForRange(
    String bookId,
    VisibleCharRange range,
  ) {
    final visibleNotes = getNotesForVisibleRange(bookId, range);
    final highlights = <TextHighlight>[];
    
    for (final note in visibleNotes) {
      // Ensure highlight is within the visible range
      final highlightStart = note.charStart.clamp(range.start, range.end);
      final highlightEnd = note.charEnd.clamp(range.start, range.end);
      
      if (highlightStart < highlightEnd) {
        highlights.add(TextHighlight(
          start: highlightStart,
          end: highlightEnd,
          noteId: note.id,
          status: note.status,
          color: _getHighlightColor(note.status),
          opacity: _getHighlightOpacity(note.status),
        ));
      }
    }
    
    // Sort by start position for consistent rendering
    highlights.sort((a, b) => a.start.compareTo(b.start));
    
    return highlights;
  }

  /// Handle text selection for note creation
  Future<Note> createNoteFromSelection(
    String bookId,
    String selectedText,
    int charStart,
    int charEnd,
    String noteContent, {
    List<String> tags = const [],
    NotePrivacy privacy = NotePrivacy.private,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Create note request
      final request = CreateNoteRequest(
        bookId: bookId,
        charStart: charStart,
        charEnd: charEnd,
        contentMarkdown: noteContent,
        authorUserId: 'current_user', // This should come from user service
        privacy: privacy,
        tags: tags,
      );
      
      // Create the note
      final note = await _repository.createNote(request);
      
      // Update cache
      _addNoteToCache(bookId, note);
      
      // Track user action
      NotesTelemetry.trackUserAction('note_created_from_selection', {
        'book_id_length': bookId.length,
        'content_length': noteContent.length,
        'tags_count': tags.length,
        'privacy': privacy.name,
      });
      
      NotesTelemetry.trackPerformanceMetric('note_creation', stopwatch.elapsed);
      
      return note;
      
    } catch (e) {
      NotesTelemetry.trackPerformanceMetric('note_creation_error', stopwatch.elapsed);
      rethrow;
    }
  }

  /// Update an existing note
  Future<Note> updateNote(
    String noteId,
    String? newContent, {
    List<String>? newTags,
    NotePrivacy? newPrivacy,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final request = UpdateNoteRequest(
        contentMarkdown: newContent,
        tags: newTags,
        privacy: newPrivacy,
      );
      
      final updatedNote = await _repository.updateNote(noteId, request);
      
      // Update cache
      _updateNoteInCache(updatedNote);
      
      NotesTelemetry.trackPerformanceMetric('note_update', stopwatch.elapsed);
      
      return updatedNote;
      
    } catch (e) {
      NotesTelemetry.trackPerformanceMetric('note_update_error', stopwatch.elapsed);
      rethrow;
    }
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      await _repository.deleteNote(noteId);
      
      // Remove from cache
      _removeNoteFromCache(noteId);
      
      NotesTelemetry.trackPerformanceMetric('note_deletion', stopwatch.elapsed);
      
    } catch (e) {
      NotesTelemetry.trackPerformanceMetric('note_deletion_error', stopwatch.elapsed);
      rethrow;
    }
  }

  /// Search notes across all books or specific book
  Future<List<Note>> searchNotes(String query, {String? bookId}) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final results = await _repository.searchNotes(query, bookId: bookId);
      
      NotesTelemetry.trackSearchPerformance(
        query,
        results.length,
        stopwatch.elapsed,
      );
      
      return results;
      
    } catch (e) {
      NotesTelemetry.trackPerformanceMetric('note_search_error', stopwatch.elapsed);
      rethrow;
    }
  }

  /// Clear cache for a specific book or all books
  void clearCache({String? bookId}) {
    if (bookId != null) {
      _notesCache.remove(bookId);
      _cacheTimestamps.remove(bookId);
    } else {
      _notesCache.clear();
      _cacheTimestamps.clear();
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final totalNotes = _notesCache.values.fold<int>(0, (sum, notes) => sum + notes.length);
    final oldestCache = _cacheTimestamps.values.isEmpty 
        ? null 
        : _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b);
    
    return {
      'cached_books': _notesCache.length,
      'total_cached_notes': totalNotes,
      'oldest_cache_age_minutes': oldestCache != null 
          ? DateTime.now().difference(oldestCache).inMinutes 
          : null,
    };
  }

  // Private helper methods

  List<Note>? _getCachedNotes(String bookId) {
    final timestamp = _cacheTimestamps[bookId];
    if (timestamp == null) return null;
    
    // Cache expires after 1 hour
    if (DateTime.now().difference(timestamp) > const Duration(hours: 1)) {
      _notesCache.remove(bookId);
      _cacheTimestamps.remove(bookId);
      return null;
    }
    
    return _notesCache[bookId];
  }

  void _cacheNotes(String bookId, List<Note> notes) {
    _notesCache[bookId] = List.from(notes);
    _cacheTimestamps[bookId] = DateTime.now();
  }

  void _addNoteToCache(String bookId, Note note) {
    final cachedNotes = _notesCache[bookId];
    if (cachedNotes != null) {
      cachedNotes.add(note);
      // Keep sorted by position
      cachedNotes.sort((a, b) => a.charStart.compareTo(b.charStart));
    }
  }

  void _updateNoteInCache(Note updatedNote) {
    for (final notes in _notesCache.values) {
      final index = notes.indexWhere((note) => note.id == updatedNote.id);
      if (index != -1) {
        notes[index] = updatedNote;
        break;
      }
    }
  }

  void _removeNoteFromCache(String noteId) {
    for (final notes in _notesCache.values) {
      notes.removeWhere((note) => note.id == noteId);
    }
  }

  Future<List<Note>> _reanchorNotesIfNeeded(
    List<Note> notes,
    CanonicalDocument canonicalDoc,
  ) async {
    if (notes.isEmpty) return notes;
    
    final stopwatch = Stopwatch()..start();
    
    try {
      final reanchoringResults = await _repository.reanchorNotesForBook(canonicalDoc.bookId);
      
      NotesTelemetry.trackBatchReanchoring(
        'integration_reanchor_${DateTime.now().millisecondsSinceEpoch}',
        notes.length,
        reanchoringResults.successCount,
        stopwatch.elapsed,
      );
      
      // Return updated notes
      return await _repository.getNotesForBook(canonicalDoc.bookId);
      
    } catch (e) {
      NotesTelemetry.trackPerformanceMetric('reanchoring_error', stopwatch.elapsed);
      // Return original notes if re-anchoring fails
      return notes;
    }
  }

  int _getHighlightColor(NoteStatus status) {
    switch (status) {
      case NoteStatus.anchored:
        return 0xFF4CAF50; // Green
      case NoteStatus.shifted:
        return 0xFFFF9800; // Orange
      case NoteStatus.orphan:
        return 0xFFF44336; // Red
    }
  }

  double _getHighlightOpacity(NoteStatus status) {
    switch (status) {
      case NoteStatus.anchored:
        return 0.3;
      case NoteStatus.shifted:
        return 0.4;
      case NoteStatus.orphan:
        return 0.5;
    }
  }
}

/// Data structure for book notes integration
class BookNotesData {
  final String bookId;
  final List<Note> notes;
  final VisibleCharRange? visibleRange;
  final Duration loadTime;
  final bool fromCache;
  final bool reanchoringPerformed;

  const BookNotesData({
    required this.bookId,
    required this.notes,
    this.visibleRange,
    required this.loadTime,
    this.fromCache = false,
    this.reanchoringPerformed = false,
  });

  /// Get notes by status
  List<Note> getNotesByStatus(NoteStatus status) {
    return notes.where((note) => note.status == status).toList();
  }

  /// Get notes count by status
  Map<NoteStatus, int> getNotesCountByStatus() {
    final counts = <NoteStatus, int>{};
    for (final note in notes) {
      counts[note.status] = (counts[note.status] ?? 0) + 1;
    }
    return counts;
  }

  /// Check if any notes need attention (orphans)
  bool get hasOrphanNotes => notes.any((note) => note.status == NoteStatus.orphan);

  /// Get performance summary
  String get performanceSummary {
    final source = fromCache ? 'cache' : 'database';
    final reanchor = reanchoringPerformed ? ' (re-anchored)' : '';
    return 'Loaded ${notes.length} notes from $source in ${loadTime.inMilliseconds}ms$reanchor';
  }
}

/// Text highlight data for rendering
class TextHighlight {
  final int start;
  final int end;
  final String noteId;
  final NoteStatus status;
  final int color;
  final double opacity;

  const TextHighlight({
    required this.start,
    required this.end,
    required this.noteId,
    required this.status,
    required this.color,
    required this.opacity,
  });

  /// Check if this highlight overlaps with another
  bool overlapsWith(TextHighlight other) {
    return !(end <= other.start || start >= other.end);
  }

  /// Get the length of this highlight
  int get length => end - start;
}