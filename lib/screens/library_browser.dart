import 'dart:isolate';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:flutter/material.dart';
import 'package:otzaria/widgets/grid_items.dart';
import 'package:otzaria/models/library.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/app_model.dart';
import 'dart:math';
import 'package:provider/provider.dart';

class LibraryBrowser extends StatefulWidget {
  const LibraryBrowser({
    Key? key,
  }) : super(key: key);

  @override
  State<LibraryBrowser> createState() => _LibraryBrowserState();
}

class _LibraryBrowserState extends State<LibraryBrowser> {
  late Category currentTopCategory;
  TextEditingController searchController = TextEditingController();
  late Future<List<Widget>> items;
  int depth = 0;
  @override
  void initState() {
    currentTopCategory = Provider.of<AppModel>(context, listen: false).library;
    super.initState();
    items = getGrids(currentTopCategory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
            child: Text('ספריית אוצריא',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ))),
        leading: Row(children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox.fromSize(
              size: const Size.fromWidth(64),
              child: IconButton(
                icon: const Icon(Icons.arrow_upward),
                tooltip: 'חזרה לתיקיה הקודמת',
                onPressed: () => setState(() {
                  searchController.clear();
                  depth = max(0, depth - 1);
                  currentTopCategory = currentTopCategory.parent!.parent!;
                  items = getGrids(currentTopCategory);
                }),
              ),
            ),
          ),
        ]),
      ),
      body: Column(
        children: [
          buildSearchBar(),
          Expanded(
            child: FutureBuilder(
                future: items,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        children: snapshot.data!,
                      ),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                }),
          ),
        ],
      ),
    );
  }

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
          controller: searchController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8.0))),
            hintText: 'איתור ספר ב' + currentTopCategory.title,
          ),
          onChanged: (value) {
            if (value.length < 3) {
              items = getGrids(currentTopCategory);
            } else {
              items = getFilteredBooks();
              items = (() async => [
                    Column(children: [MyGridView(items: items)])
                  ])();
            }
            setState(() {});
          }),
    );
  }

  Future<List<Widget>> getFilteredBooks() async {
    List<Book> books = currentTopCategory.getAllBooks().where((element) {
      bool result = true;
      for (final word in searchController.text.split(' ')) {
        result = result && element.title.contains(word);
      }
      return result;
    }).toList();

    books = sortBooks(books, searchController.text);

    List<Widget> items = [];

    for (final book in books) {
      items.add(
        BookGridItem(
            book: book,
            onBookClickCallback: () {
              Provider.of<AppModel>(context, listen: false).openBook(book, 0);
              Provider.of<AppModel>(context, listen: false).currentView = 1;
            }),
      );
    }
    return items;
  }

  List<Book> sortBooks(List<Book> books, String query) {
    books.sort(
      (a, b) => ratio(query, b.title).compareTo(ratio(query, a.title)),
    );
    return books;
  }

  Future<List<Widget>> getGrids(Category category) async {
    List<Widget> items = [];
    category.books.sort(
      (a, b) => a.order.compareTo(b.order),
    );
    category.subCategories.sort(
      (a, b) => a.order.compareTo(b.order),
    );
    if (depth != 0) {
      Future<List<Widget>> books = () async {
        List<Widget> books = [];
        for (Book book in category.books) {
          books.add(
            BookGridItem(
                book: book,
                onBookClickCallback: () {
                  Provider.of<AppModel>(context, listen: false)
                      .openBook(book, 0);
                  Provider.of<AppModel>(context, listen: false).currentView = 1;
                }),
          );
        }
        return books;
      }();
      items.add(MyGridView(items: books));

      for (Category subCategory in category.subCategories) {
        try {
          subCategory.books.sort((a, b) => a.order.compareTo(b.order));
          subCategory.subCategories.sort((a, b) => a.order.compareTo(b.order));
        } catch (e) {
          print(e.toString());
          print(subCategory.toString());
        }
        items.add(Center(child: HeaderItem(category: subCategory)));
        items.add(MyGridView(items: _getGridItems(subCategory)));
      }
    } else {
      items.add(MyGridView(
        items: _getGridItems(currentTopCategory),
      ));
    }

    return items;
  }

  Future<List<Widget>> _getGridItems(Category category) async {
    List<Widget> items = [];
    for (Book book in category.books) {
      items.add(
        BookGridItem(
            book: book,
            onBookClickCallback: () {
              Provider.of<AppModel>(context, listen: false).openBook(book, 0);
              Provider.of<AppModel>(context, listen: false).currentView = 1;
            }),
      );
    }
    for (Category subCategory in category.subCategories) {
      items.add(
        CategoryGridItem(
          category: subCategory,
          onCategoryClickCallback: () => _openCategory(subCategory),
        ),
      );
    }

    return items;
  }

  void _openCategory(Category category) {
    depth += 1;
    currentTopCategory = category;
    setState(() {
      items = getGrids(currentTopCategory);
    });
  }
}
