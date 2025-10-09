/// This is the main entry point for the Otzaria application.
/// The application is a Flutter-based digital library system that supports
/// RTL (Right-to-Left) languages, particularly Hebrew.
/// It includes features for dark mode, customizable themes, and local storage management.
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:otzaria/app.dart';
import 'package:otzaria/bookmarks/bloc/bookmark_bloc.dart';
import 'package:otzaria/bookmarks/repository/bookmark_repository.dart';
import 'package:otzaria/find_ref/find_ref_bloc.dart';
import 'package:otzaria/find_ref/find_ref_repository.dart';
import 'package:otzaria/focus/focus_repository.dart';
import 'package:otzaria/history/bloc/history_bloc.dart';
import 'package:otzaria/history/history_repository.dart';
import 'package:otzaria/indexing/bloc/indexing_bloc.dart';
import 'package:otzaria/library/bloc/library_bloc.dart';
import 'package:otzaria/library/bloc/library_event.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_event.dart';
import 'package:otzaria/navigation/navigation_repository.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_event.dart';
import 'package:otzaria/settings/settings_repository.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_event.dart';
import 'package:otzaria/tabs/tabs_repository.dart';
import 'package:otzaria/workspaces/bloc/workspace_bloc.dart';
import 'package:otzaria/workspaces/bloc/workspace_event.dart';
import 'package:otzaria/workspaces/workspace_repository.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:otzaria/app_bloc_observer.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/data/data_providers/hive_data_provider.dart';
import 'package:otzaria/notes/data/database_schema.dart';
import 'package:otzaria/notes/bloc/notes_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:search_engine/search_engine.dart';
import 'package:otzaria/core/app_paths.dart';
import 'package:otzaria/core/window_listener.dart';
import 'package:shamor_zachor/providers/shamor_zachor_data_provider.dart';
import 'package:shamor_zachor/providers/shamor_zachor_progress_provider.dart';

// Global reference to window listener for cleanup
AppWindowListener? _appWindowListener;

/// Application entry point that initializes necessary components and launches the app.
///
/// This function performs the following initialization steps:
/// 1. Ensures Flutter bindings are initialized
/// 2. Calls [initialize] to set up required services and configurations
/// 3. Launches the main application widget
void main() async {
  // write errors to file
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    } else {
      File('errors.txt')
          .writeAsStringSync(details.toString(), mode: FileMode.append);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(FlutterErrorDetails(
        exception: error,
        stack: stack,
      ));
    } else {
      File('errors.txt')
          .writeAsStringSync(error.toString(), mode: FileMode.append);
    }
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();

  // Check for single instance
  FlutterSingleInstance flutterSingleInstance = FlutterSingleInstance();
  bool isFirstInstance = await flutterSingleInstance.isFirstInstance();
  if (!isFirstInstance) {
    // If not the first instance, exit the app
    exit(0);
  }

  // Initialize bloc observer for debugging
  Bloc.observer = AppBlocObserver();

  await initialize();

  final historyRepository = HistoryRepository();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<FocusRepository>(
          create: (context) => FocusRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SettingsBloc>(
            create: (context) => SettingsBloc(
              repository: SettingsRepository(),
            )..add(LoadSettings()),
          ),
          BlocProvider<LibraryBloc>(
            create: (context) => LibraryBloc()..add(LoadLibrary()),
          ),
          BlocProvider<IndexingBloc>(
            create: (context) => IndexingBloc.create(),
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
          BlocProvider<NotesBloc>(
            create: (context) => NotesBloc(),
          ),
          BlocProvider<BookmarkBloc>(
            create: (context) => BookmarkBloc(BookmarkRepository()),
          ),
          BlocProvider<WorkspaceBloc>(
            create: (context) => WorkspaceBloc(
              repository: WorkspaceRepository(),
              tabsBloc: context.read<TabsBloc>(),
            )..add(LoadWorkspaces()),
          ),
          ChangeNotifierProvider<ShamorZachorDataProvider>(
            create: (context) => ShamorZachorDataProvider(),
          ),
          ChangeNotifierProvider<ShamorZachorProgressProvider>(
            create: (context) => ShamorZachorProgressProvider(),
          ),
        ],
        child: const App(),
      ),
    ),
  );
}

/// Initializes all required services and configurations for the application.
///
/// This function handles the following initialization steps:
/// 1. Settings initialization with Hive cache
/// 2. Library path configuration
/// 3. Rust library initialization
/// 4. Hive storage boxes setup
/// 5. Required directory structure creation
Future<void> initialize() async {
  // Initialize SQLite FFI for desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await windowManager.ensureInitialized();

    // Configure window manager for proper close handling
    WindowOptions windowOptions = const WindowOptions(
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    // Add window listener for proper close handling
    _appWindowListener = AppWindowListener();
    windowManager.addListener(_appWindowListener!);

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  await RustLib.init();
  await Settings.init(cacheProvider: HiveCache());
  await initHive();
  await createDirs();
  await loadCerts();

  // Initialize notes database
  try {
    await DatabaseSchema.initializeDatabase();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Failed to initialize notes database: $e');
    }
    // Continue without notes functionality if database fails
  }
}

/// Creates the necessary directory structure for the application.
///
/// Sets up two main directories:
/// - Main library directory ('אוצריא')
/// - Index directory for search functionality
Future<void> createDirs() async {
  await AppPaths.createNecessaryDirectories();
}

/// Creates a directory if it doesn't already exist.
///
/// [path] The full path of the directory to create
///
/// Prints status messages indicating whether the directory was created
/// or already existed.
void createDirectoryIfNotExists(String path) {
  Directory directory = Directory(path);
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }
}

initHive() async {
  Hive.defaultDirectory = (await getApplicationSupportDirectory()).path;
}

Future<void> loadCerts() async {
  final certs = ['assets/ca/netfree_cas.pem'];
  for (var cert in certs) {
    final certBytes = await rootBundle.load(cert);
    SecurityContext.defaultContext
        .setTrustedCertificatesBytes(certBytes.buffer.asUint8List());
  }
}

/// Clean up resources when the app is closing
void cleanup() {
  _appWindowListener?.dispose();
}
