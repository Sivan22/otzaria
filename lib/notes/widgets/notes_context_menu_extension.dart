import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../services/notes_telemetry.dart';
import 'note_editor_dialog.dart';

/// Extension for adding notes context menu to text selection
class NotesContextMenuExtension {
  /// Create note from selected text (simplified version)
  static void createNoteFromSelection(
    BuildContext context,
    String selectedText,
    int start,
    int end,
    String? bookId,
  ) {
    if (bookId == null || selectedText.trim().isEmpty) return;
    
    _createNoteFromSelection(context, selectedText, start, end);
  }

  /// Create a note from the selected text
  static void _createNoteFromSelection(
    BuildContext context,
    String selectedText,
    int start,
    int end,
  ) {
    // Track user action
    NotesTelemetry.trackUserAction('note_create_from_selection', {
      'content_length': selectedText.length,
    });

    // Show note editor dialog
    showDialog(
      context: context,
      builder: (context) => NoteEditorDialog(
        selectedText: selectedText,
        charStart: start,
        charEnd: end,
        onSave: (request) {
          context.read<NotesBloc>().add(CreateNoteEvent(request));
          // Dialog will be closed by the caller
        },
      ),
    );
  }

  /// Highlight the selected text
  static void highlightSelection(
    BuildContext context,
    String selectedText,
    int start,
    int end,
  ) {
    // Track user action
    NotesTelemetry.trackUserAction('text_highlight', {
      'content_length': selectedText.length,
    });

    // For now, just show a snackbar
    // In a full implementation, this would add highlighting to the text
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('הודגש: "${selectedText.length > 30 ? '${selectedText.substring(0, 30)}...' : selectedText}"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Build simple wrapper with notes support
  static Widget buildWithNotesSupport({
    required BuildContext context,
    required Widget child,
    required String? bookId,
  }) {
    return GestureDetector(
      onLongPress: () {
        if (bookId != null) {
          _showQuickNoteDialog(context, bookId);
        }
      },
      child: child,
    );
  }

  /// Show quick note creation dialog
  static void _showQuickNoteDialog(BuildContext context, String? bookId) {
    if (bookId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('הערה מהירה'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('בחר טקסט כדי ליצור הערה'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // This would trigger text selection mode
              },
              child: const Text('בחר טקסט'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
        ],
      ),
    );
  }
}

/// Custom context menu button for notes
class NotesContextMenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const NotesContextMenuButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: color ?? Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color ?? Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mixin for widgets that want to support notes context menu
mixin NotesContextMenuMixin<T extends StatefulWidget> on State<T> {
  /// Current book ID for context
  String? get currentBookId;

  /// Build context menu with notes support
  Widget buildWithNotesContextMenu(Widget child) {
    return NotesContextMenuExtension.buildWithNotesSupport(
      context: context,
      bookId: currentBookId,
      child: child,
    );
  }

  /// Handle text selection for note creation
  void handleTextSelectionForNote(String selectedText, int start, int end) {
    if (selectedText.trim().isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => NoteEditorDialog(
        selectedText: selectedText,
        charStart: start,
        charEnd: end,
        onSave: (request) {
          context.read<NotesBloc>().add(CreateNoteEvent(request));
          // Dialog will be closed by the caller
        },
      ),
    );
  }
}