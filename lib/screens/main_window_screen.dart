import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/tabs/searching_tab.dart';
import 'package:otzaria/screens/empty_library_screen.dart';
import 'package:otzaria/screens/favorites/favoriets.dart';
import 'package:otzaria/screens/find_ref_screen.dart';
import 'package:otzaria/screens/reading/reading_screen.dart';
import 'package:otzaria/screens/library_browser.dart';
import 'package:otzaria/screens/settings_screen.dart';
import 'package:otzaria/widgets/keyboard_shortcuts.dart';
import 'package:otzaria/widgets/my_updat_widget.dart';
import 'package:provider/provider.dart';

/// The main window of the application that handles navigation between different screens
/// and manages the overall layout based on device orientation.
///
/// This screen implements a responsive layout that adapts between:
/// - Portrait mode: Bottom navigation bar
/// - Landscape mode: Side navigation rail
///
/// It manages several key features:
/// - Navigation between main app sections (Library, Reference Finding, Reading, etc.)
/// - State preservation across orientation changes
/// - Library availability checking
/// - Keyboard shortcuts integration
class MainWindowScreen extends StatefulWidget {
  const MainWindowScreen({Key? key}) : super(key: key);
  @override
  MainWindowScreenState createState() => MainWindowScreenState();
}

class MainWindowScreenState extends State<MainWindowScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Navigation and UI State
  ValueNotifier selectedIndex = ValueNotifier(0);
  late final PageController pageController;
  Orientation? _previousOrientation;

  // Focus Management
  final bookSearchfocusNode = FocusNode();
  final FocusScopeNode mainFocusScopeNode = FocusScopeNode();

  // Library State
  bool _isLibraryEmpty = false;

  /// Cached list of main application pages
  /// Using KeepAlive to preserve state when switching between pages
  late final List<Widget> _pages;

  /// Initializes the screen state and sets up necessary listeners and controllers
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    if (Settings.getValue('key-font-size') == null) {
      Settings.setValue('key-font-size', 25.0);
    }
    if (Settings.getValue('key-font-family') == null) {
      Settings.setValue('key-font-family', 'FrankRuhlCLM');
    }

    _checkLibrary();

    // Initialize the pages with KeepAlive widgets
    _pages = [
      const KeepAlivePage(child: LibraryBrowser()),
      const KeepAlivePage(child: FindRefScreen()),
      const KeepAlivePage(child: ReadingScreen()),
      const KeepAlivePage(child: SizedBox.shrink()),
      const KeepAlivePage(child: FavouritesScreen()),
      const KeepAlivePage(child: MySettingsScreen()),
    ];

    final currentView = context.read<AppModel>().currentView;
    pageController = PageController(
      initialPage: currentView.value.index,
    );

    currentView.addListener(() {
      if (!mounted) return;
      final targetPage = currentView.value == Screens.search
          ? Screens.reading.index
          : currentView.value.index;

      if (pageController.hasClients &&
          pageController.page?.round() != targetPage) {
        pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.linear,
        );
      }
      setState(() {});
    });

    super.initState();
  }

  /// Checks if the library is properly set up and contains books
  /// Sets [_isLibraryEmpty] to true if:
  /// - Library path is not set
  /// - Library directory doesn't exist
  /// - Library directory is empty
  void _checkLibrary() {
    final libraryPath = Settings.getValue<String>('key-library-path');
    if (libraryPath == null) {
      _isLibraryEmpty = true;
      return;
    }

    final libraryDir = Directory('$libraryPath/אוצריא');
    if (!libraryDir.existsSync() || libraryDir.listSync().isEmpty) {
      _isLibraryEmpty = true;
      return;
    }

    _isLibraryEmpty = false;
  }

  @override
  void dispose() {
    pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      Provider.of<AppModel>(context, listen: false).saveTabsToDisk();
    }
  }

  /// Handles orientation changes and ensures correct page display
  ///
  /// When orientation changes:
  /// 1. Updates the previous orientation tracking
  /// 2. Ensures the correct page is displayed after the change
  /// 3. Maintains navigation state consistency
  void _handleOrientationChange(BuildContext context, Orientation orientation) {
    if (_previousOrientation != orientation) {
      _previousOrientation = orientation;

      // Ensure we maintain the correct page after orientation change
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && pageController.hasClients) {
          final appModel = Provider.of<AppModel>(context, listen: false);
          final targetPage = appModel.currentView.value == Screens.search
              ? Screens.reading.index
              : appModel.currentView.value.index;

          if (pageController.page?.round() != targetPage) {
            pageController.jumpToPage(targetPage);
          }
        }
      });
    }
  }

  /// Builds the navigation destinations used in both portrait and landscape modes
  List<NavigationDestination> _buildNavigationDestinations() {
    return const [
      NavigationDestination(
        icon: Icon(Icons.library_books),
        label: 'ספרייה',
      ),
      NavigationDestination(
        icon: Icon(Icons.auto_stories_rounded),
        label: 'איתור',
      ),
      NavigationDestination(
        icon: Icon(Icons.menu_book),
        label: 'עיון',
      ),
      NavigationDestination(
        icon: Icon(Icons.search),
        label: 'חיפוש',
      ),
      NavigationDestination(
        icon: Icon(Icons.star),
        label: 'מועדפים',
      ),
      NavigationDestination(
        icon: Icon(Icons.settings),
        label: 'הגדרות',
      ),
    ];
  }

  /// Handles navigation selection and associated side effects
  void _handleNavigationSelected(int index, AppModel appModel) {
    switch (index) {
      case 3:
        // we need to open a new search if no search tab exists, OR if the current tab is a search tab (meaning the user wants a new search)
        if (appModel.tabs.every((tab) => tab.runtimeType != SearchingTab) ||
            (appModel.currentView.value == Screens.search &&
            appModel.tabs.length > appModel.currentTab &&
                appModel.tabs[appModel.currentTab].runtimeType ==
                    SearchingTab)) {
          appModel.openNewSearchTab();
        }
        // if sesrch tab exists but not focused, move to it
        else if (appModel.tabs.any((tab) => tab.runtimeType == SearchingTab)) {
          appModel.currentTab = appModel.tabs
              .indexWhere((tab) => tab.runtimeType == SearchingTab);
          appModel.setTab(index);
        }
        appModel.currentView.value = Screens.values[index];
        break;
      case 0:
        appModel.currentView.value = Screens.library;
        if (!(Platform.isAndroid || Platform.isIOS)) {
          appModel.bookLocatorFocusNode.requestFocus();
          appModel.bookLocatorController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: appModel.bookLocatorController.text.length);
        }
        break;
      case 1:
        appModel.currentView.value = Screens.find;
        appModel.findReferenceFocusNode.requestFocus();
        appModel.findReferenceController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: appModel.findReferenceController.text.length);
        break;
      default:
        appModel.currentView.value = Screens.values[index];
    }
  }

  /// Builds the main layout of the application
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: Provider.of<AppModel>(context),
        builder: (context, child) {
          _checkLibrary();
          if (_isLibraryEmpty) {
            return EmptyLibraryScreen(
              onLibraryLoaded: () {
                Provider.of<AppModel>(context, listen: false).refreshLibrary();
                setState(() {
                  _checkLibrary();
                });
              },
            );
          }
          return SafeArea(
              child: KeyboardShortcuts(
            child: Consumer<AppModel>(
              builder: (context, appModel, child) => MyUpdatWidget(
                child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  body: OrientationBuilder(builder: (context, orientation) {
                    _handleOrientationChange(context, orientation);

                    final pageView = PageView(
                      scrollDirection: orientation == Orientation.landscape
                          ? Axis.vertical
                          : Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      controller: pageController,
                      children: _pages,
                    );
                    if (orientation == Orientation.landscape) {
                      return Row(children: [
                        SizedBox.fromSize(
                          size: const Size.fromWidth(80),
                          child: LayoutBuilder(
                            builder: (context, constraints) => NavigationRail(
                                labelType: NavigationRailLabelType.all,
                                destinations: [
                                  for (var destination
                                      in _buildNavigationDestinations())
                                    NavigationRailDestination(
                                      icon: destination.icon,
                                      label: Text(destination.label),
                                      padding: destination.label == 'הגדרות'
                                          ? EdgeInsets.only(
                                              top: constraints.maxHeight - 410)
                                          : null,
                                    ),
                                ],
                                selectedIndex: appModel.currentView.value.index,
                                onDestinationSelected: (index) =>
                                    _handleNavigationSelected(index, appModel)),
                          ),
                        ),
                        Expanded(child: pageView),
                      ]);
                    } else {
                      return Column(children: [
                        Expanded(child: pageView),
                        Consumer<AppModel>(
                          builder: (context, appModel, child) => NavigationBar(
                              destinations: _buildNavigationDestinations(),
                              selectedIndex: appModel.currentView.value.index,
                              onDestinationSelected: (int index) {
                                appModel.currentView.value =
                                    Screens.values[index];
                                switch (index) {
                                  case 3:
                                    appModel.openNewSearchTab();
                                }
                              }),
                        ),
                      ]);
                    }
                  }),
                ),
              ),
            ),
          ));
        });
  }
}

// Widget to keep pages alive when switching orientations
class KeepAlivePage extends StatefulWidget {
  final Widget child;

  const KeepAlivePage({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
