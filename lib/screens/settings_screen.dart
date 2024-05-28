import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:otzaria/models/app_model.dart';
import 'package:provider/provider.dart';

class MySettingsScreen extends StatefulWidget {
  const MySettingsScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<MySettingsScreen> createState() => _MySettingsScreenState();
}

class _MySettingsScreenState extends State<MySettingsScreen> {
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
      body: Consumer<AppModel>(
        builder: (context, appModel, child) {
          return Center(
            child: SettingsScreen(
              title: 'הגדרות',
              children: [
                SettingsGroup(
                  titleAlignment: Alignment.centerRight,
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
                        appModel.isDarkMode.value = value;
                      },
                    ),
                    ColorPickerSettingsTile(
                        title: 'צבע בסיס',
                        leading: const Icon(Icons.color_lens),
                        settingKey: 'key-swatch-color',
                        onChange: (p0) {
                          appModel.seedColor.value = p0;
                        }),
                    const SliderSettingsTile(
                      title: 'גודל גופן התחלתי בספרים',
                      settingKey: 'key-font-size',
                      defaultValue: 30,
                      min: 15,
                      max: 60,
                      step: 1,
                      leading: Icon(Icons.format_size),
                      decimalPrecision: 0,
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
                    SliderSettingsTile(
                      title: 'רוחב השוליים בצידי הטקסט',
                      settingKey: 'key-padding-size',
                      defaultValue: 10,
                      min: 0,
                      max: 500,
                      step: 2,
                      leading: Icon(Icons.horizontal_distribute),
                      decimalPrecision: 0,
                      onChange: (p0) => appModel.paddingSize.value = p0,
                    ),
                  ],
                ),
                Platform.isAndroid
                    ? const SizedBox.shrink()
                    : const SettingsGroup(
                        titleAlignment: Alignment.centerRight,
                        title: "קיצורי מקשים",
                        titleTextStyle: TextStyle(fontSize: 25),
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
                const SettingsGroup(
                    title: 'הגדרות ממשק',
                    titleAlignment: Alignment.centerRight,
                    titleTextStyle: TextStyle(fontSize: 25),
                    children: [
                      //       Platform.isAndroid
                      //           ? const SizedBox.shrink()
                      //           : const SwitchSettingsTile(
                      //               settingKey: 'key-close-left-pane-on-scroll',
                      //               title: 'סגירת תפריט הצד בעת גלילה',
                      //               enabledLabel:
                      //                   'עם תחילת הגלילה, ייסגר תפריט הצד אוטומטית',
                      //               disabledLabel: 'תפריט הצד לא ייסגר אוטומטית',
                      //               leading: Icon(Icons.arrow_back),
                      //             ),
                      SwitchSettingsTile(
                        settingKey: 'key-splited-view',
                        title: 'ברירת המחדל להצגת המפרשים',
                        enabledLabel: 'המפרשים יוצגו לצד הטקסט',
                        disabledLabel: 'המפרשים יוצגו מתחת הטקסט',
                        leading: Icon(Icons.vertical_split),
                        defaultValue: false,
                      ),
                    ]),
                SettingsGroup(
                  title: 'כללי',
                  titleAlignment: Alignment.centerRight,
                  titleTextStyle: const TextStyle(fontSize: 25),
                  children: [
                    SimpleSettingsTile(
                      title: 'מיקום הספרייה',
                      subtitle:
                          '${Settings.getValue<String>('key-library-path') ?? 'לא קיים'}',
                      leading: Icon(Icons.folder),
                      onTap: () async {
                        String? path =
                            await FilePicker.platform.getDirectoryPath();
                        if (path != null) {
                          Settings.setValue<String>('key-library-path', path);
                          setState(
                            () {},
                          );
                        }
                      },
                    ),
                    const SwitchSettingsTile(
                      settingKey: 'key-dev-channel',
                      title: 'עדכון לגרסאות מפתחים',
                      enabledLabel:
                          'קבלת עדכונים על גרסאות בדיקה, ייתכנו באגים וחוסר יציבות',
                      disabledLabel: 'קבלת עדכונים על גרסאות יציבות בלבד',
                      leading: Icon(Icons.bug_report),
                    )
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
