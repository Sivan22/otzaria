import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:provider/provider.dart';
import 'screens/main_window_screen.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/data/cache_provider.dart';
import 'package:otzaria/data/hive_data_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

/// The main entry point of the application.
///
/// This function is responsible for initializing the application and running
/// it. It performs the following steps:
/// 1. Requests external storage permission on Android.
/// 2. Initializes all the Hive components.
/// 3. Initializes the library path.
///
/// This function does not take any parameters and does not return any values.
///

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // requesting external storage permission on android
  while (
      Platform.isAndroid && !await Permission.manageExternalStorage.isGranted) {
    Permission.manageExternalStorage.request();
  }
  // initializing all the hive components
  await () async {
    await Settings.init(cacheProvider: HiveCache());
    await initHiveBoxes();
  }();
  // initializing the library path
  await () async {
    //first try to get the library path from settings
    String? libraryPath = Settings.getValue('key-library-path');
    //on windows, if the path is not set, defaults to C:/אוצריא
    if (Platform.isWindows && libraryPath == null) {
      libraryPath = 'C:/אוצריא';
      Settings.setValue('key-library-path', libraryPath);
    }
    //if faild, ask the user to choose the path
    while (libraryPath == null ||
        (!Directory('$libraryPath${Platform.pathSeparator}אוצריא')
            .existsSync())) {
      libraryPath = await FilePicker.platform
          .getDirectoryPath(dialogTitle: "הגדר את מיקום ספריית אוצריא");
      Settings.setValue('key-library-path', libraryPath);
    }
  }();
  runApp(const OtzariaApp());
}

class OtzariaApp extends StatelessWidget {
  const OtzariaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppModel(),
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
