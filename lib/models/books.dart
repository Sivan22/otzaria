import 'package:otzaria/data/data.dart';
import 'package:otzaria/data/file_system_data_provider.dart';
import 'package:otzaria/models/links.dart';
import 'dart:isolate';
import 'package:pdfrx/pdfrx.dart';

/// Represents a book in the application.
///
/// A `Book` object has a [title] which is the name of the book,
/// and an [author], [heShortDesc], [pubPlace], [pubDate], and [order] if available.
///
abstract class Book {
  /// The title of the book.
  final String title;

  /// an access to the data layer
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
}

///a representation of a text book (opposite PDF book).
///a text book has a getter 'text' which returns a [Future] that resolvs to a [String].
///it has also a 'tableOfContents' field that returns a [Future] that resolvs to a list of [TocEntry]s
class TextBook extends Book {
  TextBook({required String title}) : super(title: title);

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

  /// The text data of the book.
  Future<String> get text async => (await data.getBookText(title));

  /// Creates a new `Book` instance from a JSON object.
  ///
  /// The JSON object should have a 'title' key.
  factory TextBook.fromJson(Map<String, dynamic> json) {
    return TextBook(
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

///represents an entry in table of content , which is a node in a hirarchial tree of topics.
///every entry has its 'level' in the tree, and an index of the line in the book that it is refers to
class TocEntry {
  final String text;
  final int index;
  final int level;
  List<TocEntry> children = [];

  ///creats [TocEntry]
  TocEntry({
    required this.text,
    required this.index,
    this.level = 1,
  });
}

///represents a PDF format book, which is always a file on the device, and there for the [String] fiels 'path'
///is required
class PdfBook extends Book {
  final String path;
  PdfBook({required String title, required this.path}) : super(title: title);

  ///get a preview of the first page in the book (returns a [Widget] viewing the page)
  Future<PdfPageView> get thumbnail async {
    //TODO memory efiiciecy is needed
    var document = await PdfDocument.openFile(
      path,
    );
    var result = PdfPageView(
      document: document,
      pageNumber: 1,
    );
    //free the memory
    document.dispose();
    return result;
  }

  factory PdfBook.fromJson(Map<String, dynamic> json) {
    return PdfBook(
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
