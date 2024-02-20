import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'main_window_view.dart';
import 'settings_screen.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'cache_provider.dart';

void main() {
  Settings.init(cacheProvider: HiveCache());
  runApp(const FileExplorerApp());
}

class FileExplorerApp extends StatelessWidget {
  const FileExplorerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'candara',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 18.0, fontFamily: 'candara'),
        ),
      ),
      routes: {
        '/settings': (context) => mySettingsScreen(),
      },
      home: const MainWindowView(),
    );
  }
}
