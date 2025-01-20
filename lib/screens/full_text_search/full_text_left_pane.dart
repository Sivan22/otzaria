import 'package:flutter/material.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/library.dart';
import 'package:otzaria/models/tabs.dart';
import 'package:otzaria/screens/full_text_search/full_text_settings_screen.dart';
import 'package:provider/provider.dart';

class FullTextLeftPane extends StatefulWidget {
  final SearchingTab tab;
  final Future<Library> library;
  const FullTextLeftPane({Key? key, required this.tab, required this.library})
      : super(key: key);
  @override
  _FullTextLeftPaneState createState() => _FullTextLeftPaneState();
}

class _FullTextLeftPaneState extends State<FullTextLeftPane>
    with SingleTickerProviderStateMixin {
  List<Book> allBooks = [];
  List<Book> books = [];
  TextEditingController _filterQuery = TextEditingController();

  void update() {
    var filteredList =
        allBooks.where((book) => book.title.contains(_filterQuery.text));
    setState(() {
      books = filteredList.toList();
    });
  }

  @override
  void initState() {
    super.initState();
    () async {
      allBooks = (await widget.library).getAllBooks();
    }();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox.fromSize(
            size: Size.fromHeight(120.0),
            child: FullTextSettingsScreen(tab: widget.tab)),
        TextField(
          controller: _filterQuery,
          decoration: InputDecoration(
              hintText: "סינון ספרים",
              prefixIcon: Icon(Icons.filter_list_alt),
              suffixIcon: IconButton(
                  onPressed: () => setState(() => _filterQuery.text = ''),
                  icon: Icon(Icons.close))),
          onChanged: (query) {
            setState(() {
              update();
            });
          },
        ),
        _filterQuery.text.isEmpty
            ? Expanded(child: _buildBooksTree(context))
            : Expanded(child: _buildBooksList()),
      ],
    );
  }

  Widget _buildBooksList() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Expanded(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: books.length,
          itemBuilder: (context, index) => index == 0
              ? CheckboxListTile(
                  title: const Text("הכל"),
                  value: books.every(
                      (test) => widget.tab.booksToSearch.value.contains(test)),
                  onChanged: (value) {
                    setState(() {
                      if (value!) {
                        widget.tab.booksToSearch.value.addAll(books);
                      } else {
                        widget.tab.booksToSearch.value
                            .removeWhere((e) => books.contains(e));
                      }
                      widget.tab.booksToSearch.value =
                          widget.tab.booksToSearch.value;
                    });
                  },
                )
              : CheckboxListTile(
                  title: Text(books[index - 1].title),
                  value:
                      widget.tab.booksToSearch.value.contains(books[index - 1]),
                  onChanged: (value) {
                    if (value!) {
                      widget.tab.booksToSearch.value.add(books[index - 1]);
                    } else {
                      widget.tab.booksToSearch.value
                          .removeWhere((s) => s == books[index - 1]);
                    }
                    widget.tab.booksToSearch.value =
                        widget.tab.booksToSearch.value;
                    setState(() {});
                  },
                ),
        ),
      )
    ]);
  }

  Widget _buildBooksTree(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: widget.tab.booksToSearch,
        builder: (context, value, child) {
          return FutureBuilder(
              future: Provider.of<AppModel>(context, listen: false).library,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                return SingleChildScrollView(
                    key: const PageStorageKey('tree'),
                    child: _buildTree(snapshot.data!));
              });
        });
  }

  Widget _buildTree(Category category, {int level = 0}) {
    return ExpansionTile(
      key: PageStorageKey(category), // Ensure unique keys for ExpansionTiles
      title: Text(category.title),
      initiallyExpanded: level == 0,
      tilePadding: EdgeInsets.symmetric(horizontal: 6 + (level) * 6),
      leading: SizedBox.fromSize(
        size: const Size.fromWidth(60.0),
        child: Row(
          children: [
            Checkbox(
                value: isCategoryChecked(category),
                onChanged: (value) {
                  if (value != null && value) {
                    addCategory(category);
                  } else {
                    removeCategory(category);
                  }
                  widget.tab.booksToSearch.value =
                      widget.tab.booksToSearch.value;
                  setState(() {});
                }),
            const Icon(Icons.folder),
          ], // Icon(Icons.folder,
        ),
      ),

      children: ([] + category.subCategories + category.books).map((entity) {
        if (entity is Category) {
          return _buildTree(entity, level: level + 1);
        } else if (entity is Book) {
          return CheckboxListTile(
            title: Row(children: [
              Text(
                entity.title,
              ),
            ]),
            value: widget.tab.booksToSearch.value.contains(entity),
            onChanged: (value) {
              widget.tab.booksToSearch.value.contains(entity)
                  ? widget.tab.booksToSearch.value.remove(entity)
                  : widget.tab.booksToSearch.value.add(entity);
              widget.tab.booksToSearch.value = widget.tab.booksToSearch.value;
              setState(() {});
            }, //TODO: fix
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.symmetric(horizontal: 16 + level * 16),
          );
        } else {
          return ListTile(
            title: Text('Unknown: ${entity.path}'),
          );
        }
      }).toList(),
    );
  }

  void addCategory(Category category) {
    for (Book book in category.books) {
      widget.tab.booksToSearch.value.add(book);
    }
    for (Category subCategory in category.subCategories) {
      addCategory(subCategory);
    }
  }

  void removeCategory(Category category) {
    for (Book book in category.books) {
      widget.tab.booksToSearch.value.remove(book);
    }
    for (Category subCategory in category.subCategories) {
      removeCategory(subCategory);
    }
  }

  bool isCategoryChecked(Category category) {
    return category.books
            .every((test) => widget.tab.booksToSearch.value.contains(test)) &&
        category.subCategories.every((test) => isCategoryChecked(test));
  }
}
