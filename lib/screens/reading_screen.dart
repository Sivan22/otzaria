import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/tabs.dart';
import 'package:otzaria/screens/full_text_search_screen.dart';
import 'package:otzaria/screens/pdf_book_screen.dart';
import 'package:otzaria/screens/text_book_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({Key? key}) : super(key: key);

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen>
    with TickerProviderStateMixin {
  Widget buildTabBarView(AppModel appModel, TabController? controller) {
    return TabBarView(
        controller: controller,
        children: appModel.tabs.map((tab) {
          if (tab is PdfBookTab) {
            return PdfBookViewr(
              key: PageStorageKey(tab),
              tab: tab,
            );
          } else if (tab is TextBookTab) {
            return TextBookViewer(
              tab: tab,
              openBookCallback: appModel.openTab,
              data: tab.text,
            );
          } else if (tab is SearchingTab) {
            return TextFileSearchScreen(
              openBookCallback: appModel.openTab,
              searcher: tab.searcher,
            );
          }
          return const SizedBox.shrink();
        }).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, appModel, child) {
        if (appModel.tabs.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: Text('לא נבחרו ספרים')),
              ),
              // a button to open the library browser
              Center(
                child: ElevatedButton(
                  onPressed: (() =>
                      appModel.currentView.value = Screens.library),
                  child: const Text('דפדוף בספריה'),
                ),
              ),
            ],
          );
        }
        return Builder(
          builder: (context) {
            final controller = TabController(
                length: appModel.tabs.length,
                vsync: this,
                initialIndex:
                    min(appModel.currentTab, appModel.tabs.length - 1));
            controller.addListener(() {
              appModel.currentTab = controller.index;
            });
            try {
              return Scaffold(
                appBar: TabBar(
                  controller: controller,
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                  tabs: appModel.tabs
                      .map((tab) => Listener(
                            // close tab on middle mouse button click
                            onPointerDown: (PointerDownEvent event) {
                              if (event.buttons == 4) {
                                appModel.closeTab(tab);
                              }
                            },
                            child: ContextMenuRegion(
                              contextMenu: ContextMenu(
                                entries: [
                                  MenuItem(
                                    label: 'סגור',
                                    onSelected: () => appModel.closeTab(tab),
                                  ),
                                  MenuItem(
                                    label: 'סגור הכל',
                                    onSelected: () => appModel.closeAllTabs(),
                                  ),
                                  MenuItem(
                                    label: 'סגור את האחרים',
                                    onSelected: () => appModel.closeOthers(tab),
                                  ),
                                  MenuItem(
                                    label: 'שיכפול',
                                    onSelected: () => appModel.cloneTab(tab),
                                  ),
                                  MenuItem.submenu(
                                    label: 'רשימת הכרטיסיות ',
                                    items: appModel.tabs
                                        .map(
                                          (tab) => MenuItem(
                                              label: tab.title,
                                              onSelected: () {
                                                appModel.currentTab =
                                                    appModel.tabs.indexOf(tab);
                                                setState(() {});
                                              }),
                                        )
                                        .toList() as List<ContextMenuEntry>,
                                  )
                                ],
                              ),
                              child: Draggable<OpenedTab>(
                                axis: Axis.horizontal,
                                data: tab,
                                childWhenDragging:
                                    SizedBox.fromSize(size: Size.fromWidth(2)),
                                feedback: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(10),
                                          topRight: Radius.circular(10)),
                                      color: Colors.white),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 10, 20, 15),
                                    child: Text(
                                      tab is SearchingTab
                                          ? '${tab.title}:  ${tab.searcher.queryController.text}'
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
                                    appModel.moveTab(draggedTab.data,
                                        appModel.tabs.indexOf(tab));
                                    setState(() {});
                                  },
                                  builder:
                                      (context, candidateData, rejectedData) =>
                                          Tab(
                                    child: Row(children: [
                                      Text(
                                        tab is SearchingTab
                                            ? '${tab.title}:  ${tab.searcher.queryController.text}'
                                            : tab.title,
                                      ),
                                      IconButton(
                                          onPressed: () {
                                            appModel.closeTab(tab);
                                          },
                                          icon:
                                              const Icon(Icons.close, size: 10))
                                    ]),
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                body: SizedBox.fromSize(
                    size: MediaQuery.of(context).size,
                    child: TabBarView(
                        controller: controller,
                        children: appModel.tabs.map((tab) {
                          if (tab is PdfBookTab) {
                            return PdfBookViewr(
                              key: PageStorageKey(tab),
                              tab: tab,
                            );
                          } else if (tab is TextBookTab) {
                            return TextBookViewer(
                              tab: tab,
                              openBookCallback: appModel.openTab,
                              data: tab.text,
                            );
                          } else if (tab is SearchingTab) {
                            return TextFileSearchScreen(
                              openBookCallback: appModel.openTab,
                              searcher: tab.searcher,
                            );
                          }
                          return const SizedBox.shrink();
                        }).toList())),
              );
            } catch (e) {
              return Text(e.toString());
            }
          },
        );
      },
    );
  }
}
