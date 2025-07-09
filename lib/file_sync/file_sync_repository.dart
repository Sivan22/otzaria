import 'dart:convert';
import 'dart:io';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class FileSyncRepository {
  final String githubOwner;
  final String repositoryName;
  final String branch;
  final String manifestFileName;
  bool isSyncing = false;
  int _currentProgress = 0;
  int _totalFiles = 0;

  FileSyncRepository({
    required this.githubOwner,
    required this.repositoryName,
    this.branch = 'main',
    this.manifestFileName = 'files_manifest.json',
  });

  int get currentProgress => _currentProgress;
  int get totalFiles => _totalFiles;

  Future<String> get _basePath async =>
      Settings.getValue<String>('key-library-path') ?? 'C:/אוצריא';

  // --- שיפור 2: שימוש ב-path package לבדיקה אמינה ---
  Future<String> get _targetDir async {
    final base = await _basePath;
    // בדיקה חסינה לשגיאות: לא רגישה לאותיות גדולות/קטנות או לקו נטוי בסוף
    if (p.basename(base).toLowerCase() == 'אוצריא') {
      return base;
    }
    // --- שיפור 3: שימוש ב-path.join ליצירת נתיב תקני ---
    return p.join(base, 'אוצריא');
  }

  Future<String> get _localManifestPath async {
    // --- שיפור 3: שימוש ב-path.join ---
    return p.join(await _targetDir, manifestFileName);
  }

  Future<Map<String, dynamic>> _getLocalManifest() async {
    final path = await _localManifestPath;
    final file = File(path);
    try {
      if (!await file.exists()) {
        final oldFile = File('$path.old');
        if (await oldFile.exists()) {
          print('Main manifest missing, restoring from .old backup...');
          await oldFile.rename(path);
        } else {
          return {};
        }
      }
      final content = await file.readAsString(encoding: utf8);
      return json.decode(content);
    } catch (e) {
      print('Error reading local manifest: $e');
      final oldFile = File('$path.old');
      if (await oldFile.exists()) {
        try {
          print('Main manifest is corrupt, restoring from .old backup...');
          final backupContent = await oldFile.readAsString(encoding: utf8);
          await oldFile.rename(path);
          return json.decode(backupContent);
        } catch (_) {}
      }
      return {};
    }
  }

  Future<Map<String, dynamic>> _getRemoteManifest() async {
    final url = 'https://raw.githubusercontent.com/$githubOwner/$repositoryName/$branch/$manifestFileName';
    try {
      final response = await http.get(Uri.parse(url),
        headers: {'Accept': 'application/json', 'Accept-Charset': 'utf-8'});
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      throw Exception('Failed to fetch remote manifest');
    } catch (e) {
      print('Error fetching remote manifest: $e');
      rethrow;
    }
  }

  Future<bool> downloadFile(String filePath) async {
    // filePath מגיע מהמניפסט ומתחיל ב "דיקטה/..."

    // 1. הגדר את הקידומת האמיתית של הנתיב במאגר
    const String remotePathPrefix = 'DictaToOtzaria/ספרים/לא ערוך/';
    
    // 2. בנה את הנתיב המלא כפי שהוא קיים ב-GitHub
    // אנחנו מורידים את ה'דיקטה' מההתחלה כי הוא כבר חלק מהקידומת
    final String actualRemotePath = remotePathPrefix + filePath.replaceFirst('דיקטה/', '');

    // 3. נרמל את הנתיב לשימוש ב-URL (החלף \ ב-/)
    final urlPath = actualRemotePath.replaceAll('\\', '/');
    
    final url =
        'https://raw.githubusercontent.com/$githubOwner/$repositoryName/$branch/$urlPath';
        
    print('--> Downloading: $url');

    try {
      final response = await http
          .get(Uri.parse(url), headers: {'Accept-Charset': 'utf-8'});

      print('<-- Response Status: ${response.statusCode} for $urlPath');

      if (response.statusCode == 200) {
        // 4. שמור את הקובץ מקומית תחת הנתיב הקצר והיפה (filePath)
        final directory = await _targetDir;
        final file = File(p.join(directory, filePath)); // filePath הוא "דיקטה/אוצריא/..."

        await file.parent.create(recursive: true);

        if (filePath.endsWith('.txt') ||
            filePath.endsWith('.json') ||
            filePath.endsWith('.csv')) {
          await file.writeAsString(utf8.decode(response.bodyBytes),
              encoding: utf8);
        } else {
          await file.writeAsBytes(response.bodyBytes);
        }
        
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('!!! Network or File System Error for $urlPath: $e');
      return false;
    }
  }

  Future<void> _updateLocalManifestForFile(String filePath, Map<String, dynamic> fileInfo) async {
    try {
      Map<String, dynamic> localManifest = await _getLocalManifest();
      localManifest[filePath] = fileInfo;
      await _writeManifest(localManifest);
    } catch (e) {
      print('Error updating local manifest for file $filePath: $e');
    }
  }

  Future<void> _removeFromLocal(String filePath) async {
    try {
      final directory = await _targetDir;
      // --- שיפור 3: שימוש ב-path.join ---
      final file = File(p.join(directory, filePath));
      if (await file.exists()) {
        await file.delete();
      }      
      Map<String, dynamic> localManifest = await _getLocalManifest();
      localManifest.remove(filePath);
      await _writeManifest(localManifest);
    } catch (e) {
      print('Error removing file $filePath from local manifest: $e');
    }
  }

  Future<void> _writeManifest(Map<String, dynamic> manifest) async {
    final path = await _localManifestPath;
    final file = File(path);
    final tempFile = File('$path.tmp');
    final oldFile  = File('$path.old');

    try {
      // ודא שהתיקייה קיימת בריצה ראשונה
      await file.parent.create(recursive: true);

      // 1. כתיבה לקובץ זמני
      await tempFile.writeAsString(json.encode(manifest), encoding: utf8);

      // 2. גיבוי הקובץ הישן (אם יש)
      if (await file.exists()) {
        await file.rename(oldFile.path);
      }

      // 3. קידום הקובץ הזמני לשם הסופי (אטומי)
      await tempFile.rename(path);

      // 4. ניקוי הגיבוי אם הכול הצליח
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    } catch (e) {
      print('Error writing manifest: $e');

      // ניסיון לשחזר את הגיבוי במידה והקובץ החדש לא נוצר
      try {
        if (await oldFile.exists() && !(await file.exists())) {
          print('Attempting to restore manifest from .old backup...');
          await oldFile.rename(path);
        }
      } catch (restoreError) {
        print('FATAL: Could not restore manifest: $restoreError');
      }
      rethrow;
    }
  }

  Future<void> removeEmptyFolders() async {
    try {
      final targetDirPath = await _targetDir;
      final targetDir = Directory(targetDirPath);
      if (!await targetDir.exists()) return;
      
      await _cleanEmptyDirectories(targetDir, targetDirPath);
    } catch (e) {
      print('Error removing empty folders: $e');
    }
  }

  Future<void> _cleanEmptyDirectories(Directory dir, String rootPath) async {
    if (!await dir.exists()) return;

    await for (final entity in dir.list()) {
      if (entity is Directory) {
        await _cleanEmptyDirectories(entity, rootPath);
      }
    }

    final contents = await dir.list().toList();
    if (contents.isEmpty && p.equals(dir.path, rootPath) == false) { // שימוש ב-p.equals לבדיקה בטוחה
      await dir.delete();
      print('Removed empty directory: ${dir.path}');
    }
  }

  Future<List<String>> checkForUpdates() async {
    final localManifest = await _getLocalManifest();
    final remoteManifest = await _getRemoteManifest();

    final filesToUpdate = <String>[];
    remoteManifest.forEach((filePath, remoteInfo) {
      if (!localManifest.containsKey(filePath) || localManifest[filePath]['hash'] != remoteInfo['hash']) {
        filesToUpdate.add(filePath);
      }
    });
    return filesToUpdate;
  }

  Future<void> _migrateOldManifestIfNeeded() async {
    try {
      // --- שיפור 3: שימוש ב-path.join ---
      final oldManifestPath = p.join(await _basePath, manifestFileName);
      final newManifestPath = await _localManifestPath;

      final oldFile = File(oldManifestPath);
      final newFile = File(newManifestPath);

      if (await oldFile.exists() && !(await newFile.exists())) {
        print('Migrating old manifest to new location...');
        await newFile.parent.create(recursive: true);
        await oldFile.rename(newManifestPath);
        print('Migration successful.');
      }
    } catch (e) {
      print('Could not migrate old manifest: $e');
    }
  }

  Future<int> syncFiles() async {
    if (isSyncing) return 0;
    
    isSyncing = true;
    int count = 0;
    _currentProgress = 0;

    await _migrateOldManifestIfNeeded();

    try {
      final remoteManifest = await _getRemoteManifest();
      final localManifest = await _getLocalManifest();
      final filesToUpdate = await checkForUpdates();
      
      final filesToRemove = localManifest.keys.where((k) => !remoteManifest.containsKey(k)).toList();
      _totalFiles = filesToUpdate.length + filesToRemove.length;

      // --- לוגיקה חדשה בלולאה ---
      for (final filePath in filesToUpdate) {
        if (!isSyncing) return count;
        
        // קבל את תוצאת ההורדה
        final bool downloadedSuccessfully = await downloadFile(filePath);

        // עדכן את המניפסט והמונה רק אם ההורדה באמת הצליחה
        if (downloadedSuccessfully) {
          await _updateLocalManifestForFile(filePath, remoteManifest[filePath]);
          count++;
          _currentProgress = count;
        }
        // אם ההורדה נכשלה, לא נעשה כלום. המניפסט לא יתעדכן,
        // והמערכת תנסה להוריד את הקובץ שוב בסנכרון הבא.
      }

      for (final localFilePath in filesToRemove) {
        if (!isSyncing) return count;
        await _removeFromLocal(localFilePath);
        // הערה: כאן המונה יכול להתקדם גם אם המחיקה לא הצליחה, זה פחות קריטי
        count++;
        _currentProgress = count;
      }
      
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