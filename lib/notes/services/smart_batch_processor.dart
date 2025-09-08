import 'dart:async';
import 'dart:math';
import '../models/note.dart';
import '../models/anchor_models.dart';
import '../services/background_processor.dart';
import '../services/notes_telemetry.dart';
import '../config/notes_config.dart';

/// Smart batch processor that adapts batch sizes based on performance
class SmartBatchProcessor {
  static SmartBatchProcessor? _instance;
  final BackgroundProcessor _backgroundProcessor = BackgroundProcessor.instance;
  
  // Adaptive batch sizing
  int _currentBatchSize = 50;
  int _minBatchSize = 10;
  int _maxBatchSize = NotesConfig.maxReanchoringBatchSize;
  
  // Performance tracking
  final List<BatchPerformanceMetric> _performanceHistory = [];
  static const int _maxHistorySize = 20;
  
  // Load balancing
  int _activeProcesses = 0;
  final int _maxConcurrentProcesses = 3;
  
  SmartBatchProcessor._();
  
  /// Singleton instance
  static SmartBatchProcessor get instance {
    _instance ??= SmartBatchProcessor._();
    return _instance!;
  }

  /// Process notes in smart batches with adaptive sizing
  Future<List<AnchorResult>> processNotesInSmartBatches(
    List<Note> notes,
    CanonicalDocument document, {
    BatchProcessingOptions? options,
  }) async {
    final opts = options ?? const BatchProcessingOptions();
    final stopwatch = Stopwatch()..start();
    final allResults = <AnchorResult>[];
    
    try {
      // Prioritize notes by importance
      final prioritizedNotes = _prioritizeNotes(notes, opts);
      
      // Calculate optimal batch size
      final batchSize = _calculateOptimalBatchSize(notes.length);
      
      // Process in batches
      final batches = _createBatches(prioritizedNotes, batchSize);
      
      for (int i = 0; i < batches.length; i++) {
        final batch = batches[i];
        final batchStopwatch = Stopwatch()..start();
        
        // Wait for available processing slot
        await _waitForProcessingSlot();
        
        try {
          _activeProcesses++;
          
          // Process batch
          final batchResults = await _processBatch(
            batch,
            document,
            i + 1,
            batches.length,
          );
          
          allResults.addAll(batchResults);
          
          // Record performance metrics
          _recordBatchPerformance(BatchPerformanceMetric(
            batchSize: batch.length,
            duration: batchStopwatch.elapsed,
            successRate: batchResults.where((r) => r.isSuccess).length / batch.length,
            memoryUsage: _estimateMemoryUsage(batch),
          ));
          
          // Adapt batch size based on performance
          _adaptBatchSize(batchStopwatch.elapsed, batch.length);
          
          // Yield control to prevent UI blocking
          if (opts.yieldBetweenBatches) {
            await Future.delayed(const Duration(milliseconds: 10));
          }
          
        } finally {
          _activeProcesses--;
        }
      }
      
      // Track overall performance
      final successCount = allResults.where((r) => r.isSuccess).length;
      NotesTelemetry.trackBatchReanchoring(
        'smart_batch_${DateTime.now().millisecondsSinceEpoch}',
        notes.length,
        successCount,
        stopwatch.elapsed,
      );
      
      return allResults;
      
    } catch (e) {
      NotesTelemetry.trackPerformanceMetric('smart_batch_error', stopwatch.elapsed);
      rethrow;
    }
  }

  /// Prioritize notes based on various factors
  List<Note> _prioritizeNotes(List<Note> notes, BatchProcessingOptions options) {
    final prioritized = notes.toList();
    
    prioritized.sort((a, b) {
      double scoreA = _calculateNotePriority(a, options);
      double scoreB = _calculateNotePriority(b, options);
      
      return scoreB.compareTo(scoreA); // Higher score first
    });
    
    return prioritized;
  }

  /// Calculate priority score for a note
  double _calculateNotePriority(Note note, BatchProcessingOptions options) {
    double score = 0.0;
    
    // Status priority
    switch (note.status) {
      case NoteStatus.anchored:
        score += 1.0; // Lowest priority - already anchored
        break;
      case NoteStatus.shifted:
        score += 3.0; // Medium priority - needs re-anchoring
        break;
      case NoteStatus.orphan:
        score += 5.0; // Highest priority - needs attention
        break;
    }
    
    // Age factor (newer notes get higher priority)
    final age = DateTime.now().difference(note.updatedAt).inDays;
    score += max(0, 30 - age) / 30.0 * 2.0;
    
    // Content length factor (longer notes get slightly higher priority)
    final contentLength = note.contentMarkdown.length;
    score += min(contentLength / 1000.0, 1.0);
    
    // User priority (if specified in options)
    if (options.priorityTags.isNotEmpty) {
      final hasHighPriorityTag = note.tags.any((tag) => options.priorityTags.contains(tag));
      if (hasHighPriorityTag) {
        score += 2.0;
      }
    }
    
    return score;
  }

  /// Calculate optimal batch size based on current performance
  int _calculateOptimalBatchSize(int totalNotes) {
    if (_performanceHistory.isEmpty) {
      return min(_currentBatchSize, totalNotes);
    }
    
    // Analyze recent performance
    final recentMetrics = _performanceHistory.take(5).toList();
    final avgDuration = recentMetrics.map((m) => m.duration.inMilliseconds).reduce((a, b) => a + b) / recentMetrics.length;
    final avgSuccessRate = recentMetrics.map((m) => m.successRate).reduce((a, b) => a + b) / recentMetrics.length;
    
    // Adjust batch size based on performance
    if (avgDuration > AnchoringConstants.maxReanchoringTimeMs * 2 && _currentBatchSize > _minBatchSize) {
      // Too slow, reduce batch size
      _currentBatchSize = max(_minBatchSize, (_currentBatchSize * 0.8).round());
    } else if (avgDuration < AnchoringConstants.maxReanchoringTimeMs && avgSuccessRate > 0.9 && _currentBatchSize < _maxBatchSize) {
      // Good performance, can increase batch size
      _currentBatchSize = min(_maxBatchSize, (_currentBatchSize * 1.2).round());
    }
    
    return min(_currentBatchSize, totalNotes);
  }

  /// Create batches from notes list
  List<List<Note>> _createBatches(List<Note> notes, int batchSize) {
    final batches = <List<Note>>[];
    
    for (int i = 0; i < notes.length; i += batchSize) {
      final end = min(i + batchSize, notes.length);
      batches.add(notes.sublist(i, end));
    }
    
    return batches;
  }

  /// Wait for available processing slot
  Future<void> _waitForProcessingSlot() async {
    while (_activeProcesses >= _maxConcurrentProcesses) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Process a single batch
  Future<List<AnchorResult>> _processBatch(
    List<Note> batch,
    CanonicalDocument document,
    int batchNumber,
    int totalBatches,
  ) async {
    // Log batch processing if enabled
    NotesTelemetry.trackPerformanceMetric(
      'batch_processing_start',
      Duration.zero,
    );
    
    return await _backgroundProcessor.processReanchoring(batch, document);
  }

  /// Record batch performance metrics
  void _recordBatchPerformance(BatchPerformanceMetric metric) {
    _performanceHistory.insert(0, metric);
    
    // Keep only recent history
    if (_performanceHistory.length > _maxHistorySize) {
      _performanceHistory.removeRange(_maxHistorySize, _performanceHistory.length);
    }
  }

  /// Adapt batch size based on performance
  void _adaptBatchSize(Duration duration, int batchSize) {
    final durationMs = duration.inMilliseconds;
    final targetDurationMs = AnchoringConstants.maxReanchoringTimeMs;
    
    if (durationMs > targetDurationMs * 1.5) {
      // Too slow, reduce batch size
      _currentBatchSize = max(_minBatchSize, (batchSize * 0.8).round());
    } else if (durationMs < targetDurationMs * 0.5) {
      // Fast enough, can increase batch size
      _currentBatchSize = min(_maxBatchSize, (batchSize * 1.2).round());
    }
  }

  /// Estimate memory usage for a batch
  int _estimateMemoryUsage(List<Note> batch) {
    // Rough estimation: each note takes about 1KB in memory
    return batch.length * 1024;
  }

  /// Get current batch processing statistics
  BatchProcessingStats getProcessingStats() {
    final recentMetrics = _performanceHistory.take(10).toList();
    
    double avgDuration = 0;
    double avgSuccessRate = 0;
    int totalProcessed = 0;
    
    if (recentMetrics.isNotEmpty) {
      avgDuration = recentMetrics.map((m) => m.duration.inMilliseconds).reduce((a, b) => a + b) / recentMetrics.length;
      avgSuccessRate = recentMetrics.map((m) => m.successRate).reduce((a, b) => a + b) / recentMetrics.length;
      totalProcessed = recentMetrics.map((m) => m.batchSize).reduce((a, b) => a + b);
    }
    
    return BatchProcessingStats(
      currentBatchSize: _currentBatchSize,
      activeProcesses: _activeProcesses,
      avgDurationMs: avgDuration.round(),
      avgSuccessRate: avgSuccessRate,
      totalProcessedRecently: totalProcessed,
      performanceHistory: List.from(_performanceHistory),
    );
  }

  /// Reset batch size to default
  void resetBatchSize() {
    _currentBatchSize = 50;
    _performanceHistory.clear();
  }

  /// Set custom batch size limits
  void setBatchSizeLimits({int? minSize, int? maxSize}) {
    if (minSize != null && minSize > 0) {
      _minBatchSize = minSize;
    }
    if (maxSize != null && maxSize > _minBatchSize) {
      _maxBatchSize = maxSize;
    }
    
    // Adjust current batch size if needed
    _currentBatchSize = _currentBatchSize.clamp(_minBatchSize, _maxBatchSize);
  }
}

/// Options for batch processing
class BatchProcessingOptions {
  final List<String> priorityTags;
  final bool yieldBetweenBatches;
  final int? maxConcurrentBatches;
  final Duration? timeoutPerBatch;

  const BatchProcessingOptions({
    this.priorityTags = const [],
    this.yieldBetweenBatches = true,
    this.maxConcurrentBatches,
    this.timeoutPerBatch,
  });
}

/// Performance metric for a single batch
class BatchPerformanceMetric {
  final int batchSize;
  final Duration duration;
  final double successRate;
  final int memoryUsage;
  final DateTime timestamp;

  BatchPerformanceMetric({
    required this.batchSize,
    required this.duration,
    required this.successRate,
    required this.memoryUsage,
  }) : timestamp = DateTime.now();
}

/// Statistics for batch processing
class BatchProcessingStats {
  final int currentBatchSize;
  final int activeProcesses;
  final int avgDurationMs;
  final double avgSuccessRate;
  final int totalProcessedRecently;
  final List<BatchPerformanceMetric> performanceHistory;

  const BatchProcessingStats({
    required this.currentBatchSize,
    required this.activeProcesses,
    required this.avgDurationMs,
    required this.avgSuccessRate,
    required this.totalProcessedRecently,
    required this.performanceHistory,
  });
}