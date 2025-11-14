import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/text_book_bloc.dart';
import '../../bloc/text_book_event.dart';

import '../services/preview_renderer.dart';
import '../models/editor_settings.dart';
import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:otzaria/core/scaffold_messenger.dart';
import 'package:otzaria/widgets/confirmation_dialog.dart';
import 'markdown_toolbar.dart';
import 'package:otzaria/i18n/translations.g.dart';

/// Full-screen dialog for editing text sections with split-pane interface
///
/// Key features:
/// - No auto-save drafts - saves only when user clicks save
/// - Background rendering with debouncing for smooth typing
/// - Toolbar positioned on the right side above editor
/// - HTML tags support (not Markdown)
/// - Parallel column layout for simultaneous editing and preview
class TextSectionEditorDialog extends StatefulWidget {
  final String bookId;
  final int sectionIndex;
  final String sectionId;
  final String initialContent;
  final bool hasLinksFile;
  final bool hasDraft;
  final EditorSettings settings;

  const TextSectionEditorDialog({
    super.key,
    required this.bookId,
    required this.sectionIndex,
    required this.sectionId,
    required this.initialContent,
    required this.hasLinksFile,
    required this.hasDraft,
    required this.settings,
  });

  @override
  State<TextSectionEditorDialog> createState() =>
      _TextSectionEditorDialogState();
}

class _TextSectionEditorDialogState extends State<TextSectionEditorDialog> {
  late TextEditingController _textController;
  late PreviewRenderer _previewRenderer;
  Timer? _debounceTimer;

  bool _hasUnsavedChanges = false;
  String _previewContent = '';
  final FocusNode _editorFocusNode = FocusNode();
  String? _lastSearchText; // לשמירת טקסט החיפוש האחרון עבור F3

  // Undo functionality
  final List<String> _undoStack = [];
  final List<TextSelection> _undoSelectionStack = [];
  int _undoIndex = -1;
  bool _isUndoRedoOperation = false;

  late ScrollController _editorScrollController;
  late ScrollController _previewScrollController;
  bool _isSyncingScroll = false;

  // Background rendering state
  bool _isRenderingInBackground = false;
  Isolate? _renderIsolate;
  ReceivePort? _receivePort;

  // Performance optimizations
  String _lastRenderedContent = '';

  // Static variable to track if notification was shown this session
  static bool _hasShownNotification = false;

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController(text: widget.initialContent);
    _previewRenderer = PreviewRenderer();
    _previewContent = widget.initialContent;

    _editorScrollController = ScrollController();
    _previewScrollController = ScrollController();

    _editorScrollController.addListener(_syncScrollFromEditor);
    _previewScrollController.addListener(_syncScrollFromPreview);

    // Initialize undo stack with initial content
    _saveToUndoStack(widget.initialContent,
        TextSelection.collapsed(offset: widget.initialContent.length));

    // Listen to text changes
    _textController.addListener(_onTextChanged);

    // Show first-time notification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showFirstTimeNotification();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _debounceTimer?.cancel();
    _renderIsolate?.kill();
    _receivePort?.close();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    _previewScrollController.dispose();
    super.dispose();
  }

  void _syncScrollFromEditor() {
    if (_isSyncingScroll) return;

    setState(() {
      _isSyncingScroll = true;
    });

    final editorOffset = _editorScrollController.offset;
    final editorMaxScroll = _editorScrollController.position.maxScrollExtent;
    final previewMaxScroll = _previewScrollController.position.maxScrollExtent;

    if (editorMaxScroll > 0 && previewMaxScroll > 0) {
      final scrollFraction = editorOffset / editorMaxScroll;
      _previewScrollController.jumpTo(scrollFraction * previewMaxScroll);
    }

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _isSyncingScroll = false;
        });
      }
    });
  }

  void _syncScrollFromPreview() {
    if (_isSyncingScroll) return;

    setState(() {
      _isSyncingScroll = true;
    });

    final previewOffset = _previewScrollController.offset;
    final previewMaxScroll = _previewScrollController.position.maxScrollExtent;
    final editorMaxScroll = _editorScrollController.position.maxScrollExtent;

    if (previewMaxScroll > 0 && editorMaxScroll > 0) {
      final scrollFraction = previewOffset / previewMaxScroll;
      _editorScrollController.jumpTo(scrollFraction * editorMaxScroll);
    }

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _isSyncingScroll = false;
        });
      }
    });
  }

  void _renderPreviewInBackground(String content) async {
    if (_isRenderingInBackground || content == _lastRenderedContent) {
      // Skip if already rendering or content hasn't changed
      return;
    }

    setState(() {
      _isRenderingInBackground = true;
    });

    // Use HTML caching in MarkdownProcessor for better performance
    await Future.delayed(const Duration(milliseconds: 50));

    if (mounted) {
      setState(() {
        _previewContent = content;
        _lastRenderedContent = content;
        _isRenderingInBackground = false;
      });
    }
  }

  void _showFirstTimeNotification() {
    // Only show once per session
    if (!mounted || _hasShownNotification) return;

    _hasShownNotification = true;

    UiSnack.showFloating(
        'שים לב: השינויים נשמרים מקומית בלבד, ובמקרה של עדכון הספרייה, השינויים ימחקו!');
  }

  void _save() {
    context.read<TextBookBloc>().add(SaveEditedSection(
          index: widget.sectionIndex,
          sectionId: widget.sectionId,
          markdown: _textController.text,
        ));

    setState(() {
      _hasUnsavedChanges = false;
    });

    // Trigger content refresh to ensure the main viewer shows updated content
    Future.delayed(const Duration(milliseconds: 100), () async {
      if (mounted) {
        try {
          // Force a content reload from file system to ensure refresh
          final dataProvider = FileSystemData.instance;
          await dataProvider.getBookText(widget.bookId);

          // Show success feedback
          UiSnack.showSuccess(context.t.messages.savedSuccessfully);
        } catch (e) {
          debugPrint('Failed to verify save: $e');
          // Still show success feedback even if verification fails
          UiSnack.show(context.t.messages.savedSuccessfully);
        }
      }
    });
  }

  void _saveAndClose() {
    _save();
    Navigator.of(context).pop();
  }

  void _discardChanges() async {
    if (_hasUnsavedChanges) {
      final confirmed = await showConfirmationDialog(
        context: context,
        title: context.t.editor.discardChanges,
        content: context.t.editor.discardChangesConfirm,
        confirmText: context.t.editor.discardChanges,
        isDangerous: true,
      );

      if (confirmed == true && mounted) {
        Navigator.of(context).pop();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  void _insertText(String text) {
    final selection = _textController.selection;
    final currentText = _textController.text;

    if (widget.hasLinksFile && text.contains('\n')) {
      // Prevent line breaks in books with links
      UiSnack.show('בספר זה אסור לשנות מבנה שורות כדי לשמור על קישורי פרשנות');
      return;
    }

    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      text,
    );

    _textController.text = newText;
    _textController.selection = TextSelection.collapsed(
      offset: selection.start + text.length,
    );
  }

  void _wrapSelection(String prefix, String suffix) {
    final selection = _textController.selection;
    final currentText = _textController.text;
    final selectedText = selection.textInside(currentText);

    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      '$prefix$selectedText$suffix',
    );

    _textController.text = newText;
    _textController.selection = TextSelection(
      baseOffset: selection.start + prefix.length,
      extentOffset: selection.start + prefix.length + selectedText.length,
    );
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;

      if (isCtrlPressed) {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.keyS:
            _save();
            return true;
          case LogicalKeyboardKey.enter:
            _saveAndClose();
            return true;
          case LogicalKeyboardKey.keyB:
            _wrapSelection('<b>', '</b>');
            return true;
          case LogicalKeyboardKey.keyI:
            _wrapSelection('<i>', '</i>');
            return true;
          case LogicalKeyboardKey.keyK:
            _showLinkDialog();
            return true;
          case LogicalKeyboardKey.keyA:
            // Select all text
            _textController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _textController.text.length,
            );
            return true;
          case LogicalKeyboardKey.keyF:
            // Open search dialog
            _showSearchDialog();
            return true;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _discardChanges();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.enter &&
          widget.hasLinksFile) {
        // Prevent Enter in books with links
        UiSnack.show(
            'בספר זה אסור לשנות מבנה שורות כדי לשמור על קישורי פרשנות');
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.f3) {
        // F3 - Find next
        if (_lastSearchText != null && _lastSearchText!.isNotEmpty) {
          _performSearch(_lastSearchText!);
        }
        return true;
      }
    }

    return false;
  }

  // Undo functionality methods
  void _saveToUndoStack(String text, TextSelection selection) {
    if (_isUndoRedoOperation) return;

    // Remove any redo states if we're adding a new change
    if (_undoIndex < _undoStack.length - 1) {
      _undoStack.removeRange(_undoIndex + 1, _undoStack.length);
      _undoSelectionStack.removeRange(
          _undoIndex + 1, _undoSelectionStack.length);
    }

    _undoStack.add(text);
    _undoSelectionStack.add(selection);
    _undoIndex = _undoStack.length - 1;

    // Limit undo stack to prevent memory issues
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
      _undoSelectionStack.removeAt(0);
      _undoIndex--;
    }
  }

  void _undo() {
    if (_undoIndex > 0) {
      _undoIndex--;
      _isUndoRedoOperation = true;
      _textController.text = _undoStack[_undoIndex];
      _textController.selection = _undoSelectionStack[_undoIndex];
      _previewContent = _undoStack[_undoIndex];
      _isUndoRedoOperation = false;
    }
  }

  void _onTextChanged() {
    if (!_isUndoRedoOperation) {
      _saveToUndoStack(_textController.text, _textController.selection);
    }

    setState(() {
      _hasUnsavedChanges = _textController.text != widget.initialContent;
    });

    // Debounce preview updates and render in background
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.settings.previewDebounce, () {
      if (mounted) {
        _renderPreviewInBackground(_textController.text);
      }
    });
  }

  void _showLinkDialog() {
    showDialog(
      context: context,
      builder: (context) => _LinkInsertDialog(
        onInsert: (text, url) {
          _insertText('[$text]($url)');
        },
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => _SearchDialog(
        onSearch: (searchText) => _performSearch(searchText),
      ),
    );
  }

  void _performSearch(String searchText) {
    if (searchText.isEmpty) return;

    // שמירת טקסט החיפוש עבור F3
    _lastSearchText = searchText;

    final currentText = _textController.text;
    final currentSelection = _textController.selection;

    // Find the search text after current cursor position
    int searchStart = currentSelection.end;
    int foundIndex = currentText.indexOf(searchText, searchStart);

    // If not found from cursor, search from beginning
    if (foundIndex == -1) {
      foundIndex = currentText.indexOf(searchText, 0);
    }

    // If still not found, search case-insensitive
    if (foundIndex == -1) {
      final searchLower = searchText.toLowerCase();
      final textLower = currentText.toLowerCase();
      searchStart = currentSelection.end;
      var tempIndex = textLower.indexOf(searchLower, searchStart);

      // If not found from cursor, search from beginning
      if (tempIndex == -1) {
        tempIndex = textLower.indexOf(searchLower, 0);
      }

      if (tempIndex != -1) {
        foundIndex = tempIndex;
        searchText =
            currentText.substring(tempIndex, tempIndex + searchText.length);
      }
    }

    if (foundIndex != -1) {
      // ================== התחלת התיקון ==================

      // הערכה של מיקום הגלילה.
      // 1. חשב את מספר השורות עד לתוצאה.
      final linesUpToFound =
          '\n'.allMatches(currentText.substring(0, foundIndex)).length;

      // 2. הערך את הגובה הממוצע של שורה (למשל, 20 פיקסלים. אפשר לשפר את זה בעתיד).
      const averageLineHeight = 20.0;
      final estimatedScrollOffset = linesUpToFound * averageLineHeight;

      // 3. ודא שהגלילה לא חורגת מהגבולות.
      final maxScroll = _editorScrollController.position.maxScrollExtent;
      final targetOffset = estimatedScrollOffset.clamp(0.0, maxScroll);

      // גלול למיקום המוערך
      _editorScrollController.animateTo(
        targetOffset, // <-- שימוש במיקום המחושב
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // =================== סוף התיקון ===================

      // Select the found text
      _textController.selection = TextSelection(
        baseOffset: foundIndex,
        extentOffset: foundIndex + searchText.length,
      );

      // Focus the editor
      _editorFocusNode.requestFocus();
    } else {
      // Show not found message
      UiSnack.show('הטקסט לא נמצא');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${_hasUnsavedChanges ? 'שינויים שלא נשמרו • ' : ''}עריכת טקסט - ${widget.bookId}',
            style: const TextStyle(fontSize: 16),
          ),
          leading: IconButton(
            icon: const Icon(FluentIcons.dismiss_24_regular),
            onPressed: _discardChanges,
          ),
          actions: [
            TextButton.icon(
              onPressed: _hasUnsavedChanges ? _save : null,
              icon: const Icon(FluentIcons.save_24_regular),
              label: Text(context.t.common.save),
            ),
            TextButton.icon(
              onPressed: _saveAndClose,
              icon: const Icon(FluentIcons.save_arrow_right_24_regular),
              label: Text(context.t.editor.saveAndExit),
            ),
          ],
        ),
        // ================== התחלת מבנה חדש ==================
        body: Column(
          children: [
            // שורת הכותרות העליונה
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      border: Border(
                        bottom: BorderSide(color: theme.dividerColor),
                        left: BorderSide(color: theme.dividerColor),
                      ),
                    ),
                    child: const Text(
                      'עריכה',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      border: Border(
                        bottom: BorderSide(color: theme.dividerColor),
                      ),
                    ),
                    child: const Text(
                      'תצוגה מקדימה',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            // שורה 2: סרגל הכלים - משותף לכל הרוחב
            MarkdownToolbar(
              onBold: () => _wrapSelection('<b>', '</b>'),
              onItalic: () => _wrapSelection('<i>', '</i>'),
              onHeader1: () => _wrapSelection('<h1>', '</h1>'),
              onHeader2: () => _wrapSelection('<h2>', '</h2>'),
              onHeader3: () => _wrapSelection('<h3>', '</h3>'),
              onUnorderedList: () =>
                  _wrapSelection('<ul>\n<li>', '</li>\n</ul>'),
              onOrderedList: () => _wrapSelection('<ol>\n<li>', '</li>\n</ol>'),
              onLink: _showLinkDialog,
              onCode: () => _wrapSelection('<code>', '</code>'),
              onQuote: () => _wrapSelection('<blockquote>', '</blockquote>'),
              onUndo: _undo,
              onRedo: () {/* TODO: Implement redo */},
              onSearch: _showSearchDialog,
              hasLinksFile: widget.hasLinksFile,
            ),
            // שורה 3: החלוניות עצמן
            Expanded(
              child: Row(
                children: [
                  // חלונית העריכה (ימין)
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        border:
                            Border(left: BorderSide(color: theme.dividerColor)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        scrollController: _editorScrollController,
                        controller: _textController,
                        focusNode: _editorFocusNode,
                        maxLines: null,
                        expands: true,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'TaameyAshkenaz',
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'התחל לכתוב כאן...',
                          hintTextDirection: TextDirection.rtl,
                        ),
                        onChanged: (text) {
                          // ... לוגיקה של onChanged נשארת זהה
                        },
                      ),
                    ),
                  ),
                  // חלונית התצוגה המקדימה (שמאל)
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      controller: _previewScrollController,
                      padding: const EdgeInsets.all(
                          16), // הוספת padding גם כאן ליישור
                      child: _previewRenderer.renderPreview(
                        markdown: _previewContent,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'TaameyAshkenaz',
                        ),
                        fontFamily: 'TaameyAshkenaz',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // =================== סוף המבנה החדש ===================
      ),
    );
  }
}

/// Dialog for search functionality
class _SearchDialog extends StatefulWidget {
  final Function(String) onSearch;

  const _SearchDialog({required this.onSearch});

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final searchText = _searchController.text.trim();
    if (searchText.isNotEmpty) {
      widget.onSearch(searchText);
      // Don't close dialog - allow multiple searches
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.t.editor.searchInText),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: context.t.editor.enterTextToSearch,
              hintText: context.t.editor.whatToSearch,
              prefixIcon: Icon(FluentIcons.search_24_regular),
            ),
            textDirection: TextDirection.rtl,
            autofocus: true,
            onSubmitted: (_) => _performSearch(),
          ),
          const SizedBox(height: 8),
          Text(
            context.t.editor.searchHint,
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t.common.close),
        ),
        ElevatedButton(
          onPressed: _performSearch,
          child: Text(context.t.common.search),
        ),
      ],
    );
  }
}

/// Dialog for inserting links
class _LinkInsertDialog extends StatefulWidget {
  final Function(String text, String url) onInsert;

  const _LinkInsertDialog({required this.onInsert});

  @override
  State<_LinkInsertDialog> createState() => _LinkInsertDialogState();
}

class _LinkInsertDialogState extends State<_LinkInsertDialog> {
  final _textController = TextEditingController();
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onInsert(_textController.text, _urlController.text);
            Navigator.of(context).pop();
            return null;
          },
        ),
      },
      child: AlertDialog(
        title: Text(context.t.editor.addLink),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _textController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.t.editor.linkText,
                hintText: context.t.editor.clickHere,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: context.t.editor.urlAddress,
                hintText: 'https://example.com',
              ),
              textDirection: TextDirection.ltr,
              onSubmitted: (_) {
                widget.onInsert(_textController.text, _urlController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.t.common.cancel),
          ),
          TextButton(
            onPressed: () {
              widget.onInsert(_textController.text, _urlController.text);
              Navigator.of(context).pop();
            },
            child: Text(context.t.editor.add),
          ),
        ],
      ),
    );
  }
}
