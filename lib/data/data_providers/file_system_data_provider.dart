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

/// A data provider that manages file system operations for the library.
///
/// This class handles all file system related operations including:
/// - Reading and parsing book content from various file formats (txt, docx, pdf)
/// - Managing the library structure (categories and books)
/// - Handling external book data from CSV files
/// - Managing book links and metadata
/// - Providing table of contents functionality
class FileSystemData {
  /// Future that resolves to a mapping of book titles to their file system paths
  late Future<Map<String, String>> titleToPath;

  /// Future that resolves to metadata for all books and categories
  late Future<Map<String, Map<String, dynamic>>> metadata;

  /// Creates a new instance of [FileSystemData] and initializes the title to path mapping
  /// and metadata
  FileSystemData() {
    titleToPath = _getTitleToPath();
    metadata = _getMetadata();
  }

  /// Singleton instance of [FileSystemData]
  static FileSystemData instance = FileSystemData();

  /// Retrieves the complete library structure from the file system.
  ///
  /// Reads the library from the configured path and combines it with metadata
  /// to create a full [Library] object containing all categories and books.
  Future<Library> getLibrary() async {
    titleToPath = _getTitleToPath();
    metadata = _getMetadata();
    return _getLibraryFromDirectory(
        '${Settings.getValue<String>('key-library-path') ?? '.'}${Platform.pathSeparator}אוצריא',
        await metadata);
  }

  /// Recursively builds the library structure from a directory.
  ///
  /// Creates a hierarchical structure of categories and books by traversing
  /// the file system directory structure.
  Future<Library> _getLibraryFromDirectory(
      String path, Map<String, dynamic> metadata) async {
    /// Recursive helper function to process directories and build category structure
    Future<Category> getAllCategoriesAndBooksFromDirectory(
        Directory dir, Category? parent) async {
      final title = getTitleFromPath(dir.path);
      Category category = Category(
          title: title,
          description: metadata[title]?['heDesc'] ?? '',
          shortDescription: metadata[title]?['heShortDesc'] ?? '',
          order: metadata[title]?['order'] ?? 999,
          subCategories: [],
          books: [],
          parent: parent);

      // Process each entity in the directory
      await for (FileSystemEntity entity in dir.list()) {
        if (entity is Directory) {
          // Recursively process subdirectories as categories
          category.subCategories.add(
              await getAllCategoriesAndBooksFromDirectory(
                  Directory(entity.path), category));
        } else {
          // Extract topics from the file path
          var topics = entity.path
              .split('אוצריא${Platform.pathSeparator}')
              .last
              .split(Platform.pathSeparator)
              .toList();
          topics = topics.sublist(0, topics.length - 1);

          // Handle special case where title contains " על "
          if (getTitleFromPath(entity.path).contains(' על ')) {
            topics.add(getTitleFromPath(entity.path).split(' על ')[1]);
          }

          // Process PDF files
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

          // Process text and docx files
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
                topics: topics.join(', '),
                extraTitles: metadata[title]?['extraTitles']));
          }
        }
      }

      // Sort categories and books by their order
      category.subCategories.sort((a, b) => a.order.compareTo(b.order));
      category.books.sort((a, b) => a.order.compareTo(b.order));
      return category;
    }

    // Initialize empty library
    Library library = Library(categories: []);

    // Process top-level directories
    await for (FileSystemEntity entity in Directory(path).list()) {
      if (entity is Directory) {
        library.subCategories.add(await getAllCategoriesAndBooksFromDirectory(
            Directory(entity.path), library));
      }
    }
    library.subCategories.sort((a, b) => a.order.compareTo(b.order));
    return library;
  }

  /// Retrieves the list of books from Otzar HaChochma
  Future<List<ExternalBook>> getOtzarBooks() {
    return _getOtzarBooks();
  }

  /// Retrieves the list of books from HebrewBooks
  Future<List<ExternalBook>> getHebrewBooks() {
    return _getHebrewBooks();
  }

  /// Internal implementation for loading Otzar HaChochma books from CSV
  Future<List<ExternalBook>> _getOtzarBooks() async {
    try {
      print('Loading Otzar HaChochma books from CSV');
      final csvData = await rootBundle.loadString('assets/otzar_books.csv');

      return Isolate.run(() {
        // Normalize line endings for cross-platform compatibility
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

  /// Internal implementation for loading HebrewBooks from CSV
  Future<List<ExternalBook>> _getHebrewBooks() async {
    try {
      print('Loading hebrewbooks from CSV');
      final csvData = await rootBundle.loadString('assets/hebrew_books.csv');

      return Isolate.run(() {
        // Normalize line endings for cross-platform compatibility
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

  /// Retrieves all links associated with a specific book.
  ///
  /// Links are stored in JSON files named '<book_title>_links.json' in the links directory.
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

  /// Retrieves the text content of a book.
  ///
  /// Supports both plain text and DOCX formats. DOCX files are processed
  /// using a special converter to extract their content.
  Future<String> getBookText(String title) async {
    final path = await _getBookPath(title);
    final file = File(path);

    if (path.endsWith('.docx')) {
      final bytes = await file.readAsBytes();
      return Isolate.run(() => docxToText(bytes, title));
    } else {
      final content = await file.readAsString();
      return Isolate.run(() => content);
    }
  }

  /// Retrieves the content of a specific link within a book.
  ///
  /// Reads the file line by line and returns the content at the specified index.
  Future<String> getLinkContent(Link link) async {
    String path = await _getBookPath(getTitleFromPath(link.path2));
    return await getLineFromFile(path, link.index2);
  }

  /// Returns a list of all book paths in the library directory.
  ///
  /// This operation is performed in an isolate to prevent blocking the main thread.
  static Future<List<String>> getAllBooksPathsFromDirecctory(
      String path) async {
    return Isolate.run(() async {
      List<String> paths = [];
      final files = await Directory(path).list(recursive: true).toList();
      for (var file in files) {
        paths.add(file.path);
      }
      return paths;
    });
  }

  /// Retrieves the table of contents for a book.
  ///
  /// Parses the book content to extract headings and create a hierarchical
  /// table of contents structure.
  Future<List<TocEntry>> getBookToc(String title) async {
    return _parseToc(getBookText(title));
  }

  /// Efficiently reads a specific line from a file.
  ///
  /// Uses a stream to read the file line by line until the desired index
  /// is reached, then closes the stream to conserve resources.
  Future<String> getLineFromFile(String path, int index) async {
    return await Isolate.run(() async {
      File file = File(path);
      final lines = file
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .take(index)
          .toList();
      return (await lines).last;
    });
  }

  /// Updates the mapping of book titles to their file system paths.
  ///
  /// Creates a map where keys are book titles and values are their corresponding
  /// file system paths, excluding PDF files.
  Future<Map<String, String>> _getTitleToPath() async {
    Map<String, String> titleToPath = {};
    if (!Settings.isInitialized) {
      await Settings.init(cacheProvider: HiveCache());
    }
    final libraryPath = Settings.getValue('key-library-path');
    List<String> paths = await getAllBooksPathsFromDirecctory(libraryPath);
    for (var path in paths) {
      if (path.toLowerCase().endsWith('.pdf')) continue;
      titleToPath[getTitleFromPath(path)] = path;
    }
    return titleToPath;
  }

  /// Loads and parses the metadata for all books in the library.
  ///
  /// Reads metadata from a JSON file and creates a structured mapping of
  /// book titles to their metadata information.
  Future<Map<String, Map<String, dynamic>>> _getMetadata() async {
    if (!Settings.isInitialized) {
      await Settings.init(cacheProvider: HiveCache());
    }
    String metadataString = '';
    Map<String, Map<String, dynamic>> metadata = {};
    try {
      File file = File(
          '${Settings.getValue<String>('key-library-path') ?? '.'}${Platform.pathSeparator}metadata.json');
      metadataString = await file.readAsString();
    } catch (e) {
      return {};
    }
    final tempMetadata =
        await Isolate.run(() => jsonDecode(metadataString) as List);

    for (int i = 0; i < tempMetadata.length; i++) {
      final row = tempMetadata[i] as Map<String, dynamic>;
      metadata[row['title'].replaceAll('"', '')] = {
        'author': row['author'] ?? '',
        'heDesc': row['heDesc'] ?? '',
        'heShortDesc': row['heShortDesc'] ?? '',
        'pubDate': row['pubDate'] ?? '',
        'pubPlace': row['pubPlace'] ?? '',
        'extraTitles': row['extraTitles'] == null
            ? [row['title'].toString()]
            : row['extraTitles'].map<String>((e) => e.toString()).toList()
                as List<String>,
        'order': row['order'] == null || row['order'] == ''
            ? 999
            : row['order'].runtimeType == double
                ? row['order'].toInt()
                : row['order'] as int,
      };
    }
    return metadata;
  }

  /// Retrieves the file system path for a book with the given title.
  Future<String> _getBookPath(String title) async {
    final titleToPath = await this.titleToPath;
    return titleToPath[title] ?? 'error: book path not found: $title';
  }

  /// Parses the table of contents from book content.
  ///
  /// Creates a hierarchical structure based on HTML heading levels (h1, h2, etc.).
  /// Each entry contains the heading text, its level, and its position in the document.
  Future<List<TocEntry>> _parseToc(Future<String> bookContentFuture) async {
    final String bookContent = await bookContentFuture;

    return Isolate.run(() {
      List<String> lines = bookContent.split('\n');
      List<TocEntry> toc = [];
      Map<int, TocEntry> parents = {}; // Track parent nodes for hierarchy

      for (int i = 0; i < lines.length; i++) {
        final String line = lines[i];
        if (line.startsWith('<h')) {
          final int level = int.parse(line[2]); // Extract heading level
          final String text = stripHtmlIfNeeded(line);

          TocEntry entry = TocEntry(text: text, index: i, level: level);

          if (level == 1) {
            // Add h1 headings as root nodes
            toc.add(entry);
            parents[level] = entry;
          } else {
            // Add other headings under their parent
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
    });
  }

  /// Gets the path to the JSON file containing links for a specific book.
  String _getLinksPath(String title) {
    return '${Settings.getValue<String>('key-library-path') ?? '.'}${Platform.pathSeparator}links${Platform.pathSeparator}${title}_links.json';
  }

  /// Checks if a book with the given title exists in the library.
  Future<bool> bookExists(String title) async {
    final titleToPath = await this.titleToPath;
    return titleToPath.keys.contains(title);
  }
}
