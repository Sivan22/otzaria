/// This is the main entry point for the Otzaria application.
/// The application is a Flutter-based digital library system that supports
/// RTL (Right-to-Left) languages, particularly Hebrew.
/// It includes features for dark mode, customizable themes, and local storage management.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:search_engine/search_engine.dart';
import 'screens/main_window_screen.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/data/data_providers/cache_provider.dart';
import 'package:otzaria/data/data_providers/hive_data_provider.dart';
import 'dart:io';

/// Application entry point that initializes necessary components and launches the app.
///
/// This function performs the following initialization steps:
/// 1. Ensures Flutter bindings are initialized
/// 2. Calls [initialize] to set up required services and configurations
/// 3. Launches the main application widget [OtzariaApp]
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initialize();
  runApp(const OtzariaApp());
}

/// The root widget of the Otzaria application.
///
/// This widget sets up the application-wide configurations including:
/// - State management using Provider
/// - RTL localization support
/// - Theme configuration with dark mode support
/// - Application-wide settings
class OtzariaApp extends StatelessWidget {
  const OtzariaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Initialize AppModel with the library path from settings or default path
      create: (context) => AppModel(
        Settings.getValue('key-library-path') ?? 'c:\\אוצריא',
      ),
      builder: (context, child) {
        return Consumer<AppModel>(
          builder: (context, appModel, child) => MaterialApp(
            // Configure RTL support with Hebrew localization
            localizationsDelegates: const [
              GlobalCupertinoLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale("he", "IL"), // Hebrew (Israel) locale
            ],
            locale: const Locale("he", "IL"),
            title: 'אוצריא',
            // Dynamic theme based on dark mode preference
            theme: appModel.isDarkMode.value
                ? ThemeData.dark(useMaterial3: true)
                : ThemeData(
                    visualDensity: VisualDensity.adaptivePlatformDensity,
                    fontFamily: 'Roboto',
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: appModel.seedColor.value,
                    ),
                    textTheme: const TextTheme(
                      bodyMedium:
                          TextStyle(fontSize: 18.0, fontFamily: 'candara'),
                    ),
                  ),
            home: const MainWindowScreen(),
          ),
        );
      },
    );
  }
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
    print('Directory created: $path');
  } else {
    print('Directory already exists: $path');
  }
}
