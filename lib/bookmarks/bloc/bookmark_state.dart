import 'package:otzaria/bookmarks/models/bookmark.dart';
import 'package:otzaria/bookmarks/repository/bookmark_repository.dart';

class BookmarkState {
  final List<Bookmark> bookmarks;

  BookmarkState({required this.bookmarks});

  factory BookmarkState.initial(BookmarkRepository repository) {
    return BookmarkState(bookmarks: repository.loadBookmarks());
  }

  BookmarkState copyWith({List<Bookmark>? bookmarks}) {
    return BookmarkState(
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }
}
