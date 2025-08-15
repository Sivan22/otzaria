import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note.dart';
import '../repository/notes_repository.dart';

/// Dialog for creating and editing notes
class NoteEditorDialog extends StatefulWidget {
  final Note? existingNote;
  final String? selectedText;
  final String? bookId;
  final int? charStart;
  final int? charEnd;
  final Function(CreateNoteRequest)? onSave;
  final Function(String, UpdateNoteRequest)? onUpdate;
  final VoidCallback? onDelete;

  const NoteEditorDialog({
    super.key,
    this.existingNote,
    this.selectedText,
    this.bookId,
    this.charStart,
    this.charEnd,
    this.onSave,
    this.onUpdate,
    this.onDelete,
  });

  @override
  State<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<NoteEditorDialog> {
  late TextEditingController _contentController;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    
    // Initialize controller with existing note data or defaults
    _contentController = TextEditingController(
      text: widget.existingNote?.contentMarkdown ?? '',
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// Check if this is an edit operation
  bool get _isEditing => widget.existingNote != null;

  /// Get dialog title
  String get _dialogTitle => _isEditing ? 'עריכת הערה' : 'הערה חדשה';

  /// Handle save operation
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final content = _contentController.text.trim();

      if (_isEditing) {
        // Update existing note
        final request = UpdateNoteRequest(
          contentMarkdown: content,
          privacy: NotePrivacy.private, // Always private
          tags: [], // No tags
        );
        
        widget.onUpdate?.call(widget.existingNote!.id, request);
      } else {
        // Create new note
        if (widget.bookId == null || widget.charStart == null || widget.charEnd == null) {
          throw Exception('Missing required data for creating note');
        }

        final request = CreateNoteRequest(
          bookId: widget.bookId!,
          charStart: widget.charStart!,
          charEnd: widget.charEnd!,
          contentMarkdown: content,
          authorUserId: 'default_user', // Default user for now
          privacy: NotePrivacy.private, // Always private
          tags: [], // No tags
        );
        
        widget.onSave?.call(request);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשמירת הערה: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handle delete operation
  Future<void> _handleDelete() async {
    if (!_isEditing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת הערה'),
        content: const Text('האם אתה בטוח שברצונך למחוק הערה זו?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('מחק'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onDelete?.call();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(
          maxHeight: 500,
          minHeight: 300,
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dialogTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Selected text preview (for new notes)
              if (!_isEditing && widget.selectedText != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'טקסט נבחר:',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.selectedText!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Content input - adaptive height
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 120,
                  maxHeight: 300,
                ),
                child: TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'תוכן ההערה',
                    hintText: 'כתוב את ההערה שלך כאן...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  minLines: 4,
                  textAlignVertical: TextAlignVertical.top,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'תוכן ההערה לא יכול להיות ריק';
                    }
                    return null;
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(32768), // Max note size
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  if (_isEditing) ...[
                    TextButton.icon(
                      onPressed: _isLoading ? null : _handleDelete,
                      icon: const Icon(Icons.delete),
                      label: const Text('מחק'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const Spacer(),
                  ] else
                    const Spacer(),
                  
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('ביטול'),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  FilledButton(
                    onPressed: _isLoading ? null : _handleSave,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? 'עדכן' : 'שמור'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Show note editor dialog
Future<void> showNoteEditorDialog({
  required BuildContext context,
  Note? existingNote,
  String? selectedText,
  String? bookId,
  int? charStart,
  int? charEnd,
  Function(CreateNoteRequest)? onSave,
  Function(String, UpdateNoteRequest)? onUpdate,
  VoidCallback? onDelete,
}) {
  return showDialog(
    context: context,
    builder: (context) => NoteEditorDialog(
      existingNote: existingNote,
      selectedText: selectedText,
      bookId: bookId,
      charStart: charStart,
      charEnd: charEnd,
      onSave: onSave,
      onUpdate: onUpdate,
      onDelete: onDelete,
    ),
  );
}