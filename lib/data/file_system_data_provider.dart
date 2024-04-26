/* this is an implementation of the data layer, based on the filesystem.
the representation of the library is a tree of directories and files, which every book is stored in a file,
and every directory is represents a category */

import 'dart:io';
import 'dart:isolate';
import 'dart:convert';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:file_picker/file_picker.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/data/data.dart';
import 'package:otzaria/models/library.dart';
import 'package:otzaria/models/links.dart';

/// An implementation of the data layer based on the filesystem.
///
/// The `FileSystemData` class represents an implementation of the data layer based on the filesystem.
/// It provides methods for accessing the library, book text, book table of contents, and links for a book.
///
/// The inner representation of the library is a tree of directories and files, which every book is stored in a file, and every directory is represents a category.
/// The metadata is stored in a JSON file.
///
class FileSystemData extends Data {
  Map<String, String> titleToPath = {};
  String? libraryPath;
  static FileSystemData instance = FileSystemData();

  FileSystemData() {
    init();
  }

  /// Initializes the data for the application.
  ///
  /// This function initializes the data for the application by performing the following steps:
  /// 1. Initializes the settings using the provided cache provider.
  /// 2. Ensures that the Flutter binding is initialized.
  /// 3. Sets the default directory for Hive to the path obtained from the application support directory.
  /// 4. Creates Hive boxes for bookmarks, tabs, and app preferences.
  /// 5. Retrieves the library path using the file picker.
  /// 6. Updates the title to path mapping using the retrieved library path.
  /// 7. Registers the Bookmark adapter for Hive serialization.
  ///
  /// Returns a `Future` that completes when the initialization is done.
  ///

  init() async {
    //taking care of getting the library path
    await () async {
      //first try to get the library path from settings
      libraryPath = Settings.getValue('key-library-path');
      //if faild, ask the user to choose the path
      while (libraryPath == null) {
        libraryPath = await FilePicker.platform
            .getDirectoryPath(dialogTitle: "הגדר את מיקום ספריית אוצריא");
        Settings.setValue('key-library-path', libraryPath);
      }
    }();

    //updating the title to path index
    _updateTitleToPath(libraryPath!);
    //fetching the metadata for the books in the library
    _fetchMetadata(libraryPath!);
  }

  /// Updates the title to path mapping using the provided library path.
  void _updateTitleToPath(String libraryPath) {
    List<String> paths = getAllBooksPathsFromDirecctory(libraryPath);
    for (var path in paths) {
      titleToPath[getBookTitle(path)] = path;
    }
  }

  ///fetches the metadata for the books in the library from a json file using the provided library path.
  void _fetchMetadata(String libraryPath) {
    String metadataPath =
        (libraryPath + Platform.pathSeparator + 'metadata.json');
    File metadataFile = File(metadataPath);
    String metadataString = metadataFile.readAsStringSync();
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
  String getBookTitle(String path) {
    //get only the name of the book, without the extension and the directory path
    return path.split(Platform.pathSeparator).last.split('.').first;
  }

  /// Returns the path of the book with the given title.
  String _getBookPath(String title) {
    //make sure the map is not empty
    if (titleToPath.isEmpty) {
      _updateTitleToPath(libraryPath!);
    }
    //return the path of the book with the given title
    return titleToPath[title] ?? 'error: book path not found: $title';
  }

  @override

  /// Retrieves the text for a book with the given title asynchronously (using Isolate).
  /// supports docx files
  Future<String> getBookText(String title) {
    return Isolate.run(() async {
      String path = await _getBookPath(title);
      File file = File(path);
      if (path.endsWith('.docx')) {
        final bytes = await file.readAsBytes();
        return docxToText(bytes);
      } else {
        return await file.readAsString();
      }
    });
  }

// Retrieves the table of contents for a book with the given title.
  Future<List<TocEntry>> getBookToc(String title) async {
    return _parseToc(getBookText(title));
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
            print("Warning: Found h$level without a parent h${level - 1}");
            toc.add(entry);
          }
        }
      }
    }

    return toc;
  }

  @override

  /// Returns the library,  (b/c it is a file system data provider,
  ///  it is based on the library path that was provided in the initialization of the data provider.)
  Library getLibrary() {
    return _getLibraryFromDirectory(
        libraryPath! + Platform.pathSeparator + 'אוצריא');
  }

  ///this is the way to get the library using the file system.
  ///every directory represents a category, and every file represents a book.
  ///the
  Library _getLibraryFromDirectory(String path) {
    /// a helper recursive function to get all the categories and books from a directory and its subdirectories
    Category getAllCategoriesAndBooksFromDirectory(
        Directory dir, Category? parent) {
      Category category = Category(
          title: getBookTitle(dir.path),
          subCategories: [],
          books: [],
          parent: parent);
      // get the books and categories from the directory
      for (FileSystemEntity entity in dir.listSync()) {
        if (entity is Directory) {
          category.subCategories.add(getAllCategoriesAndBooksFromDirectory(
              Directory(entity.path), category));
        } else {
          // add the book to the category (the type of book is based on the file extension)
          entity.path.toLowerCase().endsWith('.pdf')
              ? category.books.add(
                  PdfBook(title: getBookTitle(entity.path), path: entity.path))
              : category.books.add(TextBook(title: getBookTitle(entity.path)));
        }
      }
      return category;
    }

    Library library = Library(categories: []);

    for (FileSystemEntity entity in Directory(path).listSync()) {
      if (entity is Directory) {
        library.subCategories.add(getAllCategoriesAndBooksFromDirectory(
            Directory(entity.path), library));
      }

      library.parent = library;
    }
    return library;
  }

  ///the implementation of the links from app's model, based on the filesystem.
  ///the links are in the folder 'links' with the name '<book_title>_links.json'
  @override
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

  ///gets the path of the link file asocciated with the book title.
  String _getLinksPath(String title) {
    return (Settings.getValue<String>('key-library-path') ?? '.') +
        Platform.pathSeparator +
        'links' +
        Platform.pathSeparator +
        title +
        '_links.json';
  }

  @override

  /// an file system approach to get the content of a link.
  /// we read the file line by line and return the content of the line with the given index.
  Future<String> getLinkContent(Link link) async {
    String path = _getBookPath(getBookTitle(link.path2));
    return Isolate.run(() async => await getLineFromFile(path, link.index2));
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
}
