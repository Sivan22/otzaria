import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';

class EmptyLibraryScreen extends StatefulWidget {
  final VoidCallback onLibraryLoaded;

  const EmptyLibraryScreen({Key? key, required this.onLibraryLoaded})
      : super(key: key);

  @override
  State<EmptyLibraryScreen> createState() => _EmptyLibraryScreenState();
}

class _EmptyLibraryScreenState extends State<EmptyLibraryScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String? _selectedPath;
  double _downloadedMB = 0;
  double _downloadSpeed = 0;
  String _currentOperation = '';
  Timer? _speedTimer;
  double _lastDownloadedBytes = 0;

  @override
  void dispose() {
    _speedTimer?.cancel();
    super.dispose();
  }

  Future<void> _downloadAndExtractLibrary() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _downloadedMB = 0;
      _downloadSpeed = 0;
      _currentOperation = 'מתחיל הורדה...';
    });

    final libraryPath = Settings.getValue<String>('key-library-path') ?? '';
    if (libraryPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא לבחור תיקייה תחילה')),
      );
      setState(() => _isDownloading = false);
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_library.zip');

    try {
      // Start speed calculation timer
      _lastDownloadedBytes = 0;
      _speedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        final bytesPerSecond =
            (_downloadedMB - _lastDownloadedBytes) * 1024 * 1024;
        setState(() {
          _downloadSpeed = bytesPerSecond / (1024 * 1024); // Convert to MB/s
          _lastDownloadedBytes = _downloadedMB;
        });
      });

      // Initialize the download
      final request = http.Request(
        'GET',
        Uri.parse(
            'https://github.com/Sivan22/otzaria-library/releases/download/latest/otzaria_latest.zip'),
      );
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to start download: ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      var receivedBytes = 0;

      // Create file and prepare for writing
      final sink = tempFile.openWrite();
      final stream = response.stream;

      // Download with progress
      await for (final chunk in stream) {
        if (!mounted) break;

        sink.add(chunk);
        receivedBytes += chunk.length;
        final downloadedMB = receivedBytes / (1024 * 1024);

        setState(() {
          _downloadedMB = downloadedMB;
          _downloadProgress =
              contentLength > 0 ? receivedBytes / contentLength : 0;
          _currentOperation = 'מוריד: ${downloadedMB.toStringAsFixed(2)} MB';
        });
      }

      await sink.flush();
      await sink.close();

      // Start extraction
      setState(() {
        _currentOperation = 'מחלץ קבצים...';
        _downloadProgress = 0;
      });

      // Read the zip file
      final bytes = await tempFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final totalFiles = archive.files.length;

      // Extract files
      for (var i = 0; i < archive.files.length; i++) {
        if (!mounted) break;

        final file = archive.files[i];
        final filename = file.name;
        final filePath = '$libraryPath/$filename';

        setState(() {
          _downloadProgress = i / totalFiles;
          _currentOperation = 'מחלץ: $filename';
        });

        if (file.isFile) {
          final outputFile = File(filePath);
          await outputFile.parent.create(recursive: true);
          await outputFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filePath).create(recursive: true);
        }
      }

      // Cleanup
      await tempFile.delete();

      if (mounted) {
        widget.onLibraryLoaded();
        setState(() {
          _isDownloading = false;
          _currentOperation = '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e')),
        );
        setState(() {
          _isDownloading = false;
          _currentOperation = '';
        });
      }
    } finally {
      _speedTimer?.cancel();
      if (tempFile.existsSync()) {
        await tempFile.delete();
      }
    }
  }

  Future<void> _pickDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory == null || !mounted) {
      return;
    }

    setState(() {
      _selectedPath = selectedDirectory;
    });

    final directory = Directory(selectedDirectory);
    if (!directory.existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('נתיב לא חוקי')),
        );
      }
      return;
    }

    Settings.setValue('key-library-path', selectedDirectory);
    widget.onLibraryLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'לא נמצאה ספרייה בנתיב המצוין',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_selectedPath != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _selectedPath!,
                    style: const TextStyle(fontSize: 16),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: _isDownloading ? null : _pickDirectory,
                child: const Text('בחר תיקייה'),
              ),
              const SizedBox(height: 32),
              const Text(
                'או',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 32),
              if (_isDownloading)
                Column(
                  children: [
                    LinearProgressIndicator(value: _downloadProgress),
                    const SizedBox(height: 16),
                    Text(_currentOperation),
                    if (_downloadSpeed > 0)
                      Text(
                          'מהירות הורדה: ${_downloadSpeed.toStringAsFixed(2)} MB/s'),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: _downloadAndExtractLibrary,
                  child: const Text('הורד את הספרייה מהאינטרנט'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
