import 'package:otzaria/data/data.dart';
import 'package:otzaria/data/file_system_data.dart';
import 'package:otzaria/model/links.dart';
import 'dart:isolate';
import 'package:pdfrx/pdfrx.dart';

/// Represents a book in the application.
///
/// A `Book` object has a [title] which is the name of the book.

class Book {
  /// The title of the book.
  final String title;
  final Data data = FileSystemData.instance;

  /// The author of the book, if available.
  String? get author => data.metadata[title]?['author'];

  /// A short description of the book, if available.
  String? get heShortDesc => data.metadata[title]?['heShortDesc'];

  /// The publication date of the book, if available.
  String? get pubDate => data.metadata[title]?['pubDate'];

  /// The place where the book was published, if available.
  String? get pubPlace => data.metadata[title]?['pubPlace'];

  /// The order of the book in the list of books. If not available, defaults to 999.
  int get order => data.metadata[title]?['order'] ?? 999;

  /// Creates a new `Book` instance.
  ///
  /// The [title] parameter is required and cannot be null.
  Book({
    required this.title,
  });

  /// Retrieves the table of contents of the book.
  ///
  /// Returns a [Future] that resolves to a [List] of [TocEntry] objects representing
  /// the table of contents of the book.
  Future<List<TocEntry>> get tableOfContents =>
      Isolate.run(() => data.getBookToc(title));

  /// Retrieves all the links for the book.
  ///
  /// Returns a [Future] that resolves to a [List] of [Link] objects.
  Future<List<Link>> get links => data.getAllLinksForBook(title);

  /// Creates a new `Book` instance from a JSON object.
  ///
  /// The JSON object should have a 'title' key.
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      title: json['title'],
    );
  }

  /// Converts the `Book` instance into a JSON object.
  ///
  /// Returns a JSON object with a 'title' key.
  Map<String, dynamic> toJson() {
    return {'title': title};
  }
}

class TextBook extends Book {
  TextBook({required String title}) : super(title: title);

  /// The text data of the book.
  Future<String> get text async => (await data.getBookText(title));
}

class TocEntry {
  final String text;
  final int index;
  final int level;
  List<TocEntry> children = [];

  TocEntry({
    required this.text,
    required this.index,
    this.level = 1,
  });
}

class pdfBook extends Book {
  final String path;
  pdfBook({required String title, required this.path}) : super(title: title);
  Future<PdfPageView> get thumbnail async => PdfPageView(
      document: await PdfDocument.openFile(
        path,
      ),
      pageNumber: 1);

  factory pdfBook.fromJson(Map<String, dynamic> json) {
    return pdfBook(
      title: json['title'],
      path: json['path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'path': path};
  }

  @override
  String toString() => 'pdfBook(title: $title, path: $path)';
}
