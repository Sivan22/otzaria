import 'dart:isolate';
import 'dart:async';
import '../models/note.dart';
import '../models/anchor_models.dart';
import '../services/anchoring_service.dart';
import '../services/notes_telemetry.dart';
import '../config/notes_config.dart';

/// Service for processing heavy note operations in background isolates
class BackgroundProcessor {
  static BackgroundProcessor? _instance;
  final Map<String, Completer<List<AnchorResult>>> _activeRequests = {};
  int _requestCounter = 0;
  
  BackgroundProcessor._();
  
  /// Singleton instance
  static BackgroundProcessor get instance {
    _instance ??= BackgroundProcessor._();
    return _instance!;
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
      'active_requests': _activeRequests.length,
      'request_counter': _requestCounter,
      'oldest_request_age': _getOldestRequestAge(),
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