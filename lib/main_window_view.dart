import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:otzaria/settings_screen.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:math';
import 'pdf_page.dart';
import 'text_book_view.dart';
import 'books_browser.dart';
import 'book_search_view.dart';
import 'library_searcher.dart';
import 'library_search_view.dart';

class MainWindowView extends StatefulWidget {
  const MainWindowView({
    Key? key,
  }) : super(key: key);

  @override
  MainWindowViewState createState() => MainWindowViewState();
}

class MainWindowViewState extends State<MainWindowView>
    with TickerProviderStateMixin {
  int selectedIndex = 0;
  late List<TabWindow> tabs = [BookTabWindow('אוצריא\\ברוכים הבאים.pdf', 0)];
  late TabController tabController = TabController(
      length: tabs.length, vsync: this, initialIndex: max(0, tabs.length - 1));
  final showBooksBrowser = ValueNotifier<bool>(false);
  final showBookSearch = ValueNotifier<bool>(false);
  final focusNode = FocusNode();

  void addTab(TabWindow tab) {
    setState(() {
      int newIndex = tabController.length == 0 ? 0 : tabController.index + 1;
      tabs.insert(newIndex, tab);
      tabController = TabController(length: tabs.length, vsync: this);
      tabController.index = newIndex;
    });
  }

  void closeTab(TabWindow tab) {
    setState(() {
      if (tabs.isNotEmpty) {
        int newIndex = tabs.indexOf(tab) <= tabController.index
            ? max(0, tabController.index - 1)
            : tabController.index;
        tabs.remove(tab);
        tabController = TabController(
            length: tabs.length, vsync: this, initialIndex: newIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox.fromSize(
        size: const Size.fromWidth(100),
        child: NavigationRail(
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.folder),
                label: Text('דפדוף'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.library_books),
                label: Text('איתור ספר'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.search),
                label: Text('חיפוש'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('הגדרות'),
              ),
            ],
            selectedIndex: selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                selectedIndex = index;
                switch (index) {
                  case 0:
                    showBookSearch.value = false;
                    showBooksBrowser.value = !showBooksBrowser.value;
                  case 1:
                    showBooksBrowser.value = false;
                    showBookSearch.value = !showBookSearch.value;
                  case 2:
                    showBookSearch.value = false;
                    showBooksBrowser.value = false;
                    _openSearchScreen();
                  case 3:
                    _openSettingsScreen();
                }
              });
            }),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        child: ValueListenableBuilder(
          valueListenable: showBooksBrowser,
          builder: (context, showBooksBrowser, child) => SizedBox(
            width: showBooksBrowser ? 300 : 0,
            child: child!,
          ),
          child: BooksBrowser(openFileCallback: addTab),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        child: ValueListenableBuilder(
          valueListenable: showBookSearch,
          builder: (context, showBookSearch, child) => SizedBox(
            width: showBookSearch ? 300 : 0,
            child: child!,
          ),
          child: BookSearchScreen(openFileCallback: addTab),
        ),
      ),
      Expanded(
        child: NotificationListener<UserScrollNotification>(
          onNotification: (scrollNotification) {
            Future.microtask(() {
              showBooksBrowser.value = false;
              showBookSearch.value = false;
            });
            return false; // Don't block the notification
          },
          child: Scaffold(
            appBar: TabBar(
              controller: tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              tabs: tabs
                  .map((tab) => Tab(
                        child: Row(children: [
                          Text(
                            tab is SearchingTabWindow
                                ? '${tab.title}:  ${tab.searcher.queryController.text}'
                                : tab.title,
                          ),
                          IconButton(
                              onPressed: () {
                                closeTab(tab);
                              },
                              icon: const Icon(Icons.close, size: 10))
                        ]),
                      ))
                  .toList(),
            ),
            body: Row(children: [
              Expanded(
                child: TabBarView(
                    controller: tabController,
                    children: tabs.map((tab) {
                      if (tab is BookTabWindow) {
                        if (tab.path.endsWith('.pdf')) {
                          return MyPdfPage(
                            key: PageStorageKey(tab.path),
                            file: File(tab.path),
                          );
                        } else {
                          return TextBookViewer(
                            file: File(tab.path),
                            scrollController: tab.scrollController,
                            initalIndex: tab.scrollIndex,
                            searchTextController: tab.searchTextController,
                          );
                        }
                      }
                      if (tab is SearchingTabWindow) {
                        return TextFileSearchScreen(
                          openBookCallback: addTab,
                          searcher: tab.searcher,
                        );
                      }
                      return const SizedBox.shrink();
                    }).toList()),
              ),
            ]),
          ),
        ),
      )
    ]);
  }

  void _openSettingsScreen() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (context) => mySettingsScreen()));
    setState(() {});
  }

  void _openSearchScreen() async {
    addTab(SearchingTabWindow('חיפוש'));
  }
}

class TabWindow {
  String title;

  TabWindow(this.title);
}

class BookTabWindow extends TabWindow {
  final String path;
  int scrollIndex;
  ItemScrollController scrollController = ItemScrollController();
  TextEditingController searchTextController = TextEditingController();

  BookTabWindow(this.path, this.scrollIndex, {String searchText = ''})
      : super(path.split(Platform.pathSeparator).last) {
    if (searchText != '') {
      searchTextController.text = searchText;
    }
  }
}

class SearchingTabWindow extends TabWindow {
  LibrarySearcher searcher = LibrarySearcher(
    [],
    TextEditingController(),
    ValueNotifier([]),
  );
  final ItemScrollController scrollController = ItemScrollController();

  SearchingTabWindow(
    super.title,
  );
}
