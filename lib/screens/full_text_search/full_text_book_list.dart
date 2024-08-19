import 'package:flutter/material.dart';
import 'package:filter_list/filter_list.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/tabs.dart';

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
  List<String> allTopics = [];
  List<String> selectedTopics = [];
  String _filterQuery = '';

  void update() {
    var filteredList = widget.books.where((book) =>
        book.title.toLowerCase().contains(_filterQuery.toLowerCase()));
    if (selectedTopics.isNotEmpty) {
      filteredList = filteredList.where((book) =>
          book.topics.split(' ,').any((t) => selectedTopics.contains(t)));
    }

    setState(() {
      books = filteredList.toList();
    });
  }

  @override
  void initState() {
    books = widget.books;
    super.initState();
    Set<String> allTopicsSet = {};
    for (Book book in widget.books) {
      allTopicsSet.addAll(book.topics.split(', '));
    }
    allTopics = allTopicsSet.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            child: Text('בחר קטגוריות'),
            onPressed: openFilterDialog,
          ),
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

  void openFilterDialog() async {
    await FilterListDialog.display<String>(
      context,
      listData: allTopics,
      selectedListData: selectedTopics,
      allButtonText: 'הכל',
      applyButtonText: 'סיום',
      headlineText: 'בחר קטגוריות',
      resetButtonText: 'איפוס',
      selectedItemsText: 'קטגוריות נבחרו',
      choiceChipLabel: (topic) => topic,
      validateSelectedItem: (list, val) => list!.contains(val),
      onItemSearch: (topic, query) {
        return topic.contains(query);
      },
      onApplyButtonClick: (list) {
        setState(() {
          selectedTopics = List.from(list!);
        });

        Navigator.pop(context);
      },
    );
  }
}
