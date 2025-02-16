import 'dart:convert';
import 'dart:io';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:http/http.dart' as http;

class FileSyncService {
  final String githubOwner;
  final String repositoryName;
  final String branch;
  bool isSyncing = false;
  int _currentProgress = 0;
  int _totalFiles = 0;

  FileSyncService({
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
    try {
      final file = File(await _localManifestPath);
      if (!await file.exists()) {
        return {};
      }
      final content = await file.readAsString(encoding: utf8);
      return json.decode(content);
    } catch (e) {
      print('Error reading local manifest: $e');
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

  Future<void> _updateLocalManifestForFile(
      String filePath, Map<String, dynamic> fileInfo) async {
    try {
      final manifestFile = File(await _localManifestPath);
      Map<String, dynamic> localManifest = await _getLocalManifest();

      // Update the manifest for this specific file
      localManifest[filePath] = fileInfo;

      // Write the updated manifest back to disk with UTF-8 encoding
      await manifestFile.writeAsString(
        json.encode(localManifest),
        encoding: utf8,
      );
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
      final manifestFile = File(await _localManifestPath);
      Map<String, dynamic> localManifest = await _getLocalManifest();

      // Remove the file from the manifest
      localManifest.remove(filePath);

      // Write the updated manifest back to disk with UTF-8 encoding
      await manifestFile.writeAsString(
        json.encode(localManifest),
        encoding: utf8,
      );
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
