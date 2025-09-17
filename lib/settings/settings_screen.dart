import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:math' as math;
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
import 'dart:async';

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

  Widget _buildColumns(int maxColumns, List<Widget> children) {
    const double rowSpacing = 16.0;
    const double columnSpacing = 16.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int columns = (width / 300).floor();
        columns = math.min(math.max(columns, 1), maxColumns);

        if (columns <= 1) {
          return Column(children: children);
        }

        List<Widget> rows = [];
        for (int i = 0; i < children.length; i += columns) {
          List<Widget> rowChildren = [];

          for (int j = 0; j < columns; j++) {
            if (i + j < children.length) {
              rowChildren.add(Expanded(child: children[i + j]));

              if (j < columns - 1 && i + j + 1 < children.length) {
                rowChildren.add(const VerticalDivider(
                  width: columnSpacing,
                  thickness: 1,
                ));
              }
            }
          }

          // עוטפים את ה-Row ב-IntrinsicHeight כדי להבטיח גובה אחיד לקו המפריד
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch, // גורם לילדים להימתח
                children: rowChildren,
              ),
            ),
          );
        }

        return Wrap(
          runSpacing: rowSpacing,
          children: rows,
        );
      },
    );
  }

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
                    _buildColumns(2, [
                      SwitchSettingsTile(
                        settingKey: 'key-dark-mode',
                        title: 'מצב כהה',
                        enabledLabel: 'מופעל',
                        disabledLabel: 'לא מופעל',
                        leading: const Icon(Icons.nightlight_round_outlined),
                        onChange: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdateDarkMode(value));
                        },
                        activeColor: Theme.of(context).cardColor,
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
                    ]),
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
                    SettingsContainer(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 8, bottom: 4, left: 16, right: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.horizontal_distribute),
                              const SizedBox(width: 16),
                              Text(
                                'רוחב השוליים בצידי הטקסט',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: MarginSliderPreview(
                            initial: Settings.getValue<double>(
                                'key-padding-size',
                                defaultValue: state.paddingSize)!,
                            min: 0,
                            max: 500,
                            step: 2,
                            onChanged: (v) {
                              // הלוגיקה לשמירת הערך נשארת זהה ומדויקת
                              Settings.setValue<double>('key-padding-size', v);
                              context
                                  .read<SettingsBloc>()
                                  .add(UpdatePaddingSize(v));
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Platform.isAndroid
                    ? const SizedBox.shrink()
                    : SettingsGroup(
                        titleAlignment: Alignment.centerRight,
                        title: "קיצורי מקשים",
                        titleTextStyle: const TextStyle(fontSize: 25),
                        children: [
                          _buildColumns(3, [
                            DropDownSettingsTile<String>(
                              selected: 'ctrl+l',
                              settingKey: 'key-shortcut-open-library-browser',
                              title: 'ספרייה',
                              values: shortcuctsList,
                              leading: const Icon(Icons.library_books),
                            ),
                            DropDownSettingsTile<String>(
                              selected: 'ctrl+o',
                              settingKey: 'key-shortcut-open-find-ref',
                              title: 'איתור',
                              values: shortcuctsList,
                              leading: const Icon(Icons.auto_stories_rounded),
                            ),
                            DropDownSettingsTile<String>(
                              selected: 'ctrl+r',
                              settingKey: 'key-shortcut-open-reading-screen',
                              title: 'עיון',
                              leading: const Icon(Icons.menu_book_rounded),
                              values: shortcuctsList,
                            ),
                            DropDownSettingsTile<String>(
                              selected: 'ctrl+q',
                              settingKey: 'key-shortcut-open-new-search',
                              title: 'חלון חיפוש חדש',
                              leading: const Icon(Icons.search),
                              values: shortcuctsList,
                            ),
                            DropDownSettingsTile<String>(
                              selected: 'ctrl+w',
                              settingKey: 'key-shortcut-close-tab',
                              title: 'סגור ספר נוכחי',
                              leading: const Icon(Icons.cancel),
                              values: shortcuctsList,
                            ),
                            DropDownSettingsTile<String>(
                              selected: 'ctrl+x',
                              settingKey: 'key-shortcut-close-all-tabs',
                              title: 'סגור כל הספרים',
                              leading: const Icon(Icons.close),
                              values: shortcuctsList,
                            ),
                          ]),
                        ],
                      ),
                SettingsGroup(
                  title: 'הגדרות ממשק',
                  titleAlignment: Alignment.centerRight,
                  titleTextStyle: const TextStyle(fontSize: 25),
                  children: [
                    _buildColumns(2, [
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
                        activeColor: Theme.of(context).cardColor,
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
                        activeColor: Theme.of(context).cardColor,
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
                        activeColor: Theme.of(context).cardColor,
                      ),
                      SwitchSettingsTile(
                        settingKey: 'key-remove-nikud-tanach',
                        title: 'הסרת ניקוד מספרי התנ"ך',
                        enabledLabel: 'גם ספרי התנ"ך יוצגו ללא ניקוד',
                        disabledLabel: 'בספרי התנ"ך יוצג ניקוד',
                        leading: const Icon(Icons.book),
                        defaultValue: state.removeNikudFromTanach,
                        onChange: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdateRemoveNikudFromTanach(value));
                        },
                        activeColor: Theme.of(context).cardColor,
                      ),
                      SwitchSettingsTile(
                        settingKey: 'key-splited-view',
                        title: 'ברירת המחדל להצגת המפרשים',
                        enabledLabel: 'המפרשים יוצגו לצד הטקסט',
                        disabledLabel: 'המפרשים יוצגו מתחת הטקסט',
                        leading: const Icon(Icons.vertical_split),
                        defaultValue: false,
                        activeColor: Theme.of(context).cardColor,
                      ),
                      SwitchSettingsTile(
                        settingKey: 'key-default-sidebar-open',
                        title: 'פתיחת סרגל צד כברירת מחדל',
                        enabledLabel: 'סרגל הצד יפתח אוטומטית',
                        disabledLabel: 'סרגל הצד ישאר סגור',
                        leading: const Icon(Icons.menu_open),
                        defaultValue: state.defaultSidebarOpen,
                        enabled: !state.pinSidebar,
                        onChange: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdateDefaultSidebarOpen(value));
                        },
                        activeColor: Theme.of(context).cardColor,
                      ),
                      SwitchSettingsTile(
                        settingKey: 'key-pin-sidebar',
                        title: 'הצמדת סרגל צד',
                        enabledLabel: 'סרגל הצד יוצמד תמיד',
                        disabledLabel: 'סרגל הצד יפעל כרגיל',
                        leading: const Icon(Icons.push_pin),
                        defaultValue: state.pinSidebar,
                        onChange: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdatePinSidebar(value));
                          if (value) {
                            context
                                .read<SettingsBloc>()
                                .add(const UpdateDefaultSidebarOpen(true));
                          }
                        },
                        activeColor: Theme.of(context).cardColor,
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
                        activeColor: Theme.of(context).cardColor,
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
                        activeColor: Theme.of(context).cardColor,
                      ),
                    ]),
                  ],
                ),
                SettingsGroup(
                  title: 'הגדרות העתקה',
                  titleAlignment: Alignment.centerRight,
                  titleTextStyle: const TextStyle(fontSize: 25),
                  children: [
                    _buildColumns(2, [
                      DropDownSettingsTile<String>(
                        title: 'העתקה עם כותרות',
                        settingKey: 'key-copy-with-headers',
                        values: const <String, String>{
                          'none': 'ללא',
                          'book_name': 'העתקה עם שם הספר בלבד',
                          'book_and_path': 'העתקה עם שם הספר+הנתיב',
                        },
                        selected: state.copyWithHeaders,
                        leading: const Icon(Icons.content_copy),
                        onChange: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdateCopyWithHeaders(value));
                        },
                      ),
                      DropDownSettingsTile<String>(
                        title: 'עיצוב ההעתקה',
                        settingKey: 'key-copy-header-format',
                        values: const <String, String>{
                          'same_line_after_brackets':
                              'באותה שורה אחרי הכיתוב (עם סוגריים)',
                          'same_line_after_no_brackets':
                              'באותה שורה אחרי הכיתוב (בלי סוגריים)',
                          'same_line_before_brackets':
                              'באותה שורה לפני הכיתוב (עם סוגריים)',
                          'same_line_before_no_brackets':
                              'באותה שורה לפני הכיתוב (בלי סוגריים)',
                          'separate_line_after': 'בפסקה בפני עצמה אחרי הכיתוב',
                          'separate_line_before': 'בפסקה בפני עצמה לפני הכיתוב',
                        },
                        selected: state.copyHeaderFormat,
                        leading: const Icon(Icons.format_align_right),
                        onChange: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdateCopyHeaderFormat(value));
                        },
                      ),
                    ]),
                  ],
                ),
                SettingsGroup(
                  title: 'כללי',
                  titleAlignment: Alignment.centerRight,
                  titleTextStyle: const TextStyle(fontSize: 25),
                  children: [
                    SwitchSettingsTile(
                      title: 'סינכרון הספרייה באופן אוטומטי',
                      leading: Icon(Icons.sync),
                      settingKey: 'key-auto-sync',
                      defaultValue: true,
                      enabledLabel:
                          'מאגר הספרים המובנה יתעדכן אוטומטית מאתר אוצריא',
                      disabledLabel: 'מאגר הספרים לא יתעדכן אוטומטית.',
                      activeColor: Theme.of(context).cardColor,
                    ),
                    _buildColumns(2, [
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
                                          content: const Text(
                                              'האם לאפס את האינדקס?'),
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
                                  context
                                      .read<IndexingBloc>()
                                      .add(ClearIndex());
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
                        activeColor: Theme.of(context).cardColor,
                      ),
                    ]),
                    if (!(Platform.isAndroid || Platform.isIOS))
                      _buildColumns(2, [
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
                        Tooltip(
                          message: 'במידה וקיימים ברשותכם ספרים ממאגר זה',
                          child: SimpleSettingsTile(
                            title: 'מיקום ספרי HebrewBooks (היברובוקס)',
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
                        ),
                      ]),
                    SwitchSettingsTile(
                      settingKey: 'key-dev-channel',
                      title: 'עדכון לגרסאות מפתחים',
                      enabledLabel:
                          'קבלת עדכונים על גרסאות בדיקה, ייתכנו באגים וחוסר יציבות',
                      disabledLabel: 'קבלת עדכונים על גרסאות יציבות בלבד',
                      leading: const Icon(Icons.bug_report),
                      activeColor: Theme.of(context).cardColor,
                    ),
                    SimpleSettingsTile(
                      title: 'איפוס הגדרות',
                      subtitle:
                          'פעולה זו תמחק את כל ההגדרות ותחזיר את התוכנה למצב התחלתי',
                      leading: const Icon(Icons.restore, color: Colors.red),
                      onTap: () async {
                        // דיאלוג לאישור המשתמש
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('איפוס הגדרות?'),
                            content: const Text(
                                'כל ההגדרות האישיות שלך ימחקו. פעולה זו אינה הפיכה. האם להמשיך?'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('ביטול')),
                              TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('אישור',
                                      style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );

                        if (confirmed == true && context.mounted) {
                          Settings.clearCache();

                          // הודעה למשתמש שנדרשת הפעלה מחדש
                          await showDialog<void>(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => AlertDialog(
                                      title: const Text('ההגדרות אופסו'),
                                      content: const Text(
                                          'יש לסגור ולהפעיל מחדש את התוכנה כדי שהשינויים יכנסו לתוקף.'),
                                      actions: [
                                        TextButton(
                                            onPressed: () => exit(0),
                                            child: const Text('סגור את התוכנה'))
                                      ]));
                        }
                      },
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

/// Slider סימטרי עם תצוגה חיה לרוחב השוליים
class MarginSliderPreview extends StatefulWidget {
  final double initial;
  final double min;
  final double max;
  final int step;
  final ValueChanged<double> onChanged;

  const MarginSliderPreview({
    super.key,
    required this.initial,
    this.min = 0,
    this.max = 500,
    this.step = 2,
    required this.onChanged,
  });

  @override
  State<MarginSliderPreview> createState() => _MarginSliderPreviewState();
}

class _MarginSliderPreviewState extends State<MarginSliderPreview> {
  late double _margin;
  bool _showPreview = false;
  Timer? _disappearTimer;

  // משתנים לעיצוב כדי שיהיה קל לשנות
  final double thumbSize = 20.0; // גודל הידית
  final double trackHeight = 4.0; // גובה הפס
  final double widgetHeight = 50.0; // גובה כל הווידג'ט

  @override
  void initState() {
    super.initState();
    _margin = widget.initial.clamp(widget.min, widget.max / 2);
  }

  @override
  void dispose() {
    _disappearTimer?.cancel();
    super.dispose();
  }

  void _handleDragStart() {
    _disappearTimer?.cancel();
    setState(() => _showPreview = true);
  }

  void _handleDragEnd() {
    _disappearTimer?.cancel();
    _disappearTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showPreview = false);
    });
  }

  // פונקציה לבניית הידית כדי למנוע כפילות קוד
  Widget _buildThumb({required bool isLeft}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            double newMargin = isLeft
                ? _margin + details.delta.dx
                : _margin - details.delta.dx;

            // מגבילים את המרחב לפי רוחב הווידג'ט והגדרות המשתמש
            final maxWidth =
                (context.findRenderObject() as RenderBox).size.width;
            _margin = newMargin
                .clamp(widget.min, maxWidth / 2)
                .clamp(widget.min, widget.max);
          });
          widget.onChanged(_margin);
        },
        onPanStart: (_) => _handleDragStart(),
        onPanEnd: (_) => _handleDragEnd(),
        child: Container(
          width: thumbSize * 2, // אזור לחיצה גדול יותר מהנראות
          height: thumbSize * 2,
          color: Colors.transparent, // אזור הלחיצה שקוף
          alignment: Alignment.center,
          child: Container(
            // --- שינוי 1: עיצוב הידית מחדש ---
            width: thumbSize,
            height: thumbSize,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary, // צבע ראשי
              shape: BoxShape.circle,
              boxShadow: kElevationToShadow[1], // הצללה סטנדרטית של פלאטר
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth;
        final previewTextWidth =
            (fullWidth - 2 * _margin).clamp(0.0, fullWidth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ------------  הסליידר המתוקן  -------------
            SizedBox(
              height: widgetHeight,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTapDown: (details) {
                    // חישוב המיקום החדש לפי הלחיצה
                    final RenderBox renderBox =
                        context.findRenderObject() as RenderBox;
                    final localPosition =
                        renderBox.globalToLocal(details.globalPosition);
                    final tapX = localPosition.dx;

                    // חישוב השוליים החדשים - לוגיקה נכונה
                    double newMargin;

                    // אם לחצנו במרכז - השוליים יהיו מקסימליים
                    // אם לחצנו בקצוות - השוליים יהיו מינימליים
                    double distanceFromCenter = (tapX - fullWidth / 2).abs();
                    newMargin = (fullWidth / 2) - distanceFromCenter;

                    // הגבלת הערכים
                    newMargin = newMargin
                        .clamp(widget.min, widget.max)
                        .clamp(widget.min, fullWidth / 2);

                    setState(() {
                      _margin = newMargin;
                    });

                    widget.onChanged(_margin);
                    _handleDragStart();
                    _handleDragEnd();
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // אזור לחיצה מורחב - שקוף וגדול יותר מהפס
                      Container(
                        height: thumbSize * 2, // גובה כמו הידיות
                        color: Colors.transparent,
                      ),

                      // קו הרקע
                      Container(
                        height: trackHeight,
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(trackHeight / 2),
                        ),
                      ),

                      // הקו הפעיל (מייצג את רוחב הטקסט)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: _margin),
                        child: Container(
                          height: trackHeight,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius:
                                BorderRadius.circular(trackHeight / 2),
                          ),
                        ),
                      ),

                      // הצגת הערך מעל הידית (רק בזמן תצוגה)
                      if (_showPreview)
                        Positioned(
                          left: _margin - 10,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _margin.toStringAsFixed(0),
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 12),
                            ),
                          ),
                        ),

                      if (_showPreview)
                        Positioned(
                          right: _margin - 10,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _margin.toStringAsFixed(0),
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 12),
                            ),
                          ),
                        ),

                      // הכפתור השמאלי
                      Positioned(
                        left: _margin - (thumbSize),
                        child: _buildThumb(isLeft: true),
                      ),

                      // הכפתור הימני
                      Positioned(
                        right: _margin - (thumbSize),
                        child: _buildThumb(isLeft: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ------------  תצוגה מקדימה עם אנימציה חלקה  -------------
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showPreview ? 1.0 : 0.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _showPreview ? 60 : 0,
                // ... שאר הקוד של התצוגה המקדימה נשאר אותו דבר ...
                curve: Curves.easeInOut,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withOpacity(0.5),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: _margin),
                child: SizedBox(
                  width: previewTextWidth,
                  child: Text(
                    'מאימתי קורין את שמע בערבין משעה שהכהנים נכנסים לאכול בתרומתן עד סוף האשמורה הראשונה דברי רבי אליעזר וחכמים אומרים עד חצות רבן גמליאל אומר עד שיעלה עמוד השחר מעשה ובאו בניו מבית המשתה אמרו לו לא קרינו את שמע אמר להם אם לא עלה עמוד השחר חייבין אתם לקרות ולא זו בלבד אמרו אלא כל מה שאמרו חכמים עד חצות מצותן עד שיעלה עמוד השחר',
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
