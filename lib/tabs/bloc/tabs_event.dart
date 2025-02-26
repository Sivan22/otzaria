import 'package:equatable/equatable.dart';
import 'package:otzaria/tabs/models/tab.dart';

abstract class TabsEvent extends Equatable {
  const TabsEvent();

  @override
  List<Object?> get props => [];
}

class AddTab extends TabsEvent {
  final OpenedTab tab;

  const AddTab(this.tab);

  @override
  List<Object?> get props => [tab];
}

class RemoveTab extends TabsEvent {
  final OpenedTab tab;

  const RemoveTab(this.tab);

  @override
  List<Object?> get props => [tab];
}

class CloseCurrentTab extends TabsEvent {
  const CloseCurrentTab();

  @override
  List<Object?> get props => [];
}

class SetCurrentTab extends TabsEvent {
  final int index;

  const SetCurrentTab(this.index);

  @override
  List<Object?> get props => [index];
}

class CloseAllTabs extends TabsEvent {}

class CloseOtherTabs extends TabsEvent {
  final OpenedTab keepTab;

  const CloseOtherTabs(this.keepTab);

  @override
  List<Object?> get props => [keepTab];
}

class CloneTab extends TabsEvent {
  final OpenedTab tab;

  const CloneTab(this.tab);

  @override
  List<Object?> get props => [tab];
}

class MoveTab extends TabsEvent {
  final OpenedTab tab;
  final int newIndex;

  const MoveTab(this.tab, this.newIndex);

  @override
  List<Object?> get props => [tab, newIndex];
}

class NavigateToNextTab extends TabsEvent {}

class NavigateToPreviousTab extends TabsEvent {}

class LoadTabs extends TabsEvent {}
