import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:updat/updat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otzaria/i18n/translations.g.dart';

/// רכיב לחיצה (chip) בעברית - דומה ל-flatChip המקורי
Widget hebrewFlatChip({
  required BuildContext context,
  required String? latestVersion,
  required String appVersion,
  required UpdatStatus status,
  required void Function() checkForUpdate,
  required void Function() openDialog,
  required void Function() startUpdate,
  required Future<void> Function() launchInstaller,
  required void Function() dismissUpdate,
}) {
  if (UpdatStatus.available == status ||
      UpdatStatus.availableWithChangelog == status) {
    // בדוק אם הדיאלוג כבר הוצג לגרסה זו
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final shownKey = 'update_dialog_shown_$latestVersion';
      final alreadyShown = prefs.getBool(shownKey) ?? false;

      if (!alreadyShown && context.mounted) {
        // סמן שהדיאלוג הוצג לגרסה זו
        await prefs.setBool(shownKey, true);
        openDialog();
      }
    });
    return Tooltip(
      message: context.t.update.updateToVersion(version: latestVersion!.toString()),
      child: TextButton.icon(
        onPressed: openDialog,
        icon: const Icon(FluentIcons.arrow_download_24_regular),
        label: Text(context.t.update.available),
      ),
    );
  }

  if (UpdatStatus.downloading == status) {
    return Tooltip(
      message: context.t.update.pleaseWait,
      child: TextButton.icon(
        onPressed: () {},
        icon: const SizedBox(
          width: 15,
          height: 15,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
        label: Text(context.t.update.downloading),
      ),
    );
  }

  if (UpdatStatus.readyToInstall == status) {
    return Tooltip(
      message: context.t.update.clickToInstall,
      child: TextButton.icon(
        onPressed: launchInstaller,
        icon: const Icon(FluentIcons.checkmark_circle_24_regular),
        label: Text(context.t.update.readyToInstall),
      ),
    );
  }

  if (UpdatStatus.error == status) {
    return Tooltip(
      message: context.t.update.updateError,
      child: TextButton.icon(
        onPressed: startUpdate,
        icon: const Icon(FluentIcons.warning_24_regular),
        label: Text(context.t.update.errorTryAgain),
      ),
    );
  }

  return Container();
}

/// רכיב לחיצה מורחב בעברית עם הורדה שקטה - דומה ל-floatingExtendedChipWithSilentDownload
Widget hebrewFloatingExtendedChipWithSilentDownload({
  required BuildContext context,
  required String? latestVersion,
  required String appVersion,
  required UpdatStatus status,
  required void Function() checkForUpdate,
  required void Function() openDialog,
  required void Function() startUpdate,
  required Future<void> Function() launchInstaller,
  required void Function() dismissUpdate,
}) {
  if (UpdatStatus.available == status ||
      UpdatStatus.availableWithChangelog == status) {
    startUpdate();
  }

  if (UpdatStatus.downloading == status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t.update.downloadingUpdate,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.t.update.downloadingVersion(version: latestVersion.toString()),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(context.t.update.pleaseWait),
              ],
            ),
          ],
        ),
      ),
    );
  }

  if (UpdatStatus.readyToInstall == status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t.update.updateReady,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.t.update.versionReadyToInstall(version: latestVersion.toString()),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.t.update.currentlyUsingVersion(appVersion: appVersion),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.t.update.updateNowForFeatures,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: dismissUpdate,
                  child: Text(context.t.update.later),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: startUpdate,
                  icon: const Icon(FluentIcons.desktop_arrow_down_24_regular),
                  label: Text(context.t.update.installNow),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  return Container();
}

/// דיאלוג ברירת מחדל בעברית - דומה ל-defaultDialog
void hebrewDefaultDialog({
  required BuildContext context,
  required String? latestVersion,
  required String appVersion,
  required UpdatStatus status,
  required String? changelog,
  required void Function() checkForUpdate,
  required void Function() openDialog,
  required void Function() startUpdate,
  required Future<void> Function() launchInstaller,
  required void Function() dismissUpdate,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Flex(
        direction:
            Theme.of(context).useMaterial3 ? Axis.vertical : Axis.horizontal,
        children: [
          const Icon(FluentIcons.arrow_sync_24_regular),
          Text(context.t.update.available),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.t.update.newVersionAvailable),
          const SizedBox(width: 10),
          Text(context.t.update.newVersion(version: latestVersion!.toString())),
          const SizedBox(height: 10),
          if (status == UpdatStatus.availableWithChangelog) ...[
            Text(
              context.t.update.changelog,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Markdown(data: changelog!),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: Text(context.t.update.later),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            startUpdate();
          },
          child: Text(context.t.update.updateNow),
        ),
      ],
    ),
  );
}

/// פונקציה שעוטפת את _flatChipAutoHideError אבל עם הרכיב העברי
Widget hebrewFlatChipAutoHideError({
  required BuildContext context,
  required String? latestVersion,
  required String appVersion,
  required UpdatStatus status,
  required void Function() checkForUpdate,
  required void Function() openDialog,
  required void Function() startUpdate,
  required Future<void> Function() launchInstaller,
  required void Function() dismissUpdate,
}) {
  if (status == UpdatStatus.error) {
    Future.delayed(const Duration(seconds: 3), dismissUpdate);
  }
  return hebrewFlatChip(
    context: context,
    latestVersion: latestVersion,
    appVersion: appVersion,
    status: status,
    checkForUpdate: checkForUpdate,
    openDialog: openDialog,
    startUpdate: startUpdate,
    launchInstaller: launchInstaller,
    dismissUpdate: dismissUpdate,
  );
}
