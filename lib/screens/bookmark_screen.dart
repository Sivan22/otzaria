import 'package:flutter/material.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:provider/provider.dart';

class BookmarkView extends StatefulWidget {
  const BookmarkView({
    Key? key,
  }) : super(key: key);

  @override
  State<BookmarkView> createState() => _BookmarkViewState();
}

class _BookmarkViewState extends State<BookmarkView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(builder: (context, appModel, child) {
      return appModel.bookmarks.isEmpty
          ? const Center(child: Text('אין סימניות'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: appModel.bookmarks.length,
                    itemBuilder: (context, index) => ListTile(
                        title: Text(appModel.bookmarks[index].ref),
                        onTap: () => appModel.openBook(
                              appModel.bookmarks[index].book,
                              appModel.bookmarks[index].index,
                            ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_forever,
                          ),
                          onPressed: () {
                            appModel.removeBookmark(index);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('הסימניה נמחקה'),
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
                      appModel.clearBookmarks();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('כל הסימניות נמחקו'),
                        ),
                      );
                      setState(() {});
                    },
                    child: const Text('מחק את כל הסימניות'),
                  ),
                ),
              ],
            );
    });
  }
}
