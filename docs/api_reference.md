# Personal Notes System - API Reference

## Overview

This document provides comprehensive API documentation for the Personal Notes System in Otzaria.

## Core Services

### NotesIntegrationService

The main service for integrating notes with the existing book system.

```dart
class NotesIntegrationService {
  static NotesIntegrationService get instance;
  
  /// Load notes for a book and integrate with text display
  Future<BookNotesData> loadNotesForBook(String bookId, String bookText);
  
  /// Get notes for a specific visible range (for performance)
  List<Note> getNotesForVisibleRange(String bookId, VisibleCharRange range);
  
  /// Create highlight data for text rendering
  List<TextHighlight> createHighlightsForRange(String bookId, VisibleCharRange range);
  
  /// Handle text selection for note creation
  Future<Note> createNoteFromSelection(
    String bookId,
    String selectedText,
    int charStart,
    int charEnd,
    String noteContent, {
    List<String> tags = const [],
    NotePrivacy privacy = NotePrivacy.private,
  });
  
  /// Update an existing note
  Future<Note> updateNote(String noteId, String? newContent, {
    List<String>? newTags,
    NotePrivacy? newPrivacy,
  });
  
  /// Delete a note
  Future<void> deleteNote(String noteId);
  
  /// Search notes across all books or specific book
  Future<List<Note>> searchNotes(String query, {String? bookId});
  
  /// Clear cache for a specific book or all books
  void clearCache({String? bookId});
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStats();
}
```

### ImportExportService

Service for importing and exporting notes.

```dart
class ImportExportService {
  static ImportExportService get instance;
  
  /// Export notes to JSON format
  Future<ExportResult> exportNotes({
    String? bookId,
    List<String>? noteIds,
    bool includeOrphans = true,
    bool includePrivateNotes = true,
    String? filePath,
  });
  
  /// Import notes from JSON format
  Future<ImportResult> importNotes(
    String jsonData, {
    bool overwriteExisting = false,
    bool validateAnchors = true,
    String? targetBookId,
    Function(int current, int total)? onProgress,
  });
  
  /// Import notes from file
  Future<ImportResult> importNotesFromFile(
    String filePath, {
    bool overwriteExisting = false,
    bool validateAnchors = true,
    String? targetBookId,
    Function(int current, int total)? onProgress,
  });
}
```

### AdvancedOrphanManager

Service for managing orphaned notes with smart re-anchoring.

```dart
class AdvancedOrphanManager {
  static AdvancedOrphanManager get instance;
  
  /// Find potential anchor candidates for an orphan note
  Future<List<AnchorCandidate>> findCandidatesForOrphan(
    Note orphan,
    CanonicalDocument document,
  );
  
  /// Auto-reanchor orphans with high confidence scores
  Future<List<AutoReanchorResult>> autoReanchorOrphans(
    List<Note> orphans,
    CanonicalDocument document, {
    double confidenceThreshold = 0.9,
  });
  
  /// Get orphan statistics and recommendations
  OrphanAnalysis analyzeOrphans(List<Note> orphans);
}
```

### PerformanceOptimizer

Service for optimizing notes system performance.

```dart
class PerformanceOptimizer {
  static PerformanceOptimizer get instance;
  
  /// Start automatic performance optimization
  void startAutoOptimization();
  
  /// Stop automatic performance optimization
  void stopAutoOptimization();
  
  /// Run a complete optimization cycle
  Future<OptimizationResult> runOptimizationCycle();
  
  /// Get optimization status
  OptimizationStatus getOptimizationStatus();
  
  /// Force immediate optimization
  Future<OptimizationResult> forceOptimization();
}
```

### NotesTelemetry

Service for tracking notes performance and usage metrics.

```dart
class NotesTelemetry {
  static NotesTelemetry get instance;
  
  /// Track anchoring result (no sensitive data)
  static void trackAnchoringResult(
    String requestId,
    NoteStatus status,
    Duration duration,
    String strategy,
  );
  
  /// Track batch re-anchoring performance
  static void trackBatchReanchoring(
    String requestId,
    int noteCount,
    int successCount,
    Duration totalDuration,
  );
  
  /// Track search performance
  static void trackSearchPerformance(
    String query,
    int resultCount,
    Duration duration,
  );
  
  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats();
  
  /// Get aggregated metrics for reporting
  Map<String, dynamic> getAggregatedMetrics();
  
  /// Check if performance is within acceptable limits
  bool isPerformanceHealthy();
  
  /// Clear all metrics (for testing or privacy)
  void clearMetrics();
}
```

## UI Components

### NotesSidebar

Sidebar widget for displaying and managing notes.

```dart
class NotesSidebar extends StatefulWidget {
  const NotesSidebar({
    super.key,
    this.bookId,
    this.onClose,
    this.onNoteSelected,
    this.onNavigateToPosition,
  });
  
  final String? bookId;
  final VoidCallback? onClose;
  final Function(Note)? onNoteSelected;
  final Function(int, int)? onNavigateToPosition;
}
```

### NoteEditorDialog

Dialog widget for creating and editing notes.

```dart
class NoteEditorDialog extends StatefulWidget {
  const NoteEditorDialog({
    super.key,
    this.note,
    this.selectedText,
    this.charStart,
    this.charEnd,
    required this.onSave,
    this.onCancel,
  });
  
  final Note? note;
  final String? selectedText;
  final int? charStart;
  final int? charEnd;
  final Function(CreateNoteRequest) onSave;
  final VoidCallback? onCancel;
}
```

### NoteHighlight

Widget for highlighting notes in text.

```dart
class NoteHighlight extends StatefulWidget {
  const NoteHighlight({
    super.key,
    required this.note,
    required this.child,
    this.onTap,
    this.onLongPress,
  });
  
  final Note note;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
}
```

### OrphanNotesManager

Widget for managing orphaned notes and helping re-anchor them.

```dart
class OrphanNotesManager extends StatefulWidget {
  const OrphanNotesManager({
    super.key,
    required this.bookId,
    this.onClose,
  });
  
  final String bookId;
  final VoidCallback? onClose;
}
```

### NotesPerformanceDashboard

Widget for displaying notes performance metrics and health status.

```dart
class NotesPerformanceDashboard extends StatefulWidget {
  const NotesPerformanceDashboard({super.key});
}

class CompactPerformanceDashboard extends StatelessWidget {
  const CompactPerformanceDashboard({super.key});
}
```

## BLoC Pattern

### NotesBloc

Main BLoC for managing notes state.

```dart
class NotesBloc extends Bloc<NotesEvent, NotesState> {
  NotesBloc() : super(const NotesInitial());
}
```

### NotesEvent

Base class for all notes events.

```dart
abstract class NotesEvent extends Equatable {
  const NotesEvent();
}

class LoadNotesEvent extends NotesEvent;
class CreateNoteEvent extends NotesEvent;
class UpdateNoteEvent extends NotesEvent;
class DeleteNoteEvent extends NotesEvent;
class SearchNotesEvent extends NotesEvent;
class ReanchorNotesEvent extends NotesEvent;
class FindAnchorCandidatesEvent extends NotesEvent;
// ... and more
```

### NotesState

Base class for all notes states.

```dart
abstract class NotesState extends Equatable {
  const NotesState();
}

class NotesInitial extends NotesState;
class NotesLoading extends NotesState;
class NotesLoaded extends NotesState;
class NotesError extends NotesState;
class NotesSearchResults extends NotesState;
// ... and more
```

## Data Models

### Note

Represents a personal note attached to a specific text location.

```dart
class Note extends Equatable {
  const Note({
    required this.id,
    required this.bookId,
    required this.docVersionId,
    this.logicalPath,
    required this.charStart,
    required this.charEnd,
    required this.selectedTextNormalized,
    required this.textHash,
    required this.contextBefore,
    required this.contextAfter,
    required this.contextBeforeHash,
    required this.contextAfterHash,
    required this.rollingBefore,
    required this.rollingAfter,
    required this.status,
    required this.contentMarkdown,
    required this.authorUserId,
    required this.privacy,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.normalizationConfig,
  });
  
  final String id;
  final String bookId;
  final String docVersionId;
  final List<String>? logicalPath;
  final int charStart;
  final int charEnd;
  final String selectedTextNormalized;
  final String textHash;
  final String contextBefore;
  final String contextAfter;
  final String contextBeforeHash;
  final String contextAfterHash;
  final int rollingBefore;
  final int rollingAfter;
  final NoteStatus status;
  final String contentMarkdown;
  final String authorUserId;
  final NotePrivacy privacy;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String normalizationConfig;
}
```

### NoteStatus

Enumeration of possible note statuses.

```dart
enum NoteStatus {
  /// Note is anchored to its exact original location
  anchored,
  
  /// Note has been re-anchored to a new location due to text changes
  shifted,
  
  /// Note cannot be anchored to any location (orphaned)
  orphan,
}
```

### NotePrivacy

Enumeration of note privacy levels.

```dart
enum NotePrivacy {
  /// Note is private to the user
  private,
  
  /// Note can be shared with others
  shared,
}
```

## Configuration

### NotesConfig

Feature flags and configuration for the notes system.

```dart
class NotesConfig {
  static const bool enabled = true;
  static const bool highlightEnabled = true;
  static const bool fuzzyMatchingEnabled = false;
  static const bool encryptionEnabled = false;
  static const bool importExportEnabled = false;
  static const int maxNotesPerBook = 5000;
  static const int maxNoteSize = 32768;
  static const int reanchoringTimeoutMs = 50;
  static const int maxReanchoringBatchSize = 200;
  static const bool telemetryEnabled = true;
  static const int busyTimeoutMs = 5000;
}
```

### AnchoringConstants

Constants for the anchoring algorithm.

```dart
class AnchoringConstants {
  static const int contextWindowSize = 40;
  static const int maxContextDistance = 300;
  static const double levenshteinThreshold = 0.18;
  static const double jaccardThreshold = 0.82;
  static const double cosineThreshold = 0.82;
  static const int ngramSize = 3;
  static const double levenshteinWeight = 0.4;
  static const double jaccardWeight = 0.3;
  static const double cosineWeight = 0.3;
  static const int maxReanchoringTimeMs = 50;
  static const int maxPageLoadDelayMs = 16;
  static const int rollingHashWindowSize = 20;
  static const double candidateScoreDifference = 0.03;
}
```

## Error Handling

### Common Exceptions

```dart
class RepositoryException implements Exception;
class AnchoringException implements Exception;
class ImportException implements Exception;
class TimeoutException implements Exception;
```

## Performance Metrics

### Key Performance Indicators

- **Note Creation**: Target < 100ms average
- **Re-anchoring**: Target < 50ms per note average  
- **Search**: Target < 200ms for typical queries
- **Memory Usage**: Target < 50MB additional for 1000+ notes
- **Accuracy**: Target 98% after 5% text changes

### Telemetry Data

The system tracks performance metrics without logging sensitive content:

- Anchoring success rates by strategy
- Average processing times
- Search performance metrics
- Batch operation statistics
- Memory usage estimates

## Integration Examples

### Basic Integration

```dart
// Initialize notes system
final notesService = NotesIntegrationService.instance;

// In your book widget
class BookWidget extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BookTextView(
            onTextSelection: (selectedText, start, end) {
              _showNoteCreationDialog(selectedText, start, end);
            },
          ),
        ),
        NotesSidebar(
          bookId: widget.bookId,
          onNoteSelected: (note) {
            _navigateToNote(note);
          },
        ),
      ],
    );
  }
}
```

### BLoC Integration

```dart
class BookBloc extends Bloc<BookEvent, BookState> {
  final NotesBloc notesBloc;
  
  BookBloc({required this.notesBloc}) : super(BookInitial()) {
    on<LoadBookEvent>(_onLoadBook);
  }
  
  Future<void> _onLoadBook(LoadBookEvent event, Emitter<BookState> emit) async {
    // Load book content
    final bookContent = await loadBook(event.bookId);
    
    // Load notes for the book
    notesBloc.add(LoadNotesEvent(event.bookId));
    
    emit(BookLoaded(content: bookContent));
  }
}
```

### Context Menu Integration

```dart
Widget buildTextWithNotes(String text, String bookId) {
  return NotesContextMenuExtension.buildWithNotesSupport(
    context: context,
    bookId: bookId,
    child: SelectableText(
      text,
      onSelectionChanged: (selection, cause) {
        if (selection.isValid) {
          _showContextMenu(selection, bookId);
        }
      },
    ),
  );
}
```

## Testing

### Unit Testing

```dart
void main() {
  group('NotesIntegrationService', () {
    late NotesIntegrationService service;
    
    setUp(() {
      service = NotesIntegrationService.instance;
    });
    
    test('should create note from selection', () async {
      final note = await service.createNoteFromSelection(
        'test-book',
        'selected text',
        10,
        23,
        'Test note content',
      );
      
      expect(note.bookId, equals('test-book'));
      expect(note.contentMarkdown, equals('Test note content'));
    });
  });
}
```

### Integration Testing

```dart
void main() {
  testWidgets('Notes sidebar integration', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotesSidebar(
            bookId: 'test-book',
            onNoteSelected: (note) {
              // Handle note selection
            },
          ),
        ),
      ),
    );
    
    expect(find.text('הערות אישיות'), findsOneWidget);
  });
}
```

## Troubleshooting

### Common Issues

1. **Notes not appearing**: Check if notes are loaded for the correct book ID
2. **Performance issues**: Use telemetry to identify bottlenecks
3. **Orphan notes**: Use the Orphan Manager to re-anchor notes
4. **Search not working**: Rebuild the search index via performance optimizer

### Debug Information

```dart
// Get performance statistics
final stats = NotesTelemetry.instance.getPerformanceStats();
print('Performance stats: $stats');

// Check cache status
final cacheStats = notesService.getCacheStats();
print('Cache stats: $cacheStats');

// Get optimization status
final optimizationStatus = PerformanceOptimizer.instance.getOptimizationStatus();
print('Optimization status: $optimizationStatus');
```