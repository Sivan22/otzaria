import 'package:equatable/equatable.dart';
import 'package:otzaria/workspaces/workspace.dart';
import 'package:otzaria/tabs/models/tab.dart';

abstract class WorkspaceEvent extends Equatable {
  const WorkspaceEvent();

  @override
  List<Object?> get props => [];
}

class LoadWorkspaces extends WorkspaceEvent {}

class AddWorkspace extends WorkspaceEvent {
  final String name;
  final List<OpenedTab> tabs;
  final int currentTabIndex;

  const AddWorkspace({
    required this.name,
    required this.tabs,
    required this.currentTabIndex,
  });

  @override
  List<Object?> get props => [name, tabs, currentTabIndex];
}

class RemoveWorkspace extends WorkspaceEvent {
  final Workspace workspace;

  const RemoveWorkspace(this.workspace);

  @override
  List<Object?> get props => [workspace];
}

class SwitchToWorkspace extends WorkspaceEvent {
  final Workspace workspace;

  const SwitchToWorkspace(this.workspace);

  @override
  List<Object?> get props => [workspace];
}

class RenameWorkspace extends WorkspaceEvent {
  final Workspace workspace;
  final String newName;

  const RenameWorkspace(this.workspace, this.newName);

  @override
  List<Object?> get props => [workspace, newName];
}

class ClearWorkspaces extends WorkspaceEvent {}
