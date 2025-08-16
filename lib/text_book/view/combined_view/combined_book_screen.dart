import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
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

  // הוסרנו את _showNotesSidebar המקומי - נשתמש ב-state מה-BLoC

  // מעקב אחר בחירת טקסט בלי setState
  String? _selectedText;
  int? _selectionStart;
  int? _selectionEnd;

  // שמירת הבחירה האחרונה לשימוש בתפריט הקונטקסט
  String? _lastSelectedText;
  int? _lastSelectionStart;
  int? _lastSelectionEnd;

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

  ctx.ContextMenu _buildContextMenu(TextBookLoaded state) {
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
      // 4. הגדרת הגובה המקסימלי ל-70% מגובה המסך
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
            // תורה שבכתב
            ..._buildGroup('תורה שבכתב', state.torahShebichtav, state),

            // מוסיפים קו הפרדה רק אם יש גם תורה שבכתב וגם חזל
            if (state.torahShebichtav.isNotEmpty && state.chazal.isNotEmpty)
              const ctx.MenuDivider(),

            // חזל
            ..._buildGroup('חז"ל', state.chazal, state),

            // מוסיפים קו הפרדה בין חז"ל לראשונים, או בין תורה שבכתב לראשונים אם אין חז"ל
            if ((state.chazal.isNotEmpty && state.rishonim.isNotEmpty) ||
                (state.chazal.isEmpty &&
                    state.torahShebichtav.isNotEmpty &&
                    state.rishonim.isNotEmpty))
              const ctx.MenuDivider(),

            // ראשונים
            ..._buildGroup('הראשונים', state.rishonim, state),

            // מוסיפים קו הפרדה בין ראשונים לאחרונים, או מהקבוצה הקודמת לאחרונים
            if ((state.rishonim.isNotEmpty && state.acharonim.isNotEmpty) ||
                (state.rishonim.isEmpty &&
                    state.chazal.isNotEmpty &&
                    state.acharonim.isNotEmpty) ||
                (state.rishonim.isEmpty &&
                    state.chazal.isEmpty &&
                    state.torahShebichtav.isNotEmpty &&
                    state.acharonim.isNotEmpty))
              const ctx.MenuDivider(),

            // אחרונים
            ..._buildGroup('האחרונים', state.acharonim, state),

            // מוסיפים קו הפרדה בין אחרונים למחברי זמננו, או מהקבוצה הקודמת למחברי זמננו
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

            // מחברי זמננו
            ..._buildGroup('מחברי זמננו', state.modernCommentators, state),

            // הוסף קו הפרדה רק אם יש קבוצות אחרות וגם פרשנים לא-משויכים
            if ((state.torahShebichtav.isNotEmpty ||
                    state.chazal.isNotEmpty ||
                    state.rishonim.isNotEmpty ||
                    state.acharonim.isNotEmpty ||
                    state.modernCommentators.isNotEmpty) &&
                ungrouped.isNotEmpty)
              const ctx.MenuDivider(),

            // הוסף את רשימת הפרשנים הלא משויכים
            ..._buildGroup('שאר המפרשים', ungrouped, state),
          ],
        ),
        ctx.MenuItem.submenu(
          label: 'קישורים',
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
              return 'הוסף הערה';
            }
            final preview =
                text.length > 12 ? '${text.substring(0, 12)}...' : text;
            return 'הוסף הערה ל: "$preview"';
          }(),
          onSelected: () => _createNoteFromSelection(),
        ),
        const ctx.MenuDivider(),
        ctx.MenuItem(
          label: 'בחר את כל הטקסט',
          onSelected: () =>
              _selectionKey.currentState?.selectableRegion.selectAll(),
        ),
      ],
    );
  }

  /// יצירת הערה מטקסט נבחר
  void _createNoteFromSelection() {
    // נשתמש בבחירה האחרונה שנשמרה, או בבחירה הנוכחית
    final text = _lastSelectedText ?? _selectedText;
    if (text == null || text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('אנא בחר טקסט ליצירת הערה'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final start = _lastSelectionStart ?? _selectionStart ?? 0;
    final end = _lastSelectionEnd ?? _selectionEnd ?? text.length;
    _showNoteEditor(text, start, end);
  }

  /// הצגת עורך ההערות
  void _showNoteEditor(String selectedText, int charStart, int charEnd) {
    showDialog(
      context: context,
      builder: (context) => NoteEditorDialog(
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
              final currentState = context.read<TextBookBloc>().state;
              if (currentState is TextBookLoaded &&
                  !currentState.showNotesSidebar) {
                context.read<TextBookBloc>().add(const ToggleNotesSidebar());
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ההערה נוצרה והוצגה בסרגל')),
              );
            }
          } catch (e) {
            if (mounted) {
              // Dialog is already closed by NoteEditorDialog
              ScaffoldMessenger.of(context).showSnackBar(
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
          scrollController: state.scrollOffsetController,
          child: SelectionArea(
            key: _selectionKey,
            contextMenuBuilder: (_, __) => const SizedBox.shrink(),
            onSelectionChanged: (selection) {
              final text = selection?.plainText ?? '';
              if (text.isEmpty) {
                _selectedText = null;
                _selectionStart = null;
                _selectionEnd = null;
                // עדכון ה-BLoC שאין טקסט נבחר
                context.read<TextBookBloc>().add(const UpdateSelectedTextForNote(null, null, null));
              } else {
                _selectedText = text;
                _selectionStart = 0;
                _selectionEnd = text.length;

                // שמירת הבחירה האחרונה
                _lastSelectedText = text;
                _lastSelectionStart = 0;
                _lastSelectionEnd = text.length;
                
                // עדכון ה-BLoC עם הטקסט הנבחר
                context.read<TextBookBloc>().add(UpdateSelectedTextForNote(text, 0, text.length));
              }
              // בלי setState – כדי לא לרנדר את כל העץ תוך כדי גרירת הבחירה
            },
            child: ctx.ContextMenuRegion(
              // <-- ה-Region היחיד, במיקום הנכון
              contextMenu: _buildContextMenu(state),
              child: buildOuterList(state),
            ),
          ),
        );
      },
    );
  }

  Widget buildOuterList(TextBookLoaded state) {
    return ScrollablePositionedList.builder(
      key: PageStorageKey(widget.tab),
      initialScrollIndex: state.visibleIndices.first,
      itemPositionsListener: state.positionsListener,
      itemScrollController: state.scrollController,
      scrollOffsetController: state.scrollOffsetController,
      itemCount: widget.data.length,
      itemBuilder: (context, index) {
        ExpansibleController controller = ExpansibleController();
        return buildExpansiomTile(controller, index, state);
      },
    );
  }

  ExpansionTile buildExpansiomTile(
    ExpansibleController controller,
    int index,
    TextBookLoaded state,
  ) {
    return ExpansionTile(
      shape: const Border(),
      //maintainState: true,
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
          return Html(
            //remove nikud if needed
            data: state.removeNikud
                ? utils.highLight(
                    utils.removeVolwels('$data\n'),
                    state.searchText,
                  )
                : utils.highLight('$data\n', state.searchText),
            style: {
              'body': Style(
                  fontSize: FontSize(widget.textSize),
                  fontFamily: settingsState.fontFamily,
                  textAlign: TextAlign.justify),
            },
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
                child: NotesSidebar(
                  bookId: widget.tab.book.title,
                  onClose: () => context
                      .read<TextBookBloc>()
                      .add(const ToggleNotesSidebar()),
                  onNavigateToPosition: (start, end) {
                    // ניווט למיקום ההערה בטקסט
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ניווט למיקום $start-$end'),
                      ),
                    );
                  },
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
