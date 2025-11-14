import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:file_picker/file_picker.dart';
import 'package:window_manager/window_manager.dart';
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
import 'package:otzaria/settings/reading_settings_dialog.dart';
import 'package:otzaria/settings/library_settings_dialog.dart';
import 'package:otzaria/settings/calendar_settings_dialog.dart';
import 'package:otzaria/settings/gematria_settings_dialog.dart';
import 'package:otzaria/settings/backup_service.dart';
import 'package:otzaria/widgets/shortcut_dropdown_tile.dart';
import 'package:otzaria/widgets/confirmation_dialog.dart';
import 'dart:async';
import 'package:otzaria/i18n/translations.g.dart';

class MySettingsScreen extends StatefulWidget {
  const MySettingsScreen({
    super.key,
  });

  @override
  State<MySettingsScreen> createState() => _MySettingsScreenState();
}

class _MySettingsScreenState extends State<MySettingsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Widget _buildSettingsCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 160,
      height: 140,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 36,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



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
      'ctrl+comma': "CTRL + ,",
      'ctrl+shift+b': "CTRL + SHIFT + B",
      'ctrl+shift+w': "CTRL + SHIFT + W",
    };

    return Scaffold(
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return Theme(
            data: Theme.of(context).copyWith(
              appBarTheme: AppBarTheme(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15),
                centerTitle: true,
                titleTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            child: Center(
              child: SettingsScreen(
                title: 'הגדרות',
                children: [
                  SettingsGroup(
                    titleAlignment: Alignment.centerRight,
                    title: context.t.settings.appearance,
                    titleTextStyle: const TextStyle(fontSize: 25),
                    children: <Widget>[
                      _buildColumns(3, [
                        if (!(Platform.isAndroid || Platform.isIOS))
                          BlocBuilder<SettingsBloc, SettingsState>(
                            builder: (context, settingsState) {
                              return SimpleSettingsTile(
                                title: context.t.settings.fullscreen,
                                subtitle: context.t.settings.toggleFullscreen,
                                leading: Icon(settingsState.isFullscreen
                                    ? FluentIcons
                                        .full_screen_minimize_24_regular
                                    : FluentIcons
                                        .full_screen_maximize_24_regular),
                                onTap: () async {
                                  final newFullscreenState =
                                      !settingsState.isFullscreen;
                                  context.read<SettingsBloc>().add(
                                      UpdateIsFullscreen(newFullscreenState));
                                  await windowManager
                                      .setFullScreen(newFullscreenState);
                                },
                              );
                            },
                          ),
                        SwitchSettingsTile(
                          settingKey: 'key-dark-mode',
                          title: context.t.settings.darkMode,
                          enabledLabel: context.t.settings.enabled,
                          disabledLabel: context.t.settings.disabled,
                          leading:
                              const Icon(FluentIcons.weather_moon_24_regular),
                          onChange: (value) {
                            context
                                .read<SettingsBloc>()
                                .add(UpdateDarkMode(value));
                          },
                          activeColor: Theme.of(context).cardColor,
                        ),
                        ColorPickerSettingsTile(
                          title: context.t.settings.baseColor,
                          leading: const Icon(FluentIcons.color_24_regular),
                          settingKey: 'key-swatch-color',
                          onChange: (color) {
                            context
                                .read<SettingsBloc>()
                                .add(UpdateSeedColor(color));
                          },
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Platform.isAndroid
                      ? const SizedBox.shrink()
                      : SettingsGroup(
                          titleAlignment: Alignment.centerRight,
                          title: context.t.settings.shortcuts,
                          titleTextStyle: const TextStyle(fontSize: 25),
                          children: [
                            SimpleSettingsTile(
                              title: context.t.settings.resetShortcuts,
                              subtitle: context.t.settings.resetShortcutsSubtitle,
                              leading: const Icon(
                                  FluentIcons.arrow_reset_24_regular),
                              onTap: () async {
                                final confirmed = await showConfirmationDialog(
                                  context: context,
                                  title: context.t.settings.resetShortcutsTitle,
                                  content: context.t.settings.resetShortcutsContent,
                                  isDangerous: true,
                                  barrierDismissible: false,
                                );

                                if (confirmed == true && context.mounted) {
                                  context
                                      .read<SettingsBloc>()
                                      .add(ResetShortcuts());

                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                      content: Text(
                                        context.t.settings.shortcutsReset,
                                        textDirection: TextDirection.rtl,
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: EdgeInsets.only(bottom: 8.0, right: 8.0),
                              child: Text(
                                context.t.settings.generalNavigation,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            _buildColumns(3, [
                              ShortcutDropDownTile(
                                selected: 'ctrl+l',
                                settingKey: 'key-shortcut-open-library-browser',
                                title: context.t.navigation.library,
                                allShortcuts: shortcuctsList,
                                leading:
                                    const Icon(FluentIcons.library_24_regular),
                              ),
                              ShortcutDropDownTile(
                                selected: 'ctrl+o',
                                settingKey: 'key-shortcut-open-find-ref',
                                title: context.t.navigation.find,
                                allShortcuts: shortcuctsList,
                                leading: const Icon(
                                    FluentIcons.book_open_24_regular),
                              ),
                              ShortcutDropDownTile(
                                selected: 'ctrl+r',
                                settingKey: 'key-shortcut-open-reading-screen',
                                title: context.t.navigation.reading,
                                leading:
                                    const Icon(FluentIcons.book_24_regular),
                                allShortcuts: shortcuctsList,
                              ),
                              ShortcutDropDownTile(
                                selected: 'ctrl+q',
                                settingKey: 'key-shortcut-open-new-search',
                                title: context.t.settings.newSearchWindow,
                                leading:
                                    const Icon(FluentIcons.search_24_regular),
                                allShortcuts: shortcuctsList,
                              ),
                              ShortcutDropDownTile(
                                settingKey: 'key-shortcut-open-settings',
                                title: context.t.navigation.settings,
                                allShortcuts: shortcuctsList,
                                selected: 'ctrl+comma',
                                leading:
                                    const Icon(FluentIcons.settings_24_regular),
                              ),
                              ShortcutDropDownTile(
                                settingKey: 'key-shortcut-open-more',
                                title: context.t.navigation.tools,
                                allShortcuts: shortcuctsList,
                                selected: 'ctrl+m',
                                leading:
                                    const Icon(FluentIcons.apps_24_regular),
                              ),
                              ShortcutDropDownTile(
                                settingKey: 'key-shortcut-open-bookmarks',
                                title: context.t.bookmarks.title,
                                allShortcuts: shortcuctsList,
                                selected: 'ctrl+shift+b',
                                leading:
                                    const Icon(FluentIcons.bookmark_24_regular),
                              ),
                              ShortcutDropDownTile(
                                settingKey: 'key-shortcut-open-history',
                                title: context.t.history.title,
                                allShortcuts: shortcuctsList,
                                selected: 'ctrl+h',
                                leading:
                                    const Icon(FluentIcons.history_24_regular),
                              ),
                              ShortcutDropDownTile(
                                settingKey: 'key-shortcut-switch-workspace',
                                title: context.t.settings.switchWorkspace,
                                allShortcuts: shortcuctsList,
                                selected: 'ctrl+k',
                                leading:
                                    const Icon(FluentIcons.grid_24_regular),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            Padding(
                              padding: EdgeInsets.only(bottom: 8.0, right: 8.0),
                              child: Text(
                                context.t.settings.bookView,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            _buildColumns(3, [
                              ShortcutDropDownTile(
                                settingKey: 'key-shortcut-search-in-book',
                                title: context.t.settings.searchInBook,
                                allShortcuts: shortcuctsList,
                                selected: 'ctrl+f',
                                leading:
                                    const Icon(FluentIcons.search_24_regular),
                              ),
                              ShortcutDropDownTile(
                                settingKey: 'key-shortcut-edit-section',
                                title: context.t.settings.editSection,
                                allShortcuts: shortcuctsList,
                                selected: 'ctrl+e',
                                leading: const Icon(
                                    FluentIcons.document_edit_24_regular),
                              ),
                              ShortcutDropDownTile(
                                settingKey: 'key-shortcut-print',
                                title: context.t.settings.print,
                                allShortcuts: shortcuctsList,
                                selected: 'ctrl+p',
                                leading:
                                    const Icon(FluentIcons.print_24_regular),
                              ),
                              ShortcutDropDownTile(
                                settingKey: 'key-shortcut-add-bookmark',
                                title: context.t.settings.addBookmark,
                                allShortcuts: shortcuctsList,
                                selected: 'ctrl+b',
                                leading:
                                    const Icon(FluentIcons.bookmark_24_regular),
                              ),
                              ShortcutDropDownTile(
                                settingKey: 'key-shortcut-add-note',
                                title: context.t.settings.addNote,
                                allShortcuts: shortcuctsList,
                                selected: 'ctrl+n',
                                leading:
                                    const Icon(FluentIcons.note_24_regular),
                              ),
                              ShortcutDropDownTile(
                                selected: 'ctrl+w',
                                settingKey: 'key-shortcut-close-tab',
                                title: context.t.settings.closeCurrentBook,
                                allShortcuts: shortcuctsList,
                                leading: const Icon(
                                    FluentIcons.dismiss_circle_24_regular),
                              ),
                              ShortcutDropDownTile(
                                selected: 'ctrl+shift+w',
                                settingKey: 'key-shortcut-close-all-tabs',
                                title: context.t.settings.closeAllBooks,
                                allShortcuts: shortcuctsList,
                                leading:
                                    const Icon(FluentIcons.dismiss_24_regular),
                              ),
                            ]),
                          ],
                        ),
                  const SizedBox(height: 24),
                  SettingsGroup(
                    title: context.t.settings.interface,
                    titleAlignment: Alignment.centerRight,
                    titleTextStyle: const TextStyle(fontSize: 25),
                    children: [
                      SwitchSettingsTile(
                        settingKey: 'key-replace-holy-names',
                        title: context.t.settings.hideHolyNames,
                        enabledLabel: context.t.settings.hideHolyNamesEnabled,
                        disabledLabel: context.t.settings.hideHolyNamesDisabled,
                        leading: const Icon(FluentIcons.eye_off_24_regular),
                        defaultValue: state.replaceHolyNames,
                        onChange: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdateReplaceHolyNames(value));
                        },
                        activeColor: Theme.of(context).cardColor,
                      ),
                      // קוביות הגדרות
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Wrap(
                          spacing: 12.0,
                          runSpacing: 12.0,
                          alignment: WrapAlignment.end,
                          children: [
                            _buildSettingsCard(
                              context: context,
                              title: context.t.settings.libraryScreenSettings,
                              icon: FluentIcons.library_24_regular,
                              onTap: () => showLibrarySettingsDialog(context),
                            ),
                            _buildSettingsCard(
                              context: context,
                              title: context.t.settings.bookDisplaySettings,
                              icon: FluentIcons.book_24_regular,
                              onTap: () => showReadingSettingsDialog(context),
                            ),
                            _buildSettingsCard(
                              context: context,
                              title: context.t.settings.calendarSettings,
                              icon: Icons.calendar_month_outlined,
                              onTap: () => showCalendarSettingsDialog(context),
                            ),
                            // הגדרות זכור ושמור - מוסתר כרגע
                            // ignore: dead_code
                            if (false)
                              // ignore: dead_code
                              _buildSettingsCard(
                                context: context,
                                title: 'הגדרות זכור ושמור',
                                icon: FluentIcons.book_24_regular,
                                onTap: () {
                                  // יוסף בעתיד
                                },
                              ),
                            _buildSettingsCard(
                              context: context,
                              title: context.t.settings.gematriaSettings,
                              icon: FluentIcons.calculator_24_regular,
                              onTap: () => showGematriaSettingsDialog(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SettingsGroup(
                    title: context.t.settings.backup,
                    titleAlignment: Alignment.centerRight,
                    titleTextStyle: const TextStyle(fontSize: 25),
                    children: [
                      SettingsGroup(
                        title: context.t.settings.backupWhat,
                        titleAlignment: Alignment.centerRight,
                        children: [
                          _buildColumns(3, [
                            SwitchSettingsTile(
                              settingKey: 'key-backup-settings',
                              title: context.t.settings.title,
                              subtitle: context.t.settings.backupSettingsSubtitle,
                              leading:
                                  const Icon(FluentIcons.settings_24_regular),
                              defaultValue: true,
                              activeColor: Theme.of(context).cardColor,
                            ),
                            SwitchSettingsTile(
                              settingKey: 'key-backup-bookmarks',
                              title: context.t.settings.backupBookmarks,
                              subtitle: context.t.settings.backupBookmarksSubtitle,
                              leading:
                                  const Icon(FluentIcons.bookmark_24_regular),
                              defaultValue: true,
                              activeColor: Theme.of(context).cardColor,
                            ),
                            SwitchSettingsTile(
                              settingKey: 'key-backup-history',
                              title: context.t.settings.backupHistory,
                              subtitle: context.t.settings.backupHistorySubtitle,
                              leading:
                                  const Icon(FluentIcons.history_24_regular),
                              defaultValue: true,
                              activeColor: Theme.of(context).cardColor,
                            ),
                            SwitchSettingsTile(
                              settingKey: 'key-backup-notes',
                              title: context.t.settings.backupNotes,
                              subtitle: context.t.settings.backupNotesSubtitle,
                              leading: const Icon(FluentIcons.note_24_regular),
                              defaultValue: true,
                              activeColor: Theme.of(context).cardColor,
                            ),
                            SwitchSettingsTile(
                              settingKey: 'key-backup-workspaces',
                              title: context.t.settings.backupWorkspaces,
                              subtitle: context.t.settings.backupWorkspacesSubtitle,
                              leading: const Icon(FluentIcons.grid_24_regular),
                              defaultValue: true,
                              activeColor: Theme.of(context).cardColor,
                            ),
                            SwitchSettingsTile(
                              settingKey: 'key-backup-shamor-zachor',
                              title: context.t.settings.backupShamorZachor,
                              subtitle: context.t.settings.backupShamorZachorSubtitle,
                              leading: const Icon(FluentIcons.book_24_regular),
                              defaultValue: true,
                              activeColor: Theme.of(context).cardColor,
                            ),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropDownSettingsTile<String>(
                        settingKey: 'key-auto-backup-frequency',
                        title: context.t.settings.autoBackup,
                        leading:
                            const Icon(FluentIcons.calendar_clock_24_regular),
                        selected: 'none',
                        values: {
                          'none': context.t.settings.none,
                          'weekly': context.t.settings.weekly,
                          'monthly': context.t.settings.monthly,
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SimpleSettingsTile(
                              title: context.t.settings.createBackupNow,
                              subtitle: context.t.settings.createBackupSubtitle,
                              leading: const Icon(
                                  FluentIcons.arrow_upload_24_regular),
                              onTap: () async {
                                final includeSettings = Settings.getValue<bool>(
                                        'key-backup-settings') ??
                                    true;
                                final includeBookmarks =
                                    Settings.getValue<bool>(
                                            'key-backup-bookmarks') ??
                                        true;
                                final includeHistory = Settings.getValue<bool>(
                                        'key-backup-history') ??
                                    true;
                                final includeNotes = Settings.getValue<bool>(
                                        'key-backup-notes') ??
                                    true;
                                final includeWorkspaces =
                                    Settings.getValue<bool>(
                                            'key-backup-workspaces') ??
                                        true;
                                final includeShamorZachor =
                                    Settings.getValue<bool>(
                                            'key-backup-shamor-zachor') ??
                                        true;

                                try {
                                  final backupPath =
                                      await BackupService.createBackup(
                                    includeSettings: includeSettings,
                                    includeBookmarks: includeBookmarks,
                                    includeHistory: includeHistory,
                                    includeNotes: includeNotes,
                                    includeWorkspaces: includeWorkspaces,
                                    includeShamorZachor: includeShamorZachor,
                                  );

                                  // Verify file was created
                                  final file = File(backupPath);
                                  final fileExists = await file.exists();
                                  final fileSize =
                                      fileExists ? await file.length() : 0;

                                  if (!context.mounted) return;

                                  if (fileExists) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${context.t.settings.backupSaved}\n'
                                            '${context.t.settings.backupPath}: $backupPath\n'
                                            '${context.t.settings.backupSize}: ${(fileSize / 1024).toStringAsFixed(1)} KB'),
                                        duration: const Duration(seconds: 5),
                                        action: SnackBarAction(
                                          label: context.t.settings.openFolder,
                                          onPressed: () async {
                                            final dir =
                                                Directory(file.parent.path);
                                            if (Platform.isWindows) {
                                              await Process.run(
                                                  'explorer', [dir.path]);
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '${context.t.settings.backupFileNotCreated}\n$backupPath'),
                                        backgroundColor: Colors.orange,
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                } catch (e, stackTrace) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${context.t.settings.backupError}\n$e\n\nStack trace:\n${stackTrace.toString().substring(0, 200)}'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 10),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SimpleSettingsTile(
                              title: context.t.settings.restoreFromBackup,
                              subtitle: context.t.settings.restoreFromBackupSubtitle,
                              leading: const Icon(
                                  FluentIcons.arrow_download_24_regular),
                              onTap: () async {
                                String? filePath = await FilePicker.platform
                                    .pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: ['json'],
                                      dialogTitle: context.t.settings.selectBackupFile,
                                    )
                                    .then(
                                        (result) => result?.files.single.path);

                                if (filePath == null) return;

                                if (!context.mounted) return;
                                final confirmed = await showConfirmationDialog(
                                  context: context,
                                  title: context.t.settings.restoreBackupTitle,
                                  content: context.t.settings.restoreBackupContent,
                                  confirmColor: Colors.blue,
                                );

                                if (confirmed != true) return;

                                try {
                                  await BackupService.restoreFromBackup(
                                      filePath);

                                  if (!context.mounted) return;
                                  await showDialog<void>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => AlertDialog(
                                      title: Text(context.t.settings.restoreCompleted),
                                      content: Text(
                                        context.t.settings.restoreCompletedContent,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => exit(0),
                                          child: Text(context.t.settings.closeApp),
                                        ),
                                      ],
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${context.t.settings.restoreError} $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SettingsGroup(
                    title: context.t.settings.general,
                    titleAlignment: Alignment.centerRight,
                    titleTextStyle: const TextStyle(fontSize: 25),
                    children: [
                      SwitchSettingsTile(
                        title: context.t.settings.autoSyncLibrary,
                        leading: Icon(FluentIcons.arrow_sync_24_regular),
                        settingKey: 'key-auto-sync',
                        defaultValue: true,
                        enabledLabel: context.t.settings.autoSyncEnabled,
                        disabledLabel: context.t.settings.autoSyncDisabled,
                        activeColor: Theme.of(context).cardColor,
                      ),
                      SwitchSettingsTile(
                        settingKey: 'key-use-fast-search',
                        title: context.t.settings.fastSearch,
                        enabledLabel: context.t.settings.fastSearchEnabled,
                        disabledLabel: context.t.settings.fastSearchDisabled,
                        leading: const Icon(FluentIcons.search_24_regular),
                        defaultValue: state.useFastSearch,
                        onChange: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdateUseFastSearch(value));
                        },
                        activeColor: Theme.of(context).cardColor,
                      ),
                      _buildColumns(2, [
                        BlocBuilder<IndexingBloc, IndexingState>(
                          builder: (context, indexingState) {
                            return SimpleSettingsTile(
                              title: context.t.settings.searchIndex,
                              subtitle: indexingState is IndexingInProgress
                                  ? "${context.t.settings.indexUpdating}${indexingState.booksProcessed}/${indexingState.totalBooks}"
                                  : context.t.settings.indexUpdated,
                              leading: const Icon(FluentIcons.table_24_regular),
                              onTap: () async {
                                if (indexingState is IndexingInProgress) {
                                  final result = await showConfirmationDialog(
                                    context: context,
                                    title: context.t.settings.stopIndexing,
                                    content: context.t.settings.stopIndexingContent,
                                  );
                                  if (!context.mounted) return;
                                  if (result == true) {
                                    context
                                        .read<IndexingBloc>()
                                        .add(CancelIndexing());
                                    setState(() {});
                                  }
                                } else {
                                  final result = await showConfirmationDialog(
                                    context: context,
                                    title: context.t.settings.resetIndex,
                                    content: context.t.settings.resetIndexContent,
                                  );
                                  if (!context.mounted) return;
                                  if (result == true) {
                                    //reset the index
                                    context
                                        .read<IndexingBloc>()
                                        .add(ClearIndex());
                                    final library = context
                                        .read<LibraryBloc>()
                                        .state
                                        .library;
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
                          title: context.t.settings.autoUpdateIndex,
                          leading:
                              const Icon(FluentIcons.arrow_sync_24_regular),
                          settingKey: 'key-auto-index-update',
                          defaultValue: state.autoUpdateIndex,
                          enabledLabel: context.t.settings.autoUpdateIndexEnabled,
                          disabledLabel: context.t.settings.autoUpdateIndexDisabled,
                          onChange: (value) async {
                            context
                                .read<SettingsBloc>()
                                .add(UpdateAutoUpdateIndex(value));
                            if (value) {
                              final library =
                                  await DataRepository.instance.library;
                              if (!context.mounted) return;
                              context
                                  .read<IndexingBloc>()
                                  .add(StartIndexing(library));
                            }
                          },
                          activeColor: Theme.of(context).cardColor,
                        ),
                      ]),
                      if (!(Platform.isAndroid || Platform.isIOS))
                        _buildColumns(2, [
                          SimpleSettingsTile(
                            title: context.t.settings.libraryLocation,
                            subtitle:
                                Settings.getValue<String>('key-library-path') ??
                                    context.t.settings.notExists,
                            leading: const Icon(FluentIcons.folder_24_regular),
                            onTap: () async {
                              String? path =
                                  await FilePicker.platform.getDirectoryPath();
                              if (path != null) {
                                if (!context.mounted) return;
                                context
                                    .read<LibraryBloc>()
                                    .add(UpdateLibraryPath(path));
                              }
                            },
                          ),
                          Tooltip(
                            message: context.t.settings.hebrewBooksTooltip,
                            child: SimpleSettingsTile(
                              title: context.t.settings.hebrewBooksLocation,
                              subtitle: Settings.getValue<String>(
                                      'key-hebrew-books-path') ??
                                  context.t.settings.notExists,
                              leading:
                                  const Icon(FluentIcons.folder_24_regular),
                              onTap: () async {
                                String? path = await FilePicker.platform
                                    .getDirectoryPath();
                                if (path != null) {
                                  if (!context.mounted) return;
                                  context
                                      .read<LibraryBloc>()
                                      .add(UpdateHebrewBooksPath(path));
                                }
                              },
                            ),
                          ),
                        ]),
                      if (!(Platform.isAndroid || Platform.isIOS))


                      SwitchSettingsTile(
                        settingKey: 'key-dev-channel',
                        title: context.t.settings.devChannel,
                        enabledLabel: context.t.settings.devChannelEnabled,
                        disabledLabel: context.t.settings.devChannelDisabled,
                        leading: const Icon(FluentIcons.bug_24_regular),
                        activeColor: Theme.of(context).cardColor,
                      ),
                      SimpleSettingsTile(
                        title: context.t.settings.resetSettings,
                        subtitle: context.t.settings.resetSettingsSubtitle,
                        leading: const Icon(FluentIcons.arrow_reset_24_regular),
                        onTap: () async {
                          // דיאלוג לאישור המשתמש
                          final confirmed = await showConfirmationDialog(
                            context: context,
                            title: context.t.settings.resetSettingsTitle,
                            content: context.t.settings.resetSettingsContent,
                            isDangerous: true,
                          );

                          if (confirmed == true && context.mounted) {
                            Settings.clearCache();

                            // הודעה למשתמש שנדרשת הפעלה מחדש
                            await showDialog<void>(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => AlertDialog(
                                        title: Text(context.t.settings.settingsReset),
                                        content: Text(
                                            context.t.settings.settingsResetContent),
                                        actions: [
                                          TextButton(
                                              onPressed: () => exit(0),
                                              child:
                                                  Text(context.t.settings.closeApp))
                                        ]));
                          }
                        },
                      ),
                    ],
                  )
                ],
              ),
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
            SizedBox(
              height: widgetHeight,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTapDown: (details) {
                    final renderBox = context.findRenderObject() as RenderBox;
                    final localPosition =
                        renderBox.globalToLocal(details.globalPosition);
                    final tapX = localPosition.dx;

                    double newMargin;

                    double distanceFromCenter = (tapX - fullWidth / 2).abs();
                    newMargin = (fullWidth / 2) - distanceFromCenter;

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
                      Container(
                        height: thumbSize * 2,
                        color: Colors.transparent,
                      ),

                      // קו הרקע
                      Container(
                        height: trackHeight,
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor.withAlpha(128),
                          borderRadius: BorderRadius.circular(trackHeight / 2),
                        ),
                      ),

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
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showPreview ? 1.0 : 0.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _showPreview ? 60 : 0,
                curve: Curves.easeInOut,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withAlpha(128),
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
