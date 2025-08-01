import 'package:flutter/material.dart';
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
import 'package:otzaria/workspaces/bloc/workspace_bloc.dart';
import 'package:otzaria/workspaces/bloc/workspace_event.dart';
import 'package:otzaria/history/history_dialog.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/widgets/workspace_icon_button.dart';


class ReadingScreen extends StatefulWidget {
  const ReadingScreen({Key? key}) : super(key: key);

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // וודא שה-WorkspaceBloc נטען
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WorkspaceBloc>().add(LoadWorkspaces());
      }
    });
  }

  @override
  void dispose() {
    context.read<HistoryBloc>().add(FlushHistory());
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
    return MultiBlocListener(
      listeners: [
        BlocListener<TabsBloc, TabsState>(
          listener: (context, state) {
            if(state.hasOpenTabs) {
              context.read<HistoryBloc>().add(CaptureStateForHistory(state.currentTab!));
            }
            // עדכון WorkspaceBloc כשמשנים tabs
            context.read<WorkspaceBloc>().add(LoadWorkspaces());
          },
          listenWhen: (previous, current) => previous.currentTabIndex != current.currentTabIndex,
        ),
      ],
      child: BlocBuilder<TabsBloc, TabsState>(
        builder: (context, state) {
          if (!state.hasOpenTabs) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('לא נבחרו ספרים'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextButton(
                      onPressed: () {
                        context.read<NavigationBloc>().add(
                              const NavigateToScreen(Screen.library),
                            );
                      },
                      child: const Text('דפדף בספרייה'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextButton(
                      onPressed: () {
                        _showHistoryDialog(context);
                      },
                      child: const Text('הצג היסטוריה'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextButton(
                      onPressed: () {
                        _showSaveWorkspaceDialog(context);
                      },
                      child: const Text('החלף שולחן עבודה'),
                    ),
                  )
                ],
              ),
            );
          }
    
          return Builder(
            builder: (context) {
              final controller = TabController(
                length: state.tabs.length,
                vsync: this,
                initialIndex: state.currentTabIndex,
              );
    
              controller.addListener(() {
                if (controller.indexIsChanging &&
                    state.currentTabIndex < state.tabs.length) {
                  context
                      .read<HistoryBloc>()
                      .add(CaptureStateForHistory(state.tabs[state.currentTabIndex]));
                }
                if (controller.index != state.currentTabIndex) {
                  context.read<TabsBloc>().add(SetCurrentTab(controller.index));
                }
              });
    
              return Scaffold(
                appBar: AppBar(
                  title: Row(
                    children: [
                      WorkspaceIconButton(
                        onPressed: () => _showSaveWorkspaceDialog(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 50),
                          child: TabBar(
                            controller: controller,
                            isScrollable: true,
                            tabAlignment: TabAlignment.center,
                            tabs: state.tabs
                                .map((tab) => _buildTab(context, tab, state))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  automaticallyImplyLeading: false,
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
    return Listener(
      onPointerDown: (PointerDownEvent event) {
        if (event.buttons == 4) {
          closeTab(tab, context);
        }
      },
      child: ContextMenuRegion(
        contextMenu: ContextMenu(
          entries: [
            MenuItem(label: 'סגור', onSelected: () => closeTab(tab, context)),
            MenuItem(
                label: 'סגור הכל',
                onSelected: () => closeAllTabs(state, context)),
            MenuItem(
              label: 'סגור את האחרים',
              onSelected: () => closeAllTabsButCurrent(state, context),
            ),
            MenuItem(
              label: 'שיכפול',
              onSelected: () => context.read<TabsBloc>().add(CloneTab(tab)),
            ),
            MenuItem.submenu(
              label: 'רשימת הכרטיסיות ',
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
            builder: (context, candidateData, rejectedData) => Tab(
              child: Row(
                children: [
                  if (tab is SearchingTab)
                    ValueListenableBuilder(
                      valueListenable: tab.queryController,
                      builder: (context, value, child) => Tooltip(
                        message: '${tab.title}:  ${tab.queryController.text}',
                        child: Text(
                          truncate(
                              '${tab.title}:  ${tab.queryController.text}', 12),
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
                            child: Icon(Icons.picture_as_pdf, size: 16),
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
                    message: (Settings.getValue<String>('key-shortcut-close-tab') ??
                            'ctrl+w')
                        .toUpperCase(),
                    child: IconButton(
                      onPressed: () => closeTab(tab, context),
                      icon: const Icon(Icons.close, size: 10),
                    ),
                  ),
                ],
              ),
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
}