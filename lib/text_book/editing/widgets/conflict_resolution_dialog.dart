import 'package:flutter/material.dart';
import '../services/overrides_rebase_service.dart';
import 'package:otzaria/i18n/translations.g.dart';

/// Dialog for resolving rebase conflicts
class ConflictResolutionDialog extends StatefulWidget {
  final RebaseContext context;
  final Function(String resolution) onResolve;

  const ConflictResolutionDialog({
    super.key,
    required this.context,
    required this.onResolve,
  });

  @override
  State<ConflictResolutionDialog> createState() =>
      _ConflictResolutionDialogState();
}

class _ConflictResolutionDialogState extends State<ConflictResolutionDialog> {
  String _selectedResolution = 'keep_override';

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onResolve(_selectedResolution);
            Navigator.of(context).pop();
            return null;
          },
        ),
      },
      child: AlertDialog(
        title: Text(context.t.editor.conflictInEditing),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: RadioGroup<String>(
            groupValue: _selectedResolution,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedResolution = value);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.t.editor.conflictMessage,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),

                // Resolution options
                RadioListTile<String>(
                  title: Text(context.t.editor.keepMyEdit),
                  subtitle: Text(context.t.editor.ignoreSourceChanges),
                  value: 'keep_override',
                ),
                RadioListTile<String>(
                  title: Text(context.t.editor.useNewVersion),
                  subtitle: Text(context.t.editor.cancelMyEdit),
                  value: 'use_new_source',
                ),
                RadioListTile<String>(
                  title: Text(context.t.editor.saveSeparately),
                  subtitle: Text(context.t.editor.saveAsSeparateVersion),
                  value: 'save_separate',
                ),

                const SizedBox(height: 16),

                // Three-way diff preview
                Expanded(
                  child: Row(
                    children: [
                      // Original
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'מקור ישן',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color:
                                          Colors.grey.withValues(alpha: 0.3)),
                                ),
                                child: SingleChildScrollView(
                                  child: Text(
                                    widget.context.originalContent,
                                    style: const TextStyle(fontSize: 12),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 4),

                      // Edited
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                border: Border.all(
                                    color: Colors.blue.withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'העריכה שלי',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color:
                                          Colors.blue.withValues(alpha: 0.3)),
                                ),
                                child: SingleChildScrollView(
                                  child: Text(
                                    widget.context.overrideContent,
                                    style: const TextStyle(fontSize: 12),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 4),

                      // New source
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'מקור חדש',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color:
                                          Colors.green.withValues(alpha: 0.3)),
                                ),
                                child: SingleChildScrollView(
                                  child: Text(
                                    widget.context.newSourceContent,
                                    style: const TextStyle(fontSize: 12),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.t.common.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onResolve(_selectedResolution);
              Navigator.of(context).pop();
            },
            child: Text(context.t.editor.resolveConflict),
          ),
        ],
      ),
    );
  }
}

/// Shows a conflict resolution dialog
Future<String?> showConflictResolutionDialog({
  required BuildContext context,
  required RebaseContext rebaseContext,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ConflictResolutionDialog(
      context: rebaseContext,
      onResolve: (resolution) => Navigator.of(context).pop(resolution),
    ),
  );
}
