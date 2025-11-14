import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otzaria/i18n/translations.g.dart';

/// דיאלוג לקליטת קיצור מקשים מותאם אישית
class CustomShortcutDialog extends StatefulWidget {
  final String? initialShortcut;

  const CustomShortcutDialog({
    super.key,
    this.initialShortcut,
  });

  @override
  State<CustomShortcutDialog> createState() => _CustomShortcutDialogState();
}

class _CustomShortcutDialogState extends State<CustomShortcutDialog> {
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  String _displayText = '';
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialShortcut != null) {
      _displayText = _formatShortcutForDisplay(widget.initialShortcut!);
    }
  }

  String _formatShortcutForDisplay(String shortcut) {
    return shortcut
        .replaceAll('ctrl+', 'CTRL + ')
        .replaceAll('shift+', 'SHIFT + ')
        .replaceAll('alt+', 'ALT + ')
        .replaceAll('meta+', 'WIN + ')
        .toUpperCase();
  }

  String _formatKeysToShortcut(Set<LogicalKeyboardKey> keys) {
    if (keys.isEmpty) return '';

    final List<String> parts = [];
    bool hasCtrl = false;
    bool hasShift = false;
    bool hasAlt = false;
    bool hasMeta = false;
    String? mainKey;

    for (final key in keys) {
      if (key == LogicalKeyboardKey.control ||
          key == LogicalKeyboardKey.controlLeft ||
          key == LogicalKeyboardKey.controlRight) {
        hasCtrl = true;
      } else if (key == LogicalKeyboardKey.shift ||
          key == LogicalKeyboardKey.shiftLeft ||
          key == LogicalKeyboardKey.shiftRight) {
        hasShift = true;
      } else if (key == LogicalKeyboardKey.alt ||
          key == LogicalKeyboardKey.altLeft ||
          key == LogicalKeyboardKey.altRight) {
        hasAlt = true;
      } else if (key == LogicalKeyboardKey.meta ||
          key == LogicalKeyboardKey.metaLeft ||
          key == LogicalKeyboardKey.metaRight) {
        hasMeta = true;
      } else {
        // מקש ראשי
        mainKey = _getKeyLabel(key);
      }
    }

    // בניית המחרוזת לפי סדר: ctrl, shift, alt, meta, mainKey
    if (hasCtrl) parts.add('ctrl');
    if (hasShift) parts.add('shift');
    if (hasAlt) parts.add('alt');
    if (hasMeta) parts.add('meta');
    if (mainKey != null) parts.add(mainKey);

    return parts.join('+');
  }

  String _getKeyLabel(LogicalKeyboardKey key) {
    // אותיות
    if (key.keyLabel.length == 1 &&
        key.keyLabel.toLowerCase() != key.keyLabel.toUpperCase()) {
      return key.keyLabel.toLowerCase();
    }

    // מספרים
    if (key == LogicalKeyboardKey.digit0) return '0';
    if (key == LogicalKeyboardKey.digit1) return '1';
    if (key == LogicalKeyboardKey.digit2) return '2';
    if (key == LogicalKeyboardKey.digit3) return '3';
    if (key == LogicalKeyboardKey.digit4) return '4';
    if (key == LogicalKeyboardKey.digit5) return '5';
    if (key == LogicalKeyboardKey.digit6) return '6';
    if (key == LogicalKeyboardKey.digit7) return '7';
    if (key == LogicalKeyboardKey.digit8) return '8';
    if (key == LogicalKeyboardKey.digit9) return '9';

    // מקשים מיוחדים
    if (key == LogicalKeyboardKey.comma) return 'comma';
    if (key == LogicalKeyboardKey.period) return 'period';
    if (key == LogicalKeyboardKey.slash) return 'slash';
    if (key == LogicalKeyboardKey.backslash) return 'backslash';
    if (key == LogicalKeyboardKey.semicolon) return 'semicolon';
    if (key == LogicalKeyboardKey.quote) return 'quote';
    if (key == LogicalKeyboardKey.bracketLeft) return 'bracketleft';
    if (key == LogicalKeyboardKey.bracketRight) return 'bracketright';
    if (key == LogicalKeyboardKey.minus) return 'minus';
    if (key == LogicalKeyboardKey.equal) return 'equal';
    if (key == LogicalKeyboardKey.space) return 'space';
    if (key == LogicalKeyboardKey.tab) return 'tab';
    if (key == LogicalKeyboardKey.enter) return 'enter';
    if (key == LogicalKeyboardKey.backspace) return 'backspace';
    if (key == LogicalKeyboardKey.delete) return 'delete';
    if (key == LogicalKeyboardKey.escape) return 'escape';
    if (key == LogicalKeyboardKey.arrowUp) return 'arrowup';
    if (key == LogicalKeyboardKey.arrowDown) return 'arrowdown';
    if (key == LogicalKeyboardKey.arrowLeft) return 'arrowleft';
    if (key == LogicalKeyboardKey.arrowRight) return 'arrowright';
    if (key == LogicalKeyboardKey.home) return 'home';
    if (key == LogicalKeyboardKey.end) return 'end';
    if (key == LogicalKeyboardKey.pageUp) return 'pageup';
    if (key == LogicalKeyboardKey.pageDown) return 'pagedown';

    // F keys
    if (key == LogicalKeyboardKey.f1) return 'f1';
    if (key == LogicalKeyboardKey.f2) return 'f2';
    if (key == LogicalKeyboardKey.f3) return 'f3';
    if (key == LogicalKeyboardKey.f4) return 'f4';
    if (key == LogicalKeyboardKey.f5) return 'f5';
    if (key == LogicalKeyboardKey.f6) return 'f6';
    if (key == LogicalKeyboardKey.f7) return 'f7';
    if (key == LogicalKeyboardKey.f8) return 'f8';
    if (key == LogicalKeyboardKey.f9) return 'f9';
    if (key == LogicalKeyboardKey.f10) return 'f10';
    if (key == LogicalKeyboardKey.f11) return 'f11';
    if (key == LogicalKeyboardKey.f12) return 'f12';

    return key.keyLabel.toLowerCase();
  }

  void _updateDisplay(BuildContext context) {
    if (_pressedKeys.isEmpty) {
      setState(() {
        _displayText = context.t.shortcuts.pressKeys;
      });
      return;
    }

    final shortcut = _formatKeysToShortcut(_pressedKeys);
    setState(() {
      _displayText = _formatShortcutForDisplay(shortcut);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Initialize display text if not set
    if (_displayText.isEmpty && widget.initialShortcut == null) {
      _displayText = context.t.shortcuts.pressKeys;
    }
    
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (!_isRecording) {
          // אם לא מקליטים, אפשר אנטר לאישור
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter &&
              _pressedKeys.isNotEmpty) {
            final shortcut = _formatKeysToShortcut(_pressedKeys);
            Navigator.pop(context, shortcut);
          }
          return;
        }

        if (event is KeyDownEvent) {
          setState(() {
            _pressedKeys.add(event.logicalKey);
          });
          _updateDisplay(context);
        } else if (event is KeyUpEvent) {
          // כאשר משחררים מקש, לא מסירים אותו מיד
          // נחכה שכל המקשים ישוחררו
        }
      },
      child: AlertDialog(
        title: Text(
          context.t.shortcuts
              .customShortcutTitle, // Old: 'הגדרת קיצור מקשים מותאם אישית'
          textAlign: TextAlign.right,
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.t.shortcuts
                    .pressKeysInstructions, // Old: 'לחץ על "התחל הקלטה" ואז לחץ על צירוף המקשים הרצוי'
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isRecording
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _isRecording ? Icons.keyboard : Icons.keyboard_outlined,
                      size: 48,
                      color: _isRecording
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _displayText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _isRecording
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_isRecording)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isRecording = false;
                    });
                  },
                  icon: const Icon(Icons.stop),
                  label: Text(
                      context.t.shortcuts.stopRecording), // Old: 'עצור הקלטה'
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _pressedKeys.clear();
                      _isRecording = true;
                      _displayText = context.t.shortcuts.pressKeys;
                    });
                    _updateDisplay(context);
                  },
                  icon: const Icon(Icons.fiber_manual_record),
                  label: Text(
                      context.t.shortcuts.startRecording), // Old: 'התחל הקלטה'
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.t.common.cancel), // Old: 'ביטול'
          ),
          TextButton(
            onPressed: _pressedKeys.isEmpty
                ? null
                : () {
                    final shortcut = _formatKeysToShortcut(_pressedKeys);
                    Navigator.pop(context, shortcut);
                  },
            child: Text(context.t.common.confirm), // Old: 'אישור'
          ),
        ],
      ),
    );
  }
}
