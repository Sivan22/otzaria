import 'dart:io';
import 'dart:convert';
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

class Books extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get author => text().nullable()();
  TextColumn get heShortDesc => text().nullable()();
  TextColumn get pubDate => text().nullable()();
  TextColumn get pubPlace => text().nullable()();
  TextColumn get topics => text().withDefault(const Constant(''))();
  IntColumn get order => integer().withDefault(const Constant(999))();
  TextColumn get extraTitles => text().map(const StringListConverter()).nullable()();
  TextColumn get path => text().nullable()(); // For PdfBooks
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get metadata => text().map(const JsonTypeConverter()).nullable()();
  DateTimeColumn get lastModified => dateTime()();
  DateTimeColumn get created => dateTime()();
  TextColumn get type => text()(); // To distinguish between TextBook, PdfBook, etc.
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  IntColumn get parentId => integer().nullable().references(Categories, #id)();
  TextColumn get description => text().nullable()();
  TextColumn get shortDescription => text().nullable()();
  IntColumn get order => integer().withDefault(const Constant(999))();
}

class JsonTypeConverter extends TypeConverter<Map<String, dynamic>, String> {
  const JsonTypeConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    return json.decode(fromDb) as Map<String, dynamic>;
  }

  @override
  String toSql(Map<String, dynamic> value) {
    return json.encode(value);
  }
}

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    final List<dynamic> list = json.decode(fromDb) as List<dynamic>;
    return list.cast<String>();
  }

  @override
  String toSql(List<String> value) {
    return json.encode(value);
  }
}

@DriftDatabase(tables: [ExternalBooks, Books, Categories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<Book> getBook(int id) {
    return (select(books)..where((b) => b.id.equals(id))).getSingle();
  }

  Future<List<Book>> getBooksByCategory(int categoryId) {
    return (select(books)..where((b) => b.categoryId.equals(categoryId))).get();
  }

  Future<int> insertBook(BooksCompanion book) {
    return into(books).insert(book);
  }

  Future<bool> updateBook(BooksCompanion book) {
    return update(books).replace(book);
  }

  Future<int> deleteBook(int id) {
    return (delete(books)..where((b) => b.id.equals(id))).go();
  }

  Future<Category> getCategory(int id) {
    return (select(categories)..where((c) => c.id.equals(id))).getSingle();
  }

  Future<List<Category>> getRootCategories() {
    return (select(categories)
      ..where((c) => c.parentId.isNull())
      ..orderBy([(c) => OrderingTerm(expression: c.order)]))
    .get();
  }

  Future<List<Category>> getSubcategories(int parentId) {
    return (select(categories)
      ..where((c) => c.parentId.equals(parentId))
      ..orderBy([(c) => OrderingTerm(expression: c.order)]))
    .get();
  }

  Future<Category> insertCategory(CategoriesCompanion category) {
    return into(categories).insertReturning(category);
  }

  Future<bool> updateCategory(CategoriesCompanion category) {
    return update(categories).replace(category);
  }

  Future<int> deleteCategory(int id) {
    return (delete(categories)..where((c) => c.id.equals(id))).go();
  }

  Future<List<ExternalBook>> getOtzarBooks() {
    return (select(externalBooks)
      ..where((b) => b.source.equals('otzar'))
      ..orderBy([(b) => OrderingTerm(expression: b.order)]))
    .get();
  }

  Future<List<ExternalBook>> getHebrewBooks() {
    return (select(externalBooks)
      ..where((b) => b.source.equals('hebrew'))
      ..orderBy([(b) => OrderingTerm(expression: b.order)]))
    .get();
  }

  Future<int> insertExternalBook(ExternalBooksCompanion book) {
    return into(externalBooks).insert(book);
  }

  Future<bool> updateExternalBook(ExternalBooksCompanion book) {
    return update(externalBooks).replace(book);
  }

  Future<int> deleteExternalBook(int id) {
    return (delete(externalBooks)..where((b) => b.id.equals(id))).go();
  }

  // Helper methods for recursive queries
  Future<List<int>> getAllChildCategoryIds(int parentId) async {
    final children = await getSubcategories(parentId);
    final List<int> allIds = [parentId];
    
    for (var child in children) {
      allIds.addAll(await getAllChildCategoryIds(child.id));
    }
    
    return allIds;
  }

  Future<List<Book>> getAllBooksInCategory(int categoryId) async {
    final categoryIds = await getAllChildCategoryIds(categoryId);
    return (select(books)
      ..where((b) => b.categoryId.isIn(categoryIds))
      ..orderBy([(b) => OrderingTerm(expression: b.order)]))
    .get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'otzaria.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
