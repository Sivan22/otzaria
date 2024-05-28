import 'package:flutter/material.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/tabs.dart';
import 'package:provider/provider.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({
    Key? key,
  }) : super(key: key);

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(builder: (context, appModel, child) {
      return appModel.history.isEmpty
          ? const Center(child: Text('אין היסטוריה'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: appModel.history.length,
                    itemBuilder: (context, index) => ListTile(
                        title: Text(appModel.history[index].ref),
                        onTap: () => appModel.openBook(
                            appModel.history[index].book,
                            appModel.history[index].index),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_forever,
                          ),
                          onPressed: () {
                            appModel.removeHistory(index);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('נמחק בהצלחה'),
                              ),
                            );
                            setState(() {});
                          },
                        )),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      appModel.clearHistory();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('כל ההיסטוריה נמחקה'),
                        ),
                      );
                      setState(() {});
                    },
                    child: const Text('מחק את כל ההיסטוריה'),
                  ),
                ),
              ],
            );
    });
  }
}
