import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/library.dart';
import 'package:otzaria/utils/daf_yomi_helper.dart';
import 'package:otzaria/utils/extraction.dart';
import 'package:otzaria/utils/file_sync_service.dart';
import 'package:otzaria/widgets/daf_yomi.dart';
import 'package:otzaria/widgets/file_sync_widget.dart';
import 'package:otzaria/widgets/filter_list/src/filter_list_dialog.dart';
import 'package:otzaria/widgets/filter_list/src/theme/filter_list_theme.dart';
import 'package:otzaria/widgets/grid_items.dart';
import 'package:otzaria/widgets/otzar_book_dialog.dart';
import 'package:provider/provider.dart';

class LibraryBrowser extends StatefulWidget {
  const LibraryBrowser({Key? key}) : super(key: key);

  @override
  State<LibraryBrowser> createState() => _LibraryBrowserState();
}

class _LibraryBrowserState extends State<LibraryBrowser>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late Future<Category> currentTopCategory;
  late Future<List<Widget>> items;
  int depth = 0;
  List<String> topics = [];
  List<String> selectedTopics = [];

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    currentTopCategory = Provider.of<AppModel>(context, listen: false).library;
    items = getGrids(currentTopCategory);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
        future: currentTopCategory,
        builder: (context, resolvedCurrentTopCategory) {
          if (!resolvedCurrentTopCategory.hasData) {
            return const Center(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                Text('טוען ספרייה...'),
              ],
            ));
          }
          return Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.home),
                          tooltip: 'חזרה לתיקיה הראשית',
                          onPressed: () => setState(() {
                            Provider.of<AppModel>(context, listen: false)
                                .bookLocatorController
                                .text = '';
                            depth = 0;
                            currentTopCategory =
                                Provider.of<AppModel>(context, listen: false)
                                    .library;
                            items = getGrids(currentTopCategory);
                          }),
                        ),
                        SyncIconButton(
                            fileSync: FileSyncService(
                                githubOwner: "zevisvei",
                                repositoryName: "otzaria-library",
                                branch: "main")),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                        child: Text(resolvedCurrentTopCategory.data!.title,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ))),
                  ),
                  DafYomi(
                    onDafYomiTap: (tractate, daf) {
                      openDafYomiBook(context, tractate, ' $daf.');
                    },
                  )
                ],
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_upward),
                tooltip: 'חזרה לתיקיה הקודמת',
                onPressed: () => setState(() {
                  context.read<AppModel>().bookLocatorController.clear();
                  depth = max(0, depth - 1);
                  currentTopCategory = Future(
                      () => resolvedCurrentTopCategory.data!.parent!.parent!);
                  items = getGrids(currentTopCategory);
                }),
              ),
            ),
            body: Column(
              children: [
                buildSearchBar(resolvedCurrentTopCategory),
                context.read<AppModel>().bookLocatorController.text.length > 2
                    ? showTopicsSelection(context,
                        resolvedCurrentTopCategory: resolvedCurrentTopCategory)
                    : Container(),
                Expanded(
                  child: FutureBuilder<List<Widget>>(
                    future: items,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (snapshot.hasData && snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            context
                                    .read<AppModel>()
                                    .bookLocatorController
                                    .text
                                    .isNotEmpty
                                ? 'אין תוצאות עבור "${context.read<AppModel>().bookLocatorController.text}"'
                                : 'אין פריטים להצגה בתיקייה זו',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        key: PageStorageKey(
                          resolvedCurrentTopCategory.data!,
                        ),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) => snapshot.data![index],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget showTopicsSelection(BuildContext context,
      {required AsyncSnapshot resolvedCurrentTopCategory}) {
    return FutureBuilder(
        future: Provider.of<AppModel>(context).findBooks(
            context.read<AppModel>().bookLocatorController.text,
            resolvedCurrentTopCategory.data!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          return FilterListWidget<String>(
            hideSearchField: true,
            controlButtons: const [],
            themeData: FilterListThemeData(
              context,
              wrapAlignment: WrapAlignment.center,
            ),
            onApplyButtonClick: (list) => setState(() {
              selectedTopics = list ?? [];
              items = getFilteredBooks(
                  Provider.of<AppModel>(context, listen: false),
                  resolvedCurrentTopCategory.data!,
                  selectedTopics);
              items = (() async => [
                    Column(children: [MyGridView(items: items)])
                  ])();
            }),
            validateSelectedItem: (list, item) =>
                list != null && list.contains(item),
            onItemSearch: (item, query) => item == query,
            listData: getAllTopics(snapshot.data!),
            selectedListData: selectedTopics,
            choiceChipLabel: (p0) => p0,
            hideSelectedTextCount: true,
            choiceChipBuilder: (context, item, isSelected) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 2,
              ),
              child: Chip(
                label: Text(item),
                backgroundColor: isSelected!
                    ? Theme.of(context).colorScheme.secondary
                    : null,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onSecondary
                      : null,
                  fontSize: 11,
                ),
                labelPadding: const EdgeInsets.all(0),
              ),
            ),
          );
        });
  }

  Widget buildSearchBar(AsyncSnapshot resolvedCurrentTopCategory) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ValueListenableBuilder(
          valueListenable:
              Provider.of<AppModel>(context, listen: false).showExternalBooks,
          builder: (context, value, child) {
            return Row(
              children: [
                Expanded(
                  child: TextField(
                      focusNode: Provider.of<AppModel>(context, listen: false)
                          .bookLocatorFocusNode,
                      autofocus: !(Platform.isAndroid || Platform.isIOS),
                      controller:
                          context.read<AppModel>().bookLocatorController,
                      decoration: InputDecoration(
                        constraints: const BoxConstraints(maxWidth: 400),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                            onPressed: () {
                              context
                                  .read<AppModel>()
                                  .bookLocatorController
                                  .clear();
                              items = getGrids(currentTopCategory);
                              setState(() {});
                            },
                            icon: const Icon(Icons.cancel)),
                        border: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.0))),
                        hintText:
                            'איתור ספר ב${resolvedCurrentTopCategory.data!.title}',
                      ),
                      onChanged: (value) {
                        selectedTopics = [];
                        if (value.length < 3) {
                          items = getGrids(currentTopCategory);
                        } else {
                          items = getFilteredBooks(
                              Provider.of<AppModel>(context, listen: false),
                              resolvedCurrentTopCategory.data!,
                              selectedTopics);
                          items = (() async => [
                                Column(children: [MyGridView(items: items)])
                              ])();
                        }
                        setState(() {});
                      }),
                ),
                value
                    ? IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () => _showFilterDialog(),
                      )
                    : const SizedBox.shrink(),
              ],
            );
          }),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text('הצג ספרים מאוצר החכמה'),
                  value:
                      Provider.of<AppModel>(context).showOtzarHachochma.value,
                  onChanged: (bool? value) {
                    setState(() {
                      Provider.of<AppModel>(context, listen: false)
                          .showOtzarHachochma
                          .value = value ?? false;
                      Settings.setValue<bool?>(
                          'key-show-otzar-hachochma', value);
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('הצג ספרים מהיברובוקס'),
                  value: Provider.of<AppModel>(context).showHebrewBooks.value,
                  onChanged: (bool? value) {
                    setState(() {
                      Provider.of<AppModel>(context, listen: false)
                          .showHebrewBooks
                          .value = value ?? false;
                      Settings.setValue<bool?>('key-show-hebrew-books', value);
                    });
                  },
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<List<Widget>> getFilteredBooks(AppModel appModel, Category? category,
      List<String>? selectedTopics) async {
    final allEntries = await appModel.findBooks(
        context.read<AppModel>().bookLocatorController.text, category,
        topics: selectedTopics);
    List<Widget> items = [];

    for (final entry in allEntries.take(100)) {
      if (entry is ExternalBook) {
        items.add(
          BookGridItem(
            book: entry,
            onBookClickCallback: () => _openOtzarBook(entry),
            showTopics: true,
          ),
        );
      } else {
        items.add(
          BookGridItem(
            book: entry,
            showTopics: true,
            onBookClickCallback: () {
              Provider.of<AppModel>(context, listen: false)
                  .openBook(entry, 0, openLeftPane: true);
            },
          ),
        );
      }
    }
    return items;
  }

  void _openOtzarBook(ExternalBook book) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return OtzarBookDialog(book: book);
      },
    );
  }

  Future<List<Widget>> getGrids(Future<Category> rawcategory) async {
    final category = await rawcategory;
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
        items.add(MyGridView(items: _getGridItems(Future(() => subCategory))));
      }
    } else {
      items.add(MyGridView(
        items: _getGridItems(currentTopCategory),
      ));
    }
    // Refocus the search bar after the grid is built.
    // Doing it here, because the search bar is rebuilt every time the grid is rebuilt
    // ignore: use_build_context_synchronously
    context.read<AppModel>().bookLocatorFocusNode.requestFocus();

    return items;
  }

  Future<List<Widget>> _getGridItems(Future<Category> rawcategory) async {
    final category = await rawcategory;
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
    currentTopCategory = Future(() => category);

    setState(() {
      items = getGrids(currentTopCategory);
    });
  }
}
