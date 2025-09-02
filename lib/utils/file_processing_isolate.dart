import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:otzaria/utils/isolate_manager.dart';
import 'package:otzaria/utils/text_manipulation.dart';

/// סוגי הודעות לעיבוד קבצים
abstract class FileMessage {}

class ReadFileMessage extends FileMessage {
  final String filePath;
  final String? encoding;
  
  ReadFileMessage({
    required this.filePath,
    this.encoding = 'utf8',
  });
}

class WriteFileMessage extends FileMessage {
  final String filePath;
  final String content;
  final FileMode mode;
  
  WriteFileMessage({
    required this.filePath,
    required this.content,
    this.mode = FileMode.write,
  });
}

class ParseJsonMessage extends FileMessage {
  final String jsonString;
  
  ParseJsonMessage({required this.jsonString});
}

class EncodeJsonMessage extends FileMessage {
  final dynamic object;
  final bool pretty;
  
  EncodeJsonMessage({
    required this.object,
    this.pretty = false,
  });
}

class ProcessTextMessage extends FileMessage {
  final String text;
  final List<TextOperation> operations;
  
  ProcessTextMessage({
    required this.text,
    required this.operations,
  });
}

class ParseTocMessage extends FileMessage {
  final String bookContent;
  
  ParseTocMessage({required this.bookContent});
}

/// פעולות עיבוד טקסט
enum TextOperation {
  stripHtml,
  removeVowels,
  removeSectionNames,
  replaceParaphrases,
}

/// תוצאות עיבוד קבצים
class FileResult<T> {
  final T? data;
  final String? error;
  final bool success;
  
  FileResult({
    this.data,
    this.error,
  }) : success = error == null;
}

/// שירות עיבוד קבצים ב-Isolate
class FileProcessingIsolate {
  static IsolateHandler? _isolateHandler;
  
  /// אתחול ה-Isolate
  static Future<void> initialize() async {
    _isolateHandler ??= await IsolateManager.getOrCreate(
      'file_processing',
      _fileProcessingEntry,
    );
  }
  
  /// קריאת קובץ טקסט
  static Future<FileResult<String>> readFile(String filePath, {String encoding = 'utf8'}) async {
    await initialize();
    return await _isolateHandler!.compute<FileResult<String>>(
      ReadFileMessage(filePath: filePath, encoding: encoding),
    );
  }
  
  /// כתיבת קובץ טקסט
  static Future<FileResult<bool>> writeFile(
    String filePath,
    String content, {
    FileMode mode = FileMode.write,
  }) async {
    await initialize();
    return await _isolateHandler!.compute<FileResult<bool>>(
      WriteFileMessage(
        filePath: filePath,
        content: content,
        mode: mode,
      ),
    );
  }
  
  /// פענוח JSON
  static Future<FileResult<dynamic>> parseJson(String jsonString) async {
    await initialize();
    return await _isolateHandler!.compute<FileResult<dynamic>>(
      ParseJsonMessage(jsonString: jsonString),
    );
  }
  
  /// קידוד JSON
  static Future<FileResult<String>> encodeJson(dynamic object, {bool pretty = false}) async {
    await initialize();
    return await _isolateHandler!.compute<FileResult<String>>(
      EncodeJsonMessage(object: object, pretty: pretty),
    );
  }
  
  /// עיבוד טקסט עם פעולות שונות
  static Future<FileResult<String>> processText(
    String text,
    List<TextOperation> operations,
  ) async {
    await initialize();
    return await _isolateHandler!.compute<FileResult<String>>(
      ProcessTextMessage(text: text, operations: operations),
    );
  }
  
  /// פענוח תוכן עניינים
  static Future<FileResult<List<TocEntry>>> parseToc(String bookContent) async {
    await initialize();
    return await _isolateHandler!.compute<FileResult<List<TocEntry>>>(
      ParseTocMessage(bookContent: bookContent),
    );
  }
  
  /// שחרור ה-Isolate
  static Future<void> dispose() async {
    if (_isolateHandler != null) {
      await IsolateManager.kill('file_processing');
      _isolateHandler = null;
    }
  }
}

/// נקודת כניסה ל-Isolate של עיבוד קבצים
void _fileProcessingEntry(IsolateContext context) {
  // האזנה להודעות
  context.messages.listen((message) async {
    try {
      if (message is ReadFileMessage) {
        // קריאת קובץ
        final file = File(message.filePath);
        
        if (!await file.exists()) {
          context.send(FileResult<String>(
            error: 'File not found: ${message.filePath}',
          ));
          return;
        }
        
        String content;
        if (message.encoding == 'utf8') {
          content = await file.readAsString(encoding: utf8);
        } else {
          content = await file.readAsString();
        }
        
        context.send(FileResult<String>(data: content));
        
      } else if (message is WriteFileMessage) {
        // כתיבת קובץ
        final file = File(message.filePath);
        
        // יצירת תיקייה אם לא קיימת
        final directory = file.parent;
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        
        await file.writeAsString(
          message.content,
          mode: message.mode,
          encoding: utf8,
        );
        
        context.send(FileResult<bool>(data: true));
        
      } else if (message is ParseJsonMessage) {
        // פענוח JSON
        final parsed = jsonDecode(message.jsonString);
        context.send(FileResult<dynamic>(data: parsed));
        
      } else if (message is EncodeJsonMessage) {
        // קידוד JSON
        String encoded;
        if (message.pretty) {
          const encoder = JsonEncoder.withIndent('  ');
          encoded = encoder.convert(message.object);
        } else {
          encoded = jsonEncode(message.object);
        }
        
        context.send(FileResult<String>(data: encoded));
        
      } else if (message is ProcessTextMessage) {
        // עיבוד טקסט
        String result = message.text;
        
        for (final operation in message.operations) {
          switch (operation) {
            case TextOperation.stripHtml:
              result = stripHtmlIfNeeded(result);
              break;
            case TextOperation.removeVowels:
              result = removeVolwels(result);
              break;
            case TextOperation.removeSectionNames:
              result = removeSectionNames(result);
              break;
            case TextOperation.replaceParaphrases:
              result = replaceParaphrases(result);
              break;
          }
        }
        
        context.send(FileResult<String>(data: result));
        
      } else if (message is ParseTocMessage) {
        // פענוח תוכן עניינים
        final toc = _parseTocInIsolate(message.bookContent);
        context.send(FileResult<List<TocEntry>>(data: toc));
      }
    } catch (e) {
      // שליחת שגיאה
      if (message is ReadFileMessage) {
        context.send(FileResult<String>(error: e.toString()));
      } else if (message is WriteFileMessage) {
        context.send(FileResult<bool>(error: e.toString()));
      } else if (message is ParseJsonMessage) {
        context.send(FileResult<dynamic>(error: e.toString()));
      } else if (message is EncodeJsonMessage) {
        context.send(FileResult<String>(error: e.toString()));
      } else if (message is ProcessTextMessage) {
        context.send(FileResult<String>(error: e.toString()));
      } else if (message is ParseTocMessage) {
        context.send(FileResult<List<TocEntry>>(error: e.toString()));
      }
    }
  });
}

/// פענוח תוכן עניינים בתוך ה-Isolate
List<TocEntry> _parseTocInIsolate(String bookContent) {
  List<String> lines = bookContent.split('\n');
  List<TocEntry> toc = [];
  Map<int, TocEntry> parents = {};
  
  for (int i = 0; i < lines.length; i++) {
    final String line = lines[i];
    if (line.startsWith('<h')) {
      final int level = int.parse(line[2]);
      final String text = stripHtmlIfNeeded(line);
      
      if (level == 1) {
        TocEntry entry = TocEntry(text: text, index: i, level: level);
        toc.add(entry);
        parents[level] = entry;
      } else {
        TocEntry entry = TocEntry(
            text: text, index: i, level: level, parent: parents[level - 1]);
        final TocEntry? parent = parents[level - 1];
        if (parent != null) {
          parent.children.add(entry);
          parents[level] = entry;
        } else {
          toc.add(entry);
        }
      }
    }
  }
  
  return toc;
}

/// מבנה TocEntry
class TocEntry {
  final String text;
  final int index;
  final int level;
  final TocEntry? parent;
  final List<TocEntry> children = [];
  
  TocEntry({
    required this.text,
    required this.index,
    required this.level,
    this.parent,
  });
  
  Map<String, dynamic> toJson() => {
    'text': text,
    'index': index,
    'level': level,
    'children': children.map((e) => e.toJson()).toList(),
  };
}

/// כיתת עזר לקריאה וכתיבה אסינכרונית של קבצים גדולים
class LargeFileProcessor {
  /// קריאת קובץ גדול בחלקים
  static Stream<String> readLargeFile(String filePath, {int chunkSize = 1024 * 1024}) async* {
    final file = File(filePath);
    final inputStream = file.openRead();
    
    await for (final chunk in inputStream.transform(utf8.decoder)) {
      yield chunk;
    }
  }
  
  /// כתיבת קובץ גדול בחלקים
  static Future<void> writeLargeFile(
    String filePath,
    Stream<String> dataStream,
  ) async {
    final file = File(filePath);
    final sink = file.openWrite();
    
    await for (final chunk in dataStream) {
      sink.write(chunk);
    }
    
    await sink.flush();
    await sink.close();
  }
  
  /// עיבוד קובץ JSON גדול שורה-שורה
  static Stream<dynamic> processJsonLines(String filePath) async* {
    final file = File(filePath);
    final lines = file.openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    
    await for (final line in lines) {
      if (line.trim().isNotEmpty) {
        try {
          yield jsonDecode(line);
        } catch (e) {
          debugPrint('Error parsing JSON line: $e');
        }
      }
    }
  }
}
