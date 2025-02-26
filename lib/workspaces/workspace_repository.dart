import 'package:hive/hive.dart';
import 'package:otzaria/workspaces/workspace.dart';

class WorkspaceRepository {
  static const String _workspacesBoxKey = 'key-workspaces';

  (List<Workspace>, int) loadWorkspaces() {
    try {
      final box = Hive.box(name: 'workspaces');
      final rawWorkspaces =
          box.get(_workspacesBoxKey, defaultValue: []) as List;
      final currentWorksapce =
          box.get("key-current-workspace", defaultValue: 0) as int;
      return (
        List<Workspace>.from(
          rawWorkspaces.map((e) => Workspace.fromJson(e)).toList(),
        ),
        currentWorksapce
      );
    } catch (e) {
      print('Error loading workspaces from disk: $e');
      Hive.box(name: 'workspaces').put(_workspacesBoxKey, []);
      return ([], 0);
    }
  }

  void saveWorkspaces(List<Workspace> workspaces, int currentWorkspace) {
    final box = Hive.box(name: 'workspaces');
    box.put(_workspacesBoxKey,
        workspaces.map((workspace) => workspace.toJson()).toList());
    Hive.box(name: 'workspaces').put("key-current-workspace", currentWorkspace);
  }
}
