import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:otzaria/bookmarks/bloc/bookmark_bloc.dart';
import 'package:otzaria/bookmarks/repository/bookmark_repository.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/find_ref/find_ref_bloc.dart';
import 'package:otzaria/find_ref/find_ref_event.dart';
import 'package:otzaria/find_ref/find_ref_repository.dart';
import 'package:otzaria/focus/focus_bloc.dart';
import 'package:otzaria/history/bloc/history_bloc.dart';
import 'package:otzaria/history/history_repository.dart';
import 'package:otzaria/indexing/bloc/indexing_bloc.dart';
import 'package:otzaria/library/bloc/library_bloc.dart';
import 'package:otzaria/library/bloc/library_event.dart';
import 'package:otzaria/navigation/bloc/navigation_event.dart';
import 'package:otzaria/navigation/navigation_repository.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_event.dart';
import 'package:otzaria/settings/settings_repository.dart';
import 'package:otzaria/settings/settings_state.dart';
import 'package:otzaria/navigation/main_window_screen.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_event.dart';
import 'package:otzaria/tabs/tabs_repository.dart';
import 'package:otzaria/workspaces/bloc/workspace_bloc.dart';
import 'package:otzaria/workspaces/bloc/workspace_event.dart';
import 'package:otzaria/workspaces/workspace_repository.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final historyRepository = HistoryRepository();

    return MultiBlocProvider(
      providers: [
        BlocProvider<LibraryBloc>(
          create: (context) => LibraryBloc()..add(LoadLibrary()),
        ),
        BlocProvider<SettingsBloc>(
          create: (context) => SettingsBloc(
            repository: SettingsRepository(),
          ),
        ),
        BlocProvider<HistoryBloc>(
            create: (context) => HistoryBloc(historyRepository)),
        BlocProvider<TabsBloc>(
          create: (context) => TabsBloc(
            repository: TabsRepository(),
          )..add(LoadTabs()),
        ),
        BlocProvider<NavigationBloc>(
          create: (context) => NavigationBloc(
            repository: NavigationRepository(),
            tabsRepository: TabsRepository(),
          )..add(const CheckLibrary()),
        ),
        BlocProvider<FindRefBloc>(
            create: (context) => FindRefBloc(
                findRefRepository: FindRefRepository(
                    dataRepository: DataRepository.instance))),
        BlocProvider<BookmarkBloc>(
          create: (context) => BookmarkBloc(BookmarkRepository()),
        ),
        BlocProvider<FocusBloc>(
          create: (context) => FocusBloc(),
        ),
        BlocProvider<WorkspaceBloc>(
          create: (context) => WorkspaceBloc(
            repository: WorkspaceRepository(),
            tabsBloc: context.read<TabsBloc>(),
          )..add(LoadWorkspaces()),
        ),
        BlocProvider<IndexingBloc>(create: (context) => IndexingBloc.create()),
      ],
      child: Builder(builder: (context) {
        context.read<SettingsBloc>().add(LoadSettings());
        return BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, settingsState) {
            final state = settingsState;
            return MaterialApp(
              localizationsDelegates: const [
                GlobalCupertinoLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale("he", "IL"),
              ],
              locale: const Locale("he", "IL"),
              title: 'אוצריא',
              theme: state.isDarkMode
                  ? ThemeData.dark(useMaterial3: true)
                  : ThemeData(
                      visualDensity: VisualDensity.adaptivePlatformDensity,
                      fontFamily: 'Roboto',
                      colorScheme: ColorScheme.fromSeed(
                        seedColor: state.seedColor,
                      ),
                      textTheme: const TextTheme(
                        bodyMedium:
                            TextStyle(fontSize: 18.0, fontFamily: 'candara'),
                      ),
                    ),
              home: const MainWindowScreen(),
            );
          },
        );
      }),
    );
  }
}
