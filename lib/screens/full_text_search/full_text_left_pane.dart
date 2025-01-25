// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:flutter/material.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/library.dart';
import 'package:otzaria/models/tabs/searching_tab.dart';
import 'package:otzaria/screens/full_text_search/full_text_settings_screen.dart';
import 'package:provider/provider.dart';

class FullTextLeftPane extends StatefulWidget {
  final SearchingTab tab;
  final Future<Library> library;
  const FullTextLeftPane({Key? key, required this.tab, required this.library})
      : super(key: key);
  @override
  State<FullTextLeftPane> createState() => _FullTextLeftPaneState();
}

class _FullTextLeftPaneState extends State<FullTextLeftPane>
    with SingleTickerProviderStateMixin {
  List<Book> allBooks = [];
  List<Book> books = [];
  final TextEditingController _filterQuery = TextEditingController();

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
            size: const Size.fromHeight(120.0),
            child: FullTextSettingsScreen(tab: widget.tab)),
        TextField(
          controller: _filterQuery,
          decoration: InputDecoration(
              hintText: "איתור ספר...",
              prefixIcon: const Icon(Icons.filter_list_alt),
              suffixIcon: IconButton(
                  onPressed: () => setState(() => _filterQuery.text = ''),
                  icon: const Icon(Icons.close))),
          onChanged: (query) {
            setState(() {
              update();
            });
          },
        ),
        _filterQuery.text.length < 2
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
          itemBuilder: (context, index) => FutureBuilder(
              future: widget.tab.countForFacet(
                  '${books[index].category?.path}/${books[index].title}'),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data! <= 0) {
                  return const SizedBox.shrink();
                }
                return InkWell(
                    onDoubleTap: () => setState(() {
                          if (widget.tab.currentFacets.value.contains(
                              '${books[index].category?.path}/${books[index].title}')) {
                            widget.tab.currentFacets.value.remove(
                                '${books[index].category?.path}/${books[index].title}');
                          } else if (!isChecked(books[index])) {
                            widget.tab.currentFacets.value.add(
                                '${books[index].category?.path}/${books[index].title}');
                          }
                          widget.tab.currentFacets.notifyListeners();
                          widget.tab.updateResults();
                        }),
                    child: ListTile(
                      tileColor: isChecked(books[index].category)
                          ? Theme.of(context)
                              .colorScheme
                              .surfaceTint
                              .withOpacity(0.1)
                          : null,
                      title: Text(snapshot.hasData
                          ? "${books[index].title} (${snapshot.data})"
                          : books[index].title),
                      onTap: () {
                        widget.tab.currentFacets.value = [
                          '${books[index].category?.path}/${books[index].title}'
                        ];
                        widget.tab.currentFacets.notifyListeners();
                        widget.tab.updateResults();
                      },
                      onLongPress: () => setState(() {
                        if (widget.tab.currentFacets.value.contains(
                            '${books[index].category?.path}/${books[index].title}')) {
                          widget.tab.currentFacets.value.remove(
                              '${books[index].category?.path}/${books[index].title}');
                        } else if (!isChecked(books[index])) {
                          widget.tab.currentFacets.value.add(
                              '${books[index].category?.path}/${books[index].title}');
                        }
                        widget.tab.currentFacets.notifyListeners();
                        widget.tab.updateResults();
                      }),
                    ));
              }),
        ),
      )
    ]);
  }

  Widget _buildBooksTree(BuildContext context) {
    return ListenableBuilder(
        listenable: widget.tab.results,
        builder: (context, _) {
          return ValueListenableBuilder(
              valueListenable: widget.tab.booksToSearch,
              builder: (context, value, child) {
                return FutureBuilder(
                    future:
                        Provider.of<AppModel>(context, listen: false).library,
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
        });
  }

  Widget _buildTree(Category category, {int level = 0}) {
    return ListenableBuilder(
        listenable: widget.tab.results,
        builder: (context, _) {
          final count = widget.tab.countForFacet(category.path);
          return FutureBuilder(
              future: count,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (snapshot.hasData && snapshot.data! > 0) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      backgroundColor: isChecked(category)
                          ? Theme.of(context)
                              .colorScheme
                              .surfaceTint
                              .withOpacity(0.1)
                          : null,
                      collapsedBackgroundColor: isChecked(category)
                          ? Theme.of(context)
                              .colorScheme
                              .surfaceTint
                              .withOpacity(0.1)
                          : null,
                      leading: const Icon(Icons.chevron_right_rounded),
                      trailing: const SizedBox.shrink(),
                      iconColor: Theme.of(context).colorScheme.primary,
                      collapsedIconColor: Theme.of(context).colorScheme.primary,
                      key: PageStorageKey(category),
                      title: Builder(
                        builder: (context) {
                          if (snapshot.hasData && snapshot.data! > 0) {
                            return GestureDetector(
                                onTap: () => setState(() {
                                      widget.tab.currentFacets.value = [
                                        category.path
                                      ];
                                      widget.tab.currentFacets
                                          .notifyListeners();
                                      widget.tab.updateResults();
                                    }),
                                onLongPress: () => setState(() {
                                      if (widget.tab.currentFacets.value
                                          .contains(category.path)) {
                                        widget.tab.currentFacets.value
                                            .remove(category.path);
                                      } else {
                                        widget.tab.currentFacets.value
                                            .add(category.path);
                                      }
                                      widget.tab.currentFacets
                                          .notifyListeners();
                                      widget.tab.updateResults();
                                    }),
                                onDoubleTap: () => setState(() {
                                      if (widget.tab.currentFacets.value
                                          .contains(category.path)) {
                                        widget.tab.currentFacets.value
                                            .remove(category.path);
                                      } else if (!isChecked(category)) {
                                        widget.tab.currentFacets.value
                                            .add(category.path);
                                      }
                                      widget.tab.currentFacets
                                          .notifyListeners();
                                      widget.tab.updateResults();
                                    }),
                                child: Text(
                                    "${category.title} (${snapshot.data})"));
                          }
                          return SizedBox.shrink();
                        },
                      ),
                      initiallyExpanded: level == 0,
                      tilePadding:
                          EdgeInsets.symmetric(horizontal: 6 + (level) * 10),
                      children: ([] + category.subCategories + category.books)
                          .map((entity) {
                        if (entity is Category) {
                          return _buildTree(entity, level: level + 1);
                        } else if (entity is Book) {
                          return ListenableBuilder(
                              listenable: widget.tab.results,
                              builder: (context, _) {
                                final count = widget.tab.countForFacet(
                                    '${entity.category?.path}/${entity.title}');
                                return FutureBuilder(
                                  future: count,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return Text('Error: ${snapshot.error}');
                                    }
                                    if (snapshot.hasData &&
                                        snapshot.data! > 0) {
                                      return InkWell(
                                        onDoubleTap: () => setState(() {
                                          if (widget.tab.currentFacets.value
                                              .contains(
                                                  '${entity.category?.path}/${entity.title}')) {
                                            widget.tab.currentFacets.value.remove(
                                                '${entity.category?.path}/${entity.title}');
                                          } else if (!isChecked(entity)) {
                                            widget.tab.currentFacets.value.add(
                                                '${entity.category?.path}/${entity.title}');
                                          }
                                          widget.tab.currentFacets
                                              .notifyListeners();
                                          widget.tab.updateResults();
                                        }),
                                        child: ListTile(
                                          tileColor: isChecked(category)
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .surfaceTint
                                                  .withOpacity(0.1)
                                              : null,
                                          title: Text(snapshot.hasData
                                              ? "${entity.title} (${snapshot.data})"
                                              : entity.title),
                                          onTap: () {
                                            widget.tab.currentFacets.value = [
                                              '${entity.category?.path}/${entity.title}'
                                            ];
                                            widget.tab.currentFacets
                                                .notifyListeners();
                                            widget.tab.updateResults();
                                          },
                                          onLongPress: () => setState(() {
                                            if (widget.tab.currentFacets.value
                                                .contains(
                                                    '${entity.category?.path}/${entity.title}')) {
                                              widget.tab.currentFacets.value.remove(
                                                  '${entity.category?.path}/${entity.title}');
                                            } else if (!isChecked(entity)) {
                                              widget.tab.currentFacets.value.add(
                                                  '${entity.category?.path}/${entity.title}');
                                            }
                                            widget.tab.currentFacets
                                                .notifyListeners();
                                            widget.tab.updateResults();
                                          }),
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 16 + level * 16),
                                        ),
                                      );
                                    }
                                    return SizedBox.shrink();
                                  },
                                );
                              });
                        }
                        return const SizedBox.shrink();
                      }).toList(),
                    ),
                  );
                }
                return const SizedBox.shrink();
              });
        });
  }

  bool isChecked(dynamic entity) {
    if (entity is Category) {
      return widget.tab.currentFacets.value.contains(entity.path) ||
          (entity.title != "ספריית אוצריא" && isChecked(entity.parent));
    }
    return widget.tab.currentFacets.value
            .contains('${entity.category?.path}/${entity.title}') ||
        isChecked(entity.category);
  }
}
