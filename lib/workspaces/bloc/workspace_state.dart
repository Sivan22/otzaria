import 'package:equatable/equatable.dart';
import 'package:otzaria/workspaces/workspace.dart';

class WorkspaceState extends Equatable {
  final List<Workspace> workspaces;
  final bool isLoading;
  final String? error;
  final int? currentWorkspace;

  const WorkspaceState(
      {required this.workspaces,
      this.isLoading = false,
      this.error,
      this.currentWorkspace});

  factory WorkspaceState.initial() {
    return const WorkspaceState(
      workspaces: [],
      isLoading: true,
      error: null,
      currentWorkspace: null,
    );
  }

  WorkspaceState copyWith({
    List<Workspace>? workspaces,
    bool? isLoading,
    String? error,
    int? currentWorkspace,
  }) {
    return WorkspaceState(
      workspaces: workspaces ?? this.workspaces,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentWorkspace: currentWorkspace ?? this.currentWorkspace,
    );
  }

  @override
  List<Object?> get props => [workspaces, isLoading, error, currentWorkspace];
}
