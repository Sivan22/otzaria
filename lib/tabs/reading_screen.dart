import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:otzaria/history/bloc/history_bloc.dart';
import 'package:otzaria/history/bloc/history_event.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_event.dart';
import 'package:otzaria/navigation/bloc/navigation_state.dart' show Screen;
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_event.dart';
import 'package:otzaria/tabs/bloc/tabs_state.dart';
import 'package:otzaria/tabs/models/pdf_tab.dart';
import 'package:otzaria/tabs/models/searching_tab.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/search/view/full_text_search_screen.dart';
import 'package:otzaria/pdf_book/view/pdf_book_screen.dart';
import 'package:otzaria/text_book/view/text_book_screen.dart';
import 'package:otzaria/daf_yomi/calendar.dart';
import 'package:otzaria/workspaces/view/workspace_switcher_dialog.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({Key? key}) : super(key: key);

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TabsBloc, TabsState>(
      builder: (context, state) {
        if (!state.hasOpenTabs) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('לא נבחרו ספרים'),
                TextButton(
                  onPressed: () {
                    context.read<NavigationBloc>().add(
                          const NavigateToScreen(Screen.library),
                        );
                  },
                  child: const Text('דפדף בספרייה'),
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
              if (controller.index != state.currentTabIndex) {
                context.read<TabsBloc>().add(SetCurrentTab(controller.index));
              }
            });

            try {
              return Scaffold(
                appBar: AppBar(
                  title: Container(
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
                  leading: IconButton(
                    icon: const Icon(Icons.add_to_queue),
                    tooltip: 'החלף סביבת עבודה',
                    onPressed: () => _showSaveWorkspaceDialog(context),
                  ),
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
            } catch (e) {
              return Text(e.toString());
            }
          },
        );
      },
    );
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
                onSelected: () {
                  for (final tab in state.tabs) {
                    context.read<HistoryBloc>().add(AddHistory(tab));
                  }
                  context.read<TabsBloc>().add(CloseAllTabs());
                }),
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
          childWhenDragging: SizedBox.fromSize(size: const Size(0, 0)),
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
                      builder: (context, value, child) => Text(
                        '${tab.title}:  ${tab.queryController.text}',
                      ),
                    )
                  else if (tab is PdfBookTab)
                    Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.picture_as_pdf, size: 16),
                        ),
                        Text(tab.title),
                      ],
                    )
                  else
                    Text(tab.title),
                  IconButton(
                    onPressed: () => closeTab(tab, context),
                    icon: const Icon(Icons.close, size: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabView(OpenedTab tab) {
    if (tab is PdfBookTab) {
      return PdfBookScreen(
        key: PageStorageKey(tab),
        book: tab.book,
        initialPage: tab.initialPage,
      );
    } else if (tab is TextBookTab) {
      return BlocProvider(
        create: (context) => tab.bloc,
        child: TextBookViewerBloc(
          tab: tab,
          openBookCallback: (tab, {int index = 1}) {
            context.read<TabsBloc>().add(AddTab(tab));
          },
        ),
      );
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
    for (final tab in state.tabs) {
      if (tab is! SearchingTab && tab != state.tabs[state.currentTabIndex]) {
        context.read<HistoryBloc>().add(AddHistory(tab));
      }
      context
          .read<TabsBloc>()
          .add(CloseOtherTabs(state.tabs[state.currentTabIndex]));
    }
  }
}
