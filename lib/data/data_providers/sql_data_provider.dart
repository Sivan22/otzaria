import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import 'package:otzaria/data/data_providers/drift_database.dart';
import 'package:otzaria/models/books.dart' as model;

class SqlDataProvider {
  static final SqlDataProvider _instance = SqlDataProvider._internal();
  static SqlDataProvider get instance => _instance;
  late final AppDatabase database;
  bool _initialized = false;

  SqlDataProvider._internal() {
    database = AppDatabase();
  }

  Future<void> initialize() async {
    if (_initialized) return;
    
    // Check if we need to migrate data from CSV
    final booksCount = await database.externalBooks.count().getSingle();
    if (booksCount == 0) {
      await _migrateFromCsv();
    }
    _initialized = true;
  }

  Future<void> _migrateFromCsv() async {
    try {
      // Migrate Otzar books
      final otzarData = await rootBundle.loadString('assets/otzar_books.csv');
      final otzarRows = const CsvToListConverter().convert(otzarData);
      
      for (var row in otzarRows.skip(1)) { // Skip header row
         database.insertExternalBook(
          ExternalBooksCompanion.insert(
            id: row[0] as int,
            title: row[1] as String,
            author: Value(row[2] as String?),
            pubPlace: Value(row[3] as String?),
            pubDate: Value(row[4] as String?),
            topics: Value(row[5]?.toString() ?? ''),
            heShortDesc: Value(row[6] as String?),
            link: row[7] as String,
            source: 'otzar',          ),
        );
        print('Migrated book: ${row[1]}');
      }

      // Migrate Hebrew books
      final hebrewData = await rootBundle.loadString('assets/hebrew_books.csv');
      final hebrewRows = const CsvToListConverter().convert(hebrewData);
      
      for (var row in hebrewRows.skip(1)) { // Skip header row
         database.insertExternalBook(
          ExternalBooksCompanion.insert(
            id: row[0] as int,
            title: row[1] as String,
            author: Value(row[2] as String?),
            pubPlace: Value(row[3] as String?),
            pubDate: Value(row[4] as String?),
            topics: Value(row[5]?.toString() ?? ''),
            heShortDesc: Value(row[6] as String?),
            link: row[7] as String,
            source: 'hebrew',
          ),
        );
        print('Migrated book: ${row[1]}');
      }
    } catch (e) {
      print('Error during CSV migration: $e');
      rethrow;
    }
  }

  Future<List<model.ExternalBook>> getOtzarBooks() async {
    await initialize();
    final books = await database.getOtzarBooks();
    return books.map((book) => model.ExternalBook(
      title: book.title,
      id: book.id,
      author: book.author,
      pubPlace: book.pubPlace,
      pubDate: book.pubDate,
      topics: book.topics,
      heShortDesc: book.heShortDesc,
      link: book.link,
    )).toList();
    
  }

  Future<List<model.ExternalBook>> getHebrewBooks() async {
    await initialize();
    final books = await database.getHebrewBooks();
    return books.map((book) => model.ExternalBook(
      title: book.title,
      id: book.id,
      author: book.author,
      pubPlace: book.pubPlace,
      pubDate: book.pubDate,
      topics: book.topics,
      heShortDesc: book.heShortDesc,
      link: book.link,
    )).toList();
  }
}
