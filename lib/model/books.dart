import 'package:otzaria/data/data.dart';
import 'package:otzaria/data/file_system_data.dart';
import 'package:otzaria/model/links.dart';
import 'dart:isolate';

/// Represents a book in the application.
///
/// A `Book` object has a [title] which is the name of the book.
/// The book data is fetched using the [bookData] getter, which returns a [Future]
/// that resolves to a [String] containing the text of the book.
class Book {
  /// The title of the book.
  final String title;
  final Data data = FileSystemData.instance;

  /// The text data of the book.
  Future<String> get text async => (await data.getBookText(title));

  /// The author of the book.
  String? get author => data.metadata[title]?['author'];

  //the short description of the book
  String? get heShortDesc => data.metadata[title]?['heShortDesc'];

  /// The publication date of the book.
  String? get pubDate => data.metadata[title]?['pubDate'];

  /// The place where the book was published.
  String? get pubPlace => data.metadata[title]?['pubPlace'];

  /// The order of the book in the list of books.
  int get order => data.metadata[title]?['order'] == null
      ? 999
      : data.metadata[title]!['order'] as int;

  /// Creates a new `Book` instance.
  ///
  /// The [title] parameter is required and cannot be null.
  ///
  /// The [author] parameter is optional and defaults to an empty string.
  ///
  /// The [pubDate] parameter is optional and defaults to an empty string.
  ///
  /// The [pubPlace] parameter is optional and defaults to an empty string.
  ///
  /// The [order] parameter is optional and defaults to 0.
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
