import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart' as ctx;
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_state.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_state.dart';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/text_book/view/combined_view/commentary_list_for_combined_view.dart';
import 'package:otzaria/text_book/view/links_screen.dart';
import 'package:otzaria/widgets/progressive_scrolling.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;
import 'package:otzaria/text_book/bloc/text_book_event.dart';
import 'package:otzaria/notes/notes_system.dart';
import 'package:otzaria/utils/copy_utils.dart';
import 'package:super_clipboard/super_clipboard.dart';

class CombinedView extends StatefulWidget {
  CombinedView({
    super.key,
    required this.data,
    required this.openBookCallback,
    required this.openLeftPaneTab,
    required this.textSize,
    required this.showSplitedView,
    required this.tab,
  });

  final List<String> data;
  final Function(OpenedTab) openBookCallback;
  final void Function(int) openLeftPaneTab;
  final ValueNotifier<bool> showSplitedView;
  final double textSize;
  final TextBookTab tab;

  @override
  State<CombinedView> createState() => _CombinedViewState();
}

class _CombinedViewState extends State<CombinedView> {
  final GlobalKey<SelectionAreaState> _selectionKey =
      GlobalKey<SelectionAreaState>();
  bool _didInitialJump = false;

  void _jumpToInitialIndexWhenReady() {
    int attempts = 0;
    void tryJump(Duration _) {
      if (!mounted) return;
      final ctrl = widget.tab.scrollController;
      if (ctrl.isAttached) {
        ctrl.jumpTo(index: widget.tab.index);
      } else if (attempts++ < 5) {
        WidgetsBinding.instance.addPostFrameCallback(tryJump);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback(tryJump);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitialJump) {
      _didInitialJump = true;
      _jumpToInitialIndexWhenReady();
    }
  }

  // הוסרנו את _showNotesSidebar המקומי - נשתמש ב-state מה-BLoC

  // מעקב אחר בחירת טקסט בלי setState
  String? _selectedText;
  int? _selectionStart;
  int? _selectionEnd;

  // שמירת הבחירה האחרונה לשימוש בתפריט הקונטקסט
  String? _lastSelectedText;
  int? _lastSelectionStart;
  int? _lastSelectionEnd;

  // מעקב אחר האינדקס הנוכחי שנבחר
  int? _currentSelectedIndex;

  /// helper קטן שמחזיר רשימת MenuEntry מקבוצה אחת, כולל כפתור הצג/הסתר הכל
  List<ctx.MenuItem<void>> _buildGroup(
    String groupName,
    List<String>? group,
    TextBookLoaded st,
  ) {
    if (group == null || group.isEmpty) return const [];

    final bool groupActive =
        group.every((title) => st.activeCommentators.contains(title));

    return [
      ctx.MenuItem<void>(
        label: 'הצג את כל ${groupName}',
        icon: groupActive ? Icons.check : null,
        onSelected: () {
          final current = List<String>.from(st.activeCommentators);
          if (groupActive) {
            current.removeWhere(group.contains);
          } else {
            for (final title in group) {
              if (!current.contains(title)) current.add(title);
            }
          }
          context.read<TextBookBloc>().add(UpdateCommentators(current));
        },
      ),
      ...group.map((title) {
        final bool isActive = st.activeCommentators.contains(title);
        return ctx.MenuItem<void>(
          label: title,
          icon: isActive ? Icons.check : null,
          onSelected: () {
            final current = List<String>.from(st.activeCommentators);
            current.contains(title)
                ? current.remove(title)
                : current.add(title);
            context.read<TextBookBloc>().add(UpdateCommentators(current));
          },
        );
      }),
    ];
  }

// + בניית תפריט קונטקסט "מקובע" לאינדקס ספציפי של פסקה
  ctx.ContextMenu _buildContextMenuForIndex(
      TextBookLoaded state, int paragraphIndex) {
    // 1. קבלת מידע על גודל המסך
    final screenHeight = MediaQuery.of(context).size.height;

    // 2. זיהוי פרשנים שכבר שויכו לקבוצה
    final Set<String> alreadyListed = {
      ...state.torahShebichtav,
      ...state.chazal,
      ...state.rishonim,
      ...state.acharonim,
      ...state.modernCommentators,
    };

    // 3. יצירת רשימה של פרשנים שלא שויכו לאף קבוצה
    final List<String> ungrouped = state.availableCommentators
        .where((c) => !alreadyListed.contains(c))
        .toList();

    return ctx.ContextMenu(
      maxHeight: screenHeight * 0.9,
      entries: [
        ctx.MenuItem(
            label: 'חיפוש', onSelected: () => widget.openLeftPaneTab(1)),
        ctx.MenuItem.submenu(
          label: 'מפרשים',
          items: [
            ctx.MenuItem(
              label: 'הצג את כל המפרשים',
              icon: state.activeCommentators
                      .toSet()
                      .containsAll(state.availableCommentators)
                  ? Icons.check
                  : null,
              onSelected: () {
                final allActive = state.activeCommentators
                    .toSet()
                    .containsAll(state.availableCommentators);
                context.read<TextBookBloc>().add(
                      UpdateCommentators(
                        allActive
                            ? <String>[]
                            : List<String>.from(state.availableCommentators),
                      ),
                    );
              },
            ),
            const ctx.MenuDivider(),
            ..._buildGroup('תורה שבכתב', state.torahShebichtav, state),
            if (state.torahShebichtav.isNotEmpty && state.chazal.isNotEmpty)
              const ctx.MenuDivider(),
            ..._buildGroup('חז\"ל', state.chazal, state),
            if ((state.chazal.isNotEmpty && state.rishonim.isNotEmpty) ||
                (state.chazal.isEmpty &&
                    state.torahShebichtav.isNotEmpty &&
                    state.rishonim.isNotEmpty))
              const ctx.MenuDivider(),
            ..._buildGroup('הראשונים', state.rishonim, state),
            if ((state.rishonim.isNotEmpty && state.acharonim.isNotEmpty) ||
                (state.rishonim.isEmpty &&
                    state.chazal.isNotEmpty &&
                    state.acharonim.isNotEmpty) ||
                (state.rishonim.isEmpty &&
                    state.chazal.isEmpty &&
                    state.torahShebichtav.isNotEmpty &&
                    state.acharonim.isNotEmpty))
              const ctx.MenuDivider(),
            ..._buildGroup('האחרונים', state.acharonim, state),
            if ((state.acharonim.isNotEmpty &&
                    state.modernCommentators.isNotEmpty) ||
                (state.acharonim.isEmpty &&
                    state.rishonim.isNotEmpty &&
                    state.modernCommentators.isNotEmpty) ||
                (state.acharonim.isEmpty &&
                    state.rishonim.isEmpty &&
                    state.chazal.isNotEmpty &&
                    state.modernCommentators.isNotEmpty) ||
                (state.acharonim.isEmpty &&
                    state.rishonim.isEmpty &&
                    state.chazal.isEmpty &&
                    state.torahShebichtav.isNotEmpty &&
                    state.modernCommentators.isNotEmpty))
              const ctx.MenuDivider(),
            ..._buildGroup('מחברי זמננו', state.modernCommentators, state),
            if ((state.torahShebichtav.isNotEmpty ||
                    state.chazal.isNotEmpty ||
                    state.rishonim.isNotEmpty ||
                    state.acharonim.isNotEmpty ||
                    state.modernCommentators.isNotEmpty) &&
                ungrouped.isNotEmpty)
              const ctx.MenuDivider(),
            ..._buildGroup('שאר המפרשים', ungrouped, state),
          ],
        ),
        ctx.MenuItem.submenu(
          label: 'קישורים',
          enabled: LinksViewer.getLinks(state).isNotEmpty,
          items: LinksViewer.getLinks(state)
              .map(
                (link) => ctx.MenuItem(
                  label: link.heRef,
                  onSelected: () {
                    widget.openBookCallback(
                      TextBookTab(
                        book: TextBook(
                          title: utils.getTitleFromPath(link.path2),
                        ),
                        index: link.index2 - 1,
                        openLeftPane:
                            (Settings.getValue<bool>('key-pin-sidebar') ??
                                    false) ||
                                (Settings.getValue<bool>(
                                        'key-default-sidebar-open') ??
                                    false),
                      ),
                    );
                  },
                ),
              )
              .toList(),
        ),
        const ctx.MenuDivider(),
        // הערות אישיות
        ctx.MenuItem(
          label: () {
            final text = _lastSelectedText ?? _selectedText;
            if (text == null || text.trim().isEmpty) {
              return 'הוסף הערה אישית';
            }
            final preview =
                text.length > 12 ? '${text.substring(0, 12)}...' : text;
            return 'הוסף הערה ל: "$preview"';
          }(),
          onSelected: () => _createNoteFromSelection(),
        ),
        const ctx.MenuDivider(),
        // העתקה
        ctx.MenuItem(
          label: 'העתק',
          enabled: (_lastSelectedText ?? _selectedText) != null &&
              (_lastSelectedText ?? _selectedText)!.trim().isNotEmpty,
          onSelected: _copyFormattedText,
        ),
        // + שים לב לשינוי בפונקציה שנקראת וב-enabled
        ctx.MenuItem(
          label: 'העתק את כל הפסקה',
          enabled: paragraphIndex >= 0 && paragraphIndex < widget.data.length,
          onSelected: () => _copyParagraphByIndex(
              paragraphIndex), // <--- קריאה לפונקציה החדשה עם האינדקס
        ),
        ctx.MenuItem(
          label: 'העתק את הטקסט המוצג',
          onSelected: _copyVisibleText,
        ),
      ],
    );
  }

  /// זיהוי האינדקס של הטקסט הנבחר
  int? _findIndexByText(String selectedText) {
    final cleanedSelected = selectedText.replaceAll(RegExp(r'\s+'), ' ').trim();

    for (int i = 0; i < widget.data.length; i++) {
      final originalData = widget.data[i];
      final cleanedOriginal = originalData
          .replaceAll(RegExp(r'<[^>]*>'), '') // הסרת תגי HTML
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (cleanedOriginal.contains(cleanedSelected) ||
          cleanedSelected.contains(cleanedOriginal)) {
        return i;
      }
    }
    return null;
  }

  /// יצירת הערה מטקסט נבחר
  void _createNoteFromSelection() {
    // נשתמש בבחירה האחרונה שנשמרה, או בבחירה הנוכחית
    final text = _lastSelectedText ?? _selectedText;
    if (text == null || text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('אנא בחר טקסט ליצירת הערה אישית'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final start = _lastSelectionStart ?? _selectionStart ?? 0;
    final end = _lastSelectionEnd ?? _selectionEnd ?? text.length;
    _showNoteEditor(text, start, end);
  }

  /// העתקת פסקה לפי אינדקס (משתמש ב־widget.data[index] ומייצר גם HTML)
  Future<void> _copyParagraphByIndex(int index) async {
    if (index < 0 || index >= widget.data.length) return;

    final text = widget.data[index];
    if (text.trim().isEmpty) return;

    // קבלת ההגדרות הנוכחיות
    final settingsState = context.read<SettingsBloc>().state;
    final textBookState = context.read<TextBookBloc>().state;
    
    String finalText = text;
    String finalHtmlText = text;
    
    // אם צריך להוסיף כותרות
    if (settingsState.copyWithHeaders != 'none' && textBookState is TextBookLoaded) {
      final bookName = CopyUtils.extractBookName(textBookState.book);
      final currentPath = await CopyUtils.extractCurrentPath(
        textBookState.book, 
        index,
        bookContent: textBookState.content,
      );
      
      finalText = CopyUtils.formatTextWithHeaders(
        originalText: text,
        copyWithHeaders: settingsState.copyWithHeaders,
        copyHeaderFormat: settingsState.copyHeaderFormat,
        bookName: bookName,
        currentPath: currentPath,
      );
      
      finalHtmlText = CopyUtils.formatTextWithHeaders(
        originalText: text,
        copyWithHeaders: settingsState.copyWithHeaders,
        copyHeaderFormat: settingsState.copyHeaderFormat,
        bookName: bookName,
        currentPath: currentPath,
      );
    }

    final item = DataWriterItem();
    item.add(Formats.plainText(finalText));
    item.add(Formats.htmlText(_formatTextAsHtml(finalHtmlText)));

    await SystemClipboard.instance?.write([item]);
  }

  /// העתקת הטקסט המוצג במסך ללוח
  void _copyVisibleText() async {
    final state = context.read<TextBookBloc>().state;
    if (state is! TextBookLoaded || state.visibleIndices.isEmpty) return;

    // איסוף כל הטקסט הנראה במסך
    final visibleTexts = <String>[];
    for (final index in state.visibleIndices) {
      if (index >= 0 && index < widget.data.length) {
        visibleTexts.add(widget.data[index]);
      }
    }

    if (visibleTexts.isEmpty) return;

    final combinedText = visibleTexts.join('\n\n');
    
    // קבלת ההגדרות הנוכחיות
    final settingsState = context.read<SettingsBloc>().state;
    
    String finalText = combinedText;
    
    // אם צריך להוסיף כותרות
    if (settingsState.copyWithHeaders != 'none') {
      final bookName = CopyUtils.extractBookName(state.book);
      final firstVisibleIndex = state.visibleIndices.first;
      final currentPath = await CopyUtils.extractCurrentPath(
        state.book, 
        firstVisibleIndex,
        bookContent: state.content,
      );
      
      finalText = CopyUtils.formatTextWithHeaders(
        originalText: combinedText,
        copyWithHeaders: settingsState.copyWithHeaders,
        copyHeaderFormat: settingsState.copyHeaderFormat,
        bookName: bookName,
        currentPath: currentPath,
      );
    }
    
    final combinedHtml = finalText.split('\n\n').map(_formatTextAsHtml).join('<br><br>');

    final item = DataWriterItem();
    item.add(Formats.plainText(finalText));
    item.add(Formats.htmlText(combinedHtml));

    await SystemClipboard.instance?.write([item]);
  }

  /// עיצוב טקסט כ-HTML עם הגדרות הגופן הנוכחיות
  String _formatTextAsHtml(String text) {
    final settingsState = context.read<SettingsBloc>().state;
    // ממיר \n ל-<br> ב-HTML
    final textWithBreaks = text.replaceAll('\n', '<br>');
    return '''
<div style="font-family: ${settingsState.fontFamily}; font-size: ${widget.textSize}px; text-align: justify; direction: rtl;">
$textWithBreaks
</div>
''';
  }

  /// העתקת טקסט רגיל ללוח
  Future<void> _copyPlainText() async {
    final text = _lastSelectedText ?? _selectedText;
    if (text == null || text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('אנא בחר טקסט להעתקה'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard != null) {
        // קבלת ההגדרות הנוכחיות
        final settingsState = context.read<SettingsBloc>().state;
        final textBookState = context.read<TextBookBloc>().state;
        
        String finalText = text;
        
        // אם צריך להוסיף כותרות
        if (settingsState.copyWithHeaders != 'none' && textBookState is TextBookLoaded) {
          final bookName = CopyUtils.extractBookName(textBookState.book);
          final currentIndex = _currentSelectedIndex ?? 0;
          final currentPath = await CopyUtils.extractCurrentPath(
            textBookState.book, 
            currentIndex,
            bookContent: textBookState.content,
          );
          
          finalText = CopyUtils.formatTextWithHeaders(
            originalText: text,
            copyWithHeaders: settingsState.copyWithHeaders,
            copyHeaderFormat: settingsState.copyHeaderFormat,
            bookName: bookName,
            currentPath: currentPath,
          );
        }

        final item = DataWriterItem();
        item.add(Formats.plainText(finalText));
        await clipboard.write([item]);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('הטקסט הועתק ללוח'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בהעתקה: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// העתקת טקסט מעוצב (HTML) ללוח
  Future<void> _copyFormattedText() async {
    final plainText = _lastSelectedText ?? _selectedText;
    if (plainText == null || plainText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('אנא בחר טקסט להעתקה'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard != null) {
        // קבלת ההגדרות הנוכחיות לעיצוב
        final settingsState = context.read<SettingsBloc>().state;
        final textBookState = context.read<TextBookBloc>().state;

        // ניסיון למצוא את הטקסט המקורי עם תגי HTML
        String htmlContentToUse = plainText;

        // אם יש לנו אינדקס נוכחי, ננסה למצוא את הטקסט המקורי
        if (_currentSelectedIndex != null &&
            _currentSelectedIndex! >= 0 &&
            _currentSelectedIndex! < widget.data.length) {
          final originalData = widget.data[_currentSelectedIndex!];

          // בדיקה אם הטקסט הפשוט מופיע בטקסט המקורי
          final plainTextCleaned =
              plainText.replaceAll(RegExp(r'\s+'), ' ').trim();
          final originalCleaned = originalData
              .replaceAll(RegExp(r'<[^>]*>'), '') // הסרת תגי HTML
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          // אם הטקסט הפשוט תואם לטקסט המקורי (או חלק ממנו), נשתמש במקורי
          if (originalCleaned.contains(plainTextCleaned) ||
              plainTextCleaned.contains(originalCleaned)) {
            htmlContentToUse = originalData;
          }
        }

        // הוספת כותרות אם נדרש
        String finalPlainText = plainText;
        if (settingsState.copyWithHeaders != 'none' && textBookState is TextBookLoaded) {
          final bookName = CopyUtils.extractBookName(textBookState.book);
          final currentIndex = _currentSelectedIndex ?? 0;
          final currentPath = await CopyUtils.extractCurrentPath(
            textBookState.book, 
            currentIndex,
            bookContent: textBookState.content,
          );
          
          finalPlainText = CopyUtils.formatTextWithHeaders(
            originalText: plainText,
            copyWithHeaders: settingsState.copyWithHeaders,
            copyHeaderFormat: settingsState.copyHeaderFormat,
            bookName: bookName,
            currentPath: currentPath,
          );
          
          // גם עדכון ה-HTML עם הכותרות
          htmlContentToUse = CopyUtils.formatTextWithHeaders(
            originalText: htmlContentToUse,
            copyWithHeaders: settingsState.copyWithHeaders,
            copyHeaderFormat: settingsState.copyHeaderFormat,
            bookName: bookName,
            currentPath: currentPath,
          );
        }

        // יצירת HTML מעוצב עם הגדרות הגופן והגודל
        // ממיר \n ל-<br> ב-HTML
        final htmlWithBreaks = htmlContentToUse.replaceAll('\n', '<br>');
        final finalHtmlContent = '''
<div style="font-family: ${settingsState.fontFamily}; font-size: ${widget.textSize}px; text-align: justify; direction: rtl;">
$htmlWithBreaks
</div>
''';

        final item = DataWriterItem();
        item.add(Formats.plainText(finalPlainText)); // טקסט רגיל כגיבוי
        item.add(Formats.htmlText(
            finalHtmlContent)); // טקסט מעוצב עם תגי HTML מקוריים
        await clipboard.write([item]);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('הטקסט המעוצב הועתק ללוח'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בהעתקה מעוצבת: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// הצגת עורך ההערות
  void _showNoteEditor(String selectedText, int charStart, int charEnd) {
    // שמירת ה-context המקורי וה-bloc
    final originalContext = context;
    final textBookBloc = context.read<TextBookBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => NoteEditorDialog(
        selectedText: selectedText,
        bookId: widget.tab.book.title,
        charStart: charStart,
        charEnd: charEnd,
        onSave: (noteRequest) async {
          try {
            final notesService = NotesIntegrationService.instance;
            final bookId = widget.tab.book.title;
            await notesService.createNoteFromSelection(
              bookId,
              selectedText,
              charStart,
              charEnd,
              noteRequest.contentMarkdown,
              tags: noteRequest.tags,
              privacy: noteRequest.privacy,
            );

            if (mounted) {
              // Dialog is already closed by NoteEditorDialog
              // הצגת סרגל ההערות אם הוא לא פתוח
              final currentState = textBookBloc.state;
              if (currentState is TextBookLoaded &&
                  !currentState.showNotesSidebar) {
                textBookBloc.add(const ToggleNotesSidebar());
              }
              ScaffoldMessenger.of(originalContext).showSnackBar(
                const SnackBar(content: Text('ההערה נוצרה והוצגה בסרגל')),
              );
            }
          } catch (e) {
            if (mounted) {
              // Dialog is already closed by NoteEditorDialog
              ScaffoldMessenger.of(originalContext).showSnackBar(
                SnackBar(content: Text('שגיאה ביצירת הערה: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Widget buildKeyboardListener() {
    return BlocBuilder<TextBookBloc, TextBookState>(
      bloc: context.read<TextBookBloc>(),
      builder: (context, state) {
        if (state is! TextBookLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        return ProgressiveScroll(
          maxSpeed: 10000.0,
          curve: 10.0,
          accelerationFactor: 5,
          scrollController: widget.tab.mainOffsetController,
          child: SelectionArea(
            key: _selectionKey,
            contextMenuBuilder: (_, __) => const SizedBox.shrink(),
            onSelectionChanged: (selection) {
              final text = selection?.plainText ?? '';
              if (text.isEmpty) {
                _selectedText = null;
                _selectionStart = null;
                _selectionEnd = null;
                _currentSelectedIndex = null;
                // עדכון ה-BLoC שאין טקסט נבחר
                context
                    .read<TextBookBloc>()
                    .add(const UpdateSelectedTextForNote(null, null, null));
              } else {
                _selectedText = text;
                _selectionStart = 0;
                _selectionEnd = text.length;

                // ניסיון לזהות את האינדקס על בסיס התוכן
                _currentSelectedIndex = _findIndexByText(text);

                // שמירת הבחירה האחרונה
                _lastSelectedText = text;
                _lastSelectionStart = 0;
                _lastSelectionEnd = text.length;

                // עדכון ה-BLoC עם הטקסט הנבחר
                context
                    .read<TextBookBloc>()
                    .add(UpdateSelectedTextForNote(text, 0, text.length));
              }
              // בלי setState – כדי לא לרנדר את כל העץ תוך כדי גרירת הבחירה
            },
            // שים לב: אין כאן יותר ContextMenuRegion עוטף את כל הרשימה.
            child: buildOuterList(state),
          ),
        );
      },
    );
  }

  Widget buildOuterList(TextBookLoaded state) {
    return ScrollablePositionedList.builder(
      key: ValueKey('combined-${widget.tab.book.title}'),
      itemPositionsListener: widget.tab.positionsListener,
      itemScrollController: widget.tab.scrollController,
      scrollOffsetController: widget.tab.mainOffsetController,
      itemCount: widget.data.length,
      itemBuilder: (context, index) {
        ExpansibleController controller = ExpansibleController();
        return buildExpansiomTile(controller, index, state);
      },
    );
  }

  Widget buildExpansiomTile(
    ExpansibleController controller,
    int index,
    TextBookLoaded state,
  ) {
    // עוטפים את כל ה־ExpansionTile בתפריט קונטקסט ספציפי לאינדקס הנוכחי:
    return ctx.ContextMenuRegion(
      contextMenu: _buildContextMenuForIndex(state, index),
      child: ExpansionTile(
        shape: const Border(),
        controller: controller,
        key: PageStorageKey(widget.data[index]),
        iconColor: Colors.transparent,
        tilePadding: const EdgeInsets.all(0.0),
        collapsedIconColor: Colors.transparent,
        title: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, settingsState) {
            String data = widget.data[index];
            if (!settingsState.showTeamim) {
              data = utils.removeTeamim(data);
            }
            if (settingsState.replaceHolyNames) {
              data = utils.replaceHolyNames(data);
            }
            return HtmlWidget(
              '''
              <div style="text-align: justify; direction: rtl;">
                ${() {
                String processedData = state.removeNikud
                    ? utils.highLight(
                        utils.removeVolwels('$data\n'), state.searchText)
                    : utils.highLight('$data\n', state.searchText);
                // החלת עיצוב הסוגריים העגולים
                return utils.formatTextWithParentheses(processedData);
              }()}
              </div>
              ''',
              textStyle: TextStyle(
                fontSize: widget.textSize,
                fontFamily: settingsState.fontFamily,
                height: 1.5,
              ),
            );
          },
        ),
        children: [
          widget.showSplitedView.value
              ? const SizedBox.shrink()
              : CommentaryListForCombinedView(
                  index: index,
                  fontSize: widget.textSize,
                  openBookCallback: widget.openBookCallback,
                  showSplitView: false,
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookView = buildKeyboardListener();

    // אם סרגל ההערות פתוח, הצג אותו לצד התוכן
    return BlocBuilder<TextBookBloc, TextBookState>(
      builder: (context, state) {
        if (state is! TextBookLoaded) return bookView;

        if (state.showNotesSidebar) {
          return Row(
            children: [
              Expanded(flex: 3, child: bookView),
              Container(
                width: 1,
                color: Theme.of(context).dividerColor,
              ),
              Expanded(
                flex: 1,
                child: _NotesSection(
                  bookId: widget.tab.book.title,
                  onClose: () => context
                      .read<TextBookBloc>()
                      .add(const ToggleNotesSidebar()),
                ),
              ),
            ],
          );
        }

        return bookView;
      },
    );
  }
}

/// Widget נפרד לסרגל ההערות כדי למנוע rebuilds מיותרים של הטקסט
class _NotesSection extends StatelessWidget {
  final String bookId;
  final VoidCallback onClose;

  const _NotesSection({
    required this.bookId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return NotesSidebar(
      bookId: bookId,
      onClose: onClose,
      onNavigateToPosition: (start, end) {
        // ניווט למיקום ההערה בטקסט
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ניווט למיקום $start-$end'),
          ),
        );
      },
    );
  }
}
