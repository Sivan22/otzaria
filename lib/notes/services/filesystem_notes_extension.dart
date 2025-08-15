import 'dart:async';
import '../models/anchor_models.dart';
import '../services/canonical_text_service.dart';
import '../services/notes_telemetry.dart';

/// Extension service for integrating notes with the existing FileSystemData
class FileSystemNotesExtension {
  static FileSystemNotesExtension? _instance;
  final CanonicalTextService _canonicalService = CanonicalTextService.instance;
  
  // Cache for canonical documents
  final Map<String, CanonicalDocument> _canonicalCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, String> _bookVersions = {};
  
  FileSystemNotesExtension._();
  
  /// Singleton instance
  static FileSystemNotesExtension get instance {
    _instance ??= FileSystemNotesExtension._();
    return _instance!;
  }

  /// Get or create canonical document for a book
  Future<CanonicalDocument> getCanonicalDocument(
    String bookId,
    String bookText,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Check if we have a cached version
      final cached = _getCachedCanonicalDocument(bookId, bookText);
      if (cached != null) {
        NotesTelemetry.trackPerformanceMetric('canonical_doc_cache_hit', stopwatch.elapsed);
        return cached;
      }
      
      // Create new canonical document
      final canonicalDoc = await _canonicalService.createCanonicalDocument(bookId);
      
      // Cache the result
      _cacheCanonicalDocument(bookId, canonicalDoc, bookText);
      
      NotesTelemetry.trackPerformanceMetric('canonical_doc_creation', stopwatch.elapsed);
      
      return canonicalDoc;
      
    } catch (e) {
      NotesTelemetry.trackPerformanceMetric('canonical_doc_error', stopwatch.elapsed);
      rethrow;
    }
  }

  /// Check if book content has changed since last canonical document creation
  bool hasBookContentChanged(String bookId, String currentBookText) {
    final cachedVersion = _bookVersions[bookId];
    if (cachedVersion == null) return true;
    
    final currentVersion = _calculateBookVersion(currentBookText);
    return cachedVersion != currentVersion;
  }

  /// Get book version information
  BookVersionInfo getBookVersionInfo(String bookId, String bookText) {
    final currentVersion = _calculateBookVersion(bookText);
    final cachedVersion = _bookVersions[bookId];
    final hasChanged = cachedVersion != null && cachedVersion != currentVersion;
    
    return BookVersionInfo(
      bookId: bookId,
      currentVersion: currentVersion,
      cachedVersion: cachedVersion,
      hasChanged: hasChanged,
      textLength: bookText.length,
      lastChecked: DateTime.now(),
    );
  }

  /// Preload canonical documents for multiple books
  Future<Map<String, CanonicalDocument>> preloadCanonicalDocuments(
    Map<String, String> booksData, {
    Function(int current, int total)? onProgress,
  }) async {
    final results = <String, CanonicalDocument>{};
    final total = booksData.length;
    int current = 0;
    
    for (final entry in booksData.entries) {
      try {
        final canonicalDoc = await getCanonicalDocument(entry.key, entry.value);
        results[entry.key] = canonicalDoc;
        
        current++;
        onProgress?.call(current, total);
        
      } catch (e) {
        // Log error but continue with other books
        NotesTelemetry.trackPerformanceMetric('preload_canonical_error', Duration.zero);
      }
    }
    
    return results;
  }

  /// Clear cache for specific book or all books
  void clearCanonicalCache({String? bookId}) {
    if (bookId != null) {
      _canonicalCache.remove(bookId);
      _cacheTimestamps.remove(bookId);
      _bookVersions.remove(bookId);
    } else {
      _canonicalCache.clear();
      _cacheTimestamps.clear();
      _bookVersions.clear();
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    final cacheAges = _cacheTimestamps.values.map((timestamp) => 
        now.difference(timestamp).inMinutes).toList();
    
    return {
      'cached_documents': _canonicalCache.length,
      'average_cache_age_minutes': cacheAges.isEmpty 
          ? 0 
          : cacheAges.reduce((a, b) => a + b) / cacheAges.length,
      'oldest_cache_minutes': cacheAges.isEmpty ? 0 : cacheAges.reduce((a, b) => a > b ? a : b),
      'cache_memory_estimate_mb': _estimateCacheMemoryUsage() / (1024 * 1024),
    };
  }

  /// Optimize cache by removing old entries
  void optimizeCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    // Find expired entries (older than 2 hours)
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > const Duration(hours: 2)) {
        expiredKeys.add(entry.key);
      }
    }
    
    // Remove expired entries
    for (final key in expiredKeys) {
      _canonicalCache.remove(key);
      _cacheTimestamps.remove(key);
      _bookVersions.remove(key);
    }
    
    // If cache is still too large, remove oldest entries
    while (_canonicalCache.length > 50) { // Max 50 cached documents
      final oldestKey = _cacheTimestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      
      _canonicalCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
      _bookVersions.remove(oldestKey);
    }
  }

  /// Export cache data for backup
  Map<String, dynamic> exportCacheData() {
    return {
      'version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'book_versions': _bookVersions,
      'cache_timestamps': _cacheTimestamps.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
    };
  }

  /// Import cache data from backup
  void importCacheData(Map<String, dynamic> data) {
    try {
      final bookVersions = data['book_versions'] as Map<String, dynamic>?;
      if (bookVersions != null) {
        _bookVersions.clear();
        _bookVersions.addAll(bookVersions.cast<String, String>());
      }
      
      final cacheTimestamps = data['cache_timestamps'] as Map<String, dynamic>?;
      if (cacheTimestamps != null) {
        _cacheTimestamps.clear();
        for (final entry in cacheTimestamps.entries) {
          _cacheTimestamps[entry.key] = DateTime.parse(entry.value as String);
        }
      }
      
    } catch (e) {
      // If import fails, just clear the cache
      clearCanonicalCache();
    }
  }

  // Private helper methods

  CanonicalDocument? _getCachedCanonicalDocument(String bookId, String bookText) {
    final timestamp = _cacheTimestamps[bookId];
    if (timestamp == null) return null;
    
    // Check if cache is expired (1 hour)
    if (DateTime.now().difference(timestamp) > const Duration(hours: 1)) {
      _canonicalCache.remove(bookId);
      _cacheTimestamps.remove(bookId);
      _bookVersions.remove(bookId);
      return null;
    }
    
    // Check if book content has changed
    if (hasBookContentChanged(bookId, bookText)) {
      _canonicalCache.remove(bookId);
      _cacheTimestamps.remove(bookId);
      _bookVersions.remove(bookId);
      return null;
    }
    
    return _canonicalCache[bookId];
  }

  void _cacheCanonicalDocument(
    String bookId,
    CanonicalDocument canonicalDoc,
    String bookText,
  ) {
    _canonicalCache[bookId] = canonicalDoc;
    _cacheTimestamps[bookId] = DateTime.now();
    _bookVersions[bookId] = _calculateBookVersion(bookText);
    
    // Optimize cache if it gets too large
    if (_canonicalCache.length > 100) {
      optimizeCache();
    }
  }

  String _calculateBookVersion(String bookText) {
    // Simple hash-based version calculation
    // In a real implementation, this might use a more sophisticated algorithm
    return bookText.hashCode.toString();
  }

  int _estimateCacheMemoryUsage() {
    int totalSize = 0;
    
    for (final doc in _canonicalCache.values) {
      // Estimate memory usage for each canonical document
      totalSize += doc.canonicalText.length * 2; // UTF-16 encoding
      totalSize += doc.textHashIndex.length * 50; // Rough estimate for hash index
      totalSize += doc.contextHashIndex.length * 50; // Rough estimate for context index
      totalSize += doc.rollingHashIndex.length * 20; // Rough estimate for rolling hash index
    }
    
    return totalSize;
  }
}

/// Information about book version and changes
class BookVersionInfo {
  final String bookId;
  final String currentVersion;
  final String? cachedVersion;
  final bool hasChanged;
  final int textLength;
  final DateTime lastChecked;

  const BookVersionInfo({
    required this.bookId,
    required this.currentVersion,
    this.cachedVersion,
    required this.hasChanged,
    required this.textLength,
    required this.lastChecked,
  });

  /// Check if this is the first time we're seeing this book
  bool get isFirstTime => cachedVersion == null;

  /// Get a summary of the version status
  String get statusSummary {
    if (isFirstTime) return 'First load';
    if (hasChanged) return 'Content changed';
    return 'Up to date';
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'book_id': bookId,
      'current_version': currentVersion,
      'cached_version': cachedVersion,
      'has_changed': hasChanged,
      'text_length': textLength,
      'last_checked': lastChecked.toIso8601String(),
    };
  }

  /// Create from JSON
  factory BookVersionInfo.fromJson(Map<String, dynamic> json) {
    return BookVersionInfo(
      bookId: json['book_id'] as String,
      currentVersion: json['current_version'] as String,
      cachedVersion: json['cached_version'] as String?,
      hasChanged: json['has_changed'] as bool,
      textLength: json['text_length'] as int,
      lastChecked: DateTime.parse(json['last_checked'] as String),
    );
  }
}