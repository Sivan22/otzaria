import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:updat/theme/chips/flat.dart';
import 'package:updat/updat_window_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyUpdatWidget extends StatelessWidget {
  const MyUpdatWidget({Key? key, required this.child}) : super(key: key);
  final Widget child;
  @override
  Widget build(BuildContext context) => UpdatWindowManager(
        getLatestVersion: () async {
          // Github gives us a super useful latest endpoint, and we can use it to get the latest stable release
          final data = await http.get(Uri.parse(
            Settings.getValue<bool>('key-dev-channel') ?? false
                ? "https://api.github.com/repos/sivan22/otzaria-dev-channel/releases/latest"
                : "https://api.github.com/repos/sivan22/otzaria/releases/latest",
          ));

          // Return the tag name, which is always a semantically versioned string.
          return jsonDecode(data.body)["tag_name"];
        },
        getBinaryUrl: (version) async {
          // Github also gives us a great way to download the binary for a certain release (as long as we use a consistent naming scheme)

          // Make sure that this link includes the platform extension with which to save your binary.
          // If you use https://exapmle.com/latest/macos for instance then you need to create your own file using `getDownloadFileLocation`

          final repo = Settings.getValue<bool>('key-dev-channel') ?? false
              ? "otzaria-dev-channel"
              : "otzaria";
          return "https://github.com/sivan22/$repo/releases/download/$version/otzaria-$version-${Platform.operatingSystem}.$platformExt";
        },
        appName: "otzaria", // This is used to name the downloaded files.
        getChangelog: (_, __) async {
          // That same latest endpoint gives us access to a markdown-flavored release body. Perfect!
          final repo = Settings.getValue<bool>('key-dev-channel') ?? false
              ? "otzaria-dev-channel"
              : "otzaria";
          final data = await http.get(Uri.parse(
            "https://api.github.com/repos/sivan22/$repo/releases/latest",
          ));
          return jsonDecode(data.body)["body"];
        },
        currentVersion: '0.1.8-dev.4',
        updateChipBuilder: flatChip,

        callback: (status) {},
        child: child,
      );

  String get platformExt {
    switch (Platform.operatingSystem) {
      case 'windows':
        {
          return Settings.getValue<bool>('key-dev-channel') ?? false
              ? 'msix'
              : 'exe';
        }

      case 'macos':
        {
          return 'dmg';
        }

      case 'linux':
        {
          return 'AppImage';
        }
      default:
        {
          return 'zip';
        }
    }
  }
}
