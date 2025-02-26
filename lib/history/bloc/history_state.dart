import 'package:otzaria/bookmarks/models/bookmark.dart';

abstract class HistoryState {
  final List<Bookmark> history;
  HistoryState(this.history);
}

class HistoryInitial extends HistoryState {
  HistoryInitial() : super([]);
}

class HistoryLoading extends HistoryState {
  HistoryLoading(super.history);
}

class HistoryLoaded extends HistoryState {
  HistoryLoaded(super.history);
}

class HistoryError extends HistoryState {
  final String message;
  HistoryError(super.history, this.message);
}
