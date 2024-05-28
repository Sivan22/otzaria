import 'package:otzaria/models/books.dart';

/// Represents a bookmark in the application.
///
/// A `Bookmark` object has a [ref] which is a reference to a specific
/// part of a text (can be a word, a phrase, a sentence, etc.), a [title]
/// which is the name of the book, and an [index] which is the index
/// of the bookmark in the text.
class Bookmark {
  /// The reference to a specific part of a text.
  final String ref;

  //the book
  final Book book;

  //the commentators to show
  final List<String> commentatorsToShow;

  /// The index of the bookmark in the text.
  final int index;

  /// Creates a new `Bookmark` instance.
  ///
  /// The [ref], [title], and [index] parameters must not be null.
  Bookmark(
      {required this.ref,
      required this.book,
      required this.index,
      this.commentatorsToShow = const []});

  /// Creates a new `Bookmark` instance from a JSON object.
  ///
  /// The JSON object must have 'ref', 'title', and 'index' keys.
  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      ref: json['ref'] as String,
      index: json['index'] as int,
      book: Book.fromJson(json['book'] as Map<String, dynamic>),
    );
  }

  /// Converts the `Bookmark` instance into a JSON object.
  ///
  /// Returns a JSON object with 'ref', 'title', and 'index' keys.
  Map<String, dynamic> toJson() {
    return {
      'ref': ref,
      'book': book.toJson(),
      'index': index,
    };
  }
}
