import 'dart:async';
import 'dart:isolate';

/// מנהל מרכזי לכל ה-Isolates באפליקציה
/// 
/// מטפל ביצירה, תקשורת והשמדה של Isolates לפעולות כבדות
class IsolateManager {
  static final Map<String, IsolateHandler> _isolates = {};
  
  /// יצירת Isolate חדש או קבלת קיים
  static Future<IsolateHandler> getOrCreate(
    String name,
    IsolateEntryPoint entryPoint, {
    Map<String, dynamic>? initialData,
  }) async {
    if (_isolates.containsKey(name)) {
      return _isolates[name]!;
    }
    
    final handler = await IsolateHandler.spawn(
      name: name,
      entryPoint: entryPoint,
      initialData: initialData,
    );
    
    _isolates[name] = handler;
    return handler;
  }
  
  /// סגירת Isolate ספציפי
  static Future<void> kill(String name) async {
    final isolate = _isolates[name];
    if (isolate != null) {
      await isolate.dispose();
      _isolates.remove(name);
    }
  }
  
  /// סגירת כל ה-Isolates
  static Future<void> killAll() async {
    for (final isolate in _isolates.values) {
      await isolate.dispose();
    }
    _isolates.clear();
  }
}

/// נקודת כניסה ל-Isolate
typedef IsolateEntryPoint = void Function(IsolateContext context);

/// הקשר של ה-Isolate
class IsolateContext {
  final SendPort sendPort;
  final Map<String, dynamic>? initialData;
  final ReceivePort receivePort = ReceivePort();
  
  IsolateContext({
    required this.sendPort,
    this.initialData,
  });
  
  /// שליחת תוצאה חזרה ל-Main thread
  void send(dynamic message) {
    sendPort.send(message);
  }
  
  /// האזנה להודעות מה-Main thread
  Stream<dynamic> get messages => receivePort.asBroadcastStream();
}

/// מטפל ב-Isolate בודד
class IsolateHandler {
  final String name;
  final Isolate _isolate;
  final SendPort _sendPort;
  final ReceivePort _receivePort;
  final StreamController<dynamic> _responseController;
  
  IsolateHandler._({
    required this.name,
    required Isolate isolate,
    required SendPort sendPort,
    required ReceivePort receivePort,
  })  : _isolate = isolate,
        _sendPort = sendPort,
        _receivePort = receivePort,
        _responseController = StreamController.broadcast();
  
  /// יצירת Isolate חדש
  static Future<IsolateHandler> spawn({
    required String name,
    required IsolateEntryPoint entryPoint,
    Map<String, dynamic>? initialData,
  }) async {
    final receivePort = ReceivePort();
    final completer = Completer<SendPort>();
    
    // האזנה להודעה הראשונה שתכיל את ה-SendPort
    receivePort.listen((message) {
      if (message is SendPort && !completer.isCompleted) {
        completer.complete(message);
      }
    });
    
    // יצירת ה-Isolate
    final isolate = await Isolate.spawn(
      _isolateEntryWrapper,
      _IsolateStartupData(
        sendPort: receivePort.sendPort,
        entryPoint: entryPoint,
        initialData: initialData,
      ),
    );
    
    // קבלת ה-SendPort מה-Isolate
    final sendPort = await completer.future;
    
    final handler = IsolateHandler._(
      name: name,
      isolate: isolate,
      sendPort: sendPort,
      receivePort: receivePort,
    );
    
    // האזנה להודעות מה-Isolate
    receivePort.listen((message) {
      if (message is! SendPort) {
        handler._responseController.add(message);
      }
    });
    
    return handler;
  }
  
  /// שליחת הודעה ל-Isolate
  Future<T> compute<T>(dynamic message) async {
    _sendPort.send(message);
    return await _responseController.stream.first as T;
  }
  
  /// שליחת הודעה ל-Isolate ללא המתנה לתשובה
  void send(dynamic message) {
    _sendPort.send(message);
  }
  
  /// האזנה לתשובות מה-Isolate
  Stream<dynamic> get responses => _responseController.stream;
  
  /// סגירת ה-Isolate
  Future<void> dispose() async {
    _isolate.kill(priority: Isolate.immediate);
    _receivePort.close();
    await _responseController.close();
  }
}

/// מידע להפעלת Isolate
class _IsolateStartupData {
  final SendPort sendPort;
  final IsolateEntryPoint entryPoint;
  final Map<String, dynamic>? initialData;
  
  _IsolateStartupData({
    required this.sendPort,
    required this.entryPoint,
    this.initialData,
  });
}

/// Wrapper לנקודת הכניסה ל-Isolate
void _isolateEntryWrapper(_IsolateStartupData data) {
  final context = IsolateContext(
    sendPort: data.sendPort,
    initialData: data.initialData,
  );
  
  // שליחת ה-SendPort חזרה ל-Main thread
  data.sendPort.send(context.receivePort.sendPort);
  
  // הפעלת נקודת הכניסה
  data.entryPoint(context);
}
