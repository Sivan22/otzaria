import 'package:otzaria/data/repository/data.dart';
import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:otzaria/models/links.dart';
import 'dart:isolate';
//import 'package:pdfrx/pdfrx.dart';

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
  String? author;

  /// A short description of the book, if available.
  String? heShortDesc;

  /// The publication date of the book, if available.
  String? pubDate;

  /// The place where the book was published, if available.
  String? pubPlace;

  /// The order of the book in the list of books. If not available, defaults to 999.
  int order;

  String topics;

  Map<String, dynamic> toJson();

  factory Book.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'TextBook':
        return TextBook(title: json['title']);
      case 'PdfBook':
        return PdfBook(title: json['title'], path: json['path']);
      case 'OtzarBook':
        return ExternalBook.fromJson(json);
      default:
        throw Exception('Unknown book type: ${json['type']}');
    }
  }

  /// Creates a new `Book` instance.
  ///
  /// The [title] parameter is required and cannot be null.
  Book({
    required this.title,
    this.author,
    this.heShortDesc,
    this.pubDate,
    this.pubPlace,
    this.order = 999,
    this.topics = '',
  });
}

///a representation of a text book (opposite PDF book).
///a text book has a getter 'text' which returns a [Future] that resolvs to a [String].
///it has also a 'tableOfContents' field that returns a [Future] that resolvs to a list of [TocEntry]s
class TextBook extends Book {
  TextBook({
    required String title,
    super.author,
    super.heShortDesc,
    super.pubDate,
    super.pubPlace,
    super.order = 999,
    super.topics,
  }) : super(title: title);

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
  @override
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': 'TextBook',
    };
  }
}

///represents an entry in table of content , which is a node in a hirarchial tree of topics.
///every entry has its 'level' in the tree, and an index of the line in the book that it is refers to
class TocEntry {
  String text;
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

/// Represents a book from the Otzar HaChochma digital library.
///
/// This class extends the [Book] class and includes additional properties
/// specific to Otzar HaChochma books, such as the Otzar ID and online link.
class ExternalBook extends Book {
  /// The unique identifier for the book in the Otzar HaChochma system.
  final int id;

  /// The online link to access the book in the Otzar HaChochma system.
  final String link;

  /// Creates an [ExternalBook] instance.
  ///
  /// [title] and [id] are required. Other parameters are optional.
  /// [link] is required for online access to the book.
  ExternalBook({
    required String title,
    required this.id,
    super.author,
    super.pubPlace,
    super.pubDate,
    super.topics,
    super.heShortDesc,
    required this.link,
  }) : super(title: title);

  /// Returns the publication date of the book.
  ///

  /// Creates an [ExternalBook] instance from a JSON map.
  ///
  /// This factory constructor is used to deserialize OtzarBook objects.
  factory ExternalBook.fromJson(Map<String, dynamic> json) {
    return ExternalBook(
      title: json['bookName'],
      id: json['id'],
      author: json['author'],
      pubPlace: json['pubPlace'],
      pubDate: json['pubDate'],
      topics: json['topics'],
      link: json['link'],
    );
  }

  /// Converts the [ExternalBook] instance to a JSON map.
  ///
  /// This method is used to serialize OtzarBook objects.
  @override
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': 'ExternalBook',
      'otzarId': id,
      'author': author,
      'pubPlace': pubPlace,
      'pubDate': pubDate,
      'topics': topics,
      'link': link,
    };
  }
}

///represents a PDF format book, which is always a file on the device, and there for the [String] fiels 'path'
///is required
class PdfBook extends Book {
  final String path;
  PdfBook(
      {required String title,
      required this.path,
      super.topics,
      super.author,
      super.heShortDesc,
      super.pubDate,
      super.pubPlace,
      super.order = 999})
      : super(title: title);

  factory PdfBook.fromJson(Map<String, dynamic> json) {
    return PdfBook(
      title: json['title'],
      path: json['path'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'title': title, 'path': path, 'type': 'PdfBook'};
  }

  @override
  String toString() => 'pdfBook(title: $title, path: $path)';
}
