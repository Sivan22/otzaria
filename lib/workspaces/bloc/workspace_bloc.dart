import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/workspaces/bloc/workspace_event.dart';
import 'package:otzaria/workspaces/bloc/workspace_state.dart';
import 'package:otzaria/workspaces/workspace.dart';
import 'package:otzaria/workspaces/workspace_repository.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_event.dart';

class WorkspaceBloc extends Bloc<WorkspaceEvent, WorkspaceState> {
  final WorkspaceRepository _repository;
  final TabsBloc _tabsBloc;

  WorkspaceBloc({
    required WorkspaceRepository repository,
    required TabsBloc tabsBloc,
  })  : _repository = repository,
        _tabsBloc = tabsBloc,
        super(WorkspaceState.initial()) {
    on<LoadWorkspaces>(_onLoadWorkspaces);
    on<AddWorkspace>(_onAddWorkspace);
    on<RemoveWorkspace>(_onRemoveWorkspace);
    on<SwitchToWorkspace>(_onSwitchToWorkspace);
    on<RenameWorkspace>(_onRenameWorkspace);
    on<ClearWorkspaces>(_onClearWorkspaces);
  }

  void _onLoadWorkspaces(LoadWorkspaces event, Emitter<WorkspaceState> emit) {
    emit(state.copyWith(isLoading: true));
    try {
      final workspaces = _repository.loadWorkspaces();
      if (workspaces.$1.isEmpty) {
        workspaces.$1
            .add(Workspace(name: "שולחן עבודה 1", tabs: [], currentTab: 0));
      }

      final currentWorkSpace = workspaces.$2;

      workspaces.$1[currentWorkSpace] = Workspace(
          name: workspaces.$1[currentWorkSpace].name,
          tabs: _tabsBloc.state.tabs,
          currentTab: _tabsBloc.state.currentTabIndex);

      _repository.saveWorkspaces(workspaces.$1, currentWorkSpace);

      emit(state.copyWith(
        workspaces: workspaces.$1,
        currentWorkspace: workspaces.$2,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load workspaces: $e',
      ));
    }
  }

  void _onAddWorkspace(AddWorkspace event, Emitter<WorkspaceState> emit) {
    try {
      final newWorkspace = Workspace(
        name: event.name,
        tabs: event.tabs,
        currentTab: event.currentTabIndex,
      );

      final updatedWorkspaces = List<Workspace>.from(state.workspaces)
        ..add(newWorkspace);

      _repository.saveWorkspaces(
          updatedWorkspaces, state.currentWorkspace ?? 0);

      emit(state.copyWith(
        workspaces: updatedWorkspaces,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to add workspace: $e',
      ));
    }
  }

  void _onRemoveWorkspace(RemoveWorkspace event, Emitter<WorkspaceState> emit) {
    try {
      int activeWorkspaceIndex = state.currentWorkspace ?? 0;
      int indexOfWorkspaceToRemove = state.workspaces.indexOf(event.workspace);

      // can't remove active workspace
      if (activeWorkspaceIndex == indexOfWorkspaceToRemove) {
        return;
      }

      final updatedWorkspaces = List<Workspace>.from(state.workspaces)
        ..remove(event.workspace);

      //update the active workspace
      if (activeWorkspaceIndex > indexOfWorkspaceToRemove) {
        activeWorkspaceIndex -= 1;
      }

      _repository.saveWorkspaces(updatedWorkspaces, activeWorkspaceIndex);

      emit(state.copyWith(
        workspaces: updatedWorkspaces,
        currentWorkspace: activeWorkspaceIndex,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to remove workspace: $e',
      ));
    }
  }

  void _onSwitchToWorkspace(
      SwitchToWorkspace event, Emitter<WorkspaceState> emit) {
    try {
      // First, save current tabs to the current workspace
      final currentTabs = _tabsBloc.state.tabs;
      final currentTabIndex = _tabsBloc.state.currentTabIndex;

      final currentWorkspace = Workspace(
        name: state.workspaces[state.currentWorkspace ?? 0].name,
        tabs: currentTabs,
        currentTab: currentTabIndex,
      );

      // Add the opened tabs to current workspase
      final updatedWorkspaces = List<Workspace>.from(state.workspaces);
      updatedWorkspaces[state.currentWorkspace ?? 0] = currentWorkspace;

      final newWorkspaceIndex = state.workspaces.indexOf(event.workspace);

      _repository.saveWorkspaces(updatedWorkspaces, newWorkspaceIndex);

      emit(state.copyWith(
          workspaces: updatedWorkspaces, currentWorkspace: newWorkspaceIndex));

      // Now switch to the selected workspace
      // Close all current tabs
      _tabsBloc.add(CloseAllTabs());

      // Add tabs from the selected workspace
      for (final tab in event.workspace.tabs) {
        _tabsBloc.add(AddTab(tab));
      }

      // Set the current tab
      if (event.workspace.tabs.isNotEmpty) {
        _tabsBloc.add(SetCurrentTab(
            event.workspace.currentTab < event.workspace.tabs.length
                ? event.workspace.currentTab
                : 0));
      }
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to switch workspace: $e',
      ));
    }
  }

  void _onRenameWorkspace(RenameWorkspace event, Emitter<WorkspaceState> emit) {
    try {
      final index = state.workspaces.indexOf(event.workspace);
      if (index != -1) {
        final updatedWorkspace = Workspace(
          name: event.newName,
          tabs: event.workspace.tabs,
          currentTab: event.workspace.currentTab,
        );

        final updatedWorkspaces = List<Workspace>.from(state.workspaces)
          ..[index] = updatedWorkspace;

        _repository.saveWorkspaces(
            updatedWorkspaces, state.currentWorkspace ?? 0);

        emit(state.copyWith(
          workspaces: updatedWorkspaces,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to rename workspace: $e',
      ));
    }
  }

  void _onClearWorkspaces(ClearWorkspaces event, Emitter<WorkspaceState> emit) {
    try {
      final currentTabs = _tabsBloc.state.tabs;
      final currentTabIndex = _tabsBloc.state.currentTabIndex;

      final currentWorkspace = Workspace(
        name: "ברירת מחדל",
        tabs: currentTabs,
        currentTab: currentTabIndex,
      );

      _repository.saveWorkspaces([currentWorkspace], 0);

      emit(state.copyWith(
        workspaces: [currentWorkspace],
        currentWorkspace: 0,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to clear workspaces: $e',
      ));
    }
  }
}
