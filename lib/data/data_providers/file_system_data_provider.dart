import 'dart:io';
import 'dart:isolate';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:otzaria/data/data_providers/hive_data_provider.dart';
import 'package:otzaria/utils/docx_to_otzaria.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/library/models/library.dart';
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

  late String libraryPath;

  /// Future that resolves to metadata for all books and categories
  late Future<Map<String, Map<String, dynamic>>> metadata;

  /// Creates a new instance of [FileSystemData] and initializes the title to path mapping
  /// and metadata
  FileSystemData() {
    // Initialize with default values, will be properly initialized on first use
    libraryPath = '.';
    titleToPath = Future.value(<String, String>{});
    metadata = Future.value(<String, Map<String, dynamic>>{});
  }

  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    // Only initialize Settings if we're in the main isolate
    // In background isolates, we'll use default values
    if (!Settings.isInitialized) {
      try {
        await Settings.init(cacheProvider: HiveCache());
      } catch (e) {
        // If Settings initialization fails (e.g., in isolate), use defaults
        print('Settings initialization failed, using defaults: $e');
        libraryPath = '.';
        titleToPath = Future.value(<String, String>{});
        metadata = Future.value(<String, Map<String, dynamic>>{});
        _isInitialized = true;
        return;
      }
    }

    libraryPath = Settings.getValue<String>('key-library-path') ?? '.';
    titleToPath = _getTitleToPath();
    metadata = _getMetadata();
    _isInitialized = true;
  }

  /// Singleton instance of [FileSystemData]
  static FileSystemData instance = FileSystemData();

  /// Retrieves the complete library structure from the file system.
  ///
  /// Reads the library from the configured path and combines it with metadata
  /// to create a full [Library] object containing all categories and books.
  Future<Library> getLibrary() async {
    await _ensureInitialized();
    titleToPath = _getTitleToPath();
    metadata = _getMetadata();
    return _getLibraryFromDirectory(
        '$libraryPath${Platform.pathSeparator}אוצריא', await metadata);
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
                category: category,
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
                category: category,
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
  static Future<List<ExternalBook>> getOtzarBooks() {
    return _getOtzarBooks();
  }

  /// Retrieves the list of books from HebrewBooks
  static Future<List<Book>> getHebrewBooks() {
    return _getHebrewBooks();
  }

  /// Internal implementation for loading Otzar HaChochma books from CSV
  static Future<List<ExternalBook>> _getOtzarBooks() async {
    try {
      final csvData = await rootBundle.loadString('assets/otzar_books.csv');

      final table = await Isolate.run(() {
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

        return csvTable;
      });
      return table.skip(1).map((row) {
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
    } catch (e) {
      return [];
    }
  }

  /// Internal implementation for loading HebrewBooks from CSV
  static Future<List<Book>> _getHebrewBooks() async {
    try {
      final csvData = await rootBundle.loadString('assets/hebrew_books.csv');
      final hebrewBooksPath =
          Settings.getValue<String>('key-hebrew-books-path');

      final table = await Isolate.run(() {
        // Normalize line endings for cross-platform compatibility
        final normalizedCsvData =
            csvData.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

        List<List<dynamic>> csvTable;
        csvTable = const CsvToListConverter(
          fieldDelimiter: ',',
          textDelimiter: '"',
          eol: '\n',
          shouldParseNumbers: true,
        ).convert(normalizedCsvData);

        return csvTable;
      });

      final books = <Book>[];
      for (final row in table.skip(1)) {
        try {
          if (row[0] == null || row[0].toString().isEmpty) continue;

          // Check if the ID is numeric
          final bookId = row[0].toString().trim();
          if (!RegExp(r'^\d+$').hasMatch(bookId)) continue;
          String? localPath;

          if (hebrewBooksPath != null) {
            localPath =
                '$hebrewBooksPath${Platform.pathSeparator}Hebrewbooks_org_$bookId.pdf';
            if (!File(localPath).existsSync()) {
              localPath =
                  '$hebrewBooksPath${Platform.pathSeparator}$bookId.pdf';
              if (!File(localPath).existsSync()) {
                localPath = null;
              }
            }
          }

          if (localPath != null) {
            // If local file exists, add as PdfBook
            books.add(PdfBook(
              title: row[1].toString(),
              path: localPath,
              author: row[2].toString(),
              pubPlace: row[3].toString(),
              pubDate: row[4].toString(),
              topics: row[15].toString().replaceAll(';', ', '),
              heShortDesc: row[13].toString(),
            ));
          } else {
            // If no local file, add as ExternalBook
            books.add(ExternalBook(
              title: row[1].toString(),
              id: int.parse(bookId),
              author: row[2].toString(),
              pubPlace: row[3].toString(),
              pubDate: row[4].toString(),
              topics: row[15].toString().replaceAll(';', ', '),
              heShortDesc: row[13].toString(),
              link: 'https://beta.hebrewbooks.org/$bookId',
            ));
          }
        } catch (e) {
          print('Error loading book: $e');
        }
      }
      return books;
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
      final jsonList = await Isolate.run(() async {
        // Initialize Settings in isolate if needed - not needed for this function
        return jsonDecode(jsonString) as List;
      });
      // Don't use isolate for Link.fromJson since Link contains non-serializable objects
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
    await _ensureInitialized();
    final path = await _getBookPath(title);
    final file = File(path);

    if (path.endsWith('.docx')) {
      final bytes = await file.readAsBytes();
      return Isolate.run(() => docxToText(bytes, title));
    } else {
      return await Isolate.run(() => file.readAsString());
    }
  }

  /// Retrieves a partial text content of a book around a specific section.
  ///
  /// Loads only the current section plus [sectionsAround] sections before and after.
  /// This is much more efficient for large books.
  Future<List<String>> getBookTextPartial(String title, int currentIndex,
      {int sectionsAround = 50}) async {
    await _ensureInitialized();
    final path = await _getBookPath(title);
    final file = File(path);

    if (path.endsWith('.docx')) {
      // For DOCX, we still need to load the full content
      final bytes = await file.readAsBytes();
      final fullText = await Isolate.run(() => docxToText(bytes, title));
      final lines = fullText.split('\n');
      return _extractPartialLines(lines, currentIndex, sectionsAround);
    } else {
      return await _readPartialTextFile(file, currentIndex, sectionsAround);
    }
  }

  /// Helper function to extract partial lines from a full text
  List<String> _extractPartialLines(
      List<String> allLines, int currentIndex, int sectionsAround) {
    final startIndex =
        (currentIndex - sectionsAround).clamp(0, allLines.length);
    final endIndex =
        (currentIndex + sectionsAround + 1).clamp(0, allLines.length);
    return allLines.sublist(startIndex, endIndex);
  }

  /// Helper function to read partial content from a text file
  static Future<List<String>> _readPartialTextFile(
      File file, int currentIndex, int sectionsAround) async {
    return await Isolate.run(() {
      // Don't initialize Settings in isolate - just do the file operation
      final lines = file.readAsStringSync().split('\n');
      final startIndex = (currentIndex - sectionsAround).clamp(0, lines.length);
      final endIndex =
          (currentIndex + sectionsAround + 1).clamp(0, lines.length);
      return lines.sublist(startIndex, endIndex);
    });
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
    final tempMetadata = await Isolate.run(() async {
      // Initialize Settings in isolate if needed - not needed for this function
      return jsonDecode(metadataString) as List;
    });

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
    await _ensureInitialized();
    final titleToPath = await this.titleToPath;
    return titleToPath[title] ?? 'error: book path not found: $title';
  }

  /// Parses the table of contents from book content.
  ///
  /// Creates a hierarchical structure based on HTML heading levels (h1, h2, etc.).
  /// Each entry contains the heading text, its level, and its position in the document.
  Future<List<TocEntry>> _parseToc(Future<String> bookContentFuture) async {
    final String bookContent = await bookContentFuture;

    return Isolate.run(() async {
      // Initialize Settings in isolate if needed - not needed for this function
      List<String> lines = bookContent.split('\n');
      List<TocEntry> toc = [];
      Map<int, TocEntry> parents = {}; // Track parent nodes for hierarchy

      for (int i = 0; i < lines.length; i++) {
        final String line = lines[i];
        if (line.startsWith('<h')) {
          final int level = int.parse(line[2]); // Extract heading level
          final String text = stripHtmlIfNeeded(line);

          if (level == 1) {
            // Add h1 headings as root nodes
            TocEntry entry = TocEntry(text: text, index: i, level: level);
            toc.add(entry);
            parents[level] = entry;
          } else {
            TocEntry entry = TocEntry(
                text: text, index: i, level: level, parent: parents[level - 1]);
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

  /// Returns true if the book belongs to Tanach (Torah, Neviim or Ketuvim).
  ///
  /// The check is performed by examining the book path and verifying that it
  /// resides under one of the Tanach directories.
  Future<bool> isTanachBook(String title) async {
    final path = await _getBookPath(title);
    final normalized = path
        .replaceAll('/', Platform.pathSeparator)
        .replaceAll('\\', Platform.pathSeparator);
    final tanachBase =
        '${Platform.pathSeparator}אוצריא${Platform.pathSeparator}תנך${Platform.pathSeparator}';
    final torah = tanachBase + 'תורה';
    final neviim = tanachBase + 'נביאים';
    final ktuvim = tanachBase + 'כתובים';
    return normalized.contains(torah) ||
        normalized.contains(neviim) ||
        normalized.contains(ktuvim);
  }
}
