import 'package:otzaria/models/books.dart';

/// Represents a bookmark in the application.
class Bookmark {
  final String ref;
  final Book book;
  final List<String> commentatorsToShow;
  final int index;
  final bool isSearch;
  final Map<String, Map<String, bool>>? searchOptions;
  final Map<int, List<String>>? alternativeWords;
  final Map<String, String>? spacingValues;

  /// A stable key for history management, unique per book title.
  String get historyKey => isSearch ? ref : book.title;

  Bookmark({
    required this.ref,
    required this.book,
    required this.index,
    this.commentatorsToShow = const [],
    this.isSearch = false,
    this.searchOptions,
    this.alternativeWords,
    this.spacingValues,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    final rawCommentators = json['commentatorsToShow'] as List<dynamic>?;
    return Bookmark(
      ref: json['ref'] as String,
      index: json['index'] as int,
      book: Book.fromJson(json['book'] as Map<String, dynamic>),
      commentatorsToShow:
          (rawCommentators ?? []).map((e) => e.toString()).toList(),
      isSearch: json['isSearch'] ?? false,
      searchOptions: json['searchOptions'] != null
          ? (json['searchOptions'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key,
                (value as Map<String, dynamic>)
                    .map((k, v) => MapEntry(k, v as bool)),
              ),
            )
          : null,
      alternativeWords: json['alternativeWords'] != null
          ? (json['alternativeWords'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                int.parse(key),
                (value as List<dynamic>).map((e) => e.toString()).toList(),
              ),
            )
          : null,
      spacingValues: json['spacingValues'] != null
          ? (json['spacingValues'] as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, value.toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ref': ref,
      'book': book.toJson(),
      'index': index,
      'commentatorsToShow': commentatorsToShow,
      'isSearch': isSearch,
      'searchOptions': searchOptions,
      'alternativeWords': alternativeWords
          ?.map((key, value) => MapEntry(key.toString(), value)),
      'spacingValues': spacingValues,
    };
  }
}
