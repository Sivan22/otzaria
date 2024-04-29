import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:provider/provider.dart';
import 'screens/main_window_screen.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:otzaria/models/bookmark.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:otzaria/data/cache_provider.dart';

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
  runApp(FileExplorerApp());
}

class FileExplorerApp extends StatelessWidget {
  FileExplorerApp({Key? key}) : super(key: key);

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
                    fontFamily: 'candara',
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: appModel.seedColor.value,
                    ),
                    textTheme: const TextTheme(
                      bodyMedium:
                          TextStyle(fontSize: 18.0, fontFamily: 'candara'),
                    ),
                  ),
            home: const MainWindowView(),
          ),
        );
      },
    );
  }
}
