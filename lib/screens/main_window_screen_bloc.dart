import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/blocs/navigation/navigation_bloc.dart';
import 'package:otzaria/blocs/navigation/navigation_event.dart';
import 'package:otzaria/blocs/navigation/navigation_state.dart';
import 'package:otzaria/screens/empty_library_screen.dart';
import 'package:otzaria/screens/favorites/favoriets.dart';
import 'package:otzaria/screens/find_ref_screen.dart';
import 'package:otzaria/screens/library_browser_bloc.dart';
import 'package:otzaria/screens/reading/reading_screen_bloc.dart';
import 'package:otzaria/screens/settings_screen.dart';
import 'package:otzaria/widgets/keyboard_shortcuts_bloc.dart';
import 'package:otzaria/widgets/my_updat_widget.dart';

class MainWindowScreenBloc extends StatefulWidget {
  const MainWindowScreenBloc({super.key});

  @override
  MainWindowScreenBlocState createState() => MainWindowScreenBlocState();
}

class MainWindowScreenBlocState extends State<MainWindowScreenBloc>
    with TickerProviderStateMixin {
  late final PageController pageController;
  Orientation? _previousOrientation;

  final List<Widget> _pages = const [
    KeepAlivePage(child: LibraryBrowserBloc()),
    KeepAlivePage(child: FindRefScreen()),
    KeepAlivePage(child: ReadingScreenBloc()),
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
            child: KeyboardShortcutsBloc(
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
                                    context.read<NavigationBloc>().add(
                                        NavigateToScreen(Screen.values[index]));
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
                                  context
                                      .read<NavigationBloc>()
                                      .add(const OpenNewSearchTab());
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
