/* this is an implementation of the data layer, based on the filesystem.
the representation of the library is a tree of directories and files, which every book is stored in a file,
and every directory is represents a category */

import 'dart:io';
import 'dart:isolate';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:otzaria/data/data_providers/cache_provider.dart';
import 'package:otzaria/utils/docx_to_otzaria.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/library.dart';
import 'package:otzaria/models/links.dart';

/// An implementation of the data layer based on the filesystem.
///
/// The `FileSystemData` class represents an implementation of the data layer based on the filesystem.
/// It provides methods for accessing the library, book text, book table of contents, and links for a book.
///
/// The inner representation of the library is a tree of directories and files,
///  which every book is stored in a file,  and every directory is represents a category.
/// The metadata is stored in a JSON file.
class FileSystemData {
  late String libraryPath;
  Map<String, String> titleToPath = {};
  Map<String, dynamic> metadata = {};

  FileSystemData() {
    _initialize();
  }

  static FileSystemData instance = FileSystemData();

  Future<void> _initialize() async {
    if (!Settings.isInitialized) {
      await Settings.init(cacheProvider: HiveCache());
    }
    libraryPath = Settings.getValue<String>('key-library-path') ?? '.';
    _updateTitleToPath();
  }

  /// Returns the library
  Future<Library> getLibrary() async {
    return _getLibraryFromDirectory(
        '$libraryPath${Platform.pathSeparator}אוצריא');
  }

  Future<Library> _getLibraryFromDirectory(String path) async {
    /// a helper recursive function to get all the categories and books from a directory and its subdirectories
    _fetchMetadata();
    Category getAllCategoriesAndBooksFromDirectory(
        Directory dir, Category? parent) {
      Category category = Category(
          title: getTitleFromPath(dir.path),
          subCategories: [],
          books: [],
          parent: parent);
      // get the books and categories from the directory
      for (FileSystemEntity entity in dir.listSync()) {
        if (entity is Directory) {
          category.subCategories.add(getAllCategoriesAndBooksFromDirectory(
              Directory(entity.path), category));
        } else {
          var topics = entity.path.split('אוצריא\\').last.split('\\').toList();
          topics = topics.sublist(0, topics.length - 1);
          if (getTitleFromPath(entity.path).contains(' על ')) {
            topics.add(getTitleFromPath(entity.path).split(' על ')[1]);
          }
          if (entity.path.toLowerCase().endsWith('.pdf')) {
            final title = getTitleFromPath(entity.path);
            category.books.add(
              PdfBook(
                title: title,
                path: entity.path,
                author: metadata[title]?['author'],
                heShortDesc: metadata[title]?['heShortDesc'],
                pubDate: metadata[title]?['pubDate'],
                pubPlace: metadata[title]?['pubPlace'],
                order: metadata[title]?['order'] ?? 999,
                topics: topics.join(', '),
              ),
            );
          }
          if (entity.path.toLowerCase().endsWith('.txt') ||
              entity.path.toLowerCase().endsWith('.docx')) {
            final title = getTitleFromPath(entity.path);

            category.books.add(TextBook(
                title: title,
                author: metadata[title]?['author'],
                heShortDesc: metadata[title]?['heShortDesc'],
                pubDate: metadata[title]?['pubDate'],
                pubPlace: metadata[title]?['pubPlace'],
                order: metadata[title]?['order'] ?? 999,
                topics: topics.join(', ')));
          }
        }
      }
      category.subCategories.sort((a, b) => a.order.compareTo(b.order));
      category.books.sort((a, b) => a.order.compareTo(b.order));
      return category;
    }

    //first initialize an empty library
    Library library = Library(categories: []);

    //then get all the categories and books from the top directory recursively
    for (FileSystemEntity entity in Directory(path).listSync()) {
      if (entity is Directory) {
        library.subCategories.add(getAllCategoriesAndBooksFromDirectory(
            Directory(entity.path), library));
      }
    }
    library.subCategories.sort((a, b) => a.order.compareTo(b.order));
    return library;
  }

  Future<List<ExternalBook>> getOtzarBooks() {
    return _getOtzarBooks();
  }

  Future<List<ExternalBook>> getHebrewBooks() {
    return _getHebrewBooks();
  }

  Future<List<ExternalBook>> _getOtzarBooks() async {
    try {
      print('Loading Otzar HaChochma books from CSV');
      final csvData = await rootBundle.loadString('assets/otzar_books.csv');

      return Isolate.run(() {
        // fix the line endings so that it works on all platforms
        final normalizedCsvData =
            csvData.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

        List<List<dynamic>> csvTable;
        csvTable = const CsvToListConverter(
          fieldDelimiter: ',',
          textDelimiter: '"',
          eol: '\n',
          shouldParseNumbers: false,
        ).convert(normalizedCsvData);

        print('Loaded ${csvTable.length} rows');

        return csvTable.skip(1).map((row) {
          // Skip the header row
          return ExternalBook(
            title: row[1],
            id: int.tryParse(row[0]) ?? -1,
            author: row[2],
            pubPlace: row[3],
            pubDate: row[4],
            topics: row[5],
            link: row[7],
          );
        }).toList();
      });
    } catch (e) {
      print('Error loading Otzar HaChochma books: $e');
      return [];
    }
  }

  Future<List<ExternalBook>> _getHebrewBooks() async {
    try {
      print('Loading hebrewbooks from CSV');
      final csvData = await rootBundle.loadString('assets/hebrew_books.csv');

      return Isolate.run(() {
        // fix the line endings so that it works on all platforms
        final normalizedCsvData =
            csvData.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

        List<List<dynamic>> csvTable;
        csvTable = const CsvToListConverter(
          fieldDelimiter: ',',
          textDelimiter: '"',
          eol: '\n',
          shouldParseNumbers: false,
        ).convert(normalizedCsvData);

        print('Loaded ${csvTable.length} rows');
        // Skip the header row

        return csvTable.skip(1).map((row) {
          // Skip the header row
          try {
            return ExternalBook(
              title: row[1].toString(),
              id: -1,
              author: row[2].toString(),
              pubPlace: row[3].toString(),
              pubDate: row[4].toString(),
              topics: row[15].toString().replaceAll(';', ', '),
              heShortDesc: row[13].toString(),
              link: 'https://beta.hebrewbooks.org/${row[0]}',
            );
          } catch (e) {
            print('Error loading book: $e');
            return ExternalBook(title: 'error', id: 0, link: '');
          }
        }).toList();
      });
    } catch (e) {
      print('Error loading hebrewbooks: $e');
      return [];
    }
  }

  ///the implementation of the links from app's model, based on the filesystem.
  ///the links are in the folder 'links' with the name '<book_title>_links.json'
  Future<List<Link>> getAllLinksForBook(String title) async {
    try {
      File file = File(_getLinksPath(title));
      final jsonString = await file.readAsString();
      final jsonList =
          await Isolate.run(() async => jsonDecode(jsonString) as List);
      return jsonList.map((json) => Link.fromJson(json)).toList();
    } on Exception {
      return [];
    }
  }

  /// Retrieves the text for a book with the given title asynchronously (using Isolate).
  /// supports docx files
  Future<String> getBookText(String title) {
    return Isolate.run(() async {
      String path = _getBookPath(title);
      File file = File(path);
      if (path.endsWith('.docx')) {
        final bytes = await file.readAsBytes();
        return docxToText(bytes, title);
      } else {
        return await file.readAsString();
      }
    });
  }

  /// an file system approach to get the content of a link.
  /// we read the file line by line and return the content of the line with the given index.
  Future<String> getLinkContent(Link link) async {
    String path = _getBookPath(getTitleFromPath(link.path2));
    return Isolate.run(() async => await getLineFromFile(path, link.index2));
  }

  /// Returns a list of all the book paths in the library directory.
  List<String> getAllBooksPathsFromDirecctory(String path) {
    List<String> paths = [];
    final files = Directory(path).listSync(recursive: true);
    for (var file in files) {
      paths.add(file.path);
    }
    return paths;
  }

  /// Returns the title of the book with the given path.

// Retrieves the table of contents for a book with the given title.

  Future<List<TocEntry>> getBookToc(String title) async {
    return _parseToc(getBookText(title));
  }

  ///gets a line from file in an efficient way, using a stream that is closed right
  /// after the line with the given index is found. the function
  ///
  ///the function gets a path to the file and an int index, and returns a Future<String>.
  Future<String> getLineFromFile(String path, int index) async {
    File file = File(path);
    final lines = file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .take(index)
        .toList();
    return (await lines).last;
  }

  /// Updates the title to path mapping using the provided library path.
  void _updateTitleToPath() {
    List<String> paths = getAllBooksPathsFromDirecctory('$libraryPath/אוצריא');
    for (var path in paths) {
      titleToPath[getTitleFromPath(path)] = path;
    }
  }

  ///fetches the metadata for the books in the library from a json file using the provided library path.
  void _fetchMetadata() {
    String metadataString = '';
    try {
      File file = File('$libraryPath${Platform.pathSeparator}metadata.json');
      metadataString = file.readAsStringSync();
    } catch (e) {
      return;
    }
    final tempMetadata = jsonDecode(metadataString) as List<dynamic>;
    for (int i = 0; i < tempMetadata.length; i++) {
      final row = tempMetadata[i] as Map<String, dynamic>;
      metadata[row['title'].replaceAll('"', '')] = {
        'author': row['author'] ?? '',
        'heDesc': row['heDesc'] ?? '',
        'heShortDesc': row['heShortDesc'] ?? '',
        'pubDate': row['pubDate'] ?? '',
        'pubPlace': row['pubPlace'] ?? '',
        // get order in int even if the value is null or double
        'order': row['order'] == null || row['order'] == ''
            ? 999
            : row['order'].runtimeType == double
                ? row['order'].toInt()
                : row['order'] as int
      };
    }
  }

  /// Returns the path of the book with the given title.
  String _getBookPath(String title) {
    //make sure the map is not empty
    if (titleToPath.isEmpty) {
      _updateTitleToPath();
    }
    //return the path of the book with the given title
    return titleToPath[title] ?? 'error: book path not found: $title';
  }

  ///a function that parses the table of contents from a string, based on the heading level: for example, h1, h2, h3, etc.
  ///each entry has a level and an index in the array of lines
  Future<List<TocEntry>> _parseToc(Future<String> data) async {
    List<String> lines = (await data).split('\n');
    List<TocEntry> toc = [];
    Map<int, TocEntry> parents = {}; // Keep track of parent nodes

    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      if (line.startsWith('<h')) {
        final int level =
            int.parse(line[2]); // Extract heading level (h1, h2, etc.)
        final String text = stripHtmlIfNeeded(line);

        // Create the TocEntry
        TocEntry entry = TocEntry(text: text, index: i, level: level);

        if (level == 1) {
          // If it's an h1, add it as a root node
          toc.add(entry);
          parents[level] = entry;
        } else {
          // Find the parent node based on the previous level
          final TocEntry? parent = parents[level - 1];
          if (parent != null) {
            parent.children.add(entry);
            parents[level] = entry;
          } else {
            // Handle cases where heading levels might be skipped
            //print("Warning: Found h$level without a parent h${level - 1}");
            toc.add(entry);
          }
        }
      }
    }

    return toc;
  }

  ///this is the way to get the library using the file system.
  ///every directory represents a category, and every file represents a book.
  ///the

  ///gets the path of the link file asocciated with the book title.
  String _getLinksPath(String title) {
    return '${Settings.getValue<String>('key-library-path') ?? '.'}${Platform.pathSeparator}links${Platform.pathSeparator}${title}_links.json';
  }

  bool bookExists(String title) {
    return titleToPath.keys.contains(title);
  }
}
