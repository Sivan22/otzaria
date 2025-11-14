import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otzaria/i18n/translations.g.dart';

/// דיאלוג אישור עם תמיכה באנטר וחיצים
class ConfirmationDialog extends StatefulWidget {
  final String title;
  final String content;
  final String? cancelText;
  final String? confirmText;
  final Color? confirmColor;
  final bool isDangerous;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.cancelText,
    this.confirmText,
    this.confirmColor,
    this.isDangerous = false,
  });

  @override
  State<ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  int _focusedButtonIndex = 1; // 0 = ביטול, 1 = אישור (ברירת מחדל)

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }

        // חיצים - מעבר בין כפתורים
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
            event.logicalKey == LogicalKeyboardKey.arrowRight) {
          setState(() {
            _focusedButtonIndex = _focusedButtonIndex == 0 ? 1 : 0;
          });
          return KeyEventResult.handled;
        }

        // אנטר - לחיצה על הכפתור הממוקד
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          Navigator.of(context).pop(_focusedButtonIndex == 1);
          return KeyEventResult.handled;
        }

        // Escape - ביטול
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop(false);
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: AlertDialog(
        title: Text(widget.title),
        content: Text(widget.content),
        actions: [
          _buildButton(
            text: widget.cancelText ?? context.t.common.cancel,
            isFocused: _focusedButtonIndex == 0,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          _buildButton(
            text: widget.confirmText ?? context.t.common.confirm,
            isFocused: _focusedButtonIndex == 1,
            isConfirm: true,
            onPressed: () => Navigator.of(context).pop(true),
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
    final color = isConfirm
        ? (widget.confirmColor ??
            (widget.isDangerous ? Colors.red : Theme.of(context).primaryColor))
        : null;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: isFocused
            ? (color ?? Theme.of(context).primaryColor).withValues(alpha: 0.1)
            : null,
        foregroundColor: color,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

/// הצגת דיאלוג אישור
Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String? cancelText,
  String? confirmText,
  Color? confirmColor,
  bool isDangerous = false,
  bool barrierDismissible = true,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => ConfirmationDialog(
      title: title,
      content: content,
      cancelText: cancelText,
      confirmText: confirmText,
      confirmColor: confirmColor,
      isDangerous: isDangerous,
    ),
  );
}
