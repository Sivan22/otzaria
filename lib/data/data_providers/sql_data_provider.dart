import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:otzaria/data/data_providers/drift_database.dart';
import 'package:otzaria/models/books.dart' as model;
import 'package:otzaria/models/library.dart';
import 'package:otzaria/models/category.dart';
import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:path/path.dart' as p;

class SqlDataProvider {
  static final SqlDataProvider _instance = SqlDataProvider._internal();
  static SqlDataProvider get instance => _instance;
  late final AppDatabase _db;
  final Logger _logger = Logger('SqlDataProvider');
  bool _initialized = false;

  /// Provides access to the underlying database instance
  AppDatabase get database => _db;

  SqlDataProvider._internal() {
    _db = AppDatabase();
  }

  Future<void> initialize() async {
    if (_initialized) return;
    
    // Check if we need to migrate data from CSV
    final booksCount = await _db.externalBooks.count().getSingle();
    if (booksCount == 0) {
      await _migrateFromCsv();
    }

    // Check if we need to migrate from JSON
    final internalBooksCount = await _db.books.count().getSingle();
    if (internalBooksCount == 0) {
      await migrateFromJson();
    }
    
    _initialized = true;
  }

  Future<void> _migrateFromCsv() async {
    try {
      // Migrate Otzar books
      final otzarData = await rootBundle.loadString('assets/otzar_books.csv');
      final otzarRows = const CsvToListConverter().convert(otzarData);
      
      for (var row in otzarRows.skip(1)) { // Skip header row
        try {
          await _db.insertExternalBook(
            ExternalBooksCompanion.insert(
              id: int.parse(row[0].toString()),
              title: row[1].toString(),
              author: Value(row[2]?.toString()),
              pubPlace: Value(row[3]?.toString()),
              pubDate: Value(row[4]?.toString()),
              topics: Value(row[5]?.toString() ?? ''),
              heShortDesc: Value(row[6]?.toString()),
              link: row[7].toString(),
              source: 'otzar',
            ),
          );
          _logger.info('Inserted Otzar book: ${row[1]}');
        } catch (e) {
          _logger.warning('Failed to insert Otzar book: ${row[1]}, error: $e');
          continue;
        }
      }

      // Migrate Hebrew books
      final hebrewData = await rootBundle.loadString('assets/hebrew_books.csv');
      final hebrewRows = const CsvToListConverter().convert(hebrewData);
      
      for (var row in hebrewRows.skip(1)) { // Skip header row
        try {
          await _db.insertExternalBook(
            ExternalBooksCompanion.insert(
              id: int.parse(row[0].toString()),
              title: row[1].toString(),
              author: Value(row[2]?.toString()),
              pubPlace: Value(row[3]?.toString()),
              pubDate: Value(row[4]?.toString()),
              topics: Value(row[5]?.toString() ?? ''),
              heShortDesc: Value(row[6]?.toString()),
              link: row[7].toString(),
              source: 'hebrew',
            ),
          );
          _logger.info('Inserted Hebrew book: ${row[1]}');
        } catch (e) {
          _logger.warning('Failed to insert Hebrew book: ${row[1]}, error: $e');
          continue;
        }
      }
    } catch (e) {
      _logger.severe('Error during CSV migration: $e');
      rethrow;
    }
  }

  Future<void> migrateFromJson() async {
    try {
      final fsData = FileSystemData.instance;
      final metadata = await fsData.metadata;
      final libraryPath = Settings.getValue<String>('key-library-path') ?? '.';
      final rootPath = '$libraryPath${Platform.pathSeparator}אוצריא';
      
      // First, create categories based on directory structure
      final Map<String, int> pathToId = {};
      
      Future<int> ensureCategory(String path, String name, {int? parentId}) async {
        if (pathToId.containsKey(path)) {
          return pathToId[path]!;
        }

        final categoryData = metadata[path];
        final category = await _db.into(_db.categories).insertReturning(
          CategoriesCompanion.insert(
            title: name,
            parentId: Value(parentId),
            description: Value(categoryData?['description'] as String?),
            shortDescription: Value(categoryData?['shortDescription'] as String?),
            order: Value(categoryData?['order'] as int? ?? 999),
          ),
        );

        pathToId[path] = category.id;
        return category.id;
      }

      Future<void> _processDirectory(String path, int parentId) async {
        final dir = Directory(path);
        if (!await dir.exists()) {
          _logger.warning('Directory does not exist: $path');
          return;
        }

        final entities = await dir.list().toList();
        
        for (var entity in entities) {
          final name = p.basename(entity.path);
          if (entity is Directory) {
            final categoryId = await ensureCategory(entity.path, name, parentId: parentId);
            await _processDirectory(entity.path, categoryId);
          } else if (entity is File) {
            final title = p.basenameWithoutExtension(entity.path);
            final bookData = metadata[entity.path];
            final now = DateTime.now().toUtc();
            
            if (entity.path.endsWith('.txt')) {
              await _db.into(_db.books).insert(
                BooksCompanion.insert(
                  title: title,
                  type: 'TextBook',
                  author: Value(bookData?['author'] as String?),
                  heShortDesc: Value(bookData?['heShortDesc'] as String?),
                  pubDate: Value(bookData?['pubDate'] as String?),
                  pubPlace: Value(bookData?['pubPlace'] as String?),
                  topics: Value(bookData?['topics'] as String? ?? ''),
                  order: Value(bookData?['order'] as int? ?? 999),
                  extraTitles: Value(bookData?['extraTitles'] != null 
                    ? (bookData!['extraTitles'] as List).cast<String>() 
                    : null),
                  path: Value(entity.path),
                  categoryId: parentId,
                  metadata: Value(bookData),
                  lastModified: now,
                  created: now,
                ),
              );
              _logger.info('Inserted book: $title');
            } else if (entity.path.endsWith('.pdf')) {
              await _db.into(_db.books).insert(
                BooksCompanion.insert(
                  title: title,
                  type: 'PdfBook',
                  author: Value(bookData?['author'] as String?),
                  heShortDesc: Value(bookData?['heShortDesc'] as String?),
                  pubDate: Value(bookData?['pubDate'] as String?),
                  pubPlace: Value(bookData?['pubPlace'] as String?),
                  topics: Value(bookData?['topics'] as String? ?? ''),
                  order: Value(bookData?['order'] as int? ?? 999),
                  extraTitles: Value(bookData?['extraTitles'] != null 
                    ? (bookData!['extraTitles'] as List).cast<String>() 
                    : null),
                  path: Value(entity.path),
                  categoryId: parentId,
                  metadata: Value(bookData),
                  lastModified: now,
                  created: now,
                ),
              );
              _logger.info('Inserted book: $title');
            }
          }
        }
      }

      // Create root category
      final rootId = await ensureCategory(rootPath, 'אוצריא');
      
      // Process all directories and files
      await _processDirectory(rootPath, rootId);
    } catch (e, stackTrace) {
      _logger.severe('Error during JSON migration: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<List<model.ExternalBook>> getOtzarBooks() async {
    await initialize();
    final books = await _db.getOtzarBooks();
    return books.map((book) => model.ExternalBook(
      title: book.title,
      id: book.id,
      author: book.author,
      pubPlace: book.pubPlace,
      pubDate: book.pubDate,
      topics: book.topics ?? '',
      heShortDesc: book.heShortDesc,
      link: book.link,
    )).toList();
  }

  Future<List<model.ExternalBook>> getHebrewBooks() async {
    await initialize();
    final books = await _db.getHebrewBooks();
    return books.map((book) => model.ExternalBook(
      title: book.title,
      id: book.id,
      author: book.author,
      pubPlace: book.pubPlace,
      pubDate: book.pubDate,
      topics: book.topics ?? '',
      heShortDesc: book.heShortDesc,
      link: book.link,
    )).toList();
  }
}
