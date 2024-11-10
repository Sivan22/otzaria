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

void main() async {
  await initialize();
  runApp(const OtzariaApp());
}

class OtzariaApp extends StatelessWidget {
  const OtzariaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppModel(
        Settings.getValue('key-library-path') ?? 'c:\\אוצריא',
      ),
      builder: (context, child) {
        return Consumer<AppModel>(
          builder: (context, appModel, child) => MaterialApp(
            localizationsDelegates: const [
              GlobalCupertinoLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale("he", "IL"), // OR Locale('ar', 'AE') OR Other RTL locales
            ],
            locale: const Locale(
                "he", "IL"), // OR Locale('ar', 'AE') OR Other RTL locales,
            title: 'אוצריא',
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

Future<void> initialize() async {
  await Settings.init(cacheProvider: HiveCache());
  await initLibraryPath();
  await RustLib.init();
  await initHiveBoxes();
  await createDirs();
}

Future<void> createDirs() async {
  createDirectoryIfNotExists(
      '${Settings.getValue('key-library-path')}${Platform.pathSeparator}אוצריא');
  createDirectoryIfNotExists(
      '${Settings.getValue('key-library-path')}${Platform.pathSeparator}index');
}

Future<void> initLibraryPath() async {
  if (Platform.isAndroid) {
    await Settings.setValue(
        'key-library-path', (await getApplicationDocumentsDirectory()).path);
    return;
  }
  //first try to get the library path from settings
  String? libraryPath = Settings.getValue('key-library-path');
  //on windows, if the path is not set, defaults to C:/אוצריא
  if (Platform.isWindows && libraryPath == null) {
    libraryPath = 'C:/אוצריא';
    Settings.setValue('key-library-path', libraryPath);
  }
}

void createDirectoryIfNotExists(String path) {
  Directory directory = Directory(path);
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
    print('Directory created: $path');
  } else {
    print('Directory already exists: $path');
  }
}
