import 'package:otzaria/models/tabs.dart';

/// Represents a bookmark in the application.
///
/// A `Bookmark` object has a [ref] which is a reference to a specific
/// part of a text (can be a word, a phrase, a sentence, etc.), a [title]
/// which is the name of the book, and an [index] which is the index
/// of the bookmark in the text.
class Bookmark {
  /// The reference to a specific part of a text.
  final String ref;

  /// all the information to restore the book and comentators
  final OpenedTab tab;

  /// The index of the bookmark in the text.
  final int index;

  /// Creates a new `Bookmark` instance.
  ///
  /// The [ref], [title], and [index] parameters must not be null.
  Bookmark({required this.ref, required this.tab, required this.index});

  /// Creates a new `Bookmark` instance from a JSON object.
  ///
  /// The JSON object must have 'ref', 'title', and 'index' keys.
  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      ref: json['ref'] as String,
      tab: OpenedTab.fromJson(json['tab'] as Map<String, dynamic>),
      index: json['index'] as int,
    );
  }

  /// Converts the `Bookmark` instance into a JSON object.
  ///
  /// Returns a JSON object with 'ref', 'title', and 'index' keys.
  Map<String, dynamic> toJson() {
    return {
      'ref': ref,
      'tab': tab.toJson(),
      'index': index,
    };
  }
}
