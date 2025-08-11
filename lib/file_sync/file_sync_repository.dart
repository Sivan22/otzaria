import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:http/http.dart' as http;

class FileSyncRepository {
  final String githubOwner;
  final String repositoryName;
  final String branch;
  bool isSyncing = false;
  int _currentProgress = 0;
  int _totalFiles = 0;

  FileSyncRepository({
    required this.githubOwner,
    required this.repositoryName,
    this.branch = 'main',
  });

  int get currentProgress => _currentProgress;
  int get totalFiles => _totalFiles;

  Future<String> get _localManifestPath async {
    final directory = _localDirectory;
    return '${await directory}${Platform.pathSeparator}files_manifest.json';
  }

  Future<String> get _localDirectory async {
    return Settings.getValue('key-library-path') ?? 'C:/אוצריא';
  }

  Future<Map<String, dynamic>> _getLocalManifest() async {
    final path = await _localManifestPath;
    final file = File(path);
    try {
      if (!await file.exists()) {
        // ---- תוספת חשובה ---- //
        // אם הקובץ הראשי לא קיים, בדוק אם נשאר גיבוי מתהליך שנכשל
        final oldFile = File('$path.old');
        if (await oldFile.exists()) {
          print('Main manifest missing, restoring from .old backup...');
          await oldFile.rename(path); // שחזר את הגיבוי
          // עכשיו הקובץ הראשי קיים, נמשיך כרגיל
        } else {
          return {}; // אם גם גיבוי אין, באמת אין מניפסט
        }
      }
      final content = await file.readAsString(encoding: utf8);
      return await Isolate.run(() => json.decode(content));
    } catch (e) {
      print('Error reading local manifest: $e');
      // הלוגיקה שלך לגיבוי מ-.bak הייתה טובה, נתאים אותה ל-.old
      final oldFile = File('$path.old'); // השתמש ב-.old במקום .bak
      if (await oldFile.exists()) {
        try {
          print('Main manifest is corrupt, restoring from .old backup...');
          final backupContent = await oldFile.readAsString(encoding: utf8);
          await oldFile.rename(path); // rename בטוח יותר מ-copy
          return await Isolate.run(() => json.decode(backupContent));
        } catch (_) {}
      }
      return {};
    }
  }

  Future<Map<String, dynamic>> _getRemoteManifest() async {
    final url =
        'https://raw.githubusercontent.com/$githubOwner/$repositoryName/$branch/files_manifest.json';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Accept-Charset': 'utf-8',
        },
      );
      if (response.statusCode == 200) {
        // Explicitly decode as UTF-8
        return json.decode(utf8.decode(response.bodyBytes));
      }
      throw Exception('Failed to fetch remote manifest');
    } catch (e) {
      print('Error fetching remote manifest: $e');
      rethrow;
    }
  }

  Future<void> downloadFile(String filePath) async {
    final url =
        'https://raw.githubusercontent.com/$githubOwner/$repositoryName/$branch/$filePath';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept-Charset': 'utf-8',
        },
      );
      if (response.statusCode == 200) {
        final directory = await _localDirectory;
        final file = File('$directory/$filePath');

        // Create directories if they don't exist
        await file.parent.create(recursive: true);

        // For text files, handle UTF-8 encoding explicitly
        if (filePath.endsWith('.txt') ||
            filePath.endsWith('.json') ||
            filePath.endsWith('.csv')) {
          await file.writeAsString(utf8.decode(response.bodyBytes),
              encoding: utf8);
        } else {
          // For binary files, write bytes directly
          await file.writeAsBytes(response.bodyBytes);
        }
      }
    } catch (e) {
      print('Error downloading file $filePath: $e');
    }
  }

  Future<void> _writeManifest(Map<String, dynamic> manifest) async {
    final path = await _localManifestPath;
    final file = File(path);
    final tempFile = File('$path.tmp');
    // נשתמש ב- .old כפי שהוצע, זה עקבי וברור
    final oldFile = File('$path.old');

    try {
      // 1. כותבים את המידע החדש לקובץ זמני.
      // אם שלב זה נכשל, שום דבר לא קרה לקובץ המקורי.
      await tempFile.writeAsString(
        json.encode(manifest),
        encoding: utf8,
      );

      // 2. אם הקובץ המקורי קיים, שנה את שמו לגיבוי.
      // זו פעולה אטומית ומהירה. אם היא נכשלת, לא קרה כלום.
      // אם היא מצליחה, המניפסט הישן בטוח בצד.
      if (await file.exists()) {
        await file.rename(oldFile.path);
      }

      // 3. שנה את שם הקובץ הזמני לשם הקובץ הסופי.
      // גם זו פעולה אטומית. אם היא נכשלת, המניפסט הישן עדיין קיים ב- .old
      // וניתן לשחזר אותו.
      await tempFile.rename(path);

      // 4. אם הגענו לכאן, הכל הצליח. אפשר למחוק בבטחה את הגיבוי.
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    } catch (e) {
      print('Error writing manifest: $e');
      // במקרה של תקלה (למשל, אחרי ש-file.rename הצליח אבל tempFile.rename נכשל),
      // ננסה לשחזר את המצב לקדמותו כדי למנוע מצב ללא מניפסט.
      try {
        if (await oldFile.exists() && !(await file.exists())) {
          print('Attempting to restore manifest from .old backup...');
          await oldFile.rename(path);
        }
      } catch (restoreError) {
        print('FATAL: Could not restore manifest from backup: $restoreError');
      }
      rethrow; // זרוק את השגיאה המקורית כדי שהפונקציה שקראה תדע שהעדכון נכשל.
    }
  }

  Future<void> _updateLocalManifestForFile(
      String filePath, Map<String, dynamic> fileInfo) async {
    try {
      Map<String, dynamic> localManifest = await _getLocalManifest();

      // Update the manifest for this specific file
      localManifest[filePath] = fileInfo;

      await _writeManifest(localManifest);
    } catch (e) {
      print('Error updating local manifest for file $filePath: $e');
    }
  }

  Future<void> _removeFromLocal(String filePath) async {
    try {
      // Try to remove the actual file if it exists
      final directory = await _localDirectory;
      final file = File('$directory/$filePath');
      if (await file.exists()) {
        await file.delete();
      }

      //if successful, remove from manifest
      Map<String, dynamic> localManifest = await _getLocalManifest();

      // Remove the file from the manifest
      localManifest.remove(filePath);

      await _writeManifest(localManifest);
    } catch (e) {
      print('Error removing file $filePath from local manifest: $e');
    }
  }

  Future<void> removeEmptyFolders() async {
    try {
      final baseDir = Directory(await _localDirectory);
      if (!await baseDir.exists()) return;

      // Bottom-up approach: process deeper directories first
      await _cleanEmptyDirectories(baseDir);
    } catch (e) {
      print('Error removing empty folders: $e');
    }
  }

  Future<void> _cleanEmptyDirectories(Directory dir) async {
    if (!await dir.exists()) return;

    // First process all subdirectories
    await for (final entity in dir.list()) {
      if (entity is Directory) {
        await _cleanEmptyDirectories(entity);
      }
    }

    // After cleaning subdirectories, check if this directory is now empty
    final contents = await dir.list().toList();
    final baseDir = await _localDirectory;
    if (contents.isEmpty && dir.path != baseDir) {
      await dir.delete();
      print('Removed empty directory: ${dir.path}');
    }
  }

  Future<List<String>> checkForUpdates() async {
    final localManifest = await _getLocalManifest();
    final remoteManifest = await _getRemoteManifest();

    final filesToUpdate = <String>[];

    remoteManifest.forEach((filePath, remoteInfo) {
      if (!localManifest.containsKey(filePath) ||
          localManifest[filePath]['hash'] != remoteInfo['hash']) {
        filesToUpdate.add(filePath);
      }
    });

    return filesToUpdate;
  }

  Future<int> syncFiles() async {
    if (isSyncing) {
      return 0;
    }
    isSyncing = true;
    int count = 0;
    _currentProgress = 0;

    try {
      final remoteManifest = await _getRemoteManifest();
      final localManifest = await _getLocalManifest();

      // Find files to update or add
      final filesToUpdate = await checkForUpdates();
      _totalFiles = filesToUpdate.length;

      // Download and update manifest for each file individually
      for (final filePath in filesToUpdate) {
        if (isSyncing == false) {
          return count;
        }
        await downloadFile(filePath);
        await _updateLocalManifestForFile(filePath, remoteManifest[filePath]);
        count++;
        _currentProgress = count;
      }

      // Remove files that exist locally but not in remote
      for (final localFilePath in localManifest.keys.toList()) {
        if (isSyncing == false) {
          return count;
        }
        if (!remoteManifest.containsKey(localFilePath)) {
          await _removeFromLocal(localFilePath);
          count++;
          _currentProgress = count;
        }
      }
      // Clean up empty folders after sync
      await removeEmptyFolders();
    } catch (e) {
      isSyncing = false;
      rethrow;
    }

    isSyncing = false;
    return count;
  }

  Future<void> stopSyncing() async {
    isSyncing = false;
  }
}
