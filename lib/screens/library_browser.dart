import 'dart:isolate';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/library.dart';
import 'package:otzaria/widgets/grid_items.dart';
import 'package:provider/provider.dart';
import 'package:otzaria/widgets/otzar_book_dialog.dart';

class LibraryBrowser extends StatefulWidget {
  const LibraryBrowser({Key? key}) : super(key: key);

  @override
  State<LibraryBrowser> createState() => _LibraryBrowserState();
}

class _LibraryBrowserState extends State<LibraryBrowser> {
  late Future<List<OtzarBook>> otzarBooks;
  late Category currentTopCategory;
  TextEditingController searchController = TextEditingController();
  late Future<List<Widget>> items;
  int depth = 0;
  bool showOtzarBooks = false;

  @override
  void initState() {
    super.initState();
    currentTopCategory = Provider.of<AppModel>(context, listen: false).library;
    otzarBooks = Provider.of<AppModel>(context, listen: false).otzarBooks;
    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Provider.of<AppModel>(context, listen: true)
        .addListener(_handleSettingsChange);
  }

  @override
  void dispose() {
    Provider.of<AppModel>(context, listen: false)
        .removeListener(_handleSettingsChange);
    searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    items = getGrids(currentTopCategory);
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  Future<void> _loadUserPreferences() async {
    final appModel = Provider.of<AppModel>(context, listen: false);
    setState(() {
      showOtzarBooks = appModel.showOnlyOtzarHachochma.value;
    });
  }

  void _handleSettingsChange() {
    final appModel = Provider.of<AppModel>(context, listen: false);
    bool newShowOtzarBooks = appModel.showOnlyOtzarHachochma.value;
    if (newShowOtzarBooks != showOtzarBooks) {
      setState(() {
        showOtzarBooks = newShowOtzarBooks;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.home),
                tooltip: 'חזרה לתיקיה הראשית',
                onPressed: () => setState(() {
                  searchController.clear();
                  depth = 0;
                  currentTopCategory =
                      Provider.of<AppModel>(context, listen: false).library;
                  items = getGrids(currentTopCategory);
                }),
              ),
            ),
            Expanded(
              child: Center(
                  child: Text(currentTopCategory.title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ))),
            ),
            Consumer<AppModel>(
              builder: (context, appModel, child) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            appModel
                                .getHebrewDateFormattedAsString(DateTime.now()),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'דף היומי: ${appModel.getDafYomi(DateTime.now())}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 11,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons.calendar_month_outlined,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 24,
                      ),
                    ],
                  ),
                );
              },
            )
          ],
        ),
        leading: IconButton(
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
      body: FutureBuilder(
        future: otzarBooks,
        builder: (context, snapshot) => snapshot.connectionState ==
                    ConnectionState.waiting &&
                showOtzarBooks
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  buildSearchBar(),
                  Expanded(
                    child: FutureBuilder<List<Widget>>(
                      future: items,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (snapshot.hasData) {
                          if (snapshot.data!.isEmpty) {
                            return Center(
                              child: Text(
                                'אין תוצאות עבור "${searchController.text}"',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            key: PageStorageKey(currentTopCategory.title),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) =>
                                snapshot.data![index],
                          );
                        } else {
                          return const Center(child: Text('No data available'));
                        }
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
                focusNode: Provider.of<AppModel>(context).bookLocatorFocusNode,
                autofocus: true,
                controller: searchController,
                decoration: InputDecoration(
                  constraints: const BoxConstraints(maxWidth: 400),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                      onPressed: () => searchController.clear(),
                      icon: const Icon(Icons.cancel)),
                  border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0))),
                  hintText: 'איתור ספר ב${currentTopCategory.title}',
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
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    bool tempShowOtzarBooks = showOtzarBooks;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text('הגדרות תצוגת ספרים'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: Text('הצג ספרים מאוצר החכמה'),
                  value: tempShowOtzarBooks,
                  onChanged: (bool? value) {
                    setState(() {
                      tempShowOtzarBooks = value ?? false;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('ביטול'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('שמור שינויים'),
                onPressed: () {
                  final appModel =
                      Provider.of<AppModel>(context, listen: false);
                  appModel.showOnlyOtzarHachochma.value = tempShowOtzarBooks;
                  print(
                      'Setting showOnlyOtzarHachochma to: ${appModel.showOnlyOtzarHachochma.value}');

                  setState(() {
                    showOtzarBooks = tempShowOtzarBooks;
                  });

                  _handleSettingsChange();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
      },
    );
  }

  Future<List<Widget>> getFilteredBooks() async {
    final query = searchController.text.trim().toLowerCase();
    final queryWords = query.split(RegExp(r'\s+'));

    List<dynamic> localEntries =
        currentTopCategory.getAllBooksAndCategories().where((element) {
      final title = element.title.toLowerCase();
      return queryWords.every((word) => title.contains(word));
    }).toList();

    List<OtzarBook> otzarEntries = [];
    if (showOtzarBooks) {
      otzarEntries = (await otzarBooks).where((book) {
        final title = book.title.toLowerCase();
        return queryWords.every((word) => title.contains(word));
      }).toList();
    }

    List<dynamic> allEntries = [...localEntries, ...otzarEntries];
    allEntries = await sortEntries(allEntries, query);

    List<Widget> items = [];

    for (final entry in allEntries.take(50)) {
      if (entry is Category) {
        items.add(
          CategoryGridItem(
            category: entry,
            onCategoryClickCallback: () => _openCategory(entry),
          ),
        );
      } else if (entry is Book) {
        if (entry is OtzarBook) {
          items.add(
            OtzarBookGridItem(
              book: entry,
              onTap: () => _openOtzarBook(entry),
            ),
          );
        } else {
          items.add(
            BookGridItem(
              book: entry,
              showCategory: true,
              onBookClickCallback: () {
                Provider.of<AppModel>(context, listen: false)
                    .openBook(entry, 0, openLeftPane: true);
              },
            ),
          );
        }
      }
    }
    return items;
  }

  Future<List<dynamic>> sortEntries(List<dynamic> entries, String query) async {
    return await Isolate.run(() {
      entries.sort((a, b) {
        final titleA = a is Book ? a.title : '';
        final titleB = b is Book ? b.title : '';
        final scoreA = ratio(query, titleA.toLowerCase());
        final scoreB = ratio(query, titleB.toLowerCase());
        return scoreB.compareTo(scoreA);
      });
      return entries;
    });
  }

  void _openOtzarBook(OtzarBook book) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return OtzarBookDialog(book: book);
      },
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
                onBookClickCallback: () {
                  Provider.of<AppModel>(context, listen: false)
                      .openBook(book, 0, openLeftPane: true);
                }),
          );
        }
        return books;
      }();
      items.add(MyGridView(items: books));

      for (Category subCategory in category.subCategories) {
        subCategory.books.sort((a, b) => a.order.compareTo(b.order));
        subCategory.subCategories.sort((a, b) => a.order.compareTo(b.order));

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
              Provider.of<AppModel>(context, listen: false)
                  .openBook(book, 0, openLeftPane: true);
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
