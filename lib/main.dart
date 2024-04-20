import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:otzaria/model/model.dart';
import 'screens/main_window_screen.dart';
import 'screens/settings_screen.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:otzaria/model/bookmark.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:otzaria/data/cache_provider.dart';
import 'package:get_it/get_it.dart';

void main() async {
  // initializing all the hive components
  await () async {
    await Settings.init(cacheProvider: HiveCache());
    WidgetsFlutterBinding.ensureInitialized();
    Hive.registerAdapter<Bookmark>(
        'Bookmark', (json) => Bookmark.fromJson(json));
    Hive.defaultDirectory = (await getApplicationSupportDirectory()).path;
    Hive.box(name: 'bookmarks');
    Hive.box(name: 'tabs');
  }();
  GetIt.I.registerSingleton<AppModel>(AppModel());
  runApp(FileExplorerApp());
}

class FileExplorerApp extends StatelessWidget {
  FileExplorerApp({Key? key}) : super(key: key);
  final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(
    Settings.getValue<bool>('key-dark-mode') ?? false,
  );
  final ValueNotifier<Color> seedColor = ValueNotifier<Color>(
    ConversionUtils.colorFromString(
        Settings.getValue<String>('key-swatch-color') ?? ('#ff2c1b02')),
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: isDarkMode,
        builder: (BuildContext context, dynamic value, Widget? child) {
          return ValueListenableBuilder(
              valueListenable: seedColor,
              builder:
                  (BuildContext context, dynamic seedColor, Widget? child) {
                return MaterialApp(
                  localizationsDelegates: const [
                    GlobalCupertinoLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                  ],
                  supportedLocales: const [
                    Locale("he",
                        "IL"), // OR Locale('ar', 'AE') OR Other RTL locales
                  ],
                  locale: const Locale("he",
                      "IL"), // OR Locale('ar', 'AE') OR Other RTL locales,
                  title: 'אוצריא',
                  theme: value
                      ? ThemeData.dark(useMaterial3: true)
                      : ThemeData(
                          visualDensity: VisualDensity.adaptivePlatformDensity,
                          fontFamily: 'candara',
                          colorScheme: ColorScheme.fromSeed(
                            seedColor: seedColor,
                          ),
                          textTheme: const TextTheme(
                            bodyMedium: TextStyle(
                                fontSize: 18.0, fontFamily: 'candara'),
                          ),
                        ),
                  routes: {
                    '/settings': (context) => MySettingsScreen(
                        isDarkMode: isDarkMode, seedColor: this.seedColor),
                  },
                  home: MainWindowView(
                      isDarkMode: isDarkMode, seedColor: this.seedColor),
                );
              });
        });
  }
}
