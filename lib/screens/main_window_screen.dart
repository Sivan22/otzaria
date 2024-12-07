import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/screens/empty_library_screen.dart';
import 'package:otzaria/screens/favorites/favoriets.dart';
import 'package:otzaria/screens/find_ref_screen.dart';
import 'package:otzaria/screens/reading/reading_screen.dart';
import 'package:otzaria/screens/library_browser.dart';
import 'package:otzaria/screens/settings_screen.dart';
import 'package:otzaria/widgets/keyboard_shortcuts.dart';
import 'package:otzaria/widgets/my_updat_widget.dart';
import 'package:provider/provider.dart';

class MainWindowScreen extends StatefulWidget {
  const MainWindowScreen({Key? key}) : super(key: key);
  @override
  MainWindowScreenState createState() => MainWindowScreenState();
}

class MainWindowScreenState extends State<MainWindowScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  ValueNotifier selectedIndex = ValueNotifier(0);
  final bookSearchfocusNode = FocusNode();
  final FocusScopeNode mainFocusScopeNode = FocusScopeNode();
  late final PageController pageController;
  bool _isLibraryEmpty = false;
  Orientation? _previousOrientation;

  // Store the page views as state to preserve them across rebuilds
  late final List<Widget> _pages;

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

    final currentView =
        Provider.of<AppModel>(context, listen: false).currentView;
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
                                  const NavigationRailDestination(
                                    icon: Icon(Icons.library_books),
                                    label: Text('ספרייה'),
                                  ),
                                  const NavigationRailDestination(
                                    icon: Icon(Icons.auto_stories_rounded),
                                    label: Text('איתור'),
                                  ),
                                  const NavigationRailDestination(
                                    icon: Icon(Icons.menu_book),
                                    label: Text('עיון'),
                                  ),
                                  const NavigationRailDestination(
                                    icon: Icon(Icons.search),
                                    label: Text('חיפוש'),
                                  ),
                                  const NavigationRailDestination(
                                    icon: Icon(Icons.star),
                                    label: Text('מועדפים'),
                                  ),
                                  NavigationRailDestination(
                                    icon: const Icon(Icons.settings),
                                    label: const Text('הגדרות'),
                                    padding: EdgeInsets.only(
                                        top: constraints.maxHeight - 410),
                                  ),
                                ],
                                selectedIndex: appModel.currentView.value.index,
                                onDestinationSelected: (int index) {
                                  appModel.currentView.value =
                                      Screens.values[index];
                                  switch (index) {
                                    case 3:
                                      appModel.openNewSearchTab();
                                    case 0:
                                      if (!(Platform.isAndroid ||
                                          Platform.isIOS)) {
                                        appModel.bookLocatorFocusNode
                                            .requestFocus();
                                      }
                                    case 1:
                                      appModel.findReferenceFocusNode
                                          .requestFocus();
                                  }
                                }),
                          ),
                        ),
                        Expanded(child: pageView),
                      ]);
                    } else {
                      return Column(children: [
                        Expanded(child: pageView),
                        Consumer<AppModel>(
                          builder: (context, appModel, child) => NavigationBar(
                              destinations: const [
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
                              ],
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
