import 'package:flutter/material.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'main.dart';

class mySettingsScreen extends StatelessWidget {
  ValueNotifier<bool> isDarkMode;

  mySettingsScreen(
    this.isDarkMode,
  );

  @override
  Widget build(BuildContext context) {
    const Map<String, String> shortcuctsList = {
      'ctrl+a': 'CTRL + A',
      'ctrl+b': "CTRL + B",
      'ctrl+c': "CTRL + C",
      'ctrl+d': "CTRL + D",
      'ctrl+e': "CTRL + E",
      'ctrl+f': "CTRL + F",
      'ctrl+g': "CTRL + G",
      'ctrl+h': "CTRL + H",
      'ctrl+i': "CTRL + I",
      'ctrl+j': "CTRL + J",
      'ctrl+k': "CTRL + K",
      'ctrl+l': "CTRL + L",
      'ctrl+m': "CTRL + M",
      'ctrl+n': "CTRL + N",
      'ctrl+o': "CTRL + O",
      'ctrl+p': "CTRL + P",
      'ctrl+q': "CTRL + Q",
      'ctrl+r': "CTRL + R",
      'ctrl+s': "CTRL + S",
      'ctrl+t': "CTRL + T",
      'ctrl+u': "CTRL + U",
      'ctrl+v': "CTRL + V",
      'ctrl+w': "CTRL + W",
      'ctrl+x': "CTRL + X",
      'ctrl+y': "CTRL + Y",
      'ctrl+z': "CTRL + Z",
      'ctrl+0': "CTRL + 0",
      'ctrl+1': "CTRL + 1",
      'ctrl+2': "CTRL + 2",
      'ctrl+3': "CTRL + 3",
      'ctrl+4': "CTRL + 4",
      'ctrl+5': "CTRL + 5",
      'ctrl+6': "CTRL + 6",
      'ctrl+7': "CTRL + 7",
      'ctrl+8': "CTRL + 8",
      'ctrl+9': "CTRL + 9",
    };

    return Scaffold(
        body: Center(
      child: SettingsScreen(
        title: 'הגדרות',
        children: [
          SettingsGroup(
            title: 'הגדרות עיצוב',
            titleTextStyle: const TextStyle(fontSize: 25),
            children: <Widget>[
              SwitchSettingsTile(
                settingKey: 'key-dark-mode',
                title: 'מצב כהה',
                enabledLabel: 'מופעל',
                disabledLabel: 'לא מופעל',
                leading: const Icon(Icons.nightlight_round_outlined),
                onChange: (value) {
                  isDarkMode.value = value;
                  isDarkMode.notifyListeners();
                },
              ),
              SliderSettingsTile(
                title: 'גודל גופן התחלתי בספרים',
                settingKey: 'key-font-size',
                defaultValue: 30,
                min: 15,
                max: 60,
                step: 1,
                leading: const Icon(Icons.format_size),
                decimalPrecision: 0,
                onChange: (value) {},
              ),
              DropDownSettingsTile<String>(
                title: 'גופן',
                settingKey: 'key-font-family',
                values: const <String, String>{
                  'TaameyDavidCLM': 'דוד',
                  'FrankRuhlCLM': 'פרנק-רוהל',
                  'TaameyAshkenaz': 'טעמי אשכנז',
                  'KeterYG': 'כתר',
                  'Shofar': 'שופר',
                  'NotoSerifHebrew': 'נוטו',
                  'Tinos': 'טינוס',
                  'NotoRashiHebrew': 'רש"י',
                  'Candara': 'קנדרה',
                  'roboto': 'רובוטו',
                  'Calibri': 'קליברי',
                  'Arial': 'אריאל',
                },
                selected: 'FrankRuhlCLM',
                leading: const Icon(Icons.font_download_outlined),
                onChange: (value) {},
              ),
            ],
          ),
          const SettingsGroup(
              title: "קיצורי מקשים",
              titleTextStyle: const TextStyle(fontSize: 25),
              children: [
                DropDownSettingsTile<String>(
                  selected: 'ctrl+b',
                  settingKey: 'key-shortcut-open-book-browser',
                  title: 'דפדוף בספריה',
                  values: shortcuctsList,
                  leading: Icon(Icons.folder),
                ),
                DropDownSettingsTile<String>(
                  selected: 'ctrl+w',
                  settingKey: 'key-shortcut-close-tab',
                  title: 'סגור ספר נוכחי',
                  leading: Icon(Icons.cancel),
                  values: shortcuctsList,
                ),
                DropDownSettingsTile<String>(
                  selected: 'ctrl+x',
                  settingKey: 'key-shortcut-close-all-tabs',
                  title: 'סגור כל הספרים',
                  leading: Icon(Icons.close),
                  values: shortcuctsList,
                ),
                DropDownSettingsTile<String>(
                  selected: 'ctrl+o',
                  settingKey: 'key-shortcut-open-book-search',
                  title: 'איתור ספר',
                  leading: Icon(Icons.library_books),
                  values: shortcuctsList,
                ),
                DropDownSettingsTile<String>(
                  selected: 'ctrl+q',
                  settingKey: 'key-shortcut-open-new-search',
                  title: 'חלון חיפוש חדש',
                  leading: Icon(Icons.search),
                  values: shortcuctsList,
                ),
              ]),
          SettingsGroup(
              title: 'כללי',
              titleTextStyle: const TextStyle(fontSize: 25),
              children: [
                TextInputSettingsTile(
                  settingKey: 'key-library-path',
                  title: 'מיקום הספריה',
                  leading: IconButton(
                    icon: const Icon(Icons.folder),
                    onPressed: () async {
                      String? path =
                          await FilePicker.platform.getDirectoryPath();
                      if (path != null) {
                        Settings.setValue<String>('key-library-path', path);
                      }
                    },
                  ),
                ),
              ])
        ],
      ),
    ));
  }
}
