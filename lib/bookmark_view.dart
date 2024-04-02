import 'package:flutter/material.dart';
import 'opened_tabs.dart';
import 'package:hive/hive.dart';

class BookmarkView extends StatefulWidget {
  final List<Bookmark> bookmarks;
  final void Function(String path, int index) openBookmarkCallBack;
  const BookmarkView(
      {Key? key, required this.bookmarks, required this.openBookmarkCallBack})
      : super(key: key);

  @override
  State<BookmarkView> createState() => _BookmarkViewState();
}

class _BookmarkViewState extends State<BookmarkView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: widget.bookmarks.length,
            itemBuilder: (context, index) => ListTile(
                title: Text(widget.bookmarks[index].ref),
                onTap: () {
                  widget.openBookmarkCallBack(widget.bookmarks[index].path,
                      widget.bookmarks[index].index);
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete_forever),
                  onPressed: () {
                    widget.bookmarks.removeAt(index);
                    Hive.box(name: 'bookmarks')
                        .put('key-bookmarks', widget.bookmarks);
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
              widget.bookmarks.clear();
              Hive.box(name: 'bookmarks').clear();
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
  }
}

class Bookmark {
  final String ref;
  final String path;
  final int index;

  Bookmark({required this.ref, required this.path, required this.index});

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      ref: json['ref'] as String,
      path: json['path'] as String,
      index: json['index'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ref': ref,
      'path': path,
      'index': index,
    };
  }
}
