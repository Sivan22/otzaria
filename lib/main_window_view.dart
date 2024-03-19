import 'package:flutter/services.dart';
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
import 'dart:convert';
import 'links_view.dart';
import 'dart:isolate';

class MainWindowView extends StatefulWidget {
  final ValueNotifier<bool> isDarkMode;

  const MainWindowView({
    required this.isDarkMode,
    Key? key,
  }) : super(
          key: key,
        );

  @override
  MainWindowViewState createState() => MainWindowViewState();
}

class MainWindowViewState extends State<MainWindowView>
    with TickerProviderStateMixin {
  int selectedIndex = 0;
  late List<TabWindow> tabs =
      Platform.isAndroid ? [] : [BookTabWindow('אוצריא\\ברוכים הבאים.pdf', 0)];
  late TabController tabController = TabController(
      length: tabs.length, vsync: this, initialIndex: max(0, tabs.length - 1));
  final showBooksBrowser = ValueNotifier<bool>(false);
  final showBookSearch = ValueNotifier<bool>(false);
  final bookSearchfocusNode = FocusNode();
  final FocusScopeNode mainFocusScopeNode = FocusScopeNode();
  late Future<String?> libraryRootPath;
  final Map<String, LogicalKeySet> shortcuts = {
    'ctrl+a':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA),
    'ctrl+b':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB),
    'ctrl+c':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC),
    'ctrl+d':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyD),
    'ctrl+e':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyE),
    'ctrl+f':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF),
    'ctrl+g':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyG),
    'ctrl+h':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyH),
    'ctrl+i':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI),
    'ctrl+j':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyJ),
    'ctrl+k':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK),
    'ctrl+l':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyL),
    'ctrl+m':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyM),
    'ctrl+n':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN),
    'ctrl+o':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyO),
    'ctrl+p':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyP),
    'ctrl+q':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyQ),
    'ctrl+r':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR),
    'ctrl+s':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS),
    'ctrl+t':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyT),
    'ctrl+u':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyU),
    'ctrl+v':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV),
    'ctrl+w':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyW),
    'ctrl+x':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyX),
    'ctrl+y':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY),
    'ctrl+z':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ),
    'ctrl+0':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit0),
    'ctrl+1':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit1),
    'ctrl+2':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit2),
    'ctrl+3':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit3),
    'ctrl+4':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit4),
    'ctrl+5':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit5),
    'ctrl+6':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit6),
    'ctrl+7':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit7),
    'ctrl+8':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit8),
    'ctrl+9':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit9),
  };
  @override
  void initState() {
    super.initState();
    if (Settings.getValue('key-font-size') == null) {
      Settings.setValue('key-font-size', 25.0);
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

    libraryRootPath = () async {
      // first try to get the library path from settings
      if (Settings.getValue<String>('key-library-path') != null) {
        return Settings.getValue<String>('key-library-path');
        //if faild, ask the user on android to find the path
      } else {
        if (Platform.isAndroid) {
          String? path = await FilePicker.platform.getDirectoryPath();
          if (path != null) {
            Settings.setValue<String>('key-library-path', path);
            return path;
          }
        }
        //on windows/linux, just use the application path
        return '.';
      }
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
        body: OrientationBuilder(builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return buildShortcuts();
          } else {
            return Column(children: [
              Expanded(
                child: Row(children: [
                  buildBooksBrowser(),
                  buildBookSearchScreen(),
                  buildTabBarAndTabView()
                ]),
              ),
              buildNavigationBottomBar(),
            ]);
          }
        }),
      ),
    );
  }

  CallbackShortcuts buildShortcuts() {
    return CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          shortcuts[
              Settings.getValue<String>('key-shortcut-open-book-browser') !=
                      null
                  ? Settings.getValue<String>('key-shortcut-open-book-browser')
                  : 'ctrl+b']!: () {
            showBooksBrowser.value = true;
            showBookSearch.value = false;
          },
          shortcuts[Settings.getValue<String>('key-shortcut-close-tab') != null
              ? Settings.getValue<String>('key-shortcut-close-tab')
              : 'ctrl+w']!: () {
            setState(() {
              closeTab(tabs[tabController.index]);
            });
          },
          shortcuts[
              Settings.getValue<String>('key-shortcut-close-all-tabs') != null
                  ? Settings.getValue<String>('key-shortcut-close-all-tabs')
                  : 'ctrl+x']!: () {
            setState(() {
              tabs = [];
              tabController = TabController(length: tabs.length, vsync: this);
            });
          },
          shortcuts[
              Settings.getValue<String>('key-shortcut-open-book-search') != null
                  ? Settings.getValue<String>('key-shortcut-open-book-search')
                  : 'ctrl+o']!: () {
            showBooksBrowser.value = false;
            showBookSearch.value = true;
            bookSearchfocusNode.requestFocus();
          },
          shortcuts[
              Settings.getValue<String>('key-shortcut-open-new-search') != null
                  ? Settings.getValue<String>('key-shortcut-open-new-search')
                  : 'ctrl+q']!: () {
            setState(() {
              addTab(SearchingTabWindow('חיפוש'));
            });
          },
        },
        child: FocusScope(
          node: mainFocusScopeNode,
          //on android don't autofocus, so keyboard won't show
          autofocus: Platform.isAndroid ? false : true,
          child: Row(children: [
            buildNavigationSideBar(),
            buildBooksBrowser(),
            buildBookSearchScreen(),
            buildTabBarAndTabView()
          ]),
        ));
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
                path: tab.path,
                tab: tab,
                openBookCallback: addTab,
                data: tab.data,
              );
            }
          }
          if (tab is SearchingTabWindow) {
            return FutureBuilder(
                future: libraryRootPath,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return TextFileSearchScreen(
                      openBookCallback: addTab,
                      searcher: tab.searcher,
                      libraryRootPath: snapshot.data!,
                    );
                  }

                  return const Center(child: CircularProgressIndicator());
                });
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
            future: libraryRootPath,
            builder: (context, snapshot) {
              return snapshot.hasData
                  ? BookSearchScreen(
                      openFileCallback: addTab,
                      closeLeftPaneCallback: closeLeftPanel,
                      focusNode: bookSearchfocusNode,
                      libraryRootPath: snapshot.data!)
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
            future: libraryRootPath,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return BooksBrowser(
                  openFileCallback: addTab,
                  libraryRootPath: snapshot.data!,
                  closeLeftPaneCallback: closeLeftPanel,
                );
              }
              return const Center(child: CircularProgressIndicator());
            }),
      ),
    );
  }

  SizedBox buildNavigationSideBar() {
    return SizedBox.fromSize(
      size: const Size.fromWidth(80),
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
                  bookSearchfocusNode.requestFocus();
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

  NavigationBar buildNavigationBottomBar() {
    return NavigationBar(
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.folder),
            label: 'דפדוף',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books),
            label: 'איתור ספר',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'חיפוש',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'הגדרות',
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
        });
  }

  void _openSettingsScreen() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => mySettingsScreen(widget.isDarkMode)));
    setState(() {});
  }

  void _openSearchScreen() async {
    addTab(SearchingTabWindow('חיפוש'));
  }

  void closeLeftPanel() {
    showBooksBrowser.value = false;
    showBookSearch.value = false;
  }
}

class TabWindow {
  String title;

  TabWindow(this.title);
}

class BookTabWindow extends TabWindow {
  final String path;
  ValueNotifier<List<String>> commentariesNames = ValueNotifier([]);
  late Future<List<Link>> links;
  late Future<String> data;
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
    links = Isolate.run(() async {
      String libraryRootPath = path.split('אוצריא').first;
      return await getAllLinksFromJson(
          '$libraryRootPath${Platform.pathSeparator}links${Platform.pathSeparator}${path.split(Platform.pathSeparator).last}_links.json');
    });
    data = getBookData(path);
  }

  Future<List<Link>> getAllLinksFromJson(String path) async {
    try {
      final jsonString = await File(path).readAsString();
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => Link.fromJson(json)).toList();
    } on Exception {
      return [];
    }
  }

  Future<String> getBookData(String path) {
    return Isolate.run(() async {
      File file = File(path);
      String data = await file.readAsString();
      return data;
    });
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
