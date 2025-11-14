import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otzaria/i18n/translations.g.dart';

class PersonalNoteEditorDialog extends StatefulWidget {
  final TextEditingController controller;
  final String title;

  PersonalNoteEditorDialog({
    super.key,
    TextEditingController? controller,
    this.title = '',
  }) : controller = controller ?? TextEditingController();

  @override
  State<PersonalNoteEditorDialog> createState() =>
      _PersonalNoteEditorDialogState();
}

class _PersonalNoteEditorDialogState extends State<PersonalNoteEditorDialog> {
  int _focusedButtonIndex = 1; // 0 = ביטול, 1 = שמור (ברירת מחדל)
  final FocusNode _textFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textFieldFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }

        // Alt + Enter - שליחת הטופס מכל מקום
        if (event.logicalKey == LogicalKeyboardKey.enter &&
            HardwareKeyboard.instance.isAltPressed) {
          _submit();
          return KeyEventResult.handled;
        }

        // אם הפוקוס בשדה הטקסט, אנטר רגיל עושה ירידת שורה
        if (_textFieldFocusNode.hasFocus) {
          return KeyEventResult.ignored;
        }

        // אם הפוקוס בכפתורים - חיצים ואנטר
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
            event.logicalKey == LogicalKeyboardKey.arrowRight) {
          setState(() {
            _focusedButtonIndex = _focusedButtonIndex == 0 ? 1 : 0;
          });
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (_focusedButtonIndex == 1) {
            _submit();
          } else {
            Navigator.of(context).pop();
          }
          return KeyEventResult.handled;
        }

        // Escape - ביטול
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: AlertDialog(
        title: Text(widget.title.isEmpty ? context.t.notes.newNote : widget.title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: TextField(
            controller: widget.controller,
            focusNode: _textFieldFocusNode,
            minLines: 5,
            maxLines: 12,
            autofocus: true,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: context.t.notes.writeNoteHere,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          _buildButton(
            text: context.t.common.cancel,
            isFocused: _focusedButtonIndex == 0,
            onPressed: () => Navigator.of(context).pop(),
          ),
          _buildButton(
            text: context.t.common.save,
            isFocused: _focusedButtonIndex == 1,
            isConfirm: true,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required bool isFocused,
    required VoidCallback onPressed,
    bool isConfirm = false,
  }) {
    final showHover = isFocused && !_textFieldFocusNode.hasFocus;

    if (isConfirm) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: showHover
              ? Theme.of(context).primaryColor.withValues(alpha: 0.9)
              : null,
        ),
        child: Text(text),
      );
    } else {
      return TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: showHover
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : null,
        ),
        child: Text(text),
      );
    }
  }
}
