import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'main_window_view.dart';
import 'settings_screen.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'cache_provider.dart';

void main() async {
  await Settings.init(cacheProvider: HiveCache());
  runApp(FileExplorerApp());
}

class FileExplorerApp extends StatelessWidget {
  FileExplorerApp({Key? key}) : super(key: key);
  final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(
    Settings.getValue<bool>('key-dark-mode') ?? false,
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: isDarkMode,
        builder: (BuildContext context, dynamic value, Widget? child) {
          return MaterialApp(
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
            theme: value
                ? ThemeData.dark(useMaterial3: true)
                : ThemeData(
                    visualDensity: VisualDensity.adaptivePlatformDensity,
                    fontFamily: 'candara',
                    colorScheme: ColorScheme.fromSeed(
                        seedColor: Color.fromARGB(255, 44, 27, 2)),
                    textTheme: const TextTheme(
                      bodyMedium:
                          TextStyle(fontSize: 18.0, fontFamily: 'candara'),
                    ),
                  ),
            routes: {
              '/settings': (context) => mySettingsScreen(isDarkMode),
            },
            home: MainWindowView(isDarkMode: isDarkMode),
          );
        });
  }
}
