import 'package:otzaria/tabs/models/tab.dart';

abstract class HistoryEvent {}

class LoadHistory extends HistoryEvent {}

class AddHistory extends HistoryEvent {
  final OpenedTab tab;
  AddHistory(this.tab);
}

class RemoveHistory extends HistoryEvent {
  final int index;
  RemoveHistory(this.index);
}

class ClearHistory extends HistoryEvent {}
