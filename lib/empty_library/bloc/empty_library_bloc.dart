import 'dart:async';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_archive/flutter_archive.dart' as flutter_archive;
import 'package:flutter_document_picker/flutter_document_picker.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:otzaria/empty_library/bloc/empty_library_event.dart';
import 'package:otzaria/empty_library/bloc/empty_library_state.dart';

class EmptyLibraryBloc extends Bloc<EmptyLibraryEvent, EmptyLibraryState> {
  StreamSubscription? _downloadSubscription;
  IOSink? _fileSink;
  File? _tempFile;
  Timer? _speedTimer;
  double _lastDownloadedBytes = 0;
  bool _isCancelling = false;

  EmptyLibraryBloc() : super(EmptyLibraryInitial()) {
    on<DownloadLibraryRequested>(_onDownloadLibraryRequested);
    on<PickDirectoryRequested>(_onPickDirectoryRequested);
    on<PickAndExtractZipRequested>(_onPickAndExtractZipRequested);
    on<CancelDownloadRequested>(_onCancelDownloadRequested);
    on<DownloadProgressUpdated>(_onDownloadProgressUpdated);
  }

  @override
  Future<void> close() async {
    _speedTimer?.cancel();
    _downloadSubscription?.cancel();
    _fileSink?.close();
    await _cleanupTempFile();
    return super.close();
  }

  Future<void> _cleanupTempFile() async {
    if (_tempFile != null && await _tempFile!.exists()) {
      try {
        await _tempFile!.delete();
      } catch (e) {
        print('Error cleaning up temp file: $e');
      }
    }
  }

  Future<void> _onCancelDownloadRequested(
      CancelDownloadRequested event, Emitter<EmptyLibraryState> emit) async {
    _isCancelling = true;
    emit(const EmptyLibraryLoading(isCancelling: true));

    await _downloadSubscription?.cancel();
    await _fileSink?.close();
    _speedTimer?.cancel();

    await _cleanupTempFile();
    _isCancelling = false;

    emit(EmptyLibraryInitial());
  }

  Future<void> _onPickAndExtractZipRequested(
      PickAndExtractZipRequested event, Emitter<EmptyLibraryState> emit) async {
    final libraryPath = Settings.getValue<String>('key-library-path') ?? '';
    if (libraryPath.isEmpty) {
      emit(const EmptyLibraryError(errorMessage: 'נא לבחור תיקייה תחילה'));
      return;
    }

    emit(const EmptyLibraryLoading(
        isDownloading: true,
        currentOperation: 'פותח קובץ...',
        downloadProgress: 0));

    try {
      final path = await FlutterDocumentPicker.openDocument(
        params: FlutterDocumentPickerParams(
          allowedFileExtensions: ['zip'],
          invalidFileNameSymbols: ['/'],
        ),
      );

      if (path == null) {
        emit(EmptyLibraryInitial());
        return;
      }

      final zipFile = File(path);

      try {
        await flutter_archive.ZipFile.extractToDirectory(
          zipFile: zipFile,
          destinationDir: Directory(libraryPath),
          onExtracting: (zipEntry, progress) {
            add(DownloadProgressUpdated(
                progress: progress,
                currentOperation: 'מחלץ: ${zipEntry.name}',
                downloadedMB: 0,
                downloadSpeed: 0));
            return flutter_archive.ZipFileOperation.includeItem;
          },
        );

        emit(EmptyLibraryDownloaded());
      } catch (e) {
        emit(EmptyLibraryError(errorMessage: 'שגיאה בחילוץ: $e'));
      }
    } catch (e) {
      emit(EmptyLibraryError(errorMessage: 'שגיאה בבחירת הקובץ: $e'));
    }
  }

  Future<void> _onDownloadLibraryRequested(
      DownloadLibraryRequested event, Emitter<EmptyLibraryState> emit) async {
    if (state.isDownloading) return;

    emit(const EmptyLibraryLoading(
        isDownloading: true,
        downloadProgress: 0,
        downloadedMB: 0,
        downloadSpeed: 0,
        currentOperation: 'מתחיל הורדה...'));

    final libraryPath = Settings.getValue<String>('key-library-path') ?? '';
    if (libraryPath.isEmpty) {
      emit(const EmptyLibraryError(errorMessage: 'נא לבחור תיקייה תחילה'));
      emit(EmptyLibraryInitial());
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
        if (!_isCancelling) {
          final bytesPerSecond =
              (state.downloadedMB - _lastDownloadedBytes) * 1024 * 1024;
          if (!_isCancelling) {
            add(DownloadProgressUpdated(
                progress: state.downloadProgress,
                currentOperation: state.currentOperation,
                downloadedMB: state.downloadedMB,
                downloadSpeed: bytesPerSecond / (1024 * 1024)));
          }
          _lastDownloadedBytes = state.downloadedMB;
        }
      });

      final request = http.Request(
        'GET',
        Uri.parse(
            'https://github.com/zevisvei/otzaria-library/releases/download/latest/otzaria_latest.zip'),
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

          add(DownloadProgressUpdated(
              progress: contentLength > 0 ? receivedBytes / contentLength : 0,
              currentOperation:
                  'מוריד: ${downloadedMB.toStringAsFixed(2)} MB מתוך ${(contentLength / (1024 * 1024)).toStringAsFixed(2)} MB',
              downloadedMB: downloadedMB,
              downloadSpeed: state.downloadSpeed));
        },
        onDone: () async {
          if (_isCancelling) return;

          await _fileSink?.flush();
          await _fileSink?.close();
          _fileSink = null;

          await Future.delayed(const Duration(milliseconds: 500));

          emit(EmptyLibraryLoading(
              isDownloading: true,
              currentOperation: 'מחלץ קבצים...',
              downloadProgress: 0,
              downloadedMB: state.downloadedMB,
              downloadSpeed: state.downloadSpeed));

          try {
            if (!await _tempFile!.exists()) {
              throw Exception('קובץ הספרייה הזמני לא נמצא');
            }

            final fileSize = await _tempFile!.length();
            if (fileSize == 0) {
              throw Exception('קובץ הספרייה הזמני ריק');
            }

            Future<void> extractWithArchive() async {
              // Create extractor with memory-efficient settings
              final extractor = ZipDecoder();
              final inputStream = InputFileStream(_tempFile!.path);
              final archive = extractor.decodeBuffer(inputStream);
              final totalFiles = archive.files.length;
              var extractedFiles = 0;

              // Process files one at a time using streaming
              for (final file in archive.files) {
                if (!_isCancelling) {
                  final filename = file.name;
                  final filePath = '$libraryPath/$filename';

                  add(DownloadProgressUpdated(
                      progress: extractedFiles / totalFiles,
                      currentOperation: 'מחלץ: $filename',
                      downloadedMB: state.downloadedMB,
                      downloadSpeed: state.downloadSpeed));

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
                    print('Error extracting $filename: $e');
                    throw Exception('שגיאה בחילוץ הקובץ $filename: $e');
                  }
                }
              }

              inputStream.close();
            }

            Future<void> extractWithFlutterArchive() async {
              try {
                await flutter_archive.ZipFile.extractToDirectory(
                    zipFile: _tempFile!,
                    destinationDir: Directory(libraryPath),
                    onExtracting: (zipEntry, progress) {
                      add(DownloadProgressUpdated(
                          progress: progress,
                          currentOperation: 'מחלץ: ${zipEntry.name}',
                          downloadedMB: state.downloadedMB,
                          downloadSpeed: state.downloadSpeed));
                      return flutter_archive.ZipFileOperation.includeItem;
                    });
              } catch (e) {
                print(e);
                throw Exception('שגיאה בחילוץ הקובץ: $e');
              }
            }

            if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
              await extractWithFlutterArchive();
            } else {
              await extractWithArchive();
            }
            await _cleanupTempFile();

            emit(EmptyLibraryDownloaded());
          } catch (e) {
            emit(EmptyLibraryError(errorMessage: 'שגיאה בחילוץ: $e'));
          }
        },
        onError: (error) {
          emit(EmptyLibraryError(errorMessage: 'שגיאה בהורדה: $error'));
        },
        cancelOnError: true,
      );
    } catch (e) {
      emit(EmptyLibraryError(errorMessage: 'שגיאה: $e'));
    }
  }

  void _onDownloadProgressUpdated(
      DownloadProgressUpdated event, Emitter<EmptyLibraryState> emit) {
    emit(EmptyLibraryLoading(
        isDownloading: true,
        downloadProgress: event.progress,
        downloadedMB: event.downloadedMB,
        downloadSpeed: event.downloadSpeed,
        currentOperation: event.currentOperation,
        isCancelling: _isCancelling));
  }

  Future<void> _onPickDirectoryRequested(
      PickDirectoryRequested event, Emitter<EmptyLibraryState> emit) async {
    Future<String?> selectedDirectoryFuture =
        FilePicker.platform.getDirectoryPath();
    String? selectedDirectory = await selectedDirectoryFuture;

    if (selectedDirectory == null) {
      return;
    }

    emit(EmptyLibraryLoading(
        isDownloading: false,
        selectedPath: selectedDirectory,
        downloadProgress: 0,
        downloadedMB: 0,
        downloadSpeed: 0,
        currentOperation: ''));
    Settings.setValue('key-library-path', selectedDirectory);
    emit(
        EmptyLibraryDownloaded()); // Or maybe a different state like DirectorySelected?
  }
}
