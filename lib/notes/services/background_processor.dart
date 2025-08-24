import 'dart:isolate';
import 'dart:async';
import '../models/note.dart';
import '../models/anchor_models.dart';
import '../services/anchoring_service.dart';
import '../services/text_normalizer.dart';
import '../services/notes_telemetry.dart';
import '../config/notes_config.dart';

/// Service for processing heavy note operations in background isolates
class BackgroundProcessor {
  static BackgroundProcessor? _instance;
  final Map<String, Completer<List<AnchorResult>>> _activeRequests = {};
  final Map<String, Completer<List<Note>>> _activeSearchRequests = {};
  final Map<String, Completer<String>> _activeNormalizationRequests = {};
  final Map<String, Completer<String>> _activeHashRequests = {};
  final Map<String, Completer<Map<String, dynamic>>> _activeBatchRequests = {};
  final Map<String, Completer<List<dynamic>>> _activeParallelRequests = {};
  final Map<String, dynamic> _resultCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  int _requestCounter = 0;
  
  // Cache settings
  static const Duration _cacheExpiration = Duration(minutes: 10);
  static const int _maxCacheSize = 100;
  
  // Performance monitoring
  final Map<String, List<Duration>> _performanceMetrics = {};
  final Map<String, int> _operationCounts = {};
  int _cacheHits = 0;
  int _cacheMisses = 0;
  
  BackgroundProcessor._();
  
  /// Singleton instance
  static BackgroundProcessor get instance {
    _instance ??= BackgroundProcessor._();
    return _instance!;
  }

  /// Process text search in background isolate
  Future<List<Note>> processTextSearch(
    String query,
    List<Note> allNotes, {
    String? bookId,
  }) async {
    // Check cache first
    final cacheKey = _generateSearchCacheKey(query, bookId, allNotes.length);
    final cachedResult = _getCachedResult<List<Note>>(cacheKey);
    if (cachedResult != null) {
      return cachedResult;
    }
    final requestId = _generateRequestId();
    final stopwatch = Stopwatch()..start();
    
    try {
      // Create completer for this request
      final completer = Completer<List<Note>>();
      _activeSearchRequests[requestId] = completer;
      
      // Prepare data for isolate
      final isolateData = IsolateSearchData(
        requestId: requestId,
        query: query,
        notes: allNotes,
        bookId: bookId,
      );
      
      // Spawn isolate for heavy computation
      final receivePort = ReceivePort();
      await Isolate.spawn(_searchNotesIsolate, [receivePort.sendPort, isolateData]);
      
      // Listen for results
      receivePort.listen((message) {
        if (message is IsolateSearchResult) {
          final activeCompleter = _activeSearchRequests.remove(message.requestId);
          if (activeCompleter != null && !activeCompleter.isCompleted) {
            if (message.error != null) {
              activeCompleter.completeError(message.error!);
            } else {
              activeCompleter.complete(message.results);
            }
          }
        }
        receivePort.close();
      });
      
      // Wait for completion with timeout
      final results = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _activeSearchRequests.remove(requestId);
          throw TimeoutException('Search timed out', const Duration(seconds: 10));
        },
      );
      
      // Track search performance
      NotesTelemetry.trackSearchPerformance(
        query,
        results.length,
        stopwatch.elapsed,
      );
      
      // Track internal performance
      _trackPerformance('text_search', stopwatch.elapsed);
      
      // Cache the results
      _cacheResult(cacheKey, results);
      
      return results;
    } catch (e) {
      _activeSearchRequests.remove(requestId);
      rethrow;
    }
  }

  /// Process hash generation in background isolate
  Future<String> processHashGeneration(
    String text,
  ) async {
    // Check cache first
    final cacheKey = _generateHashCacheKey(text);
    final cachedResult = _getCachedResult<String>(cacheKey);
    if (cachedResult != null) {
      return cachedResult;
    }
    
    final requestId = _generateRequestId();
    final stopwatch = Stopwatch()..start();
    
    try {
      // Create completer for this request
      final completer = Completer<String>();
      _activeHashRequests[requestId] = completer;
      
      // Prepare data for isolate
      final isolateData = IsolateHashData(
        requestId: requestId,
        text: text,
      );
      
      // Spawn isolate for heavy computation
      final receivePort = ReceivePort();
      await Isolate.spawn(_generateHashIsolate, [receivePort.sendPort, isolateData]);
      
      // Listen for results
      receivePort.listen((message) {
        if (message is IsolateHashResult) {
          final activeCompleter = _activeHashRequests.remove(message.requestId);
          if (activeCompleter != null && !activeCompleter.isCompleted) {
            if (message.error != null) {
              activeCompleter.completeError(message.error!);
            } else {
              activeCompleter.complete(message.result!);
            }
          }
        }
        receivePort.close();
      });
      
      // Wait for completion with timeout
      final result = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _activeHashRequests.remove(requestId);
          throw TimeoutException('Hash generation timed out', const Duration(seconds: 5));
        },
      );
      
      // Track performance
      _trackPerformance('hash_generation', stopwatch.elapsed);
      
      // Cache the result
      _cacheResult(cacheKey, result);
      
      return result;
    } catch (e) {
      _activeHashRequests.remove(requestId);
      rethrow;
    }
  }

  /// Process text normalization in background isolate
  Future<String> processTextNormalization(
    String text,
    Map<String, dynamic> configData,
  ) async {
    // Check cache first
    final cacheKey = _generateNormalizationCacheKey(text, configData);
    final cachedResult = _getCachedResult<String>(cacheKey);
    if (cachedResult != null) {
      return cachedResult;
    }
    
    final requestId = _generateRequestId();
    final stopwatch = Stopwatch()..start();
    
    try {
      // Create completer for this request
      final completer = Completer<String>();
      _activeNormalizationRequests[requestId] = completer;
      
      // Prepare data for isolate
      final isolateData = IsolateNormalizationData(
        requestId: requestId,
        text: text,
        configData: configData,
      );
      
      // Spawn isolate for heavy computation
      final receivePort = ReceivePort();
      await Isolate.spawn(_normalizeTextIsolate, [receivePort.sendPort, isolateData]);
      
      // Listen for results
      receivePort.listen((message) {
        if (message is IsolateNormalizationResult) {
          final activeCompleter = _activeNormalizationRequests.remove(message.requestId);
          if (activeCompleter != null && !activeCompleter.isCompleted) {
            if (message.error != null) {
              activeCompleter.completeError(message.error!);
            } else {
              activeCompleter.complete(message.result);
            }
          }
        }
        receivePort.close();
      });
      
      // Wait for completion with timeout
      final result = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _activeNormalizationRequests.remove(requestId);
          throw TimeoutException('Normalization timed out', const Duration(seconds: 5));
        },
      );
      
      // Track performance
      _trackPerformance('text_normalization', stopwatch.elapsed);
      
      // Cache the result
      _cacheResult(cacheKey, result);
      
      return result;
    } catch (e) {
      _activeNormalizationRequests.remove(requestId);
      rethrow;
    }
  }

  /// Process batch operations on notes in background isolate
  Future<Map<String, dynamic>> processBatchOperation(
    String operationType,
    List<Note> notes,
    Map<String, dynamic> parameters,
  ) async {
    final requestId = _generateRequestId();
    final stopwatch = Stopwatch()..start();
    
    try {
      // Create completer for this request
      final completer = Completer<Map<String, dynamic>>();
      _activeBatchRequests[requestId] = completer;
      
      // Prepare data for isolate
      final isolateData = IsolateBatchData(
        requestId: requestId,
        operationType: operationType,
        notes: notes,
        parameters: parameters,
      );
      
      // Spawn isolate for heavy computation
      final receivePort = ReceivePort();
      await Isolate.spawn(_batchOperationIsolate, [receivePort.sendPort, isolateData]);
      
      // Listen for results
      receivePort.listen((message) {
        if (message is IsolateBatchResult) {
          final activeCompleter = _activeBatchRequests.remove(message.requestId);
          if (activeCompleter != null && !activeCompleter.isCompleted) {
            if (message.error != null) {
              activeCompleter.completeError(message.error!);
            } else {
              activeCompleter.complete(message.result);
            }
          }
        }
        receivePort.close();
      });
      
      // Wait for completion with timeout (longer for batch operations)
      final result = await completer.future.timeout(
        Duration(seconds: 30 + (notes.length ~/ 10)), // Scale with number of notes
        onTimeout: () {
          _activeBatchRequests.remove(requestId);
          throw TimeoutException('Batch operation timed out', Duration(seconds: 30 + (notes.length ~/ 10)));
        },
      );
      
      // Track batch performance
      NotesTelemetry.trackPerformanceMetric(
        'batch_$operationType',
        stopwatch.elapsed,
      );
      
      return result;
    } catch (e) {
      _activeBatchRequests.remove(requestId);
      rethrow;
    }
  }

  /// Process multiple operations in parallel isolates
  Future<List<T>> processParallelOperations<T>(
    List<dynamic> items,
    String operationType,
    Map<String, dynamic> parameters, {
    int? maxConcurrency,
  }) async {
    final requestId = _generateRequestId();
    final stopwatch = Stopwatch()..start();
    
    // Determine optimal concurrency based on system and data size
    final concurrency = maxConcurrency ?? _calculateOptimalConcurrency(items.length);
    
    try {
      // Create completer for this request
      final completer = Completer<List<dynamic>>();
      _activeParallelRequests[requestId] = completer;
      
      // Split items into chunks for parallel processing
      final chunks = _splitIntoChunks(items, concurrency);
      
      // Process chunks in parallel isolates
      final futures = <Future<List<dynamic>>>[];
      
      for (int i = 0; i < chunks.length; i++) {
        final chunkRequestId = '${requestId}_chunk_$i';
        final isolateData = IsolateParallelData(
          requestId: chunkRequestId,
          operationType: operationType,
          items: chunks[i],
          parameters: parameters,
        );
        
        futures.add(_processChunkInIsolate(isolateData));
      }
      
      // Wait for all chunks to complete
      final results = await Future.wait(futures);
      
      // Flatten results
      final flatResults = <dynamic>[];
      for (final chunkResult in results) {
        flatResults.addAll(chunkResult);
      }
      
      // Track parallel performance
      NotesTelemetry.trackPerformanceMetric(
        'parallel_$operationType',
        stopwatch.elapsed,
      );
      
      _activeParallelRequests.remove(requestId);
      return flatResults.cast<T>();
    } catch (e) {
      _activeParallelRequests.remove(requestId);
      rethrow;
    }
  }

  /// Calculate optimal concurrency based on data size and system capabilities
  int _calculateOptimalConcurrency(int itemCount) {
    // Base concurrency on available processors (simulate with reasonable defaults)
    const maxConcurrency = 4; // Reasonable default for most systems
    
    if (itemCount < 10) return 1;
    if (itemCount < 50) return 2;
    if (itemCount < 200) return 3;
    return maxConcurrency;
  }

  /// Split items into chunks for parallel processing
  List<List<T>> _splitIntoChunks<T>(List<T> items, int chunkCount) {
    if (items.isEmpty || chunkCount <= 0) return [];
    if (chunkCount >= items.length) return items.map((item) => [item]).toList();
    
    final chunks = <List<T>>[];
    final chunkSize = (items.length / chunkCount).ceil();
    
    for (int i = 0; i < items.length; i += chunkSize) {
      final end = (i + chunkSize < items.length) ? i + chunkSize : items.length;
      chunks.add(items.sublist(i, end));
    }
    
    return chunks;
  }

  /// Process a chunk of items in an isolate
  Future<List<dynamic>> _processChunkInIsolate(IsolateParallelData data) async {
    final completer = Completer<List<dynamic>>();
    
    try {
      // Spawn isolate for chunk processing
      final receivePort = ReceivePort();
      await Isolate.spawn(_parallelChunkIsolate, [receivePort.sendPort, data]);
      
      // Listen for results
      receivePort.listen((message) {
        if (message is IsolateParallelResult) {
          if (message.error != null) {
            completer.completeError(message.error!);
          } else {
            completer.complete(message.results ?? []);
          }
        }
        receivePort.close();
      });
      
      // Wait for completion with timeout
      return await completer.future.timeout(
        Duration(seconds: 10 + (data.items.length ~/ 5)), // Scale with chunk size
        onTimeout: () {
          throw TimeoutException('Parallel chunk processing timed out', 
              Duration(seconds: 10 + (data.items.length ~/ 5)));
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Process re-anchoring for multiple notes in background isolate
  Future<List<AnchorResult>> processReanchoring(
    List<Note> notes,
    CanonicalDocument document,
  ) async {
    final requestId = _generateRequestId();
    final stopwatch = Stopwatch()..start();
    
    try {
      // Create completer for this request
      final completer = Completer<List<AnchorResult>>();
      _activeRequests[requestId] = completer;
      
      // Prepare data for isolate
      final isolateData = IsolateReanchoringData(
        requestId: requestId,
        notes: notes,
        document: document,
        config: _createProcessingConfig(),
      );
      
      // Spawn isolate for heavy computation
      final receivePort = ReceivePort();
      await Isolate.spawn(_reanchorNotesIsolate, [receivePort.sendPort, isolateData]);
      
      // Listen for results
      receivePort.listen((message) {
        if (message is IsolateReanchoringResult) {
          final activeCompleter = _activeRequests.remove(message.requestId);
          if (activeCompleter != null && !activeCompleter.isCompleted) {
            if (message.error != null) {
              activeCompleter.completeError(message.error!);
            } else {
              activeCompleter.complete(message.results);
            }
          }
        }
        receivePort.close();
      });
      
      // Wait for completion with timeout
      final results = await completer.future.timeout(
        Duration(milliseconds: NotesConfig.reanchoringTimeoutMs * notes.length),
        onTimeout: () {
          _activeRequests.remove(requestId);
          throw TimeoutException('Re-anchoring timed out', 
              Duration(milliseconds: NotesConfig.reanchoringTimeoutMs * notes.length));
        },
      );
      
      // Track batch performance
      final successCount = results.where((r) => r.isSuccess).length;
      NotesTelemetry.trackBatchReanchoring(
        requestId,
        notes.length,
        successCount,
        stopwatch.elapsed,
      );
      
      return results;
    } catch (e) {
      _activeRequests.remove(requestId);
      rethrow;
    }
  }

  /// Cancel an active re-anchoring request
  void cancelRequest(String requestId) {
    final completer = _activeRequests.remove(requestId);
    if (completer != null && !completer.isCompleted) {
      completer.completeError('Request cancelled');
    }
  }

  /// Cancel all active requests
  void cancelAllRequests() {
    for (final entry in _activeRequests.entries) {
      if (!entry.value.isCompleted) {
        entry.value.completeError('All requests cancelled');
      }
    }
    _activeRequests.clear();
    
    for (final entry in _activeSearchRequests.entries) {
      if (!entry.value.isCompleted) {
        entry.value.completeError('All requests cancelled');
      }
    }
    _activeSearchRequests.clear();
    
    for (final entry in _activeNormalizationRequests.entries) {
      if (!entry.value.isCompleted) {
        entry.value.completeError('All requests cancelled');
      }
    }
    _activeNormalizationRequests.clear();
    
    for (final entry in _activeHashRequests.entries) {
      if (!entry.value.isCompleted) {
        entry.value.completeError('All requests cancelled');
      }
    }
    _activeHashRequests.clear();
    
    for (final entry in _activeBatchRequests.entries) {
      if (!entry.value.isCompleted) {
        entry.value.completeError('All requests cancelled');
      }
    }
    _activeBatchRequests.clear();
    
    for (final entry in _activeParallelRequests.entries) {
      if (!entry.value.isCompleted) {
        entry.value.completeError('All requests cancelled');
      }
    }
    _activeParallelRequests.clear();
  }

  /// Generate unique request ID with epoch for stale work detection
  String _generateRequestId() {
    final epoch = DateTime.now().millisecondsSinceEpoch;
    return '${++_requestCounter}_$epoch';
  }

  /// Create processing configuration
  ProcessingConfig _createProcessingConfig() {
    return ProcessingConfig(
      maxReanchoringTimeMs: NotesConfig.reanchoringTimeoutMs,
      maxBatchSize: NotesConfig.maxReanchoringBatchSize,
      fuzzyMatchingEnabled: NotesConfig.fuzzyMatchingEnabled,
    );
  }

  /// Get statistics about active requests
  Map<String, dynamic> getProcessingStats() {
    return {
      'active_reanchoring_requests': _activeRequests.length,
      'active_search_requests': _activeSearchRequests.length,
      'active_normalization_requests': _activeNormalizationRequests.length,
      'active_hash_requests': _activeHashRequests.length,
      'active_batch_requests': _activeBatchRequests.length,
      'active_parallel_requests': _activeParallelRequests.length,
      'total_active_requests': _activeRequests.length + _activeSearchRequests.length + _activeNormalizationRequests.length + _activeHashRequests.length + _activeBatchRequests.length + _activeParallelRequests.length,
      'request_counter': _requestCounter,
      'oldest_request_age': _getOldestRequestAge(),
      'cache_stats': getCacheStats(),
      'performance_stats': getPerformanceStats(),
      'performance_recommendations': getPerformanceRecommendations(),
    };
  }

  /// Get age of oldest active request in milliseconds
  int? _getOldestRequestAge() {
    if (_activeRequests.isEmpty) return null;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    int? oldestEpoch;
    
    for (final requestId in _activeRequests.keys) {
      final parts = requestId.split('_');
      if (parts.length >= 2) {
        final epoch = int.tryParse(parts.last);
        if (epoch != null) {
          oldestEpoch = oldestEpoch == null ? epoch : (epoch < oldestEpoch ? epoch : oldestEpoch);
        }
      }
    }
    
    return oldestEpoch != null ? now - oldestEpoch : null;
  }

  /// Check if result is cached and still valid
  T? _getCachedResult<T>(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) {
      _cacheMisses++;
      return null;
    }
    
    // Check if cache is expired
    if (DateTime.now().difference(timestamp) > _cacheExpiration) {
      _resultCache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
      _cacheMisses++;
      return null;
    }
    
    _cacheHits++;
    return _resultCache[cacheKey] as T?;
  }

  /// Cache a result with timestamp
  void _cacheResult<T>(String cacheKey, T result) {
    // Clean old cache entries if we're at capacity
    if (_resultCache.length >= _maxCacheSize) {
      _cleanOldCacheEntries();
    }
    
    _resultCache[cacheKey] = result;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  /// Clean old cache entries to make room for new ones
  void _cleanOldCacheEntries() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    // Find expired entries
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiration) {
        expiredKeys.add(entry.key);
      }
    }
    
    // Remove expired entries
    for (final key in expiredKeys) {
      _resultCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    // If still at capacity, remove oldest entries
    if (_resultCache.length >= _maxCacheSize) {
      final sortedEntries = _cacheTimestamps.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      final toRemove = sortedEntries.take(_maxCacheSize ~/ 4); // Remove 25%
      for (final entry in toRemove) {
        _resultCache.remove(entry.key);
        _cacheTimestamps.remove(entry.key);
      }
    }
  }

  /// Generate cache key for search operations
  String _generateSearchCacheKey(String query, String? bookId, int notesCount) {
    return 'search_${query.hashCode}_${bookId ?? 'all'}_$notesCount';
  }

  /// Generate cache key for normalization operations
  String _generateNormalizationCacheKey(String text, Map<String, dynamic> config) {
    return 'normalize_${text.hashCode}_${config.hashCode}';
  }

  /// Generate cache key for hash operations
  String _generateHashCacheKey(String text) {
    return 'hash_${text.hashCode}';
  }

  /// Clear all cached results
  void clearCache() {
    _resultCache.clear();
    _cacheTimestamps.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    int expiredCount = 0;
    
    for (final timestamp in _cacheTimestamps.values) {
      if (now.difference(timestamp) > _cacheExpiration) {
        expiredCount++;
      }
    }
    
    return {
      'total_cached_items': _resultCache.length,
      'expired_items': expiredCount,
      'cache_hit_ratio': _calculateCacheHitRatio(),
      'cache_size_bytes': _estimateCacheSize(),
    };
  }

  /// Calculate cache hit ratio
  double _calculateCacheHitRatio() {
    final totalRequests = _cacheHits + _cacheMisses;
    return totalRequests > 0 ? _cacheHits / totalRequests : 0.0;
  }

  /// Estimate cache size in bytes (simplified)
  int _estimateCacheSize() {
    // Rough estimation - in real implementation you'd want more accurate measurement
    return _resultCache.length * 1024; // Assume 1KB per entry on average
  }

  /// Track performance metric for an operation
  void _trackPerformance(String operationType, Duration duration) {
    _performanceMetrics.putIfAbsent(operationType, () => <Duration>[]);
    _performanceMetrics[operationType]!.add(duration);
    
    // Keep only last 100 measurements per operation
    if (_performanceMetrics[operationType]!.length > 100) {
      _performanceMetrics[operationType]!.removeAt(0);
    }
    
    _operationCounts[operationType] = (_operationCounts[operationType] ?? 0) + 1;
  }

  /// Get performance statistics for all operations
  Map<String, dynamic> getPerformanceStats() {
    final stats = <String, dynamic>{};
    
    for (final entry in _performanceMetrics.entries) {
      final durations = entry.value;
      if (durations.isNotEmpty) {
        final totalMs = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
        final avgMs = totalMs / durations.length;
        final minMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);
        final maxMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);
        
        stats[entry.key] = {
          'count': _operationCounts[entry.key] ?? 0,
          'average_ms': avgMs.round(),
          'min_ms': minMs,
          'max_ms': maxMs,
          'total_ms': totalMs,
        };
      }
    }
    
    return {
      'operations': stats,
      'cache_hits': _cacheHits,
      'cache_misses': _cacheMisses,
      'cache_hit_ratio': _calculateCacheHitRatio(),
      'total_operations': _operationCounts.values.fold<int>(0, (sum, count) => sum + count),
    };
  }

  /// Reset performance statistics
  void resetPerformanceStats() {
    _performanceMetrics.clear();
    _operationCounts.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
  }

  /// Get recommendations for performance optimization
  List<String> getPerformanceRecommendations() {
    final recommendations = <String>[];
    final stats = getPerformanceStats();
    
    // Check cache hit ratio
    final hitRatio = stats['cache_hit_ratio'] as double;
    if (hitRatio < 0.5) {
      recommendations.add('Consider increasing cache size or expiration time - current hit ratio: ${(hitRatio * 100).toStringAsFixed(1)}%');
    }
    
    // Check for slow operations
    final operations = stats['operations'] as Map<String, dynamic>;
    for (final entry in operations.entries) {
      final opStats = entry.value as Map<String, dynamic>;
      final avgMs = opStats['average_ms'] as int;
      
      if (avgMs > 1000) {
        recommendations.add('${entry.key} operations are slow (avg: ${avgMs}ms) - consider optimization');
      }
    }
    
    // Check for high operation counts
    final totalOps = stats['total_operations'] as int;
    if (totalOps > 1000) {
      recommendations.add('High operation count ($totalOps) - consider batching or caching strategies');
    }
    
    return recommendations;
  }
}

/// Static method to run in isolate for re-anchoring notes
void _reanchorNotesIsolate(List<dynamic> args) async {
  final sendPort = args[0] as SendPort;
  final data = args[1] as IsolateReanchoringData;
  
  try {
    final results = <AnchorResult>[];
    final anchoringService = AnchoringService.instance;
    
    // Process each note with timeout
    for (final note in data.notes) {
      try {
        final stopwatch = Stopwatch()..start();
        
        final result = await anchoringService.reanchorNote(note, data.document)
            .timeout(Duration(milliseconds: data.config.maxReanchoringTimeMs));
        
        results.add(result);
        
        // Track individual performance
        NotesTelemetry.trackPerformanceMetric(
          'isolate_reanchor',
          stopwatch.elapsed,
        );
      } catch (e) {
        results.add(AnchorResult(
          NoteStatus.orphan,
          errorMessage: 'Re-anchoring failed: $e',
        ));
      }
    }
    
    // Send results back
    sendPort.send(IsolateReanchoringResult(
      requestId: data.requestId,
      results: results,
    ));
  } catch (e) {
    // Send error back
    sendPort.send(IsolateReanchoringResult(
      requestId: data.requestId,
      error: e.toString(),
    ));
  }
}

/// Data structure for isolate communication
class IsolateReanchoringData {
  final String requestId;
  final List<Note> notes;
  final CanonicalDocument document;
  final ProcessingConfig config;

  const IsolateReanchoringData({
    required this.requestId,
    required this.notes,
    required this.document,
    required this.config,
  });
}

/// Result structure for isolate communication
class IsolateReanchoringResult {
  final String requestId;
  final List<AnchorResult>? results;
  final String? error;

  const IsolateReanchoringResult({
    required this.requestId,
    this.results,
    this.error,
  });
}

/// Configuration for background processing
class ProcessingConfig {
  final int maxReanchoringTimeMs;
  final int maxBatchSize;
  final bool fuzzyMatchingEnabled;

  const ProcessingConfig({
    required this.maxReanchoringTimeMs,
    required this.maxBatchSize,
    required this.fuzzyMatchingEnabled,
  });
}

/// Exception for timeout operations
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  const TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message (timeout: $timeout)';
}

/// Static method to run in isolate for searching notes
void _searchNotesIsolate(List<dynamic> args) async {
  final sendPort = args[0] as SendPort;
  final data = args[1] as IsolateSearchData;
  
  try {
    final results = <Note>[];
    final queryLower = data.query.toLowerCase();
    
    // Simple text search in content and tags
    for (final note in data.notes) {
      // Filter by book if specified
      if (data.bookId != null && note.bookId != data.bookId) {
        continue;
      }
      
      // Search in content
      if (note.contentMarkdown.toLowerCase().contains(queryLower)) {
        results.add(note);
        continue;
      }
      
      // Search in tags
      if (note.tags.any((tag) => tag.toLowerCase().contains(queryLower))) {
        results.add(note);
        continue;
      }
      
      // Search in selected text
      if (note.selectedTextNormalized.toLowerCase().contains(queryLower)) {
        results.add(note);
        continue;
      }
    }
    
    // Sort by relevance (simple scoring)
    results.sort((a, b) {
      int scoreA = _calculateRelevanceScore(a, queryLower);
      int scoreB = _calculateRelevanceScore(b, queryLower);
      return scoreB.compareTo(scoreA); // Higher score first
    });
    
    // Send results back
    sendPort.send(IsolateSearchResult(
      requestId: data.requestId,
      results: results,
    ));
  } catch (e) {
    // Send error back
    sendPort.send(IsolateSearchResult(
      requestId: data.requestId,
      error: e.toString(),
    ));
  }
}

/// Calculate relevance score for search results
int _calculateRelevanceScore(Note note, String queryLower) {
  int score = 0;
  
  // Content matches (highest priority)
  final contentMatches = queryLower.allMatches(note.contentMarkdown.toLowerCase()).length;
  score += contentMatches * 10;
  
  // Tag matches (medium priority)
  for (final tag in note.tags) {
    if (tag.toLowerCase().contains(queryLower)) {
      score += 5;
    }
  }
  
  // Selected text matches (lower priority)
  final selectedMatches = queryLower.allMatches(note.selectedTextNormalized.toLowerCase()).length;
  score += selectedMatches * 3;
  
  // Boost recent notes
  final daysSinceUpdate = DateTime.now().difference(note.updatedAt).inDays;
  if (daysSinceUpdate < 7) {
    score += 2;
  } else if (daysSinceUpdate < 30) {
    score += 1;
  }
  
  return score;
}

/// Static method to run in isolate for text normalization
void _normalizeTextIsolate(List<dynamic> args) async {
  final sendPort = args[0] as SendPort;
  final data = args[1] as IsolateNormalizationData;
  
  try {
    // Reconstruct normalization config from data
    final config = NormalizationConfig.fromMap(data.configData);
    
    // Perform normalization
    final result = TextNormalizer.normalize(data.text, config);
    
    // Send result back
    sendPort.send(IsolateNormalizationResult(
      requestId: data.requestId,
      result: result,
    ));
  } catch (e) {
    // Send error back
    sendPort.send(IsolateNormalizationResult(
      requestId: data.requestId,
      error: e.toString(),
    ));
  }
}

/// Data structure for search isolate communication
class IsolateSearchData {
  final String requestId;
  final String query;
  final List<Note> notes;
  final String? bookId;

  const IsolateSearchData({
    required this.requestId,
    required this.query,
    required this.notes,
    this.bookId,
  });
}

/// Result structure for search isolate communication
class IsolateSearchResult {
  final String requestId;
  final List<Note>? results;
  final String? error;

  const IsolateSearchResult({
    required this.requestId,
    this.results,
    this.error,
  });
}

/// Data structure for normalization isolate communication
class IsolateNormalizationData {
  final String requestId;
  final String text;
  final Map<String, dynamic> configData;

  const IsolateNormalizationData({
    required this.requestId,
    required this.text,
    required this.configData,
  });
}

/// Result structure for normalization isolate communication
class IsolateNormalizationResult {
  final String requestId;
  final String? result;
  final String? error;

  const IsolateNormalizationResult({
    required this.requestId,
    this.result,
    this.error,
  });
}

/// Static method to run in isolate for hash generation
void _generateHashIsolate(List<dynamic> args) async {
  final sendPort = args[0] as SendPort;
  final data = args[1] as IsolateHashData;
  
  try {
    // Import hash generator in isolate
    final result = _generateTextHashInIsolate(data.text);
    
    // Send result back
    sendPort.send(IsolateHashResult(
      requestId: data.requestId,
      result: result,
    ));
  } catch (e) {
    // Send error back
    sendPort.send(IsolateHashResult(
      requestId: data.requestId,
      error: e.toString(),
    ));
  }
}

/// Generate hash in isolate (simple implementation for isolate)
String _generateTextHashInIsolate(String text) {
  // Simple hash implementation for isolate
  // Using a basic hash algorithm that doesn't require external dependencies
  int hash = 0;
  for (int i = 0; i < text.length; i++) {
    hash = ((hash << 5) - hash + text.codeUnitAt(i)) & 0xffffffff;
  }
  return hash.abs().toString();
}

/// Data structure for hash isolate communication
class IsolateHashData {
  final String requestId;
  final String text;

  const IsolateHashData({
    required this.requestId,
    required this.text,
  });
}

/// Result structure for hash isolate communication
class IsolateHashResult {
  final String requestId;
  final String? result;
  final String? error;

  const IsolateHashResult({
    required this.requestId,
    this.result,
    this.error,
  });
}

/// Static method to run in isolate for batch operations
void _batchOperationIsolate(List<dynamic> args) async {
  final sendPort = args[0] as SendPort;
  final data = args[1] as IsolateBatchData;
  
  try {
    Map<String, dynamic> result = {};
    
    switch (data.operationType) {
      case 'export':
        result = await _exportNotesInIsolate(data.notes, data.parameters);
        break;
      case 'validate':
        result = await _validateNotesInIsolate(data.notes, data.parameters);
        break;
      case 'statistics':
        result = await _calculateStatisticsInIsolate(data.notes, data.parameters);
        break;
      case 'cleanup':
        result = await _cleanupNotesInIsolate(data.notes, data.parameters);
        break;
      default:
        throw ArgumentError('Unknown operation type: ${data.operationType}');
    }
    
    // Send result back
    sendPort.send(IsolateBatchResult(
      requestId: data.requestId,
      result: result,
    ));
  } catch (e) {
    // Send error back
    sendPort.send(IsolateBatchResult(
      requestId: data.requestId,
      error: e.toString(),
    ));
  }
}

/// Export notes to various formats in isolate
Future<Map<String, dynamic>> _exportNotesInIsolate(
  List<Note> notes,
  Map<String, dynamic> parameters,
) async {
  final format = parameters['format'] as String? ?? 'json';
  final includeMetadata = parameters['includeMetadata'] as bool? ?? true;
  
  final exportedNotes = <Map<String, dynamic>>[];
  
  for (final note in notes) {
    final noteData = <String, dynamic>{
      'id': note.id,
      'content': note.contentMarkdown,
      'selectedText': note.selectedTextNormalized,
      'tags': note.tags,
      'bookId': note.bookId,
    };
    
    if (includeMetadata) {
      noteData.addAll({
        'createdAt': note.createdAt.toIso8601String(),
        'updatedAt': note.updatedAt.toIso8601String(),
        'anchorData': {
          'charStart': note.charStart,
          'charEnd': note.charEnd,
          'contextBefore': note.contextBefore,
          'contextAfter': note.contextAfter,
        },
      });
    }
    
    exportedNotes.add(noteData);
  }
  
  return {
    'format': format,
    'count': notes.length,
    'data': exportedNotes,
    'exportedAt': DateTime.now().toIso8601String(),
  };
}

/// Validate notes integrity in isolate
Future<Map<String, dynamic>> _validateNotesInIsolate(
  List<Note> notes,
  Map<String, dynamic> parameters,
) async {
  final issues = <Map<String, dynamic>>[];
  int validNotes = 0;
  
  for (final note in notes) {
    final noteIssues = <String>[];
    
    // Check for empty content
    if (note.contentMarkdown.trim().isEmpty) {
      noteIssues.add('Empty content');
    }
    
    // Check for invalid anchor data
    if (note.charStart < 0 || note.charEnd <= note.charStart) {
      noteIssues.add('Invalid anchor positions');
    }
    
    // Check for missing selected text
    if (note.selectedTextNormalized.trim().isEmpty) {
      noteIssues.add('Missing selected text');
    }
    
    // Check for future dates
    if (note.createdAt.isAfter(DateTime.now()) || note.updatedAt.isAfter(DateTime.now())) {
      noteIssues.add('Future timestamp');
    }
    
    if (noteIssues.isNotEmpty) {
      issues.add({
        'noteId': note.id,
        'issues': noteIssues,
      });
    } else {
      validNotes++;
    }
  }
  
  return {
    'totalNotes': notes.length,
    'validNotes': validNotes,
    'invalidNotes': issues.length,
    'issues': issues,
    'validationDate': DateTime.now().toIso8601String(),
  };
}

/// Calculate statistics about notes in isolate
Future<Map<String, dynamic>> _calculateStatisticsInIsolate(
  List<Note> notes,
  Map<String, dynamic> parameters,
) async {
  final bookStats = <String, int>{};
  final tagStats = <String, int>{};
  final monthlyStats = <String, int>{};
  
  int totalCharacters = 0;
  int totalWords = 0;
  DateTime? oldestNote;
  DateTime? newestNote;
  
  for (final note in notes) {
    // Book statistics
    bookStats[note.bookId] = (bookStats[note.bookId] ?? 0) + 1;
    
    // Tag statistics
    for (final tag in note.tags) {
      tagStats[tag] = (tagStats[tag] ?? 0) + 1;
    }
    
    // Monthly statistics
    final monthKey = '${note.createdAt.year}-${note.createdAt.month.toString().padLeft(2, '0')}';
    monthlyStats[monthKey] = (monthlyStats[monthKey] ?? 0) + 1;
    
    // Content statistics
    totalCharacters += note.contentMarkdown.length;
    totalWords += note.contentMarkdown.split(RegExp(r'\s+')).length;
    
    // Date range
    if (oldestNote == null || note.createdAt.isBefore(oldestNote)) {
      oldestNote = note.createdAt;
    }
    if (newestNote == null || note.createdAt.isAfter(newestNote)) {
      newestNote = note.createdAt;
    }
  }
  
  return {
    'totalNotes': notes.length,
    'totalCharacters': totalCharacters,
    'totalWords': totalWords,
    'averageCharactersPerNote': notes.isNotEmpty ? totalCharacters / notes.length : 0,
    'averageWordsPerNote': notes.isNotEmpty ? totalWords / notes.length : 0,
    'oldestNote': oldestNote?.toIso8601String(),
    'newestNote': newestNote?.toIso8601String(),
    'bookStats': bookStats,
    'tagStats': tagStats,
    'monthlyStats': monthlyStats,
    'calculatedAt': DateTime.now().toIso8601String(),
  };
}

/// Cleanup and optimize notes data in isolate
Future<Map<String, dynamic>> _cleanupNotesInIsolate(
  List<Note> notes,
  Map<String, dynamic> parameters,
) async {
  final duplicates = <String>[];
  final emptyNotes = <String>[];
  final orphanedNotes = <String>[];
  final suggestions = <Map<String, dynamic>>[];
  
  final contentHashes = <String, String>{};
  
  for (final note in notes) {
    // Check for duplicates by content hash
    final contentHash = _generateTextHashInIsolate(note.contentMarkdown);
    if (contentHashes.containsKey(contentHash)) {
      duplicates.add(note.id);
    } else {
      contentHashes[contentHash] = note.id;
    }
    
    // Check for empty notes
    if (note.contentMarkdown.trim().isEmpty) {
      emptyNotes.add(note.id);
    }
    
    // Check for potentially orphaned notes (invalid anchor positions)
    if (note.charStart < 0 || note.charEnd <= note.charStart) {
      orphanedNotes.add(note.id);
    }
    
    // Generate cleanup suggestions
    if (note.tags.isEmpty && note.contentMarkdown.length > 100) {
      suggestions.add({
        'noteId': note.id,
        'type': 'add_tags',
        'message': 'Consider adding tags to this note for better organization',
      });
    }
    
    if (note.contentMarkdown.length < 10) {
      suggestions.add({
        'noteId': note.id,
        'type': 'expand_content',
        'message': 'This note has very short content, consider expanding it',
      });
    }
  }
  
  return {
    'totalNotes': notes.length,
    'duplicates': duplicates,
    'emptyNotes': emptyNotes,
    'orphanedNotes': orphanedNotes,
    'suggestions': suggestions,
    'cleanupDate': DateTime.now().toIso8601String(),
  };
}

/// Data structure for batch isolate communication
class IsolateBatchData {
  final String requestId;
  final String operationType;
  final List<Note> notes;
  final Map<String, dynamic> parameters;

  const IsolateBatchData({
    required this.requestId,
    required this.operationType,
    required this.notes,
    required this.parameters,
  });
}

/// Result structure for batch isolate communication
class IsolateBatchResult {
  final String requestId;
  final Map<String, dynamic>? result;
  final String? error;

  const IsolateBatchResult({
    required this.requestId,
    this.result,
    this.error,
  });
}

/// Static method to run in isolate for parallel chunk processing
void _parallelChunkIsolate(List<dynamic> args) async {
  final sendPort = args[0] as SendPort;
  final data = args[1] as IsolateParallelData;
  
  try {
    final results = <dynamic>[];
    
    switch (data.operationType) {
      case 'normalize_texts':
        for (final item in data.items) {
          if (item is String) {
            // Simple normalization in isolate
            final normalized = item.trim().toLowerCase();
            results.add(normalized);
          }
        }
        break;
        
      case 'generate_hashes':
        for (final item in data.items) {
          if (item is String) {
            final hash = _generateTextHashInIsolate(item);
            results.add(hash);
          }
        }
        break;
        
      case 'validate_notes':
        for (final item in data.items) {
          if (item is Note) {
            final isValid = _validateNoteInIsolate(item);
            results.add(isValid);
          }
        }
        break;
        
      case 'extract_keywords':
        for (final item in data.items) {
          if (item is String) {
            final keywords = _extractKeywordsInIsolate(item);
            results.add(keywords);
          }
        }
        break;
        
      default:
        throw ArgumentError('Unknown parallel operation: ${data.operationType}');
    }
    
    // Send results back
    sendPort.send(IsolateParallelResult(
      requestId: data.requestId,
      results: results,
    ));
  } catch (e) {
    // Send error back
    sendPort.send(IsolateParallelResult(
      requestId: data.requestId,
      error: e.toString(),
    ));
  }
}

/// Validate a single note in isolate
bool _validateNoteInIsolate(Note note) {
  // Basic validation checks
  if (note.contentMarkdown.trim().isEmpty) return false;
  if (note.charStart < 0 || note.charEnd <= note.charStart) return false;
  if (note.selectedTextNormalized.trim().isEmpty) return false;
  if (note.createdAt.isAfter(DateTime.now())) return false;
  if (note.updatedAt.isAfter(DateTime.now())) return false;
  
  return true;
}

/// Extract keywords from text in isolate
List<String> _extractKeywordsInIsolate(String text) {
  // Simple keyword extraction
  final words = text.toLowerCase()
      .replaceAll(RegExp(r'[^\w\s\u0590-\u05FF]'), ' ') // Keep Hebrew and Latin
      .split(RegExp(r'\s+'))
      .where((word) => word.length > 2)
      .toSet()
      .toList();
  
  // Sort by length (longer words first)
  words.sort((a, b) => b.length.compareTo(a.length));
  
  // Return top keywords
  return words.take(10).toList();
}

/// Data structure for parallel isolate communication
class IsolateParallelData {
  final String requestId;
  final String operationType;
  final List<dynamic> items;
  final Map<String, dynamic> parameters;

  const IsolateParallelData({
    required this.requestId,
    required this.operationType,
    required this.items,
    required this.parameters,
  });
}

/// Result structure for parallel isolate communication
class IsolateParallelResult {
  final String requestId;
  final List<dynamic>? results;
  final String? error;

  const IsolateParallelResult({
    required this.requestId,
    this.results,
    this.error,
  });
}