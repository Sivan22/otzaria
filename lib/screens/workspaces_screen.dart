import 'package:flutter/material.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:provider/provider.dart';

class WorkspacesView extends StatefulWidget {
  const WorkspacesView({
    Key? key,
  }) : super(key: key);

  @override
  State<WorkspacesView> createState() => _WorkspacesViewState();
}

class _WorkspacesViewState extends State<WorkspacesView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(builder: (context, appModel, child) {
      return appModel.workspaces.isEmpty
          ? const Center(child: Text('אין סביבות עבודה'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: appModel.workspaces.length,
                    itemBuilder: (context, index) {
                      TextEditingController textFieldController =
                          TextEditingController(
                              text: appModel.workspaces[index].name);
                      bool isEditing = false;
                      return StatefulBuilder(builder: (context, setState) {
                        return ListTile(
                          title: !isEditing
                              ? Text(appModel.workspaces[index].name)
                              : TextField(
                                  enabled: isEditing,
                                  controller: textFieldController,
                                  onEditingComplete: () {
                                    appModel.workspaces[index].name =
                                        textFieldController.text;
                                    isEditing = false;
                                    setState(() {});
                                    appModel.saveWorkspacesToDisk();
                                  }),
                          onTap: () {
                            appModel
                                .switchWorkspace(appModel.workspaces[index]);
                            appModel.currentView.value = Screens.reading;
                          },
                          trailing: SizedBox.fromSize(
                            size: Size.fromWidth(120),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          isEditing = true;
                                        });
                                      }),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_forever,
                                  ),
                                  onPressed: () {
                                    appModel.removeBookmark(index);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('סביבת העבודה נמחקה'),
                                      ),
                                    );
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      appModel.clearWorkspaces();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('כל סביבות העבודה נמחקו'),
                        ),
                      );
                      setState(() {});
                    },
                    child: const Text('מחק את כל סביבות העבודה'),
                  ),
                ),
              ],
            );
    });
  }
}
