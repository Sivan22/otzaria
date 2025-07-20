import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/focus/focus_repository.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_event.dart';
import 'package:otzaria/navigation/bloc/navigation_state.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_event.dart';
import 'package:otzaria/history/bloc/history_bloc.dart';
import 'package:otzaria/history/bloc/history_event.dart';
import 'package:otzaria/tabs/models/searching_tab.dart';
import 'package:provider/provider.dart';

class KeyboardShortcuts extends StatelessWidget {
  final Widget child;

  KeyboardShortcuts({Key? key, required this.child}) : super(key: key);

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
    'ctrl+tab':
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.tab),
    'ctrl+shift+tab': LogicalKeySet(LogicalKeyboardKey.control,
        LogicalKeyboardKey.tab, LogicalKeyboardKey.shift),
  };

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        shortcuts[
            Settings.getValue<String>('key-shortcut-open-library-browser') ??
                'ctrl+l']!: () {
          context
              .read<NavigationBloc>()
              .add(const NavigateToScreen(Screen.library));
          //set focus
          context.read<FocusRepository>().requestLibrarySearchFocus(selectAll: true);
        },
        shortcuts[Settings.getValue<String>('key-shortcut-open-find-ref') ??
            'ctrl+o']!: () {
          context
              .read<NavigationBloc>()
              .add(const NavigateToScreen(Screen.find));
          //set focus
          context.read<FocusRepository>().requestFindRefSearchFocus(selectAll: true);
        },
        shortcuts[Settings.getValue<String>('key-shortcut-close-tab') ??
            'ctrl+w']!: () {
          final tabsBloc = context.read<TabsBloc>();
          final historyBloc = context.read<HistoryBloc>();
          if (tabsBloc.state.tabs.isNotEmpty) {
            final currentTab =
                tabsBloc.state.tabs[tabsBloc.state.currentTabIndex];
            historyBloc.add(AddHistory(currentTab));
          }
          tabsBloc.add(const CloseCurrentTab());
        },
        shortcuts[Settings.getValue<String>('key-shortcut-close-all-tabs') ??
            'ctrl+x']!: () {
          final tabsBloc = context.read<TabsBloc>();
          final historyBloc = context.read<HistoryBloc>();
          for (final tab in tabsBloc.state.tabs) {
            if (tab is! SearchingTab) {
              historyBloc.add(AddHistory(tab));
            }
          }
          tabsBloc.add(CloseAllTabs());
        },
        shortcuts[
            Settings.getValue<String>('key-shortcut-open-reading-screen') ??
                'ctrl+r']!: () {
          context
              .read<NavigationBloc>()
              .add(const NavigateToScreen(Screen.reading));
        },
        shortcuts[Settings.getValue<String>('key-shortcut-open-new-search') ??
            'ctrl+q']!: () {
          context
              .read<NavigationBloc>()
              .add(const NavigateToScreen(Screen.search));
          context.read<TabsBloc>().add(AddTab(SearchingTab('חיפוש', null)));
        },
        shortcuts['ctrl+shift+tab']!: () {
          context.read<TabsBloc>().add(NavigateToPreviousTab());
        },
        shortcuts['ctrl+tab']!: () {
          context.read<TabsBloc>().add(NavigateToNextTab());
        }
      },
      child: child,
    );
  }
}
