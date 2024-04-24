import 'package:flutter/material.dart';
import 'package:otzaria/model/bookmark.dart';
import 'package:hive/hive.dart';
import 'package:otzaria/model/books.dart';

class BookmarkView extends StatefulWidget {
  final List<Bookmark> bookmarks;
  final void Function(Book book, int index) openBookmarkCallBack;
  final void Function() closeLeftPaneCallback;
  const BookmarkView({
    Key? key,
    required this.bookmarks,
    required this.openBookmarkCallBack,
    required this.closeLeftPaneCallback,
  }) : super(key: key);

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
                  widget.openBookmarkCallBack(
                      Book(title: widget.bookmarks[index].title),
                      widget.bookmarks[index].index);
                  widget.closeLeftPaneCallback;
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
