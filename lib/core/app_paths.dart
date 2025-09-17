import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

Future<String> resolveNotesDbPath(String fileName) async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Windows: this will go into %APPDATA% (Roaming) - exactly what was requested
    final support = await getApplicationSupportDirectory();
    final dbDir = Directory(p.join(support.path, 'databases'));
    if (!await dbDir.exists()) await dbDir.create(recursive: true);
    return p.join(dbDir.path, fileName);
  } else {
    // Mobile: the standard path for sqflite
    final dbs = await getDatabasesPath();
    final dbDir = Directory(dbs);
    if (!await dbDir.exists()) await dbDir.create(recursive: true);
    return p.join(dbs, fileName);
  }
}
