import 'package:otzaria/bookmarks/models/bookmark.dart';
import 'package:otzaria/tabs/models/tab.dart';

abstract class HistoryEvent {}

class LoadHistory extends HistoryEvent {}

class AddHistory extends HistoryEvent {
  final OpenedTab tab;
  AddHistory(this.tab);
}

class CaptureStateForHistory extends HistoryEvent {
  final OpenedTab tab;
  CaptureStateForHistory(this.tab);
}

class FlushHistory extends HistoryEvent {}

class BulkAddHistory extends HistoryEvent {
  final List<Bookmark> snapshots;
  BulkAddHistory(this.snapshots);
}

class RemoveHistory extends HistoryEvent {
  final int index;
  RemoveHistory(this.index);
}

class ClearHistory extends HistoryEvent {}
