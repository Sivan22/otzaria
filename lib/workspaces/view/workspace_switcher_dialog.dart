import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/workspaces/bloc/workspace_bloc.dart';
import 'package:otzaria/workspaces/bloc/workspace_event.dart';
import 'package:otzaria/workspaces/bloc/workspace_state.dart';
import 'package:otzaria/workspaces/workspace.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_state.dart';
import 'package:otzaria/daf_yomi/calendar.dart';
import 'package:otzaria/core/scaffold_messenger.dart';
import 'package:otzaria/i18n/translations.g.dart';

class WorkspaceSwitcherDialog extends StatefulWidget {
  const WorkspaceSwitcherDialog({super.key});

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

  String _generateUniqueWorkspaceName(List<Workspace> existingWorkspaces) {
    final existingNames = existingWorkspaces.map((w) => w.name).toSet();
    int counter = existingWorkspaces.length + 1;

    while (true) {
      final candidateName = "שולחן עבודה $counter";
      if (!existingNames.contains(candidateName)) {
        return candidateName;
      }
      counter++;
    }
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
                  icon: const Icon(FluentIcons.dismiss_24_regular),
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
                    return Center(
                        child: Text(
                            '${context.t.common.error}: ${state.error}')); // Old: 'שגיאה: ${state.error}'
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
              final newWorkspaceName =
                  _generateUniqueWorkspaceName(workspaceBloc.state.workspaces);
              workspaceBloc.add(AddWorkspace(
                  name: newWorkspaceName, tabs: const [], currentTabIndex: 0));
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
                    FluentIcons.add_24_regular,
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
                              .withValues(alpha: 0.5)
                          : Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
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
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onSubmitted: (newName) {
                                if (newName.trim().isNotEmpty) {
                                  context.read<WorkspaceBloc>().add(
                                        RenameWorkspace(
                                          workspace,
                                          newName.trim(),
                                        ),
                                      );
                                }
                                setState(() {
                                  isEditing = false;
                                });
                              },
                              onTapOutside: (event) {
                                setState(() {
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
                                    icon:
                                        const Icon(FluentIcons.edit_24_regular),
                                    onPressed: () {
                                      setState(() {
                                        editController = TextEditingController(
                                            text: workspace.name);
                                        // Set cursor position to end of text
                                        editController.selection =
                                            TextSelection.fromPosition(
                                          TextPosition(
                                              offset: workspace.name.length),
                                        );
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
              icon: const Icon(FluentIcons.dismiss_24_regular, size: 16),
              onPressed: () {
                // Remove the workspace
                if (isActive) {
                  UiSnack.showError('לא ניתן למחוק שולחן עבודה פעיל',
                      backgroundColor: Theme.of(context).colorScheme.error);
                  return;
                }
                context.read<WorkspaceBloc>().add(RemoveWorkspace(workspace));
                UiSnack.show('שולחן העבודה נמחק');
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
