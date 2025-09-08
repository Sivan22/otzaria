import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:updat/theme/chips/flat.dart';
import 'package:updat/updat.dart';
import 'package:updat/updat_window_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';

/// Wraps [flatChip] and automatically dismisses update errors after a short delay.
Widget _flatChipAutoHideError({
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
  return flatChip(
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

class MyUpdatWidget extends StatelessWidget {
  const MyUpdatWidget({Key? key, required this.child}) : super(key: key);
  final Widget child;
  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return child;
        }
        return UpdatWindowManager(
          getLatestVersion: () async {
            // Github gives us a super useful latest endpoint, and we can use it to get the latest stable release
            final isDevChannel = Settings.getValue<bool>('key-dev-channel') ?? false;
            
            if (isDevChannel) {
              // For dev channel, get the latest pre-release from the main repo
              final data = await http.get(Uri.parse(
                "https://api.github.com/repos/sivan22/otzaria/releases",
              ));
              final releases = jsonDecode(data.body) as List;
              // Find the first pre-release that is not a draft and not a PR preview
              final preRelease = releases.firstWhere(
                (release) => release["prerelease"] == true && 
                            release["draft"] == false &&
                            !release["tag_name"].toString().contains('-pr-'),
                orElse: () => releases.first,
              );
              return preRelease["tag_name"];
            } else {
              // For stable channel, get the latest stable release
              final data = await http.get(Uri.parse(
                "https://api.github.com/repos/sivan22/otzaria/releases/latest",
              ));
              return jsonDecode(data.body)["tag_name"];
            }
          },
          getBinaryUrl: (version) async {
            // Get the release info to find the correct asset
            final data = await http.get(Uri.parse(
              "https://api.github.com/repos/sivan22/otzaria/releases/tags/$version",
            ));
            final release = jsonDecode(data.body);
            final assets = release["assets"] as List;
            
            // Find the appropriate asset for the current platform
            final platformName = Platform.operatingSystem;
            final isDevChannel = Settings.getValue<bool>('key-dev-channel') ?? false;
            
            String? assetUrl;
            
            for (final asset in assets) {
              final name = asset["name"] as String;
              final downloadUrl = asset["browser_download_url"] as String;
              
              switch (platformName) {
                case 'windows':
                  // For dev channel prefer MSIX, otherwise EXE
                  if (isDevChannel && name.endsWith('.msix')) {
                    assetUrl = downloadUrl;
                    break;
                  } else if (name.endsWith('.exe')) {
                    assetUrl = downloadUrl;
                    break;
                  }
                  // Fallback: Windows ZIP
                  if (name.contains('windows') && name.endsWith('.zip') && assetUrl == null) {
                    assetUrl = downloadUrl;
                  }
                  break;
                  
                case 'macos':
                  // Look for macOS zip file (workflow creates otzaria-macos.zip)
                  if (name.contains('macos') && name.endsWith('.zip')) {
                    assetUrl = downloadUrl;
                    break;
                  }
                  break;
                  
                case 'linux':
                  // Prefer DEB, then RPM, then raw zip (workflow creates otzaria-linux-raw.zip)
                  if (name.endsWith('.deb')) {
                    assetUrl = downloadUrl;
                    break;
                  } else if (name.endsWith('.rpm') && assetUrl == null) {
                    assetUrl = downloadUrl;
                  } else if (name.contains('linux') && name.endsWith('.zip') && assetUrl == null) {
                    assetUrl = downloadUrl;
                  }
                  break;
              }
            }
            
            if (assetUrl == null) {
              throw Exception('No suitable binary found for $platformName');
            }
            
            return assetUrl;
          },
          appName: "otzaria", // This is used to name the downloaded files.
          getChangelog: (_, __) async {
            // That same latest endpoint gives us access to a markdown-flavored release body. Perfect!
            final isDevChannel = Settings.getValue<bool>('key-dev-channel') ?? false;
            
            if (isDevChannel) {
              // For dev channel, get changelog from the latest pre-release
              final data = await http.get(Uri.parse(
                "https://api.github.com/repos/sivan22/otzaria/releases",
              ));
              final releases = jsonDecode(data.body) as List;
              final preRelease = releases.firstWhere(
                (release) => release["prerelease"] == true && 
                            release["draft"] == false &&
                            !release["tag_name"].toString().contains('-pr-'),
                orElse: () => releases.first,
              );
              return preRelease["body"];
            } else {
              // For stable channel, get changelog from latest stable release
              final data = await http.get(Uri.parse(
                "https://api.github.com/repos/sivan22/otzaria/releases/latest",
              ));
              return jsonDecode(data.body)["body"];
            }
          },
          currentVersion: snapshot.data!.version,
          updateChipBuilder: _flatChipAutoHideError,

          callback: (status) {},
          child: child,
        );
      });


}
