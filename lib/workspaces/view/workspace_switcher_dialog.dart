import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/workspaces/bloc/workspace_bloc.dart';
import 'package:otzaria/workspaces/bloc/workspace_event.dart';
import 'package:otzaria/workspaces/bloc/workspace_state.dart';
import 'package:otzaria/workspaces/workspace.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_state.dart';
import 'package:otzaria/daf_yomi/calendar.dart';

class WorkspaceSwitcherDialog extends StatefulWidget {
  const WorkspaceSwitcherDialog({Key? key}) : super(key: key);

  @override
  State<WorkspaceSwitcherDialog> createState() =>
      _WorkspaceSwitcherDialogState();
}

class _WorkspaceSwitcherDialogState extends State<WorkspaceSwitcherDialog> {
  final TextEditingController _textFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textFieldController.text = getHebrewTimeStamp();
    context.read<WorkspaceBloc>().add(LoadWorkspaces());
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'שולחנות עבודה',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<WorkspaceBloc, WorkspaceState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.error != null) {
                    return Center(child: Text('שגיאה: ${state.error}'));
                  }

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: state.workspaces.length + 1,
                    itemBuilder: (context, index) {
                      if (index == state.workspaces.length) {
                        // "New Workspace" tile
                        return _buildNewWorkspaceTile(context);
                      } else {
                        // Workspace tile
                        final workspace = state.workspaces[index];
                        final isActive = state.currentWorkspace == index;
                        return _buildWorkspaceTile(
                            context, workspace, isActive);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewWorkspaceTile(BuildContext context) {
    return BlocBuilder<TabsBloc, TabsState>(
      builder: (context, tabsState) {
        return Card(
          child: InkWell(
            onTap: () {
              final workspaceBloc = context.read<WorkspaceBloc>();
              workspaceBloc.add(AddWorkspace(
                  name:
                      "שולחן עבודה חדש ${workspaceBloc.state.workspaces.length + 1}",
                  tabs: const [],
                  currentTabIndex: 0));
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'שולחן עבודה חדש',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkspaceTile(
      BuildContext context, Workspace workspace, bool isActive) {
    return Card(
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              context.read<WorkspaceBloc>().add(SwitchToWorkspace(workspace));
              Navigator.of(context).pop();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5)
                          : Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                    child: _buildWorkspacePreview(workspace),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Builder(builder: (context) {
                    bool isEditing = false; // Flag to track editing
                    late TextEditingController editController;
                    return StatefulBuilder(builder: (context, setState) {
                      return isEditing
                          ? TextField(
                              controller: editController,
                              autofocus: true,
                              onSubmitted: (newName) {
                                setState(() {
                                  context.read<WorkspaceBloc>().add(
                                        RenameWorkspace(
                                          workspace,
                                          newName,
                                        ),
                                      );
                                  isEditing = false;
                                });
                              },
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    workspace.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      setState(() {
                                        editController = TextEditingController(text: workspace.name);
                                        isEditing = true;
                                      });
                                    })
                              ],
                            );
                    });
                  }),
                )
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () {
                // Remove the workspace
                if (isActive) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('לא ניתן למחוק שולחן עבודה פעיל')));
                  return;
                }
                context.read<WorkspaceBloc>().add(RemoveWorkspace(workspace));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('שולחן העבודה נמחק')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspacePreview(Workspace workspace) {
    // Simple representation of tabs in the workspace
    return Center(
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: workspace.tabs.map((tab) {
          return Tooltip(
            message: tab.title,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
