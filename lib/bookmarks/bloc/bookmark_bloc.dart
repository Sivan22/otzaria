import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/bookmarks/bloc/bookmark_state.dart';
import 'package:otzaria/bookmarks/models/bookmark.dart';
import 'package:otzaria/bookmarks/repository/bookmark_repository.dart';
import 'package:otzaria/models/books.dart';

class BookmarkBloc extends Cubit<BookmarkState> {
  final BookmarkRepository _repository;

  BookmarkBloc(this._repository) : super(BookmarkState.initial(_repository));

  bool addBookmark(
      {required String ref,
      required Book book,
      required int index,
      List<String>? commentatorsToShow}) {
    final bookmark = Bookmark(
        ref: ref,
        book: book,
        index: index,
        commentatorsToShow: commentatorsToShow ?? []);
    // check if bookmark already exists
    if (state.bookmarks.any((b) => b.ref == bookmark.ref)) return false;

    final newBookmarks = [...state.bookmarks, bookmark];
    _repository.saveBookmarks(newBookmarks);
    emit(state.copyWith(bookmarks: newBookmarks));
    return true;
  }

  void removeBookmark(int index) {
    final newBookmarks = [...state.bookmarks]..removeAt(index);
    _repository.saveBookmarks(newBookmarks);
    emit(state.copyWith(bookmarks: newBookmarks));
  }

  void clearBookmarks() {
    _repository.clearBookmarks();
    emit(state.copyWith(bookmarks: []));
  }
}
