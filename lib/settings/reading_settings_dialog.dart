import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_event.dart';
import 'package:otzaria/settings/settings_state.dart';
import 'package:otzaria/i18n/translations.g.dart';

/// פונקציה גלובלית להצגת דיאלוג הגדרות תצוגת הספרים
/// ניתן לקרוא לה מכל מקום באפליקציה
void showReadingSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return AlertDialog(
          title: Text(
            context.t.settings.readingSettingsTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // כותרת: הגדרות גופן ועיצוב
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: Text(
                      context.t.settings.fontAndStyleSettings,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.start,
                    ),
                  ),

                  // גודל גופן והגופן בשורה אחת
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // גודל גופן - 2/4
                        Expanded(
                          flex: 2,
                          child: StatefulBuilder(
                            builder: (context, setState) {
                              double currentFontSize =
                                  settingsState.fontSize.clamp(15, 60);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(FluentIcons
                                          .text_font_size_24_regular),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          context.t.settings.initialFontSize,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                      Text(
                                        currentFontSize.toStringAsFixed(0),
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Slider(
                                    value: currentFontSize,
                                    min: 15,
                                    max: 60,
                                    divisions: 45,
                                    label: currentFontSize.toStringAsFixed(0),
                                    onChanged: (value) {
                                      setState(() {});
                                      context
                                          .read<SettingsBloc>()
                                          .add(UpdateFontSize(value));
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // גופן טקסט ראשי - 1/4
                        Expanded(
                          flex: 1,
                          child: StatefulBuilder(
                            builder: (context, setState) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                          FluentIcons.text_font_24_regular),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          context.t.settings.textFont,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: settingsState.fontFamily,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    dropdownColor:
                                        Theme.of(context).colorScheme.surface,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'TaameyDavidCLM',
                                          child: Text('דוד')),
                                      DropdownMenuItem(
                                          value: 'FrankRuhlCLM',
                                          child: Text('פרנק-רוהל')),
                                      DropdownMenuItem(
                                          value: 'TaameyAshkenaz',
                                          child: Text('טעמי אשכנז')),
                                      DropdownMenuItem(
                                          value: 'KeterYG', child: Text('כתר')),
                                      DropdownMenuItem(
                                          value: 'Shofar', child: Text('שופר')),
                                      DropdownMenuItem(
                                          value: 'NotoSerifHebrew',
                                          child: Text('נוטו')),
                                      DropdownMenuItem(
                                          value: 'Tinos', child: Text('טינוס')),
                                      DropdownMenuItem(
                                          value: 'NotoRashiHebrew',
                                          child: Text('רש"י')),
                                      DropdownMenuItem(
                                          value: 'Candara',
                                          child: Text('קנדרה')),
                                      DropdownMenuItem(
                                          value: 'roboto',
                                          child: Text('רובוטו')),
                                      DropdownMenuItem(
                                          value: 'Calibri',
                                          child: Text('קליברי')),
                                      DropdownMenuItem(
                                          value: 'Arial', child: Text('אריאל')),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        context
                                            .read<SettingsBloc>()
                                            .add(UpdateFontFamily(value));
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // גופן מפרשים - 1/4
                        Expanded(
                          flex: 1,
                          child: StatefulBuilder(
                            builder: (context, setState) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(FluentIcons.book_24_regular),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          context.t.settings.commentatorFont,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue:
                                        settingsState.commentatorsFontFamily,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    dropdownColor:
                                        Theme.of(context).colorScheme.surface,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'TaameyDavidCLM',
                                          child: Text('דוד')),
                                      DropdownMenuItem(
                                          value: 'FrankRuhlCLM',
                                          child: Text('פרנק-רוהל')),
                                      DropdownMenuItem(
                                          value: 'TaameyAshkenaz',
                                          child: Text('טעמי אשכנז')),
                                      DropdownMenuItem(
                                          value: 'KeterYG', child: Text('כתר')),
                                      DropdownMenuItem(
                                          value: 'Shofar', child: Text('שופר')),
                                      DropdownMenuItem(
                                          value: 'NotoSerifHebrew',
                                          child: Text('נוטו')),
                                      DropdownMenuItem(
                                          value: 'Tinos', child: Text('טינוס')),
                                      DropdownMenuItem(
                                          value: 'NotoRashiHebrew',
                                          child: Text('רש"י')),
                                      DropdownMenuItem(
                                          value: 'Candara',
                                          child: Text('קנדרה')),
                                      DropdownMenuItem(
                                          value: 'roboto',
                                          child: Text('רובוטו')),
                                      DropdownMenuItem(
                                          value: 'Calibri',
                                          child: Text('קליברי')),
                                      DropdownMenuItem(
                                          value: 'Arial', child: Text('אריאל')),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        context.read<SettingsBloc>().add(
                                            UpdateCommentatorsFontFamily(
                                                value));
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  // רוחב השוליים בצידי הטקסט
                  StatefulBuilder(
                    builder: (context, setState) {
                      double currentPadding = settingsState.paddingSize;
                      return Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                                FluentIcons.text_align_justify_24_regular),
                            title: Text(context.t.settings
                                .textMargins), // Old: 'רוחב השוליים בצידי הטקסט'
                            trailing: Text(
                              currentPadding.toStringAsFixed(0),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Slider(
                              value: currentPadding,
                              min: 0,
                              max: 500,
                              divisions: 250,
                              label: currentPadding.toStringAsFixed(0),
                              onChanged: (value) {
                                setState(() {});
                                context
                                    .read<SettingsBloc>()
                                    .add(UpdatePaddingSize(value));
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // כותרת: הסרת ניקוד וטעמים
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: Text(
                      context.t.settings
                          .nikudAndTeamim, // Old: 'הסרת ניקוד וטעמים'
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.start,
                    ),
                  ),

                  // הצגת טעמי המקרא
                  SwitchListTile(
                    title: Text(context
                        .t.settings.showTeamim), // Old: 'הצגת טעמי המקרא'
                    subtitle: Text(settingsState.showTeamim
                        ? context.t.settings
                            .showTeamimEnabled // Old: 'המקרא יוצג עם טעמים'
                        : context.t.settings
                            .showTeamimDisabled), // Old: 'המקרא יוצג ללא טעמים'
                    value: settingsState.showTeamim,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(UpdateShowTeamim(value));
                    },
                  ),
                  const Divider(),

                  // הסרת ניקוד כברירת מחדל
                  SwitchListTile(
                    title: Text(context.t.settings
                        .defaultRemoveNikud), // Old: 'הסרת ניקוד כברירת מחדל'
                    subtitle: Text(settingsState.defaultRemoveNikud
                        ? context.t.settings
                            .defaultRemoveNikudEnabled // Old: 'הניקוד יוסר כברירת מחדל'
                        : context.t.settings
                            .defaultRemoveNikudDisabled), // Old: 'הניקוד יוצג כברירת מחדל'
                    value: settingsState.defaultRemoveNikud,
                    onChanged: (value) {
                      context
                          .read<SettingsBloc>()
                          .add(UpdateDefaultRemoveNikud(value));
                    },
                  ),
                  if (settingsState.defaultRemoveNikud)
                    Padding(
                      padding: const EdgeInsets.only(right: 32.0),
                      child: CheckboxListTile(
                        title: Text(context.t.settings
                            .removeNikudFromTanach), // Old: 'הסרת ניקוד מספרי התנ"ך'
                        subtitle: Text(context.t.settings
                            .removeNikudFromTanachSubtitle), // Old: 'גם ספרי התנ"ך יוצגו ללא ניקוד'
                        value: settingsState.removeNikudFromTanach,
                        onChanged: (bool? value) {
                          if (value != null) {
                            context.read<SettingsBloc>().add(
                                  UpdateRemoveNikudFromTanach(value),
                                );
                          }
                        },
                      ),
                    ),

                  // כותרת: התנהגות סרגל צד
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: Text(
                      context
                          .t.settings.sidebarBehavior, // Old: 'התנהגות סרגל צד'
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.start,
                    ),
                  ),

                  // הצמדת סרגל צד
                  SwitchListTile(
                    title: Text(
                        context.t.settings.pinSidebar), // Old: 'הצמדת סרגל צד'
                    subtitle: Text(settingsState.pinSidebar
                        ? context.t.settings
                            .pinSidebarEnabled // Old: 'סרגל הצד יוצמד תמיד'
                        : context.t.settings
                            .pinSidebarDisabled), // Old: 'סרגל הצד יפעל כרגיל'
                    value: settingsState.pinSidebar,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(UpdatePinSidebar(value));
                      if (value) {
                        context
                            .read<SettingsBloc>()
                            .add(const UpdateDefaultSidebarOpen(true));
                      }
                    },
                  ),
                  const Divider(),

                  // פתיחת סרגל צד
                  SwitchListTile(
                    title: Text(context.t.settings
                        .defaultSidebarOpen), // Old: 'פתיחת סרגל צד כברירת מחדל'
                    subtitle: Text(settingsState.defaultSidebarOpen
                        ? context.t.settings
                            .defaultSidebarOpenEnabled // Old: 'סרגל הצד יפתח אוטומטית'
                        : context.t.settings
                            .defaultSidebarOpenDisabled), // Old: 'סרגל הצד ישאר סגור'
                    value: settingsState.defaultSidebarOpen,
                    onChanged: settingsState.pinSidebar
                        ? null
                        : (value) {
                            context
                                .read<SettingsBloc>()
                                .add(UpdateDefaultSidebarOpen(value));
                          },
                  ),
                  const Divider(),

                  // ברירת מחדל להצגת מפרשים
                  StatefulBuilder(
                    builder: (context, setState) {
                      final splitedView =
                          Settings.getValue<bool>('key-splited-view') ?? false;
                      return SwitchListTile(
                        title: Text(context.t.settings
                            .defaultShowCommentators), // Old: 'ברירת המחדל להצגת המפרשים'
                        subtitle: Text(splitedView
                            ? context.t.settings
                                .defaultShowCommentatorsEnabled // Old: 'המפרשים יוצגו לצד הטקסט'
                            : context.t.settings
                                .defaultShowCommentatorsDisabled), // Old: 'המפרשים יוצגו מתחת הטקסט'
                        value: splitedView,
                        onChanged: (value) {
                          setState(() {
                            Settings.setValue<bool>('key-splited-view', value);
                          });
                        },
                      );
                    },
                  ),

                  // הגדרות העתקה
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: Text(
                      context.t.settings.copySettings,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.start,
                    ),
                  ),

                  // העתקה עם כותרות ועיצוב בשורה אחת
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // העתקה עם כותרות - 1/2
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(FluentIcons.copy_24_regular),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'העתקה עם כותרות',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: settingsState.copyWithHeaders,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    dropdownColor:
                                        Theme.of(context).colorScheme.surface,
                                    isExpanded: true,
                                    items: [
                                      DropdownMenuItem(
                                          value: 'none', child: Text(context.t.settings.none)),
                                      DropdownMenuItem(
                                          value: 'book_name',
                                          child: Text(context.t.settings.bookNameOnly)),
                                      DropdownMenuItem(
                                          value: 'book_and_path',
                                          child: Text(context.t.settings.bookNameAndPath)),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        context
                                            .read<SettingsBloc>()
                                            .add(UpdateCopyWithHeaders(value));
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // עיצוב העתקה - 1/2
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(FluentIcons
                                          .text_align_right_24_regular),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          context.t.settings.copyFormatting,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue:
                                        settingsState.copyHeaderFormat,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    dropdownColor:
                                        Theme.of(context).colorScheme.surface,
                                    isExpanded: true,
                                    items: [
                                      DropdownMenuItem(
                                          value: 'same_line_after_brackets',
                                          child: Text(context.t.settings.sameLineAfterBrackets)),
                                      DropdownMenuItem(
                                          value: 'same_line_after_no_brackets',
                                          child: Text(context.t.settings.sameLineAfterNoBrackets)),
                                      DropdownMenuItem(
                                          value: 'same_line_before_brackets',
                                          child: Text(context.t.settings.sameLineBeforeBrackets)),
                                      DropdownMenuItem(
                                          value: 'same_line_before_no_brackets',
                                          child: Text(context.t.settings.sameLineBeforeNoBrackets)),
                                      DropdownMenuItem(
                                          value: 'separate_line_after',
                                          child: Text(context.t.settings.separateLineAfter)),
                                      DropdownMenuItem(
                                          value: 'separate_line_before',
                                          child: Text(context.t.settings.separateLineBefore)),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        context
                                            .read<SettingsBloc>()
                                            .add(UpdateCopyHeaderFormat(value));
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // הגדרות עורך טקסטים
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: Text(
                      context.t.settings.textEditorSettings,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.start,
                    ),
                  ),

                  StatefulBuilder(
                    builder: (context, setState) {
                      double previewDebounce = Settings.getValue<double>(
                              'key-editor-preview-debounce') ??
                          150.0;
                      double cleanupDays = Settings.getValue<double>(
                              'key-editor-draft-cleanup-days') ??
                          30.0;
                      double draftsQuota = Settings.getValue<double>(
                              'key-editor-drafts-quota') ??
                          100.0;

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // עיכוב תצוגה מקדימה
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(FluentIcons.timer_24_regular),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        context.t.settings.delayInMilliseconds,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                    Text(
                                      '${previewDebounce.toInt()}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: previewDebounce,
                                  min: 50,
                                  max: 300,
                                  divisions: 5,
                                  label: previewDebounce.toInt().toString(),
                                  onChanged: (value) {
                                    setState(() => previewDebounce = value);
                                    Settings.setValue<double>(
                                        'key-editor-preview-debounce', value);
                                  },
                                ),
                              ],
                            ),
                            const Divider(),

                            // ניקוי טיוטות ישנות
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                        FluentIcons.delete_dismiss_24_regular),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        context.t.settings.cleanOldDrafts,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                    Text(
                                      '${cleanupDays.toInt()}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: cleanupDays,
                                  min: 7,
                                  max: 90,
                                  divisions: 12,
                                  label: cleanupDays.toInt().toString(),
                                  onChanged: (value) {
                                    setState(() => cleanupDays = value);
                                    Settings.setValue<double>(
                                        'key-editor-draft-cleanup-days', value);
                                  },
                                ),
                              ],
                            ),
                            const Divider(),

                            // מכסת טיוטות
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(FluentIcons.database_24_regular),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        context.t.settings.draftQuota,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                    Text(
                                      '${draftsQuota.toInt()}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: draftsQuota,
                                  min: 50,
                                  max: 100,
                                  divisions: 5,
                                  label: draftsQuota.toInt().toString(),
                                  onChanged: (value) {
                                    setState(() => draftsQuota = value);
                                    Settings.setValue<double>(
                                        'key-editor-drafts-quota', value);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.t.common.close), // Old: 'סגור'
            ),
          ],
        );
      },
    ),
  );
}
