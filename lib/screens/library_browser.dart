import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:otzaria/model/library.dart';
import 'package:otzaria/model/books.dart';
import 'package:otzaria/model/model.dart';
import 'dart:math';

class LibraryBrowser extends StatefulWidget {
  final Function(Book, int) onBookClickCallback;

  const LibraryBrowser({
    Key? key,
    required this.onBookClickCallback,
  }) : super(key: key);

  @override
  State<LibraryBrowser> createState() => _LibraryBrowserState();
}

class _LibraryBrowserState extends State<LibraryBrowser> {
  late Category currentTopCategory;
  late List<Widget> items;
  int depth = 0;
  @override
  void initState() {
    currentTopCategory = GetIt.I.get<AppModel>().library;
    super.initState();
    items = getGrids(currentTopCategory);
  }

  void _openCategory(Category category) {
    setState(() {
      depth += 1;
      currentTopCategory = category;
      items = getGrids(currentTopCategory);
    });
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
          leading: IconButton(
              icon: Icon(Icons.arrow_upward),
              tooltip: 'חזרה לתיקיה הקודמת',
              onPressed: () => setState(() {
                    depth = max(0, depth - 1);
                    currentTopCategory = currentTopCategory.parent!.parent!;
                    items = getGrids(currentTopCategory);
                  }))),
      body: SingleChildScrollView(
        child: Column(
          children: items,
        ),
      ),
    );
  }

  Future<Library> getLibrary() async {
    return GetIt.I.get<AppModel>().library;
  }

  List<Widget> getGrids(Category category) {
    List<Widget> items = [];
    category.books.sort(
      (a, b) => a.order.compareTo(b.order),
    );
    category.subCategories.sort(
      (a, b) => a.order.compareTo(b.order),
    );
    if (depth != 0) {
      List<Widget> books = [];
      for (Book book in category.books) {
        books.add(
          _BookGridItem(
            book: book,
            onBookClickCallback: () => widget.onBookClickCallback(book, 0),
          ),
        );
      }
      items.add(GridView.count(
        crossAxisCount: 5,
        shrinkWrap: true,
        childAspectRatio: 2.0,
        physics: ClampingScrollPhysics(),
        children: books,
      ));

      for (Category subCategory in category.subCategories) {
        try {
          subCategory.books.sort((a, b) => a.order.compareTo(b.order));
          subCategory.subCategories.sort((a, b) => a.order.compareTo(b.order));
        } catch (e) {
          print(e.toString());
          print(subCategory.toString());
        }
        items.add(Center(child: _HeaderItem(category: subCategory)));
        items.add(GridView.count(
          crossAxisCount: 5,
          children: _getGridItems(subCategory),
          shrinkWrap: true,
          childAspectRatio: 2.0,
          physics: ClampingScrollPhysics(),
        ));
      }
    } else {
      items.add(GridView.count(
        crossAxisCount: 5,
        children: _getGridItems(category),
        shrinkWrap: true,
        childAspectRatio: 2.0,
        physics: ClampingScrollPhysics(),
      ));
    }

    return items;
  }

  List<Widget> _getGridItems(Category category) {
    List<Widget> items = [];
    for (Book book in category.books) {
      items.add(
        _BookGridItem(
          book: book,
          onBookClickCallback: () => widget.onBookClickCallback(book, 0),
        ),
      );
    }
    for (Category subCategory in category.subCategories) {
      items.add(
        _CategoryGridItem(
          category: subCategory,
          onCategoryClickCallback: () => _openCategory(subCategory),
        ),
      );
    }

    //}
    return items;
  }
}

class _HeaderItem extends StatelessWidget {
  final Category category;

  const _HeaderItem({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(category.title,
          style: TextStyle(
            fontSize: 20,
            color: Theme.of(context).colorScheme.secondary,
          )),
    );
  }
}

class _CategoryGridItem extends StatelessWidget {
  final Category category;
  final VoidCallback onCategoryClickCallback;

  const _CategoryGridItem({
    Key? key,
    required this.category,
    required this.onCategoryClickCallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCategoryClickCallback,
      child: Card(
          child: SingleChildScrollView(
        child: ExpandablePanel(
          theme: ExpandableThemeData(
              headerAlignment: ExpandablePanelHeaderAlignment.center,
              tapBodyToExpand: false,
              tapHeaderToExpand: false,
              hasIcon: category.shortDescription != '' ? true : false,
              iconPlacement: ExpandablePanelIconPlacement.right,
              alignment: Alignment.center,
              expandIcon: Icons.info_outline,
              collapseIcon: Icons.keyboard_arrow_up,
              iconSize: 12),
          header: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                category.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          collapsed: SizedBox.shrink(),
          expanded: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              category.shortDescription ?? '',
              style: TextStyle(
                  fontSize: 14, color: Theme.of(context).colorScheme.secondary),
            ),
          ),
        ),
      )),
    );
  }
}

class _BookGridItem extends StatelessWidget {
  final Book book;
  final VoidCallback onBookClickCallback;

  const _BookGridItem({
    Key? key,
    required this.book,
    required this.onBookClickCallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onBookClickCallback,
        child: Card(
            child: SingleChildScrollView(
          child: ExpandablePanel(
            theme: ExpandableThemeData(
                headerAlignment: ExpandablePanelHeaderAlignment.center,
                tapBodyToExpand: false,
                tapHeaderToExpand: false,
                hasIcon: book.heShortDesc != null && book.heShortDesc != ''
                    ? true
                    : false,
                iconPlacement: ExpandablePanelIconPlacement.right,
                alignment: Alignment.center,
                expandIcon: Icons.info_outline,
                collapseIcon: Icons.keyboard_arrow_up,
                iconSize: 15),
            header: ListTile(
              title: Text(
                book.title,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                  (book.author == "" || book.author == null)
                      ? ''
                      : ((book.author!) + ' ' + (book.pubDate ?? '')),
                  style: TextStyle(fontSize: 14)),
              isThreeLine: true,
            ),
            collapsed: SizedBox.shrink(),
            expanded: Text(
              book.heShortDesc ?? '',
              style: TextStyle(
                  fontSize: 14, color: Theme.of(context).colorScheme.secondary),
            ),
          ),
        )));
  }
}
