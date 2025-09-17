import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:otzaria/notes/services/notes_integration_service.dart';
import '../test_helpers/test_setup.dart';
import 'package:otzaria/notes/services/advanced_orphan_manager.dart';
import 'package:otzaria/notes/services/smart_batch_processor.dart';
import 'package:otzaria/notes/services/performance_optimizer.dart';
import 'package:otzaria/notes/services/advanced_search_engine.dart';
import 'package:otzaria/notes/models/note.dart';
import 'package:otzaria/notes/models/anchor_models.dart';
import 'package:otzaria/notes/config/notes_config.dart';

void main() {
  setUpAll(() {
    TestSetup.initializeTestEnvironment();
  });

  group('Notes Performance Tests', () {
    late NotesIntegrationService integrationService;
    late AdvancedOrphanManager orphanManager;
    late SmartBatchProcessor batchProcessor;
    late PerformanceOptimizer performanceOptimizer;
    late AdvancedSearchEngine searchEngine;

    setUp(() {
      integrationService = NotesIntegrationService.instance;
      orphanManager = AdvancedOrphanManager.instance;
      batchProcessor = SmartBatchProcessor.instance;
      performanceOptimizer = PerformanceOptimizer.instance;
      searchEngine = AdvancedSearchEngine.instance;
      
      // Clear caches
      integrationService.clearCache();
    });

    group('Note Creation Performance', () {
      test('should create single note within performance target', () async {
        const bookId = 'perf-create-single';
        const bookText = 'Performance test content for single note creation.';
        
        final stopwatch = Stopwatch()..start();
        
        final note = await integrationService.createNoteFromSelection(
          bookId,
          'performance test',
          10,
          26,
          'Performance test note',
        );
        
        stopwatch.stop();
        
        expect(note.id, isNotEmpty);
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be under 100ms
      });

      test('should create multiple notes efficiently', () async {
        const bookId = 'perf-create-multiple';
        const bookText = 'Performance test content for multiple note creation with various selections.';
        const noteCount = 10;
        
        final stopwatch = Stopwatch()..start();
        final notes = <Note>[];
        
        for (int i = 0; i < noteCount; i++) {
          final note = await integrationService.createNoteFromSelection(
            bookId,
            'test $i',
            i * 5,
            i * 5 + 4,
            'Performance test note $i',
          );
          notes.add(note);
        }
        
        stopwatch.stop();
        
        expect(notes.length, equals(noteCount));
        expect(stopwatch.elapsedMilliseconds, lessThan(noteCount * 50)); // Average 50ms per note
        
        final avgTimePerNote = stopwatch.elapsedMilliseconds / noteCount;
        expect(avgTimePerNote, lessThan(AnchoringConstants.maxReanchoringTimeMs));
      });
    });

    group('Note Loading Performance', () {
      test('should load book notes within performance target', () async {
        const bookId = 'perf-load-book';
        const bookText = 'Performance test content for book loading with multiple notes.';
        
        // Create test notes first
        for (int i = 0; i < 20; i++) {
          await integrationService.createNoteFromSelection(
            bookId,
            'note $i',
            i * 10,
            i * 10 + 5,
            'Test note $i',
          );
        }
        
        // Clear cache to ensure fresh load
        integrationService.clearCache();
        
        final stopwatch = Stopwatch()..start();
        final result = await integrationService.loadNotesForBook(bookId, bookText);
        stopwatch.stop();
        
        expect(result.notes.length, equals(20));
        expect(stopwatch.elapsedMilliseconds, lessThan(500)); // Should load 20 notes in under 500ms
        expect(result.fromCache, isFalse);
      });

      test('should load from cache very quickly', () async {
        const bookId = 'perf-cache-load';
        const bookText = 'Performance test content for cache loading.';
        
        // First load to populate cache
        await integrationService.loadNotesForBook(bookId, bookText);
        
        // Second load from cache
        final stopwatch = Stopwatch()..start();
        final result = await integrationService.loadNotesForBook(bookId, bookText);
        stopwatch.stop();
        
        expect(result.fromCache, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(10)); // Cache should be very fast
      });

      test('should handle visible range efficiently', () async {
        const bookId = 'perf-visible-range';
        
        // Create many notes across a large range
        for (int i = 0; i < 100; i++) {
          await integrationService.createNoteFromSelection(
            bookId,
            'note $i',
            i * 100,
            i * 100 + 10,
            'Test note $i',
          );
        }
        
        // Test visible range performance
        const visibleRange = VisibleCharRange(2000, 3000); // Should include ~10 notes
        
        final stopwatch = Stopwatch()..start();
        final visibleNotes = integrationService.getNotesForVisibleRange(bookId, visibleRange);
        stopwatch.stop();
        
        expect(visibleNotes.length, equals(10));
        expect(stopwatch.elapsedMilliseconds, lessThan(5)); // Should be very fast
      });
    });

    group('Search Performance', () {
      test('should search notes within performance target', () async {
        const bookId = 'perf-search';
        
        // Create test notes with searchable content
        final searchTerms = ['apple', 'banana', 'cherry', 'date', 'elderberry'];
        for (int i = 0; i < 50; i++) {
          final term = searchTerms[i % searchTerms.length];
          await integrationService.createNoteFromSelection(
            bookId,
            term,
            i * 10,
            i * 10 + term.length,
            'Note about $term number $i',
          );
        }
        
        // Test search performance
        final stopwatch = Stopwatch()..start();
        final results = await integrationService.searchNotes('apple', bookId: bookId);
        stopwatch.stop();
        
        expect(results.length, equals(10)); // Should find 10 apple notes
        expect(stopwatch.elapsedMilliseconds, lessThan(200)); // Should search in under 200ms
      });

      test('should handle complex search queries efficiently', () async {
        const bookId = 'perf-complex-search';
        
        // Create notes with various content
        for (int i = 0; i < 30; i++) {
          await integrationService.createNoteFromSelection(
            bookId,
            'content $i',
            i * 20,
            i * 20 + 10,
            'Complex search test note $i with various keywords and content',
            tags: ['tag$i', 'common', 'test'],
          );
        }
        
        // Test complex search
        final stopwatch = Stopwatch()..start();
        final results = await integrationService.searchNotes('complex test', bookId: bookId);
        stopwatch.stop();
        
        expect(results.length, greaterThan(0));
        expect(stopwatch.elapsedMilliseconds, lessThan(300)); // Complex search under 300ms
      });
    });

    group('Batch Processing Performance', () {
      test('should process batch operations efficiently', () async {
        const bookId = 'perf-batch';
        
        // Create test notes
        final notes = <Note>[];
        for (int i = 0; i < 50; i++) {
          final note = await integrationService.createNoteFromSelection(
            bookId,
            'batch $i',
            i * 15,
            i * 15 + 7,
            'Batch test note $i',
          );
          notes.add(note);
        }
        
        // Test batch processing performance
        final stopwatch = Stopwatch()..start();
        
        // Simulate batch update operations
        for (int i = 0; i < 10; i++) {
          await integrationService.updateNote(
            notes[i].id,
            'Updated batch note $i',
            newTags: ['updated', 'batch'],
          );
        }
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 10 updates in under 1 second
        
        final avgTimePerUpdate = stopwatch.elapsedMilliseconds / 10;
        expect(avgTimePerUpdate, lessThan(100)); // Average under 100ms per update
      });

      test('should handle large batch sizes with adaptive sizing', () async {
        // Test batch processor stats
        final initialStats = batchProcessor.getProcessingStats();
        expect(initialStats.currentBatchSize, greaterThan(0));
        expect(initialStats.activeProcesses, equals(0));
        
        // Reset batch size for consistent testing
        batchProcessor.resetBatchSize();
        
        final resetStats = batchProcessor.getProcessingStats();
        expect(resetStats.currentBatchSize, equals(50)); // Default batch size
      });
    });

    group('Memory Performance', () {
      test('should maintain reasonable memory usage with many notes', () async {
        const bookId = 'perf-memory';
        
        // Create a large number of notes
        for (int i = 0; i < 200; i++) {
          await integrationService.createNoteFromSelection(
            bookId,
            'memory test $i',
            i * 25,
            i * 25 + 12,
            'Memory performance test note $i with some content to test memory usage',
            tags: ['memory', 'test', 'performance'],
          );
        }
        
        // Check cache statistics
        final cacheStats = integrationService.getCacheStats();
        expect(cacheStats['total_cached_notes'], equals(200));
        
        // Memory usage should be reasonable (this is a rough estimate)
        // In a real app, you might use more sophisticated memory profiling
        expect(cacheStats['total_cached_notes'], lessThan(1000));
      });

      test('should clean up cache when needed', () async {
        const bookId = 'perf-cleanup';
        
        // Create notes and populate cache
        for (int i = 0; i < 50; i++) {
          await integrationService.createNoteFromSelection(
            bookId,
            'cleanup $i',
            i * 10,
            i * 10 + 8,
            'Cleanup test note $i',
          );
        }
        
        final statsBefore = integrationService.getCacheStats();
        expect(statsBefore['total_cached_notes'], equals(50));
        
        // Clear cache
        integrationService.clearCache();
        
        final statsAfter = integrationService.getCacheStats();
        expect(statsAfter['total_cached_notes'], equals(0));
      });
    });

    group('Performance Optimizer Tests', () {
      test('should provide optimization status', () {
        final status = performanceOptimizer.getOptimizationStatus();
        
        expect(status.isAutoOptimizationEnabled, isA<bool>());
        expect(status.isHealthy, isA<bool>());
      });

      test('should run optimization cycle', () async {
        final stopwatch = Stopwatch()..start();
        final result = await performanceOptimizer.runOptimizationCycle();
        stopwatch.stop();
        
        expect(result.success, isTrue);
        expect(result.duration.inMilliseconds, greaterThan(0));
        expect(result.results, isNotEmpty);
        expect(result.recommendations, isNotEmpty);
        
        // Optimization should complete in reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Under 5 seconds
      });

      test('should start and stop auto optimization', () {
        // Start auto optimization
        performanceOptimizer.startAutoOptimization();
        
        final statusRunning = performanceOptimizer.getOptimizationStatus();
        expect(statusRunning.isAutoOptimizationEnabled, isTrue);
        
        // Stop auto optimization
        performanceOptimizer.stopAutoOptimization();
        
        final statusStopped = performanceOptimizer.getOptimizationStatus();
        expect(statusStopped.isAutoOptimizationEnabled, isFalse);
      });
    });

    group('Stress Tests', () {
      test('should handle rapid note creation without degradation', () async {
        const bookId = 'stress-rapid-creation';
        const noteCount = 100;
        
        final times = <int>[];
        
        for (int i = 0; i < noteCount; i++) {
          final stopwatch = Stopwatch()..start();
          
          await integrationService.createNoteFromSelection(
            bookId,
            'rapid $i',
            i * 5,
            i * 5 + 6,
            'Rapid creation test note $i',
          );
          
          stopwatch.stop();
          times.add(stopwatch.elapsedMilliseconds);
        }
        
        // Check that performance doesn't degrade significantly
        final firstTen = times.take(10).reduce((a, b) => a + b) / 10;
        final lastTen = times.skip(noteCount - 10).reduce((a, b) => a + b) / 10;
        
        // Last ten shouldn't be more than 2x slower than first ten
        expect(lastTen, lessThan(firstTen * 2));
        
        // All operations should be under reasonable limit
        expect(times.every((time) => time < 200), isTrue);
      });

      test('should handle concurrent operations', () async {
        const bookId = 'stress-concurrent';
        
        // Create multiple concurrent note creation operations
        final futures = <Future<Note>>[];
        
        for (int i = 0; i < 20; i++) {
          final future = integrationService.createNoteFromSelection(
            bookId,
            'concurrent $i',
            i * 10,
            i * 10 + 11,
            'Concurrent test note $i',
          );
          futures.add(future);
        }
        
        final stopwatch = Stopwatch()..start();
        final results = await Future.wait(futures);
        stopwatch.stop();
        
        expect(results.length, equals(20));
        expect(results.every((note) => note.id.isNotEmpty), isTrue);
        
        // Concurrent operations should be faster than sequential
        expect(stopwatch.elapsedMilliseconds, lessThan(20 * 100)); // Much faster than sequential
      });

      test('should maintain performance with large visible ranges', () async {
        const bookId = 'stress-large-range';
        
        // Create notes spread across a very large range
        for (int i = 0; i < 500; i++) {
          await integrationService.createNoteFromSelection(
            bookId,
            'large range $i',
            i * 1000, // Spread notes far apart
            i * 1000 + 15,
            'Large range test note $i',
          );
        }
        
        // Test performance with various range sizes
        final ranges = [
          const VisibleCharRange(0, 10000),      // Small range
          const VisibleCharRange(0, 100000),     // Medium range
          const VisibleCharRange(0, 500000),     // Large range
        ];
        
        for (final range in ranges) {
          final stopwatch = Stopwatch()..start();
          final visibleNotes = integrationService.getNotesForVisibleRange(bookId, range);
          stopwatch.stop();
          
          expect(visibleNotes.length, greaterThan(0));
          expect(stopwatch.elapsedMilliseconds, lessThan(50)); // Should be fast regardless of range size
        }
      });
    });

    group('Performance Regression Tests', () {
      test('should maintain consistent anchoring performance', () async {
        const bookId = 'regression-anchoring';
        const bookText = 'Regression test content for anchoring performance validation.';
        
        // Create notes and measure anchoring time
        final anchoringTimes = <int>[];
        
        for (int i = 0; i < 20; i++) {
          final stopwatch = Stopwatch()..start();
          
          await integrationService.createNoteFromSelection(
            bookId,
            'anchoring $i',
            i * 10,
            i * 10 + 11,
            'Anchoring regression test note $i',
          );
          
          stopwatch.stop();
          anchoringTimes.add(stopwatch.elapsedMilliseconds);
        }
        
        // Calculate statistics
        final avgTime = anchoringTimes.reduce((a, b) => a + b) / anchoringTimes.length;
        final maxTime = anchoringTimes.reduce((a, b) => a > b ? a : b);
        
        // Performance should be within acceptable limits
        expect(avgTime, lessThan(AnchoringConstants.maxReanchoringTimeMs));
        expect(maxTime, lessThan(AnchoringConstants.maxReanchoringTimeMs * 2));
        
        // Variance should be reasonable (no outliers)
        final variance = anchoringTimes.map((time) => (time - avgTime) * (time - avgTime)).reduce((a, b) => a + b) / anchoringTimes.length;
        expect(variance, lessThan(1000)); // Low variance indicates consistent performance
      });

      test('should maintain search performance with growing dataset', () async {
        const bookId = 'regression-search';
        
        // Create increasing numbers of notes and measure search time
        final searchTimes = <int>[];
        final noteCounts = [10, 50, 100, 200];
        
        for (final count in noteCounts) {
          // Add more notes
          final currentNoteCount = integrationService.getNotesForVisibleRange(bookId, const VisibleCharRange(0, 999999)).length;
          final notesToAdd = count - currentNoteCount;
          
          for (int i = currentNoteCount; i < currentNoteCount + notesToAdd; i++) {
            await integrationService.createNoteFromSelection(
              bookId,
              'search regression $i',
              i * 5,
              i * 5 + 17,
              'Search regression test note $i with searchable content',
            );
          }
          
          // Measure search time
          final stopwatch = Stopwatch()..start();
          await integrationService.searchNotes('regression', bookId: bookId);
          stopwatch.stop();
          
          searchTimes.add(stopwatch.elapsedMilliseconds);
        }
        
        // Search time should not grow linearly with dataset size
        // (should be sub-linear due to indexing)
        expect(searchTimes.last, lessThan(searchTimes.first * 4)); // Not more than 4x slower with 20x data
        expect(searchTimes.every((time) => time < 500), isTrue); // All searches under 500ms
      });
    });
  });
}