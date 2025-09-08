import 'dart:async';
import '../services/notes_telemetry.dart';
import '../config/notes_config.dart';
import '../data/notes_data_provider.dart';

/// Service for optimizing notes system performance
class PerformanceOptimizer {
  static PerformanceOptimizer? _instance;
  Timer? _optimizationTimer;
  DateTime? _lastOptimization;
  
  PerformanceOptimizer._();
  
  /// Singleton instance
  static PerformanceOptimizer get instance {
    _instance ??= PerformanceOptimizer._();
    return _instance!;
  }

  /// Start automatic performance optimization
  void startAutoOptimization() {
    if (_optimizationTimer?.isActive == true) return;
    
    _optimizationTimer = Timer.periodic(
      const Duration(hours: 1), // Run every hour
      (_) => _runOptimizationCycle(),
    );
  }

  /// Stop automatic performance optimization
  void stopAutoOptimization() {
    _optimizationTimer?.cancel();
    _optimizationTimer = null;
  }

  /// Run a complete optimization cycle
  Future<OptimizationResult> runOptimizationCycle() async {
    return await _runOptimizationCycle();
  }

  /// Internal optimization cycle
  Future<OptimizationResult> _runOptimizationCycle() async {
    final stopwatch = Stopwatch()..start();
    final results = <String, dynamic>{};
    
    try {
      // 1. Database optimization
      final dbResult = await _optimizeDatabase();
      results['database'] = dbResult;
      
      // 2. Cache optimization
      final cacheResult = await _optimizeCache();
      results['cache'] = cacheResult;
      
      // 3. Index optimization
      final indexResult = await _optimizeSearchIndex();
      results['search_index'] = indexResult;
      
      // 4. Memory optimization
      final memoryResult = await _optimizeMemory();
      results['memory'] = memoryResult;
      
      // 5. Performance analysis
      final analysisResult = await _analyzePerformance();
      results['analysis'] = analysisResult;
      
      _lastOptimization = DateTime.now();
      
      NotesTelemetry.trackPerformanceMetric('optimization_cycle', stopwatch.elapsed);
      
      return OptimizationResult(
        success: true,
        duration: stopwatch.elapsed,
        results: results,
        recommendations: _generateRecommendations(results),
      );
    } catch (e) {
      return OptimizationResult(
        success: false,
        duration: stopwatch.elapsed,
        error: e.toString(),
        results: results,
        recommendations: ['שגיאה בתהליך האופטימיזציה: $e'],
      );
    }
  }

  /// Optimize database performance
  Future<Map<String, dynamic>> _optimizeDatabase() async {
    final db = await NotesDataProvider.instance.database;
    final results = <String, dynamic>{};
    
    try {
      // Run VACUUM to reclaim space
      await db.execute('VACUUM;');
      results['vacuum'] = 'completed';
      
      // Update statistics
      await db.execute('ANALYZE;');
      results['analyze'] = 'completed';
      
      // Check database size
      final sizeResult = await db.rawQuery('PRAGMA page_count;');
      final pageCount = sizeResult.first['page_count'] as int;
      results['page_count'] = pageCount;
      results['estimated_size_mb'] = (pageCount * 4096 / 1024 / 1024).toStringAsFixed(2);
      
      // Check fragmentation
      final fragmentResult = await db.rawQuery('PRAGMA freelist_count;');
      final freePages = fragmentResult.first['freelist_count'] as int;
      results['free_pages'] = freePages;
      results['fragmentation_percent'] = ((freePages / pageCount) * 100).toStringAsFixed(2);
      
    } catch (e) {
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// Optimize cache performance
  Future<Map<String, dynamic>> _optimizeCache() async {
    final results = <String, dynamic>{};
    
    try {
      // Clear expired cache entries (if we had a cache system)
      results['cache_cleared'] = 'simulated';
      
      // Memory usage estimation
      final telemetryStats = NotesTelemetry.instance.getPerformanceStats();
      results['telemetry_entries'] = telemetryStats.length;
      
      // Clear old telemetry data if too much
      if (telemetryStats.length > 1000) {
        NotesTelemetry.instance.clearMetrics();
        results['telemetry_cleared'] = true;
      }
      
    } catch (e) {
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// Optimize search index
  Future<Map<String, dynamic>> _optimizeSearchIndex() async {
    final db = await NotesDataProvider.instance.database;
    final results = <String, dynamic>{};
    
    try {
      // Rebuild FTS index
      await db.execute('INSERT INTO notes_fts(notes_fts) VALUES(\'rebuild\');');
      results['fts_rebuild'] = 'completed';
      
      // Optimize FTS index
      await db.execute('INSERT INTO notes_fts(notes_fts) VALUES(\'optimize\');');
      results['fts_optimize'] = 'completed';
      
    } catch (e) {
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// Optimize memory usage
  Future<Map<String, dynamic>> _optimizeMemory() async {
    final results = <String, dynamic>{};
    
    try {
      // Force garbage collection (Dart will do this automatically, but we can suggest it)
      results['gc_suggested'] = true;
      
      // Check telemetry memory usage
      final stats = NotesTelemetry.instance.getPerformanceStats();
      final memoryEstimate = stats.length * 100; // Rough estimate
      results['telemetry_memory_bytes'] = memoryEstimate;
      
      if (memoryEstimate > 1024 * 1024) { // > 1MB
        results['recommendation'] = 'Consider clearing telemetry data';
      }
      
    } catch (e) {
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// Analyze current performance
  Future<Map<String, dynamic>> _analyzePerformance() async {
    final results = <String, dynamic>{};
    
    try {
      final telemetryStats = NotesTelemetry.instance.getPerformanceStats();
      final aggregated = NotesTelemetry.instance.getAggregatedMetrics();
      final isHealthy = NotesTelemetry.instance.isPerformanceHealthy();
      
      results['health_status'] = isHealthy ? 'healthy' : 'needs_attention';
      results['metrics_count'] = telemetryStats.length;
      
      // Analyze anchoring performance
      final anchoring = aggregated['anchoring_performance'] as Map<String, dynamic>? ?? {};
      final anchoredAvg = anchoring['anchored_avg_ms'] ?? 0;
      
      if (anchoredAvg > AnchoringConstants.maxReanchoringTimeMs) {
        results['anchoring_warning'] = 'Average anchoring time exceeds threshold';
      }
      
      // Analyze search performance
      final search = aggregated['search_performance'] as Map<String, dynamic>? ?? {};
      final searchAvg = search['avg_ms'] ?? 0;
      
      if (searchAvg > 200) {
        results['search_warning'] = 'Search performance is slow';
      }
      
    } catch (e) {
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// Generate optimization recommendations
  List<String> _generateRecommendations(Map<String, dynamic> results) {
    final recommendations = <String>[];
    
    // Database recommendations
    final dbResults = results['database'] as Map<String, dynamic>? ?? {};
    final fragmentation = double.tryParse(dbResults['fragmentation_percent']?.toString() ?? '0') ?? 0;
    
    if (fragmentation > 10) {
      recommendations.add('רמת פיצול גבוהה במסד הנתונים (${fragmentation.toStringAsFixed(1)}%) - הרץ VACUUM');
    }
    
    final sizeMb = double.tryParse(dbResults['estimated_size_mb']?.toString() ?? '0') ?? 0;
    if (sizeMb > 100) {
      recommendations.add('מסד הנתונים גדול (${sizeMb.toStringAsFixed(1)}MB) - שקול ארכוב הערות ישנות');
    }
    
    // Performance recommendations
    final analysisResults = results['analysis'] as Map<String, dynamic>? ?? {};
    if (analysisResults['health_status'] == 'needs_attention') {
      recommendations.add('ביצועי המערכת דורשים תשומת לב - בדוק מדדי ביצועים');
    }
    
    if (analysisResults.containsKey('anchoring_warning')) {
      recommendations.add('ביצועי עיגון איטיים - שקול להפחית batch size');
    }
    
    if (analysisResults.containsKey('search_warning')) {
      recommendations.add('ביצועי חיפוש איטיים - שקול לבנות מחדש את אינדקס החיפוש');
    }
    
    // Memory recommendations
    final memoryResults = results['memory'] as Map<String, dynamic>? ?? {};
    final memoryBytes = memoryResults['telemetry_memory_bytes'] as int? ?? 0;
    
    if (memoryBytes > 5 * 1024 * 1024) { // > 5MB
      recommendations.add('שימוש גבוה בזיכרון עבור טלמטריה - נקה נתונים ישנים');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('המערכת פועלת בצורה אופטימלית');
    }
    
    return recommendations;
  }

  /// Get optimization status
  OptimizationStatus getOptimizationStatus() {
    final isRunning = _optimizationTimer?.isActive == true;
    final nextRun = isRunning && _lastOptimization != null
        ? _lastOptimization!.add(const Duration(hours: 1))
        : null;
    
    return OptimizationStatus(
      isAutoOptimizationEnabled: isRunning,
      lastOptimization: _lastOptimization,
      nextOptimization: nextRun,
      isHealthy: NotesTelemetry.instance.isPerformanceHealthy(),
    );
  }

  /// Force immediate optimization
  Future<OptimizationResult> forceOptimization() async {
    return await _runOptimizationCycle();
  }

  /// Clean up resources
  void dispose() {
    stopAutoOptimization();
  }
}

/// Result of optimization operation
class OptimizationResult {
  final bool success;
  final Duration duration;
  final Map<String, dynamic> results;
  final List<String> recommendations;
  final String? error;

  const OptimizationResult({
    required this.success,
    required this.duration,
    required this.results,
    required this.recommendations,
    this.error,
  });
}

/// Status of optimization system
class OptimizationStatus {
  final bool isAutoOptimizationEnabled;
  final DateTime? lastOptimization;
  final DateTime? nextOptimization;
  final bool isHealthy;

  const OptimizationStatus({
    required this.isAutoOptimizationEnabled,
    this.lastOptimization,
    this.nextOptimization,
    required this.isHealthy,
  });
}