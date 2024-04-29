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
  late Future<List<Widget>> items;
  int depth = 0;
  @override
  void initState() {
    currentTopCategory = Provider.of<AppModel>(context, listen: false).library;
    super.initState();
    items = getGrids(currentTopCategory);
  }

  void _openCategory(Category category) {
    depth += 1;
    currentTopCategory = category;
    items = getGrids(currentTopCategory);
    setState(() {});
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
                  depth = max(0, depth - 1);
                  currentTopCategory = currentTopCategory.parent!.parent!;
                  items = getGrids(currentTopCategory);
                }),
              ),
            ),
          ),
          // SizedBox.fromSize(
          //     size: const Size.fromWidth(400), child: buildSearchBar()),
        ]),
      ),
      body: FutureBuilder(
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
    );
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
              onBookClickCallback: () =>
                  Provider.of<AppModel>(context, listen: false)
                      .openBook(book, 0),
            ),
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

    //}
    return items;
  }
}
