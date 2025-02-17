/// This is the main entry point for the Otzaria application.
/// The application is a Flutter-based digital library system that supports
/// RTL (Right-to-Left) languages, particularly Hebrew.
/// It includes features for dark mode, customizable themes, and local storage management.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/app.dart';
import 'package:otzaria/bloc/library/library_bloc.dart';
import 'package:otzaria/bloc/library/library_event.dart';
import 'package:otzaria/bloc/navigation/navigation_bloc.dart';
import 'package:otzaria/bloc/navigation/navigation_event.dart';
import 'package:otzaria/bloc/navigation/navigation_repository.dart';
import 'package:otzaria/bloc/settings/settings_bloc.dart';
import 'package:otzaria/bloc/settings/settings_event.dart';
import 'package:otzaria/bloc/settings/settings_repository.dart';
import 'package:otzaria/bloc/tabs/tabs_bloc.dart';
import 'package:otzaria/bloc/tabs/tabs_event.dart';
import 'package:otzaria/bloc/tabs/tabs_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:otzaria/bloc/app_bloc_observer.dart';
import 'package:search_engine/search_engine.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/data/data_providers/cache_provider.dart';
import 'package:otzaria/data/data_providers/hive_data_provider.dart';
import 'dart:io';

/// Application entry point that initializes necessary components and launches the app.
///
/// This function performs the following initialization steps:
/// 1. Ensures Flutter bindings are initialized
/// 2. Calls [initialize] to set up required services and configurations
/// 3. Launches the main application widget
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize bloc observer for debugging
  Bloc.observer = AppBlocObserver();

  await initialize();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<LibraryBloc>(
          create: (context) => LibraryBloc()..add(LoadLibrary()),
        ),
        BlocProvider<SettingsBloc>(
          create: (context) => SettingsBloc(
            repository: SettingsRepository(),
          )..add(LoadSettings()),
        ),
        BlocProvider<TabsBloc>(
          create: (context) => TabsBloc(
            repository: TabsRepository(),
          )..add(LoadTabs()),
        ),
        BlocProvider<NavigationBloc>(
          create: (context) => NavigationBloc(
            repository: NavigationRepository(),
            tabsBloc: context.read<TabsBloc>(),
          )..add(const CheckLibrary()),
        ),
      ],
      child: const App(),
    ),
  );

  RustLib.dispose();
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
  await Settings.init(cacheProvider: HiveCache());
  await initLibraryPath();
  await RustLib.init();
  await initHiveBoxes();
  await createDirs();
  await loadCerts();
}

/// Creates the necessary directory structure for the application.
///
/// Sets up two main directories:
/// - Main library directory ('אוצריא')
/// - Index directory for search functionality
Future<void> createDirs() async {
  createDirectoryIfNotExists(
      '${Settings.getValue('key-library-path')}${Platform.pathSeparator}אוצריא');
  createDirectoryIfNotExists(
      '${Settings.getValue('key-library-path')}${Platform.pathSeparator}index');
}

/// Initializes the library path based on the platform.
///
/// For mobile platforms (Android/iOS), uses the application documents directory.
/// For Windows, defaults to 'C:/אוצריא' if not previously set.
/// For other platforms, uses the existing settings value.
Future<void> initLibraryPath() async {
  if (!Settings.isInitialized) {
    await Settings.init(cacheProvider: HiveCache());
  }
  if (Platform.isAndroid || Platform.isIOS) {
    // Mobile platforms use the app's documents directory
    await Settings.setValue(
        'key-library-path', (await getApplicationDocumentsDirectory()).path);
    return;
  }

  // Check existing library path setting
  String? libraryPath = Settings.getValue('key-library-path');

  // Set default Windows path if not configured
  if (Platform.isWindows && libraryPath == null) {
    libraryPath = 'C:/אוצריא';
    Settings.setValue('key-library-path', libraryPath);
  }
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

Future<void> loadCerts() async {
  final certs = ['assets/ca/netfree_cas.pem'];
  for (var cert in certs) {
    final certBytes = await rootBundle.load(cert);
    SecurityContext.defaultContext
        .setTrustedCertificatesBytes(certBytes.buffer.asUint8List());
  }
}
