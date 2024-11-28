import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'drift_database.g.dart';

class ExternalBooks extends Table {
  IntColumn get id => integer()();
  TextColumn get title => text()();
  TextColumn get author => text().nullable()();
  TextColumn get pubPlace => text().nullable()();
  TextColumn get pubDate => text().nullable()();
  TextColumn get topics => text().withDefault(const Constant(''))();
  TextColumn get heShortDesc => text().nullable()();
  TextColumn get link => text()();
  TextColumn get source => text()();
  IntColumn get order => integer().withDefault(const Constant(999))();
}

@DriftDatabase(tables: [ExternalBooks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<List<ExternalBook>> getOtzarBooks() {
    return (select(externalBooks)..where((tbl) => tbl.source.equals('otzar'))).get();
  }

  Future<List<ExternalBook>> getHebrewBooks() {
    return (select(externalBooks)..where((tbl) => tbl.source.equals('hebrew'))).get();
  }

  Future<void> insertExternalBook(ExternalBooksCompanion book) {
    return into(externalBooks).insert(book);
  }

  Future<void> updateExternalBook(ExternalBooksCompanion book) {
    return update(externalBooks).replace(book);
  }

  Future<void> deleteExternalBook(int id) {
    return (delete(externalBooks)..where((tbl) => tbl.id.equals(id))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'otzaria.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
