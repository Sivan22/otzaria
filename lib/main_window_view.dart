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
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

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
  late List<TabWindow> tabs = [
    /*BookTabWindow('אוצריא\\ברוכים הבאים.pdf', 0)*/
  ];
  late TabController tabController = TabController(
      length: tabs.length, vsync: this, initialIndex: max(0, tabs.length - 1));
  final showBooksBrowser = ValueNotifier<bool>(false);
  final showBookSearch = ValueNotifier<bool>(false);
  final focusNode = FocusNode();
  late Future<String?> rootOfLibrary;

  @override
  void initState() {
    if (Settings.getValue('key-font-size') == null) {
      Settings.setValue('key-font-size', 25.0);
    }
    if (Settings.getValue('key-font-weight') == null) {
      Settings.setValue('key-font-weight', 'normal');
    }
    if (Settings.getValue('key-font-family') == null) {
      Settings.setValue('key-font-family', 'FrankRuhlLibre');
    }
    () async {
      if (Platform.isAndroid &&
          !await Permission.manageExternalStorage.isGranted) {
        await Permission.manageExternalStorage.request();
      }
    }();

    rootOfLibrary = () async {
      return Settings.getValue<String>('key-library-path') != null
          ? Settings.getValue<String>('key-library-path')
          : Platform.isAndroid
              ? await FilePicker.platform.getDirectoryPath()
              : 'אוצריא';
    }();
  }

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
    return SafeArea(
      child: Scaffold(
        body: Row(children: [
          buildNavigationSideBar(),
          buildBooksBrowser(),
          buildBookSearchScreen(),
          buildTabBarAndTabView()
        ]),
      ),
    );
  }

  Expanded buildTabBarAndTabView() {
    return Expanded(
      child: NotificationListener<UserScrollNotification>(
        onNotification: (scrollNotification) {
          Future.microtask(() {
            showBooksBrowser.value = false;
            showBookSearch.value = false;
          });
          return false; // Don't block the notification
        },
        child: Scaffold(
          appBar: buildTabBar(),
          body: Row(children: [
            Expanded(
              child: buildTabBarView(),
            ),
          ]),
        ),
      ),
    );
  }

  TabBarView buildTabBarView() {
    return TabBarView(
        controller: tabController,
        children: tabs.map((tab) {
          if (tab is BookTabWindow) {
            if (tab.path.endsWith('.pdf')) {
              return MyPdfPage(
                key: PageStorageKey(tab),
                file: File(tab.path),
              );
            } else {
              return TextBookViewer(
                file: File(tab.path),
                tab: tab,
                openBookCallback: addTab,
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
        }).toList());
  }

  TabBar buildTabBar() {
    return TabBar(
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
    );
  }

  AnimatedSize buildBookSearchScreen() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: ValueListenableBuilder(
        valueListenable: showBookSearch,
        builder: (context, showBookSearch, child) => SizedBox(
          width: showBookSearch ? 300 : 0,
          child: child!,
        ),
        child: FutureBuilder(
            future: rootOfLibrary,
            builder: (context, snapshot) {
              return snapshot.hasData
                  ? BookSearchScreen(
                      openFileCallback: addTab, libraryPath: snapshot.data!)
                  : const Center(child: CircularProgressIndicator());
            }),
      ),
    );
  }

  AnimatedSize buildBooksBrowser() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: ValueListenableBuilder(
        valueListenable: showBooksBrowser,
        builder: (context, showBooksBrowser, child) => SizedBox(
          width: showBooksBrowser ? 300 : 0,
          child: child!,
        ),
        child: FutureBuilder(
            future: rootOfLibrary,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return BooksBrowser(
                    openFileCallback: addTab, libraryPath: snapshot.data!);
              }
              return const Center(child: CircularProgressIndicator());
            }),
      ),
    );
  }

  SizedBox buildNavigationSideBar() {
    return SizedBox.fromSize(
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
    );
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
  int initalIndex;
  ItemScrollController scrollController = ItemScrollController();
  ScrollOffsetController scrollOffsetController = ScrollOffsetController();
  TextEditingController searchTextController = TextEditingController();
  ItemPositionsListener positionsListener = ItemPositionsListener.create();
  BookTabWindow(this.path, this.initalIndex, {String searchText = ''})
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
