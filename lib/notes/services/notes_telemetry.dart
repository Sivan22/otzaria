import '../config/notes_config.dart';
import '../models/note.dart';

/// Service for tracking notes performance and usage metrics
class NotesTelemetry {
  static NotesTelemetry? _instance;
  final Map<String, List<int>> _performanceData = {};
  
  NotesTelemetry._();
  
  /// Singleton instance
  static NotesTelemetry get instance {
    _instance ??= NotesTelemetry._();
    return _instance!;
  }

  /// Track anchoring result (no sensitive data)
  static void trackAnchoringResult(
    String requestId,
    NoteStatus status,
    Duration duration,
    String strategy,
  ) {
    if (!NotesConfig.telemetryEnabled || !NotesEnvironment.telemetryEnabled) return;
    
    // Log performance metrics without sensitive content
    if (NotesEnvironment.performanceLogging) {
      print('Anchoring: $requestId, status: ${status.name}, '
            'strategy: $strategy, duration: ${duration.inMilliseconds}ms');
    }
    
    // Store aggregated metrics
    instance._recordMetric('anchoring_${status.name}', duration.inMilliseconds);
    instance._recordMetric('strategy_$strategy', duration.inMilliseconds);
  }

  /// Track batch re-anchoring performance
  static void trackBatchReanchoring(
    String requestId,
    int noteCount,
    int successCount,
    Duration totalDuration,
  ) {
    if (!NotesConfig.telemetryEnabled || !NotesEnvironment.telemetryEnabled) return;
    
    final avgDuration = totalDuration.inMilliseconds / noteCount;
    final successRate = successCount / noteCount;
    
    if (NotesEnvironment.performanceLogging) {
      print('Batch reanchoring: $requestId, notes: $noteCount, '
            'success: $successCount, rate: ${(successRate * 100).toStringAsFixed(1)}%, '
            'avg: ${avgDuration.toStringAsFixed(1)}ms');
    }
    
    instance._recordMetric('batch_reanchoring', totalDuration.inMilliseconds);
    instance._recordMetric('batch_success_rate', (successRate * 100).round());
  }

  /// Track search performance
  static void trackSearchPerformance(
    String query,
    int resultCount,
    Duration duration,
  ) {
    if (!NotesConfig.telemetryEnabled || !NotesEnvironment.telemetryEnabled) return;
    
    if (NotesEnvironment.performanceLogging) {
      print('Search: query_length=${query.length}, results=$resultCount, '
            'duration=${duration.inMilliseconds}ms');
    }
    
    instance._recordMetric('search_performance', duration.inMilliseconds);
    instance._recordMetric('search_results', resultCount);
  }

  /// Track general performance metric
  static void trackPerformanceMetric(String operation, Duration duration) {
    if (!NotesEnvironment.performanceLogging) return;
    
    print('Performance: $operation took ${duration.inMilliseconds}ms');
    instance._recordMetric(operation, duration.inMilliseconds);
  }

  /// Track user action (no sensitive data)
  static void trackUserAction(String action, Map<String, dynamic> context) {
    if (!NotesConfig.telemetryEnabled || !NotesEnvironment.telemetryEnabled) return;
    
    // Only log non-sensitive context data
    final safeContext = <String, dynamic>{};
    for (final entry in context.entries) {
      switch (entry.key) {
        case 'note_count':
        case 'book_id_length':
        case 'content_length':
        case 'tags_count':
        case 'status':
        case 'privacy':
          safeContext[entry.key] = entry.value;
          break;
        // Skip sensitive data like actual content, text, etc.
      }
    }
    
    if (NotesEnvironment.performanceLogging) {
      print('User action: $action, context: $safeContext');
    }
  }

  /// Record a metric value
  void _recordMetric(String metric, int value) {
    _performanceData.putIfAbsent(metric, () => <int>[]).add(value);
    
    // Keep only last 100 values per metric to prevent memory bloat
    final values = _performanceData[metric]!;
    if (values.length > 100) {
      values.removeAt(0);
    }
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final stats = <String, dynamic>{};
    
    for (final entry in _performanceData.entries) {
      final values = entry.value;
      if (values.isNotEmpty) {
        values.sort();
        final avg = values.reduce((a, b) => a + b) / values.length;
        final p95Index = (values.length * 0.95).floor().clamp(0, values.length - 1);
        final p99Index = (values.length * 0.99).floor().clamp(0, values.length - 1);
        
        stats[entry.key] = {
          'count': values.length,
          'avg': avg.round(),
          'min': values.first,
          'max': values.last,
          'p95': values[p95Index],
          'p99': values[p99Index],
        };
      }
    }
    
    return stats;
  }

  /// Get aggregated metrics for reporting
  Map<String, dynamic> getAggregatedMetrics() {
    final stats = getPerformanceStats();
    
    return {
      'anchoring_performance': {
        'anchored_avg_ms': stats['anchoring_anchored']?['avg'] ?? 0,
        'shifted_avg_ms': stats['anchoring_shifted']?['avg'] ?? 0,
        'orphan_avg_ms': stats['anchoring_orphan']?['avg'] ?? 0,
      },
      'search_performance': {
        'avg_ms': stats['search_performance']?['avg'] ?? 0,
        'p95_ms': stats['search_performance']?['p95'] ?? 0,
        'avg_results': stats['search_results']?['avg'] ?? 0,
      },
      'batch_performance': {
        'avg_ms': stats['batch_reanchoring']?['avg'] ?? 0,
        'success_rate': stats['batch_success_rate']?['avg'] ?? 0,
      },
      'strategy_usage': {
        'exact_avg_ms': stats['strategy_exact']?['avg'] ?? 0,
        'context_avg_ms': stats['strategy_context']?['avg'] ?? 0,
        'fuzzy_avg_ms': stats['strategy_fuzzy']?['avg'] ?? 0,
      },
    };
  }

  /// Clear all metrics (for testing or privacy)
  void clearMetrics() {
    _performanceData.clear();
  }

  /// Check if performance is within acceptable limits
  bool isPerformanceHealthy() {
    final stats = getPerformanceStats();
    
    // Check anchoring performance
    final anchoringAvg = stats['anchoring_anchored']?['avg'] ?? 0;
    if (anchoringAvg > AnchoringConstants.maxReanchoringTimeMs) {
      return false;
    }
    
    // Check search performance
    final searchAvg = stats['search_performance']?['avg'] ?? 0;
    if (searchAvg > 200) { // 200ms threshold for search
      return false;
    }
    
    return true;
  }
}