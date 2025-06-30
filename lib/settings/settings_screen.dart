import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/indexing/bloc/indexing_bloc.dart';
import 'package:otzaria/indexing/bloc/indexing_event.dart';
import 'package:otzaria/indexing/bloc/indexing_state.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_event.dart';
import 'package:otzaria/settings/settings_state.dart';
import 'package:otzaria/library/bloc/library_bloc.dart';
import 'package:otzaria/library/bloc/library_event.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MySettingsScreen extends StatefulWidget {
  const MySettingsScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<MySettingsScreen> createState() => _MySettingsScreenState();
}

class _MySettingsScreenState extends State<MySettingsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
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
                        context.read<SettingsBloc>().add(UpdateDarkMode(value));
                      },
                    ),
                    ColorPickerSettingsTile(
                      title: 'צבע בסיס',
                      leading: const Icon(Icons.color_lens),
                      settingKey: 'key-swatch-color',
                      onChange: (color) {
                        context
                            .read<SettingsBloc>()
                            .add(UpdateSeedColor(color));
                      },
                    ),
                    SliderSettingsTile(
                      title: 'גודל גופן התחלתי בספרים',
                      settingKey: 'key-font-size',
                      defaultValue: state.fontSize,
                      min: 15,
                      max: 60,
                      step: 1,
                      leading: const Icon(Icons.format_size),
                      decimalPrecision: 0,
                      onChange: (value) {
                        context.read<SettingsBloc>().add(UpdateFontSize(value));
                      },
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
                      selected: state.fontFamily,
                      leading: const Icon(Icons.font_download_outlined),
                      onChange: (value) {
                        context
                            .read<SettingsBloc>()
                            .add(UpdateFontFamily(value));
                      },
                    ),
                    SliderSettingsTile(
                      title: 'רוחב השוליים בצידי הטקסט',
                      settingKey: 'key-padding-size',
                      defaultValue: state.paddingSize,
                      min: 0,
                      max: 500,
                      step: 2,
                      leading: const Icon(Icons.horizontal_distribute),
                      decimalPrecision: 0,
                      onChange: (value) {
                        context
                            .read<SettingsBloc>()
                            .add(UpdatePaddingSize(value));
                      },
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
                              selected: 'ctrl+l',
                              settingKey: 'key-shortcut-open-library-browser',
                              title: 'ספרייה',
                              values: shortcuctsList,
                              leading: Icon(Icons.library_books),
                            ),
                            DropDownSettingsTile<String>(
                              selected: 'ctrl+o',
                              settingKey: 'key-shortcut-open-find-ref',
                              title: 'איתור',
                              values: shortcuctsList,
                              leading: Icon(Icons.auto_stories_rounded),
                            ),
                            DropDownSettingsTile<String>(
                              selected: 'ctrl+r',
                              settingKey: 'key-shortcut-open-reading-screen',
                              title: 'עיון',
                              leading: Icon(Icons.menu_book_rounded),
                              values: shortcuctsList,
                            ),
                            DropDownSettingsTile<String>(
                              selected: 'ctrl+q',
                              settingKey: 'key-shortcut-open-new-search',
                              title: 'חלון חיפוש חדש',
                              leading: Icon(Icons.search),
                              values: shortcuctsList,
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
                          ]),
                SettingsGroup(
                    title: 'הגדרות ממשק',
                    titleAlignment: Alignment.centerRight,
                    titleTextStyle: const TextStyle(fontSize: 25),
                    children: [
                      SwitchSettingsTile(
                        settingKey: 'key-replace-holy-names',
                        title: 'הסתרת שמות הקודש',
                        enabledLabel: 'השמות הקדושים יוחלפו מפאת קדושתם',
                        disabledLabel: 'השמות הקדושים יוצגו ככתיבתם',
                        leading: const Icon(Icons.password),
                        defaultValue: state.replaceHolyNames,
                        onChange: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdateReplaceHolyNames(value));
                        },
                      ),
                      SwitchSettingsTile(
                        settingKey: 'key-show-teamim',
                        title: 'הצגת טעמי המקרא',
                        enabledLabel: 'המקרא יוצג עם טעמים',
                        disabledLabel: 'המקרא יוצג ללא טעמים',
                        leading: const Icon(Icons.format_overline),
                        defaultValue: state.showTeamim,
                        onChange: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdateShowTeamim(value));
                        },
                      ),
                      SwitchSettingsTile(
                        settingKey: 'key-default-nikud',
                        title: 'הסרת ניקוד כברירת מחדל',
                        enabledLabel: 'הניקוד יוסר כברירת מחדל',
                        disabledLabel: 'הניקוד יוצג כברירת מחדל',
                        leading: const Icon(Icons.text_fields),
                        defaultValue: state.defaultRemoveNikud,
                        onChange: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdateDefaultRemoveNikud(value));
                        },
                      ),                      
                      const SwitchSettingsTile(
                        settingKey: 'key-splited-view',
                        title: 'ברירת המחדל להצגת המפרשים',
                        enabledLabel: 'המפרשים יוצגו לצד הטקסט',
                        disabledLabel: 'המפרשים יוצגו מתחת הטקסט',
                        leading: Icon(Icons.vertical_split),
                        defaultValue: false,
                      ),
                      SwitchSettingsTile(
                        settingKey: 'key-default-sidebar-open',
                        title: 'פתיחת סרגל צד כברירת מחדל',
                        enabledLabel: 'סרגל הצד יפתח אוטומטית',
                        disabledLabel: 'סרגל הצד ישאר סגור',
                        leading: const Icon(Icons.menu_open),
                        defaultValue: state.defaultSidebarOpen,
                        onChange: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdateDefaultSidebarOpen(value));
                        },
                      ),
                      SwitchSettingsTile(
                        settingKey: 'key-use-fast-search',
                        title: 'חיפוש מהיר באמצעות אינדקס',
                        enabledLabel:
                            'החיפוש יהיה מהיר יותר, נדרש ליצור אינדקס',
                        disabledLabel: 'החיפוש יהיה איטי יותר, לא נדרש אינדקס',
                        leading: const Icon(Icons.search),
                        defaultValue: state.useFastSearch,
                        onChange: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdateUseFastSearch(value));
                        },
                      ),
                      SwitchSettingsTile(
                        settingKey: 'key-show-external-books',
                        title: 'איתור ספרים באתרים חיצוניים',
                        enabledLabel: 'יוצגו גם ספרים מאתרים חיצוניים',
                        disabledLabel: 'יוצגו רק ספרים מספריית אוצריא',
                        leading: const Icon(Icons.open_in_new),
                        defaultValue: state.showExternalBooks,
                        onChange: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdateShowExternalBooks(value));
                          context
                              .read<SettingsBloc>()
                              .add(UpdateShowHebrewBooks(value));
                          context
                              .read<SettingsBloc>()
                              .add(UpdateShowOtzarHachochma(value));
                        },
                      ),
                    ]),
                SettingsGroup(
                  title: 'כללי',
                  titleAlignment: Alignment.centerRight,
                  titleTextStyle: const TextStyle(fontSize: 25),
                  children: [
                    const SwitchSettingsTile(
                      title: 'סינכרון אוטומטי',
                      leading: Icon(Icons.sync),
                      settingKey: 'key-auto-sync',
                      defaultValue: true,
                      enabledLabel: 'מאגר הספרים יתעדכן אוטומטית',
                      disabledLabel: 'מאגר הספרים לא יתעדכן אוטומטית.',
                    ),
                    BlocBuilder<IndexingBloc, IndexingState>(
                      builder: (context, indexingState) {
                        return SimpleSettingsTile(
                          title: "אינדקס חיפוש",
                          subtitle: indexingState is IndexingInProgress
                              ? "בתהליך עדכון:${indexingState.booksProcessed}/${indexingState.totalBooks}"
                              : "האינדקס מעודכן",
                          leading: const Icon(Icons.table_chart),
                          onTap: () async {
                            if (indexingState is IndexingInProgress) {
                              final result = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                        content: const Text(
                                            'האם לעצור את תהליך יצירת האינדקס?'),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text('ביטול'),
                                            onPressed: () {
                                              Navigator.pop(context, false);
                                            },
                                          ),
                                          TextButton(
                                            child: const Text('אישור'),
                                            onPressed: () {
                                              Navigator.pop(context, true);
                                            },
                                          ),
                                        ],
                                      ));
                              if (result == true) {
                                context
                                    .read<IndexingBloc>()
                                    .add(CancelIndexing());
                                setState(() {});
                              }
                            } else {
                              final result = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                        content:
                                            const Text('האם לאפס את האינדקס?'),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text('ביטול'),
                                            onPressed: () {
                                              Navigator.pop(context, false);
                                            },
                                          ),
                                          TextButton(
                                            child: const Text('אישור'),
                                            onPressed: () {
                                              Navigator.pop(context, true);
                                            },
                                          ),
                                        ],
                                      ));
                              if (result == true) {
                                //reset the index
                                context.read<IndexingBloc>().add(ClearIndex());
                                final library =
                                    context.read<LibraryBloc>().state.library;
                                if (library != null) {
                                  context
                                      .read<IndexingBloc>()
                                      .add(StartIndexing(library));
                                }
                              }
                            }
                          },
                        );
                      },
                    ),
                    SwitchSettingsTile(
                      title: 'עדכון אינדקס',
                      leading: const Icon(Icons.sync),
                      settingKey: 'key-auto-index-update',
                      defaultValue: state.autoUpdateIndex,
                      enabledLabel: 'אינדקס החיפוש יתעדכן אוטומטית',
                      disabledLabel: 'אינדקס החיפוש לא יתעדכן אוטומטית',
                      onChange: (value) async {
                        context
                            .read<SettingsBloc>()
                            .add(UpdateAutoUpdateIndex(value));
                        if (value) {
                          final library = DataRepository.instance.library;
                          context
                              .read<IndexingBloc>()
                              .add(StartIndexing(await library));
                        }
                      },
                    ),
                    if (!(Platform.isAndroid || Platform.isIOS)) ...[
                      SimpleSettingsTile(
                        title: 'מיקום הספרייה',
                        subtitle:
                            Settings.getValue<String>('key-library-path') ??
                                'לא קיים',
                        leading: const Icon(Icons.folder),
                        onTap: () async {
                          String? path =
                              await FilePicker.platform.getDirectoryPath();
                          if (path != null) {
                            context
                                .read<LibraryBloc>()
                                .add(UpdateLibraryPath(path));
                          }
                        },
                      ),
                      SimpleSettingsTile(
                        title: 'מיקום ספרי HebrewBooks',
                        subtitle: Settings.getValue<String>(
                                'key-hebrew-books-path') ??
                            'לא קיים',
                        leading: const Icon(Icons.folder),
                        onTap: () async {
                          String? path =
                              await FilePicker.platform.getDirectoryPath();
                          if (path != null) {
                            context
                                .read<LibraryBloc>()
                                .add(UpdateHebrewBooksPath(path));
                          }
                        },
                      ),
                    ],
                    const SwitchSettingsTile(
                      settingKey: 'key-dev-channel',
                      title: 'עדכון לגרסאות מפתחים',
                      enabledLabel:
                          'קבלת עדכונים על גרסאות בדיקה, ייתכנו באגים וחוסר יציבות',
                      disabledLabel: 'קבלת עדכונים על גרסאות יציבות בלבד',
                      leading: Icon(Icons.bug_report),
                    ),
                    FutureBuilder(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SimpleSettingsTile(
                              title: 'גרסה נוכחית',
                              subtitle: 'המתן..',
                              leading: Icon(Icons.info_rounded),
                            );
                          }
                          return Align(
                            alignment: Alignment.centerRight,
                            child: SimpleSettingsTile(
                              title: 'גרסה נוכחית',
                              subtitle: snapshot.data!.version,
                              leading: const Icon(Icons.info_rounded),
                            ),
                          );
                        }),
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
