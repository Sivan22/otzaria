import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/focus/focus_bloc.dart';
import 'package:otzaria/focus/focus_event.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_event.dart';
import 'package:otzaria/navigation/bloc/navigation_state.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_event.dart';
import 'package:otzaria/tabs/models/searching_tab.dart';
import 'package:otzaria/empty_library/empty_library_screen.dart';
import 'package:otzaria/favoriets_screen.dart';
import 'package:otzaria/find_ref/find_ref_screen.dart';
import 'package:otzaria/library/view/library_browser.dart';
import 'package:otzaria/tabs/reading_screen.dart';
import 'package:otzaria/settings/settings_screen.dart';
import 'package:otzaria/widgets/keyboard_shortcuts.dart';
import 'package:otzaria/update/my_updat_widget.dart';

class MainWindowScreen extends StatefulWidget {
  const MainWindowScreen({super.key});

  @override
  MainWindowScreenState createState() => MainWindowScreenState();
}

class MainWindowScreenState extends State<MainWindowScreen>
    with TickerProviderStateMixin {
  late final PageController pageController;
  Orientation? _previousOrientation;

  final List<Widget> _pages = const [
    KeepAlivePage(child: LibraryBrowser()),
    KeepAlivePage(child: FindRefScreen()),
    KeepAlivePage(child: ReadingScreen()),
    KeepAlivePage(child: SizedBox.shrink()),
    KeepAlivePage(child: FavouritesScreen()),
    KeepAlivePage(child: MySettingsScreen()),
  ];

  @override
  void initState() {
    super.initState();
    pageController = PageController(
      initialPage: Screen.library.index,
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void _handleOrientationChange(BuildContext context, Orientation orientation) {
    if (_previousOrientation != orientation) {
      _previousOrientation = orientation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && pageController.hasClients) {
          final currentScreen =
              context.read<NavigationBloc>().state.currentScreen;
          final targetPage = currentScreen == Screen.search
              ? Screen.reading.index
              : currentScreen.index;

          if (pageController.page?.round() != targetPage) {
            pageController.jumpToPage(targetPage);
          }
        }
      });
    }
  }

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

  void _handleNavigationChange(BuildContext context, NavigationState state) {
    if (mounted && pageController.hasClients) {
      final targetPage = state.currentScreen == Screen.search
          ? Screen.reading.index
          : state.currentScreen.index;

      if (pageController.page?.round() != targetPage) {
        pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
    if (state.currentScreen == Screen.library) {
      context
          .read<FocusBloc>()
          .add(const RequestLibrarySearchFocus(selectAll: true));
    }
    if (state.currentScreen == Screen.find) {
      context
          .read<FocusBloc>()
          .add(const RequestFindRefSearchFocus(selectAll: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NavigationBloc, NavigationState>(
      listenWhen: (previous, current) =>
          previous.currentScreen != current.currentScreen,
      listener: _handleNavigationChange,
      child: BlocBuilder<NavigationBloc, NavigationState>(
        builder: (context, state) {
          if (state.isLibraryEmpty) {
            return EmptyLibraryScreen(
              onLibraryLoaded: () {
                context.read<NavigationBloc>().refreshLibrary();
              },
            );
          }

          return SafeArea(
            child: KeyboardShortcuts(
              child: MyUpdatWidget(
                child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  body: OrientationBuilder(
                    builder: (context, orientation) {
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
                        return Row(
                          children: [
                            SizedBox.fromSize(
                              size: const Size.fromWidth(80),
                              child: LayoutBuilder(
                                builder: (context, constraints) =>
                                    NavigationRail(
                                  labelType: NavigationRailLabelType.all,
                                  destinations: [
                                    for (var destination
                                        in _buildNavigationDestinations())
                                      NavigationRailDestination(
                                        icon: destination.icon,
                                        label: Text(destination.label),
                                        padding: destination.label == 'הגדרות'
                                            ? EdgeInsets.only(
                                                top:
                                                    constraints.maxHeight - 410)
                                            : null,
                                      ),
                                  ],
                                  selectedIndex: state.currentScreen.index,
                                  onDestinationSelected: (index) {
                                    if (index == Screen.search.index) {
                                      _handleSearchTabOpen(context);
                                    } else {
                                      context.read<NavigationBloc>().add(
                                          NavigateToScreen(
                                              Screen.values[index]));
                                    }
                                  },
                                ),
                              ),
                            ),
                            Expanded(child: pageView),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            Expanded(child: pageView),
                            NavigationBar(
                              destinations: _buildNavigationDestinations(),
                              selectedIndex: state.currentScreen.index,
                              onDestinationSelected: (index) {
                                if (index == Screen.search.index) {
                                  _handleSearchTabOpen(context);
                                } else {
                                  context.read<NavigationBloc>().add(
                                      NavigateToScreen(Screen.values[index]));
                                }
                              },
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleSearchTabOpen(BuildContext context) {
    final tabsBloc = context.read<TabsBloc>();
    final navigationBloc = context.read<NavigationBloc>();
    if (tabsBloc.state.tabs.every((tab) => tab.runtimeType != SearchingTab) ||
        (navigationBloc.state.currentScreen == Screen.search &&
            tabsBloc.state.tabs[tabsBloc.state.currentTabIndex].runtimeType ==
                SearchingTab)) {
      tabsBloc.add(AddTab(SearchingTab("חיפוש", "")));
    }
    // if sesrch tab exists but not focused, move to it
    else if (tabsBloc.state.tabs
        .any((tab) => tab.runtimeType == SearchingTab)) {
      tabsBloc.add(SetCurrentTab(tabsBloc.state.tabs
          .indexWhere((tab) => tab.runtimeType == SearchingTab)));
    }
    navigationBloc.add(const NavigateToScreen(Screen.search));
  }
}

class KeepAlivePage extends StatefulWidget {
  final Widget child;

  const KeepAlivePage({
    super.key,
    required this.child,
  });

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
