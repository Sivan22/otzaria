import 'package:flutter/material.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/tabs.dart';
import 'package:provider/provider.dart';

class FullTextBookList extends StatefulWidget {
  final SearchingTab tab;
  final List<Book> books;
  const FullTextBookList({Key? key, required this.books, required this.tab})
      : super(key: key);
  @override
  State<FullTextBookList> createState() => _FullTextBookListState();
}

class _FullTextBookListState extends State<FullTextBookList> {
  List<Book> books = [];
  Set<String> allTopics = {};
  Set<String> selectedTopics = {};
  String _filterQuery = '';

  void update() {
    final filteredList = widget.books.where((book) =>
        book.title.toLowerCase().contains(_filterQuery.toLowerCase()));

    setState(() {
      books = filteredList.toList();
    });
  }

  @override
  void initState() {
    books = widget.books;
    super.initState();
    for (Book book in widget.books) {
      allTopics.addAll(book.topics.split(', '));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: "סינון",
            ),
            onChanged: (query) {
              setState(() {
                _filterQuery = query;
                update();
              });
            },
          ),
          CheckboxListTile(
            title: const Text("הכל"),
            value: books
                .every((test) => widget.tab.booksToSearch.value.contains(test)),
            onChanged: (value) {
              setState(() {
                if (value!) {
                  widget.tab.booksToSearch.value.addAll(books);
                } else {
                  widget.tab.booksToSearch.value
                      .removeWhere((e) => books.contains(e));
                }
                widget.tab.booksToSearch.notifyListeners();
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) => CheckboxListTile(
                title: Text(books[index].title),
                value: widget.tab.booksToSearch.value.contains(books[index]),
                onChanged: (value) {
                  if (value!) {
                    widget.tab.booksToSearch.value.add(books[index]);
                  } else {
                    widget.tab.booksToSearch.value
                        .removeWhere((s) => s == books[index]);
                  }
                  widget.tab.booksToSearch.notifyListeners();
                  setState(() {});
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
