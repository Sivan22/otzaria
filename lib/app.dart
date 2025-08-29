import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/core/scaffold_messenger.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_state.dart';
import 'package:otzaria/navigation/main_window_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final state = settingsState;
        return MaterialApp(
          scaffoldMessengerKey: scaffoldMessengerKey,
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
  }
}
