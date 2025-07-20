import 'package:otzaria/models/books.dart';

/// Represents a bookmark in the application.
class Bookmark {
  final String ref;
  final Book book;
  final List<String> commentatorsToShow;
  final int index;

  /// A stable key for history management, unique per book title.
  String get historyKey => book.title;

  Bookmark({
    required this.ref,
    required this.book,
    required this.index,
    this.commentatorsToShow = const [],
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    final rawCommentators = json['commentatorsToShow'] as List<dynamic>?;
    return Bookmark(
      ref: json['ref'] as String,
      index: json['index'] as int,
      book: Book.fromJson(json['book'] as Map<String, dynamic>),
      commentatorsToShow: (rawCommentators ?? []).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ref': ref,
      'book': book.toJson(),
      'index': index,
      'commentatorsToShow': commentatorsToShow,
    };
  }
}
