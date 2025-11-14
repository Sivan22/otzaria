import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:otzaria/history/bloc/history_bloc.dart';
import 'package:otzaria/history/bloc/history_event.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_event.dart';
import 'package:otzaria/navigation/bloc/navigation_state.dart' show Screen;
import 'package:otzaria/pdf_book/pdf_book_screen.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_event.dart';
import 'package:otzaria/tabs/bloc/tabs_state.dart';
import 'package:otzaria/tabs/models/pdf_tab.dart';
import 'package:otzaria/tabs/models/searching_tab.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/search/view/full_text_search_screen.dart';
import 'package:otzaria/text_book/view/text_book_screen.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:otzaria/workspaces/view/workspace_switcher_dialog.dart';
import 'package:otzaria/history/history_dialog.dart';
import 'package:otzaria/bookmarks/bookmarks_dialog.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'dart:convert';
import 'package:otzaria/widgets/scrollable_tab_bar.dart';
import 'package:otzaria/settings/reading_settings_dialog.dart';
import 'package:window_manager/window_manager.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_state.dart';
import 'package:otzaria/i18n/translations.g.dart';
import 'package:otzaria/settings/settings_event.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

const double _kAppBarControlsWidth = 125.0;
const int _kActionButtonsCount = 2; // fullscreen + settings
const double _kActionButtonWidth = 56.0;

class _ReadingScreenState extends State<ReadingScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // האם יש אוברפלואו בטאבים (גלילה)? משמש לקביעת placeholder לדינמיות מרכוז/התפרשות
  bool _tabsOverflow = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Check if widget is still mounted before accessing context
    if (mounted) {
      try {
        context.read<HistoryBloc>().add(FlushHistory());
      } catch (e) {
        // Ignore errors during disposal
      }
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      context.read<HistoryBloc>().add(FlushHistory());
      context.read<TabsBloc>().add(const SaveTabs());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TabsBloc, TabsState>(
      listener: (context, state) {
        if (state.hasOpenTabs) {
          context
              .read<HistoryBloc>()
              .add(CaptureStateForHistory(state.currentTab!));
        }
      },
      listenWhen: (previous, current) =>
          previous.currentTabIndex != current.currentTabIndex,
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return BlocBuilder<TabsBloc, TabsState>(
            builder: (context, state) {
              if (!state.hasOpenTabs) {
                // קריאת הגדרות כדי להציג את קיצורי המקלדת
                final historyShortcut =
                    Settings.getValue<String>('key-shortcut-open-history') ??
                        'ctrl+h';
                final bookmarksShortcut =
                    Settings.getValue<String>('key-shortcut-open-bookmarks') ??
                        'ctrl+shift+b';
                final workspaceShortcut = Settings.getValue<String>(
                        'key-shortcut-switch-workspace') ??
                    'ctrl+k';

                return Scaffold(
                  appBar: AppBar(
                    key: ValueKey(
                        'appbar_empty_${historyShortcut}_${bookmarksShortcut}_$workspaceShortcut'),
                    leadingWidth: _kAppBarControlsWidth,
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // קבוצת היסטוריה וסימניות
                        IconButton(
                          icon: const Icon(FluentIcons.history_24_regular),
                          tooltip: context.t.reading.showHistoryTooltip
                              .replaceAll(
                                  '{shortcut}', historyShortcut.toUpperCase()),
                          onPressed: () => _showHistoryDialog(context),
                        ),
                        IconButton(
                          icon: const Icon(FluentIcons.bookmark_24_regular),
                          tooltip: context.t.reading.showBookmarksTooltip
                              .replaceAll('{shortcut}',
                                  bookmarksShortcut.toUpperCase()),
                          onPressed: () => _showBookmarksDialog(context),
                        ),
                        // קו מפריד
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.grey.shade400,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                        ),
                        // קבוצת שולחן עבודה
                        IconButton(
                          icon: const Icon(FluentIcons.add_square_24_regular),
                          tooltip: context.t.reading.switchWorkspaceTooltip
                              .replaceAll('{shortcut}',
                                  workspaceShortcut.toUpperCase()),
                          onPressed: () => _showSaveWorkspaceDialog(context),
                        ),
                      ],
                    ),
                    titleSpacing: 0,
                    centerTitle: true,
                    title: Text(context.t.navigation.reading),
                    actions: [
                      // כפתור מסך מלא
                      BlocBuilder<SettingsBloc, SettingsState>(
                        builder: (context, settingsState) {
                          return IconButton(
                            icon: Icon(settingsState.isFullscreen
                                ? FluentIcons.full_screen_minimize_24_regular
                                : FluentIcons.full_screen_maximize_24_regular),
                            tooltip: settingsState.isFullscreen
                                ? context.t.settings.fullscreen
                                : context.t.settings.fullscreen,
                            onPressed: () async {
                              final newFullscreenState =
                                  !settingsState.isFullscreen;
                              context
                                  .read<SettingsBloc>()
                                  .add(UpdateIsFullscreen(newFullscreenState));
                              await windowManager
                                  .setFullScreen(newFullscreenState);
                            },
                          );
                        },
                      ),
                      // כפתור הגדרות
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: IconButton(
                          icon: const Icon(FluentIcons.settings_24_regular),
                          tooltip: context.t.settings.bookDisplaySettings,
                          onPressed: () => showReadingSettingsDialog(context),
                          style: IconButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            context.t.common.empty,
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.read<NavigationBloc>().add(
                                    const NavigateToScreen(Screen.library),
                                  );
                            },
                            icon: const Icon(FluentIcons.library_24_regular),
                            label: Text(context.t.navigation.library),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final controller = TabController(
                length: state.tabs.length,
                vsync: this,
                initialIndex: state.currentTabIndex,
              );

              controller.addListener(() {
                if (controller.indexIsChanging &&
                    state.currentTabIndex < state.tabs.length) {
                  // שמירת המצב הנוכחי לפני המעבר לטאב אחר
                  debugPrint(
                      'DEBUG: מעבר בין טאבים - שמירת מצב טאב ${state.currentTabIndex}');
                  context.read<HistoryBloc>().add(CaptureStateForHistory(
                      state.tabs[state.currentTabIndex]));
                  // שמירת כל הטאבים לדיסק
                  context.read<TabsBloc>().add(const SaveTabs());
                }
                if (controller.index != state.currentTabIndex) {
                  debugPrint('DEBUG: עדכון טאב נוכחי ל-${controller.index}');
                  context.read<TabsBloc>().add(SetCurrentTab(controller.index));
                }
              });

              // קריאת הגדרות כדי לגרום ל-rebuild כשהן משתנות
              final historyShortcut =
                  Settings.getValue<String>('key-shortcut-open-history') ??
                      'ctrl+h';
              final bookmarksShortcut =
                  Settings.getValue<String>('key-shortcut-open-bookmarks') ??
                      'ctrl+shift+b';
              final workspaceShortcut =
                  Settings.getValue<String>('key-shortcut-switch-workspace') ??
                      'ctrl+k';
              final closeTabShortcut =
                  Settings.getValue<String>('key-shortcut-close-tab') ??
                      'ctrl+w';

              return Scaffold(
                appBar: AppBar(
                  key: ValueKey(
                      'appbar_${historyShortcut}_${bookmarksShortcut}_${workspaceShortcut}_$closeTabShortcut'),
                  // 1. משתמשים בקבוע שהגדרנו עבור הרוחב
                  leadingWidth: _kAppBarControlsWidth,
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // קבוצת היסטוריה וסימניות
                      IconButton(
                        icon: const Icon(FluentIcons.history_24_regular),
                        tooltip: context.t.reading.showHistoryTooltip
                            .replaceAll(
                                '{shortcut}', historyShortcut.toUpperCase()),
                        onPressed: () => _showHistoryDialog(context),
                      ),
                      IconButton(
                        icon: const Icon(FluentIcons.bookmark_24_regular),
                        tooltip: context.t.reading.showBookmarksTooltip
                            .replaceAll(
                                '{shortcut}', bookmarksShortcut.toUpperCase()),
                        onPressed: () => _showBookmarksDialog(context),
                      ),
                      // קו מפריד
                      Container(
                        height: 24,
                        width: 1,
                        color: Colors.grey.shade400,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                      // קבוצת שולחן עבודה עם אנימציה
                      IconButton(
                        icon: const Icon(FluentIcons.add_square_24_regular),
                        tooltip: context.t.reading.switchWorkspaceTooltip
                            .replaceAll(
                                '{shortcut}', workspaceShortcut.toUpperCase()),
                        onPressed: () => _showSaveWorkspaceDialog(context),
                      ),
                    ],
                  ),
                  titleSpacing: 0,
                  centerTitle: true,
                  title: Container(
                    // שימוש בכל גובה ה-AppBar כך שלא יהיה רווח למעלה
                    constraints:
                        const BoxConstraints(maxHeight: kToolbarHeight),
                    child: ScrollableTabBarWithArrows(
                      controller: controller,
                      // ממורכז את שורת הטאבים
                      tabAlignment: TabAlignment.center,
                      onOverflowChanged: (overflow) {
                        if (mounted) {
                          setState(() => _tabsOverflow = overflow);
                        }
                      },
                      tabs: state.tabs
                          .map((tab) => _buildTab(context, tab, state))
                          .toList(),
                    ),
                  ),
                  // שומרים תמיד מקום קבוע לימין כדי למנוע שינויי רוחב פתאומיים
                  actions: [
                    // רווח למרכוז - חישוב דינמי
                    // מפחיתים את רוחב הכפתורים מהרוחב הכולל
                    if (!_tabsOverflow)
                      const SizedBox(
                          width: _kAppBarControlsWidth -
                              (_kActionButtonsCount * _kActionButtonWidth)),
                    // כפתור מסך מלא - פעיל תמיד
                    BlocBuilder<SettingsBloc, SettingsState>(
                      builder: (context, settingsState) {
                        return IconButton(
                          icon: Icon(settingsState.isFullscreen
                              ? FluentIcons.full_screen_minimize_24_regular
                              : FluentIcons.full_screen_maximize_24_regular),
                          tooltip: settingsState.isFullscreen
                              ? context.t.settings.exitFullscreen
                              : context.t.settings.fullscreen,
                          onPressed: () async {
                            final newFullscreenState =
                                !settingsState.isFullscreen;
                            context
                                .read<SettingsBloc>()
                                .add(UpdateIsFullscreen(newFullscreenState));
                            await windowManager
                                .setFullScreen(newFullscreenState);
                          },
                        );
                      },
                    ),
                    // כפתור הגדרות בצד שמאל של שורת הטאבים
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: IconButton(
                        icon: const Icon(FluentIcons.settings_24_regular),
                        tooltip: context.t.settings.bookDisplaySettings,
                        onPressed: () => showReadingSettingsDialog(context),
                        style: IconButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                body: SizedBox.fromSize(
                  size: MediaQuery.of(context).size,
                  child: TabBarView(
                    controller: controller,
                    children:
                        state.tabs.map((tab) => _buildTabView(tab)).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTabView(OpenedTab tab) {
    if (tab is PdfBookTab) {
      return PdfBookScreen(
        key: PageStorageKey(tab),
        tab: tab,
      );
    } else if (tab is TextBookTab) {
      return BlocProvider.value(
          value: tab.bloc,
          child: TextBookViewerBloc(
            openBookCallback: (tab, {int index = 1}) {
              context.read<TabsBloc>().add(AddTab(tab));
            },
            tab: tab,
          ));
    } else if (tab is SearchingTab) {
      return FullTextSearchScreen(
        tab: tab,
        openBookCallback: (tab, {int index = 1}) {
          context.read<TabsBloc>().add(AddTab(tab));
        },
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTab(BuildContext context, OpenedTab tab, TabsState state) {
    final index = state.tabs.indexOf(tab);
    final isSelected = index == state.currentTabIndex;
    final closeTabShortcut =
        Settings.getValue<String>('key-shortcut-close-tab') ?? 'ctrl+w';

    return Listener(
      onPointerDown: (PointerDownEvent event) {
        if (event.buttons == 4) {
          closeTab(tab, context);
        }
      },
      child: ContextMenuRegion(
        contextMenu: ContextMenu(
          entries: [
            MenuItem(
                label: context.t.common.close,
                onSelected: () => closeTab(tab, context)),
            MenuItem(
                label: context.t.settings.closeAllBooks,
                onSelected: () => closeAllTabs(state, context)),
            MenuItem(
              label: context.t.tabs.closeOthers,
              onSelected: () => closeAllTabsButCurrent(state, context),
            ),
            MenuItem(
              label: context.t.tabs.clone,
              onSelected: () => context.read<TabsBloc>().add(CloneTab(tab)),
            ),
            // הוסרת אפשרות הצמדה לדף הבית לאחר הסרת דף הבית
            MenuItem.submenu(
              label: context.t.tabs.tabList,
              items: _getMenuItems(state.tabs, context),
            )
          ],
        ),
        child: Draggable<OpenedTab>(
          axis: Axis.horizontal,
          data: tab,
          childWhenDragging: const SizedBox.shrink(),
          feedback: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
              child: Text(
                tab is SearchingTab
                    ? '${tab.title}:  ${tab.queryController.text}'
                    : tab.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          child: DragTarget<OpenedTab>(
            onAcceptWithDetails: (draggedTab) {
              if (draggedTab.data == tab) return;
              final newIndex = state.tabs.indexOf(tab);
              context.read<TabsBloc>().add(MoveTab(draggedTab.data, newIndex));
            },
            builder: (context, candidateData, rejectedData) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- לוגיקה חדשה ומאוחדת לפס הפרדה שמופיע מימין לטאב ---
                // בסביבת RTL, הווידג'ט הראשון ברשימה מופיע הכי ימני במסך.
                if (
                    // תנאי 1: הצגת פס הפרדה בקצה הימני של כל הטאבים.
                    // הפס נוצר על ידי הטאב הראשון (index 0) כשהוא אינו פעיל.
                    (index == 0 && state.currentTabIndex != 0) ||
                        // תנאי 2: הצגת פס הפרדה בין שני טאבים.
                        // הפס נוצר על ידי הטאב הנוכחי (index) אם הוא וגם הטאב שלפניו (index - 1) אינם פעילים.
                        (index > 0 &&
                            state.currentTabIndex != index &&
                            state.currentTabIndex != index - 1))
                  Container(
                    width: 1,
                    height: 32,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    color: Colors.grey.shade400,
                  ),

                // הווידג'ט המרכזי שמכיל את הטאב עצמו (ללא שינוי).
                Container(
                  // ניצול מלא של גובה ה-AppBar, ללא רווח עליון
                  constraints: const BoxConstraints(maxHeight: kToolbarHeight),
                  padding: const EdgeInsets.only(
                      left: 6, right: 6, top: 0, bottom: 0),
                  child: CustomPaint(
                    painter: isSelected
                        ? _TabBackgroundPainter(
                            Theme.of(context).colorScheme.surfaceContainer)
                        : null,
                    foregroundPainter: isSelected ? _TabBorderPainter() : null,
                    child: Tab(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (tab is SearchingTab)
                              ValueListenableBuilder(
                                valueListenable: tab.queryController,
                                builder: (context, value, child) => Tooltip(
                                  message:
                                      '${tab.title}:  ${tab.queryController.text}',
                                  child: Text(
                                    truncate(
                                        '${tab.title}:  ${tab.queryController.text}',
                                        12),
                                  ),
                                ),
                              )
                            else if (tab is PdfBookTab)
                              Tooltip(
                                message: tab.title,
                                child: Row(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                          FluentIcons.document_pdf_24_regular,
                                          size: 16),
                                    ),
                                    Text(truncate(tab.title, 12)),
                                  ],
                                ),
                              )
                            else
                              Tooltip(
                                  message: tab.title,
                                  child: Text(truncate(tab.title, 12))),
                            Tooltip(
                              preferBelow: false,
                              message: closeTabShortcut.toUpperCase(),
                              child: IconButton(
                                constraints: const BoxConstraints(
                                  minWidth: 25,
                                  minHeight: 25,
                                  maxWidth: 25,
                                  maxHeight: 25,
                                ),
                                onPressed: () => closeTab(tab, context),
                                icon: const Icon(FluentIcons.dismiss_24_regular,
                                    size: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // --- לוגיקה לפס הפרדה שמופיע משמאל לטאב ---
                // משמש רק עבור הקצה השמאלי ביותר של כל הטאבים.
                // הפס נוצר על ידי הטאב האחרון כשהוא אינו פעיל.
                if (index == state.tabs.length - 1 &&
                    state.currentTabIndex != index)
                  Container(
                    width: 1,
                    height: 32,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    color: Colors.grey.shade400,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<ContextMenuEntry> _getMenuItems(
      List<OpenedTab> tabs, BuildContext context) {
    List<MenuItem> items = tabs
        .map((tab) => MenuItem(
              label: tab.title,
              onSelected: () {
                final index = tabs.indexOf(tab);
                context.read<TabsBloc>().add(SetCurrentTab(index));
              },
            ))
        .toList();

    items.sort((a, b) => a.label.compareTo(b.label));
    return items;
  }

  void _showSaveWorkspaceDialog(BuildContext context) {
    context.read<HistoryBloc>().add(FlushHistory());
    showDialog(
      context: context,
      builder: (context) => const WorkspaceSwitcherDialog(),
    );
  }

  void closeTab(OpenedTab tab, BuildContext context) {
    context.read<HistoryBloc>().add(AddHistory(tab));
    context.read<TabsBloc>().add(RemoveTab(tab));
  }

  void pinTabToHomePage(OpenedTab tab, BuildContext context) {
    debugPrint('Pinning tab: ${tab.title}'); // debug

    // קבל את הרשימה הנוכחית של הספרים הנעוצים
    final currentBooksString =
        Settings.getValue<String>('key-pinned-books') ?? '';

    List<Map<String, dynamic>> currentPinnedBooksJson;
    try {
      currentPinnedBooksJson = currentBooksString.isEmpty
          ? <Map<String, dynamic>>[]
          : (jsonDecode(currentBooksString) as List)
              .cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error parsing current pinned books, resetting: $e');
      currentPinnedBooksJson = <Map<String, dynamic>>[];
    }

    // בדוק אם הספר כבר נעוץ
    if (currentPinnedBooksJson.any((book) => book['title'] == tab.title)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${tab.title}" ${context.t.tabs.alreadyPinned}'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // צור אובייקט עם כל המידע של הטאב
    final bookData = <String, dynamic>{
      'title': tab.title,
      'type': tab.runtimeType.toString(),
    };

    // הוסף מידע ספציפי לפי סוג הטאב
    if (tab is TextBookTab) {
      bookData['bookTitle'] = tab.book.title;
      bookData['index'] = tab.index;
    } else if (tab is PdfBookTab) {
      bookData['bookTitle'] = tab.book.title;
      bookData['bookPath'] = tab.book.path;
      bookData['pageNumber'] = tab.pageNumber;
    }

    // הוסף את הספר החדש
    final updatedBooks = [...currentPinnedBooksJson, bookData];

    // שמור את הרשימה המעודכנת כ-JSON
    final booksString = jsonEncode(updatedBooks);
    Settings.setValue<String>('key-pinned-books', booksString);

    debugPrint('Saved pinned books: $booksString'); // debug

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${context.t.tabs.pinnedToHome} "${tab.title}"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void closeAllTabs(TabsState state, BuildContext context) {
    for (final tab in state.tabs) {
      context.read<HistoryBloc>().add(AddHistory(tab));
    }
    context.read<TabsBloc>().add(CloseAllTabs());
  }

  void closeAllTabsButCurrent(TabsState state, BuildContext context) {
    final current = state.tabs[state.currentTabIndex];
    final toClose = state.tabs.where((t) => t != current).toList();
    for (final tab in toClose) {
      context.read<HistoryBloc>().add(AddHistory(tab));
    }
    context.read<TabsBloc>().add(CloseOtherTabs(current));
  }

  void _showHistoryDialog(BuildContext context) {
    context.read<HistoryBloc>().add(FlushHistory());
    showDialog(
      context: context,
      builder: (context) => const HistoryDialog(),
    );
  }

  void _showBookmarksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const BookmarksDialog(),
    );
  }
}

// CustomPainter לציור רקע של הטאב הפעיל
class _TabBackgroundPainter extends CustomPainter {
  final Color backgroundColor;

  _TabBackgroundPainter(this.backgroundColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final path = Path();
    // radius היה בשימוש בעבר לציור נוסף והוסר
    final topRadius = 8.0;
    // החזרת קו הבסיס הנמוך כדי להבטיח שהוא נראה משני הצדדים
    final bottomOffset = 6.0;

    // מתחילים מהפינה השמאלית התחתונה
    path.moveTo(0, size.height + bottomOffset);

    // קו שמאלי למעלה
    path.lineTo(0, topRadius);

    // פינה עליונה שמאלית מעוגלת
    path.arcToPoint(
      Offset(topRadius, 0),
      radius: Radius.circular(topRadius),
    );

    // קו עליון
    path.lineTo(size.width - topRadius, 0);

    // פינה עליונה ימנית מעוגלת
    path.arcToPoint(
      Offset(size.width, topRadius),
      radius: Radius.circular(topRadius),
    );

    // קו ימני למטה
    path.lineTo(size.width, size.height + bottomOffset);

    // קו תחתון
    path.lineTo(0, size.height + bottomOffset);

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// CustomPainter לציור גבול מעוגל לטאב הפעיל
// עם קווים המשתרעים משני הצדדים עד סוף החלון
class _TabBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final radius = 8.0;
    final topRadius = 8.0;
    final extendLength = 2000.0; // אורך ארוך מספיק להגיע לקצה החלון
    // שימוש ב-offset נמוך כדי למנוע "בליעה" של הקו התחתון
    final bottomOffset = 6.0;

    // מתחילים מהפינה השמאלית התחתונה עם עיגול
    path.moveTo(0, size.height - radius + bottomOffset);

    // קו שמאלי למעלה
    path.lineTo(0, topRadius);

    // פינה עליונה שמאלית מעוגלת
    path.arcToPoint(
      Offset(topRadius, 0),
      radius: Radius.circular(topRadius),
    );

    // קו עליון
    path.lineTo(size.width - topRadius, 0);

    // פינה עליונה ימנית מעוגלת
    path.arcToPoint(
      Offset(size.width, topRadius),
      radius: Radius.circular(topRadius),
    );

    // קו ימני למטה
    path.lineTo(size.width, size.height - radius + bottomOffset);

    // פינה תחתונה ימנית מעוגלת - הקפדה שהקו התחתון יישאר רציף
    path.arcToPoint(
      Offset(size.width + radius, size.height + bottomOffset),
      radius: Radius.circular(radius),
      clockwise: false,
    );

    canvas.drawPath(path, paint);

    // פינה תחתונה שמאלית מעוגלת - הקפדה שהקו התחתון יישאר רציף
    final leftBottomPath = Path();
    leftBottomPath.moveTo(0, size.height - radius + bottomOffset);
    leftBottomPath.arcToPoint(
      Offset(-radius, size.height + bottomOffset),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    canvas.drawPath(leftBottomPath, paint);

    // קווים ארוכים נפרדים - משני הצדדים
    // קו ימני
    canvas.drawLine(
      Offset(size.width + radius, size.height + bottomOffset),
      Offset(size.width + extendLength, size.height + bottomOffset),
      paint,
    );

    // קו שמאלי
    canvas.drawLine(
      Offset(-radius, size.height + bottomOffset),
      Offset(-extendLength, size.height + bottomOffset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
