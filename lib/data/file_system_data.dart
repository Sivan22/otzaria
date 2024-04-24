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
import 'package:otzaria/model/books.dart';
import 'package:otzaria/data/data.dart';
import 'package:otzaria/model/library.dart';
import 'package:otzaria/model/links.dart';

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
      libraryPath = Settings.getValue('key-library-path');
      while (libraryPath == null) {
        libraryPath = await FilePicker.platform
            .getDirectoryPath(dialogTitle: "הגדר את מיקום ספריית אוצריא");
        Settings.setValue('key-library-path', libraryPath);
      }
    }();

    //updating the title to path index, and fetching the metadata for the books from file
    updateTitleToPath(libraryPath!);
    fetchMetadata(libraryPath!);
  }

  void updateTitleToPath(String libraryPath) {
    List<String> paths = getAllBooksPathsFromDirecctory(libraryPath);
    for (var path in paths) {
      titleToPath[getBookTitle(path)] = path;
    }
  }

  void fetchMetadata(String libraryPath) {
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

  List<String> getAllBooksPathsFromDirecctory(String path) {
    List<String> paths = [];
    final files = Directory(path).listSync(recursive: true);
    for (var file in files) {
      paths.add(file.path);
    }
    return paths;
  }

  String getBookTitle(String path) {
    //get only the name of the book, without the extension and the directory path
    return path.split(Platform.pathSeparator).last.split('.').first;
  }

  String getPathFromTitle(String title) {
    //make sure the map is not empty
    if (titleToPath.isEmpty) {
      updateTitleToPath(libraryPath!);
    }

    //return the path of the book with the given title
    return titleToPath[title] ?? 'error: book path not found: $title';
  }

  Future<String> getBookText(String title) {
    return Isolate.run(() async {
      String path = await getPathFromTitle(title);
      File file = File(path);
      if (path.endsWith('.docx')) {
        final bytes = await file.readAsBytes();
        return docxToText(bytes);
      } else {
        return await file.readAsString();
      }
    });
  }

// Retrieves the table of contents for a book with the given title asynchronously.
  Future<List<TocEntry>> getBookToc(String title) async {
    return _parseToc(getBookText(title));
  }

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
  Library getLibrary() {
    return getLibraryFromDirectory(
        libraryPath! + Platform.pathSeparator + 'אוצריא');
  }

/*this is the way to get the library using the file system. 
every directory represents a category, and every file represents a book*/

  Library getLibraryFromDirectory(String path) {
    if (metadata.isEmpty) {
      fetchMetadata(libraryPath!);
    }
    Category getAllCategoriesAndBooksFromDirectory(
        Directory dir, Category? parent) {
      Category category = Category(
          title: getBookTitle(dir.path),
          subCategories: [],
          books: [],
          parent: parent);
      for (FileSystemEntity entity in dir.listSync()) {
        if (entity is Directory) {
          category.subCategories.add(getAllCategoriesAndBooksFromDirectory(
              Directory(entity.path), category));
        } else {
          entity.path.toLowerCase().endsWith('.pdf')
              ? category.books.add(
                  pdfBook(title: getBookTitle(entity.path), path: entity.path))
              : category.books.add(TextBook(title: getBookTitle(entity.path)));
        }
        try {
          category.books.sort(
            (a, b) => a.order.compareTo(b.order),
          );
          category.subCategories.sort(
            (a, b) => a.order.compareTo(b.order),
          );
        } catch (e) {
          print(e.toString());
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

/* the implementation of the links from app's model, based on the filesystem.
 the links are in the folder 'links' with the name '<book_title>_links.json'.
 */

  Future<List<Link>> getAllLinksForBook(String title) async {
    // return Isolate.run(() async {
    try {
      File file = File(getLinksPath(title));
      final jsonString = await file.readAsString();
      final jsonList =
          await Isolate.run(() async => jsonDecode(jsonString) as List);
      return jsonList.map((json) => Link.fromJson(json)).toList();
    } on Exception {
      return [];
    }
    //});
  }

  String getLinksPath(String title) {
    return (Settings.getValue<String>('key-library-path') ?? '.') +
        Platform.pathSeparator +
        'links' +
        Platform.pathSeparator +
        title +
        '_links.json';
  }

  Future<String> getLinkContent(Link link) async {
    String path = await getPathFromTitle(getBookTitle(link.path2));
    return Isolate.run(() async {
      File file = File(path);
      return (await file.readAsLines())[link.index2 - 1];
    });
  }
}
