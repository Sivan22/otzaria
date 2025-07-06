import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher_string.dart';

class OtzarUtils {
  static final List<String> _availableDrives = [
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z'
  ];

  static Future<bool> checkBookExistence(int bookId) async {
    for (final drive in _availableDrives) {
      try {
        //newer version teh path is under the /books folder with the extension .book
        final bookPath = '$drive:\\books\\$bookId.book';
        final bookFile = File(bookPath);
        if (await bookFile.exists()) {
          return true;
        }

        final zipPath = '$drive:\\zip';
        final zipDir = Directory(zipPath);
        if (await zipDir.exists()) {
          final bookPath = '$zipPath\\$bookId.ocd';
          final bookFile = File(bookPath);
          if (await bookFile.exists()) {
            return true;
          }
        }
      } catch (e) {
        // Continue to the next possible drive if there's an error (e.g., drive doesn't exist)
        continue;
      }
    }
    print('Book $bookId not found in any "<drive>" <book> folder');
    return false;
  }

  static Future<(String, bool)> findOtzarExePath() async {
    final String? otzarPath = Platform.environment['OTZARAPPCD'];
    if (otzarPath != null) {
      final String exePath = '$otzarPath\\otzar.exe';
      if (await File(exePath).exists()) {
        return (exePath, true); // true indicates version 18 and above
      }
    }

    // Check for older versions
    const String oldPath = 'C:\\OTZAR\\otzar.exe';
    if (await File(oldPath).exists()) {
      return (oldPath, false); // false indicates version < 18
    }

    return ('', false); // Not found
  }

  static Future<bool> canLaunchLocally() async {
    if (!Platform.isWindows) return false;
    final (exePath, _) = await findOtzarExePath();
    return exePath.isNotEmpty;
  }

  static Future<void> launchOtzarLocal(int bookId) async {
    final (exePath, isVersion18OrAbove) = await findOtzarExePath();
    if (exePath.isEmpty) {
      throw Exception('Otzar.exe not found');
    }

    final tabId = Random().nextInt(1000000); // Random tab ID
    final String bookLink =
        'OtzarBook://book/$bookId/p/1/t/$tabId/fs/0/start/0/end/0 /c';
    List<String> arguments = isVersion18OrAbove ? ['BOOK=$bookLink'] : [];

    final workingDir = path.dirname(exePath);

    try {
      if (isVersion18OrAbove) {
        // Try running with full path
        final result = await Process.run(
          exePath,
          arguments,
          workingDirectory: workingDir,
        );

        if (result.exitCode != 0) {
          // If failed, try running through cmd
          final cmdResult = await Process.run(
            'cmd',
            ['/c', 'start', '', exePath, ...arguments],
            workingDirectory: workingDir,
          );

          if (cmdResult.exitCode != 0) {
            throw Exception(
                'otzar.exe exited with non-zero code: ${cmdResult.exitCode}\nError: ${cmdResult.stderr}');
          }
        }
      } else {
        Process.run(exePath, []);

        if (await checkBookExistence(bookId)) {
          await Future.delayed(
            const Duration(seconds: 5),
            () => Process.run(
              "c:\\OTZAR\\view.exe",
              ['$bookId', 'DtnOzrV'],
            ),
          );
        } else {
          throw Exception('Book $bookId not found in any /zip folder');
        }
      }
    } catch (e) {
      throw Exception('Failed to launch Otzar: $e');
    }
  }

  static Future<bool> launchOtzarWeb(String url) async {
    return await canLaunchUrlString(url) && await launchUrlString(url);
  }
}
