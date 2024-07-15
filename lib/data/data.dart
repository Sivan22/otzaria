/* this is an abstract class of the data layer,
 providing all the data access methods needed for the app model. */

import 'package:otzaria/models/library.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/links.dart';

/// Abstract class of the data layer.
///
/// Provides all the data access methods needed for the app model.
///
/// The `Data` class represents an abstract layer for handling the app's data.
/// It declares the methods for accessing the library, book text, book table of contents,
/// and links for a book.
///
/// The `metadata` field is a map, where the keys are book titles and the values are maps,
/// where the keys are metadata fields and the values are their corresponding values.
///
/// The `getLibrary` method returns a [Library] object, which represents the library.
/// The `getBookText` method returns a [Future] that resolves to a [String],
/// which contains the text of the book with the given title.
/// The `getBookToc` method returns a [Future] that resolves to a [List] of [TocEntry] objects,
/// which represent the table of contents of the book with the given title.
/// The `getAllLinksForBook` method returns a [Future] that resolves to a [List] of [Link] objects,
/// which represent the links for the book with the given title.
/// The `getLinkContent` method returns a [Future] that resolves to a [String],
/// which contains the content of the link.
abstract class Data {
  Map<String, Map<String, dynamic>> metadata = {};

  /// Returns the library.
  Library getLibrary();

  /// Returns the text of the book with the given title.
  Future<String> getBookText(String title);

  /// Returns the table of contents of the book with the given title.
  Future<List<TocEntry>> getBookToc(String title);

  /// Returns the links for the book with the given title.
  Future<List<Link>> getAllLinksForBook(String title);

  /// Returns the content of the link.
  Future<String> getLinkContent(Link link);
}
