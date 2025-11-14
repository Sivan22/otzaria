import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/focus/focus_repository.dart';
import 'package:otzaria/indexing/bloc/indexing_bloc.dart';
import 'package:otzaria/indexing/bloc/indexing_event.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_event.dart';
import 'package:otzaria/navigation/bloc/navigation_state.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_state.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/empty_library/empty_library_screen.dart';
import 'package:otzaria/find_ref/find_ref_dialog.dart';
import 'package:otzaria/search/view/search_dialog.dart';
import 'package:otzaria/library/view/library_browser.dart';
import 'package:otzaria/tabs/reading_screen.dart';
import 'package:otzaria/settings/settings_screen.dart';
import 'package:otzaria/navigation/more_screen.dart';
import 'package:otzaria/navigation/about_dialog.dart';
import 'package:otzaria/widgets/keyboard_shortcuts.dart';
import 'dart:async';
import 'package:otzaria/update/my_updat_widget.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_event.dart';
import 'package:otzaria/tabs/models/searching_tab.dart';
import 'package:otzaria/navigation/calendar_cubit.dart';
import 'package:otzaria/i18n/translations.g.dart';

class MainWindowScreen extends StatefulWidget {
  const MainWindowScreen({super.key});

  @override
  MainWindowScreenState createState() => MainWindowScreenState();
}

// Global key for accessing MoreScreen
final GlobalKey<State<MoreScreen>> moreScreenKey =
    GlobalKey<State<MoreScreen>>();

class MainWindowScreenState extends State<MainWindowScreen>
    with TickerProviderStateMixin {
  late final PageController pageController;
  late final CalendarCubit _calendarCubit;
  Orientation? _previousOrientation;

  // Keep the pages list as templates; the actual first page (library)
  // will be built dynamically in build() to allow showing the
  // EmptyLibraryScreen inside the library tab while keeping the
  // rest of the application UI available.
  List<Widget> _pages = [];

  bool _hasCheckedAutoIndex = false;

  @override
  void initState() {
    super.initState();
    _calendarCubit = CalendarCubit();
    final initialPage = _pageIndexForScreen(
          context.read<NavigationBloc>().state.currentScreen,
        ) ??
        Screen.library.index;
    pageController = PageController(initialPage: initialPage);
  }

  void _checkAndStartIndexing(BuildContext context) {
    // Only check once, after settings are loaded
    if (_hasCheckedAutoIndex) return;
    _hasCheckedAutoIndex = true;

    // Check if auto-update is enabled
    if (context.read<SettingsBloc>().state.autoUpdateIndex) {
      DataRepository.instance.library.then((library) {
        if (!mounted || !context.mounted) return;
        context.read<IndexingBloc>().add(StartIndexing(library));
      });
    }
  }

  @override
  void dispose() {
    _calendarCubit.close();
    pageController.dispose();
    super.dispose();
  }

  void _handleOrientationChange(BuildContext context, Orientation orientation) {
    if (_previousOrientation != orientation) {
      _previousOrientation = orientation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !pageController.hasClients) {
          return;
        }
        final currentScreen =
            context.read<NavigationBloc>().state.currentScreen;
        final targetPage = _pageIndexForScreen(currentScreen);
        if (targetPage == null) {
          return;
        }

        if (pageController.page?.round() != targetPage) {
          pageController.jumpToPage(targetPage);
        }
      });
    }
  }

  /// ודאו שה-PageView מסונכרן למצב הניווט הנוכחי גם אם בחרו שוב באותו יעד.
  Future<void> _syncPageWithState({bool animate = true}) async {
    if (!mounted || !pageController.hasClients) return;
    final currentScreen = context.read<NavigationBloc>().state.currentScreen;
    final targetPage = _pageIndexForScreen(currentScreen);
    if (targetPage == null) return;
    if (pageController.page?.round() == targetPage) return;
    if (animate) {
      await pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      pageController.jumpToPage(targetPage);
    }
  }

  List<NavigationDestination> _buildNavigationDestinations(BuildContext context) {
    String formatShortcut(String shortcut) => shortcut.toUpperCase();

    final libraryShortcut =
        Settings.getValue<String>('key-shortcut-open-library-browser') ??
            'ctrl+l';
    final findShortcut =
        Settings.getValue<String>('key-shortcut-open-find-ref') ?? 'ctrl+o';
    final browseShortcut =
        Settings.getValue<String>('key-shortcut-open-reading-screen') ??
            'ctrl+r';
    final searchShortcut =
        Settings.getValue<String>('key-shortcut-open-new-search') ?? 'ctrl+q';

    return [
      NavigationDestination(
        tooltip: '',
        icon: Tooltip(
          preferBelow: false,
          message: formatShortcut(libraryShortcut),
          child: const Icon(FluentIcons.library_24_regular),
        ),
        label: context.t.navigation.library,
      ),
      NavigationDestination(
        tooltip: '',
        icon: Tooltip(
          preferBelow: false,
          message: formatShortcut(findShortcut),
          child: const Icon(FluentIcons.book_search_24_regular),
        ),
        label: context.t.navigation.find,
      ),
      NavigationDestination(
        tooltip: '',
        icon: Tooltip(
          preferBelow: false,
          message: formatShortcut(browseShortcut),
          child: const Icon(FluentIcons.book_open_24_regular),
        ),
        label: context.t.navigation.reading,
      ),
      NavigationDestination(
        tooltip: '',
        icon: Tooltip(
          preferBelow: false,
          message: formatShortcut(searchShortcut),
          child: const Icon(FluentIcons.search_24_regular),
        ),
        label: context.t.navigation.search,
      ),
      NavigationDestination(
        tooltip: '',
        icon: Tooltip(
          preferBelow: false,
          message: formatShortcut(
            Settings.getValue<String>('key-shortcut-open-more') ?? 'ctrl+m',
          ),
          child: const Icon(FluentIcons.apps_24_regular),
        ),
        label: context.t.navigation.tools,
      ),
      NavigationDestination(
        tooltip: '',
        icon: Tooltip(
          preferBelow: false,
          message: formatShortcut(
            Settings.getValue<String>('key-shortcut-open-settings') ??
                'ctrl+comma',
          ),
          child: const Icon(FluentIcons.settings_24_regular),
        ),
        label: context.t.navigation.settings,
      ),
      NavigationDestination(
        icon: Icon(FluentIcons.info_24_regular),
        label: context.t.navigation.about,
      ),
    ];
  }

  void _handleNavigationChange(
    BuildContext context,
    NavigationState state,
  ) async {
    if (!mounted || !context.mounted || !pageController.hasClients) {
      return;
    }

    if (pageController.hasClients) {
      final targetPage = _pageIndexForScreen(state.currentScreen);
      if (targetPage != null && pageController.page?.round() != targetPage) {
        await pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        if (!mounted || !context.mounted) return;
      }
      if (state.currentScreen == Screen.library) {
        context.read<FocusRepository>().requestLibrarySearchFocus(
              selectAll: true,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<NavigationBloc, NavigationState>(
          listenWhen: (previous, current) =>
              previous.currentScreen != current.currentScreen,
          listener: _handleNavigationChange,
        ),
        BlocListener<SettingsBloc, SettingsState>(
          listenWhen: (previous, current) {
            // Trigger when settings are loaded for the first time (not initial state anymore)
            // or when autoUpdateIndex changes
            final isInitialLoad = previous == SettingsState.initial() &&
                current != SettingsState.initial();
            final hasChanged =
                previous.autoUpdateIndex != current.autoUpdateIndex;
            return isInitialLoad || hasChanged;
          },
          listener: (context, state) {
            // When settings are loaded for the first time, check if we should start indexing
            _checkAndStartIndexing(context);
          },
        ),
      ],
      child: BlocProvider.value(
        value: _calendarCubit,
        child: BlocBuilder<NavigationBloc, NavigationState>(
          builder: (context, state) {
            // Build the pages list here so we can inject the EmptyLibraryScreen
            // into the library page while keeping the rest of the app visible.
            _pages = [
              KeepAlivePage(
                child: state.isLibraryEmpty
                    ? EmptyLibraryScreen(
                        onLibraryLoaded: () {
                          context.read<NavigationBloc>().refreshLibrary();
                        },
                      )
                    : const LibraryBrowser(),
              ),
              const KeepAlivePage(child: ReadingScreen()),
              KeepAlivePage(child: MoreScreen(key: moreScreenKey)),
              const KeepAlivePage(child: MySettingsScreen()),
            ];

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
                              child: Material(
                                color: Theme.of(context).colorScheme.surface,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    // חישוב גובה משוער לכל הכפתורים
                                    const buttonHeight = 60.0; // גובה משוער לכפתור + padding
                                    final totalButtonsHeight = 7 * buttonHeight;
                                    final minSpacerHeight = 20.0;
                                    final needsScroll = totalButtonsHeight + minSpacerHeight > constraints.maxHeight;

                                    if (needsScroll) {
                                      // אם אין מספיק מקום, השתמש בגלילה
                                      return SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            for (int i = 0; i < 7; i++)
                                              _buildNavButton(
                                                context,
                                                _buildNavigationDestinations(context)[i],
                                                i,
                                                state.currentScreen,
                                              ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      // אם יש מספיק מקום, השתמש ב-Spacer
                                      return Column(
                                        children: [
                                          // כפתורים עליונים
                                          for (int i = 0; i < 5; i++)
                                            _buildNavButton(
                                              context,
                                              _buildNavigationDestinations(context)[i],
                                              i,
                                              state.currentScreen,
                                            ),
                                          // רווח גמיש
                                          const Spacer(),
                                          // כפתורים תחתונים
                                          for (int i = 5; i < 7; i++)
                                            _buildNavButton(
                                              context,
                                              _buildNavigationDestinations(context)[i],
                                              i,
                                              state.currentScreen,
                                            ),
                                        ],
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                            const VerticalDivider(thickness: 1, width: 1),
                            Expanded(child: pageView),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            Expanded(child: pageView),
                            NavigationBar(
                              destinations: _buildNavigationDestinations(context),
                              selectedIndex: _getSelectedIndex(
                                state.currentScreen,
                              ),
                              onDestinationSelected: (index) async {
                                // אם בחרו שוב באותו היעד – רק סנכרנו את ה-PageView למסך
                                final currentIndex =
                                    _getSelectedIndex(state.currentScreen);
                                if (index == currentIndex) {
                                  // סנכרון ידני – שימושי כאשר מסיבה כלשהי ה-PageView סטה מהמצב
                                  await _syncPageWithState();
                                  return;
                                }
                                if (index == Screen.search.index) {
                                  _handleSearchTabOpen(context);
                                } else if (index == Screen.find.index) {
                                  _handleFindRefOpen(context);
                                } else if (index == Screen.about.index) {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        const AboutDialogWidget(),
                                  );
                                } else {
                                  context.read<NavigationBloc>().add(
                                    NavigateToScreen(Screen.values[index]),
                                  );
                                }
                                if (index == Screen.library.index) {
                                  context
                                      .read<FocusRepository>()
                                      .requestLibrarySearchFocus(
                                        selectAll: true,
                                      );
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
      ),
    );
  }

  int? _pageIndexForScreen(Screen screen) {
    switch (screen) {
      case Screen.library:
        return 0;
      case Screen.reading:
      case Screen.search:
        return 1;
      case Screen.more:
        return 2;
      case Screen.settings:
        return 3;
      case Screen.find:
      case Screen.about:
        return null;
    }
  }

  void _handleSearchTabOpen(BuildContext context) {
    final useFastSearch = context.read<SettingsBloc>().state.useFastSearch;
    if (!useFastSearch) {
      _openLegacySearchTab(context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => const SearchDialog(existingTab: null),
    );
  }

  void _openLegacySearchTab(BuildContext context) {
    final tabsBloc = context.read<TabsBloc>();
    final navigationBloc = context.read<NavigationBloc>();

    final tabsState = tabsBloc.state;
    final hasSearchTab = tabsState.tabs.any(
      (tab) => tab.runtimeType == SearchingTab,
    );

    if (!hasSearchTab) {
      tabsBloc.add(AddTab(SearchingTab(context.t.navigation.search, "")));
    } else {
      final currentScreen = navigationBloc.state.currentScreen;
      final isAlreadySearchTab =
          currentScreen == Screen.search &&
          tabsState.tabs[tabsState.currentTabIndex].runtimeType == SearchingTab;
      if (!isAlreadySearchTab) {
        final searchTabIndex = tabsState.tabs.indexWhere(
          (tab) => tab.runtimeType == SearchingTab,
        );
        if (searchTabIndex != -1) {
          tabsBloc.add(SetCurrentTab(searchTabIndex));
        }
      }
    }

    navigationBloc.add(const NavigateToScreen(Screen.search));
  }

  void _handleFindRefOpen(BuildContext context) {
    showDialog(context: context, builder: (context) => FindRefDialog());
  }

  int _getSelectedIndex(Screen currentScreen) {
    // מיפוי מחדש של האינדקסים כיון שהסרנו את דף האיתור
    switch (currentScreen) {
      case Screen.library:
        return 0;
      case Screen.find:
        return -1; // לא נבחר
      case Screen.reading:
        return 2;
      case Screen.search:
        return 3;
      case Screen.more:
        return 4;
      case Screen.settings:
        return 5;
      case Screen.about:
        return 6;
    }
  }

  Widget _buildNavButton(
    BuildContext context,
    NavigationDestination destination,
    int index,
    Screen currentScreen,
  ) {
    final isSelected = _getSelectedIndex(currentScreen) == index;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () async {
              // אם בחרו שוב באותו היעד – רק סנכרנו את ה-PageView למסך
              final currentIndex = _getSelectedIndex(currentScreen);
              if (index == currentIndex) {
                await _syncPageWithState();
                return;
              }
              if (index == Screen.search.index) {
                _handleSearchTabOpen(context);
              } else if (index == Screen.find.index) {
                _handleFindRefOpen(context);
              } else if (index == Screen.about.index) {
                showDialog(
                  context: context,
                  builder: (context) => const AboutDialogWidget(),
                );
              } else {
                context.read<NavigationBloc>().add(
                  NavigateToScreen(Screen.values[index]),
                );
              }
              if (index == Screen.library.index) {
                context.read<FocusRepository>().requestLibrarySearchFocus(
                  selectAll: true,
                );
              }
            },
            icon: IconTheme(
              data: IconThemeData(
                color: isSelected
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurfaceVariant,
                size: 24,
              ),
              child: destination.icon,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isSelected
                  ? colorScheme.secondaryContainer
                  : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              minimumSize: const Size(64, 25),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            destination.label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class KeepAlivePage extends StatefulWidget {
  final Widget child;

  const KeepAlivePage({super.key, required this.child});

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
