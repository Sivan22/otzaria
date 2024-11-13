import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive_io.dart';
import 'package:flutter_archive/flutter_archive.dart' as flutter_archive;
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
  bool _isCancelling = false;
  StreamSubscription? _downloadSubscription;
  IOSink? _fileSink;
  File? _tempFile;

  @override
  void dispose() {
    _speedTimer?.cancel();
    _downloadSubscription?.cancel();
    _fileSink?.close();
    _cleanupTempFile();
    super.dispose();
  }

  Future<void> _cleanupTempFile() async {
    if (_tempFile != null && await _tempFile!.exists()) {
      try {
        await _tempFile!.delete();
      } catch (e) {
        debugPrint('Error cleaning up temp file: $e');
      }
    }
  }

  Future<void> _cancelDownload() async {
    setState(() => _isCancelling = true);

    await _downloadSubscription?.cancel();
    await _fileSink?.close();
    _speedTimer?.cancel();

    await _cleanupTempFile();

    if (mounted) {
      setState(() {
        _isDownloading = false;
        _isCancelling = false;
        _currentOperation = '';
        _downloadProgress = 0;
        _downloadedMB = 0;
        _downloadSpeed = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ההורדה בוטלה')),
      );
    }
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

    try {
      final tempDir = await getApplicationDocumentsDirectory();
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }

      _tempFile = File('${tempDir.path}/temp_library.zip');
      if (await _tempFile!.exists()) {
        await _tempFile!.delete();
      }

      _lastDownloadedBytes = 0;
      _speedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        final bytesPerSecond =
            (_downloadedMB - _lastDownloadedBytes) * 1024 * 1024;
        setState(() {
          _downloadSpeed = bytesPerSecond / (1024 * 1024);
          _lastDownloadedBytes = _downloadedMB;
        });
      });

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

      _fileSink = _tempFile!.openWrite();
      final stream = response.stream;

      _downloadSubscription = stream.listen(
        (chunk) {
          if (_isCancelling) return;

          _fileSink?.add(chunk);
          receivedBytes += chunk.length;
          final downloadedMB = receivedBytes / (1024 * 1024);

          if (mounted) {
            setState(() {
              _downloadedMB = downloadedMB;
              _downloadProgress =
                  contentLength > 0 ? receivedBytes / contentLength : 0;
              _currentOperation =
                  'מוריד: ${downloadedMB.toStringAsFixed(2)} MB מתוך ${(contentLength / (1024 * 1024)).toStringAsFixed(2)} MB';
            });
          }
        },
        onDone: () async {
          if (_isCancelling) return;

          await _fileSink?.flush();
          await _fileSink?.close();
          _fileSink = null;

          await Future.delayed(const Duration(milliseconds: 500));

          if (!mounted) return;

          setState(() {
            _currentOperation = 'מחלץ קבצים...';
            _downloadProgress = 0;
          });

          try {
            if (!await _tempFile!.exists()) {
              throw Exception('קובץ הספרייה הזמני לא נמצא');
            }

            final fileSize = await _tempFile!.length();
            if (fileSize == 0) {
              throw Exception('קובץ הספרייה הזמני ריק');
            }

            Future<void> _extractWithArchive() async {
              // Create extractor with memory-efficient settings
              final extractor = ZipDecoder();
              final inputStream = InputFileStream(_tempFile!.path);
              final archive = extractor.decodeBuffer(inputStream);
              final totalFiles = archive.files.length;
              var extractedFiles = 0;

              // Process files one at a time using streaming
              for (final file in archive.files) {
                if (!mounted || _isCancelling) break;

                final filename = file.name;
                final filePath = '$libraryPath/$filename';

                setState(() {
                  _downloadProgress = extractedFiles / totalFiles;
                  _currentOperation = 'מחלץ: $filename';
                });

                try {
                  if (file.isFile) {
                    final outputFile = File(filePath);
                    await outputFile.parent.create(recursive: true);
                    final outputStream = OutputFileStream(outputFile.path);
                    file.writeContent(outputStream);
                    outputStream.close();
                  } else {
                    await Directory(filePath).create(recursive: true);
                  }
                  extractedFiles++;
                } catch (e) {
                  debugPrint('Error extracting $filename: $e');
                  throw Exception('שגיאה בחילוץ הקובץ $filename: $e');
                }
              }

              inputStream.close();
            }

            Future<void> _extractWithFlutterArchive() async {
              try {
                await flutter_archive.ZipFile.extractToDirectory(
                    zipFile: _tempFile!,
                    destinationDir: Directory(libraryPath),
                    onExtracting: (zipEntry, progress) {
                      setState(() {
                        _downloadProgress = progress;
                        _currentOperation = 'מחלץ: ${zipEntry.name}';
                      });
                      return flutter_archive.ZipFileOperation.includeItem;
                    });
              } catch (e) {
                print(e);
                throw Exception('שגיאה בחילוץ הקובץ: $e');
              }
            }

            if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
              await _extractWithFlutterArchive();
            } else {
              await _extractWithArchive();
            }
            await _cleanupTempFile();

            if (mounted && !_isCancelling) {
              widget.onLibraryLoaded();
              setState(() {
                _isDownloading = false;
                _currentOperation = '';
              });
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('שגיאה בחילוץ: $e')),
              );
              setState(() {
                _isDownloading = false;
                _currentOperation = '';
              });
            }
          }
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('שגיאה בהורדה: $error')),
            );
            setState(() {
              _isDownloading = false;
              _currentOperation = '';
            });
          }
        },
        cancelOnError: true,
      );
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
              if (Platform.isAndroid || Platform.isIOS)
                const Text(
                    'לא נמצאה ספרייה, יש להוריד את הספרייה - נדרש חיבור אינטרנט.\n גודל הורדה: 1200MB')
              else
                const Text(
                  'לא נמצאה ספרייה בנתיב המצוין',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              if (!Platform.isAndroid && !Platform.isIOS)
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
              if (!Platform.isAndroid && !Platform.isIOS)
                ElevatedButton(
                  onPressed: _isDownloading ? null : _pickDirectory,
                  child: const Text('בחר תיקייה'),
                ),
              const SizedBox(height: 32),
              if (!Platform.isAndroid || Platform.isIOS)
                const Text(
                  'או',
                  style: TextStyle(fontSize: 18),
                ),
              const SizedBox(height: 32),
              if (_isDownloading) ...[
                Column(
                  children: [
                    LinearProgressIndicator(value: _downloadProgress),
                    const SizedBox(height: 16),
                    Text(_currentOperation),
                    if (_downloadSpeed > 0)
                      Text(
                          'מהירות הורדה: ${_downloadSpeed.toStringAsFixed(2)} MB/s'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isCancelling ? null : _cancelDownload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.stop),
                      label: Text(_isCancelling ? 'מבטל...' : 'בטל הורדה'),
                    ),
                  ],
                ),
              ] else
                ElevatedButton(
                  onPressed: _downloadAndExtractLibrary,
                  child: const Text(' הורד את הספרייה מהאינטרנט'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
