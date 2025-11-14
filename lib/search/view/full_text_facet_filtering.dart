import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/library/bloc/library_bloc.dart';
import 'package:otzaria/library/bloc/library_state.dart';
import 'package:otzaria/search/bloc/search_bloc.dart';
import 'package:otzaria/search/bloc/search_event.dart';
import 'package:otzaria/search/bloc/search_state.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/library/models/library.dart';
import 'package:otzaria/tabs/models/searching_tab.dart';
import 'package:otzaria/i18n/translations.g.dart';

// Constants
const double _kMinQueryLength = 2;

/// A reusable divider widget that creates a line with a consistent height,
/// color, and margin to match other dividers in the UI.
class ThinDivider extends StatelessWidget {
  const ThinDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1, // 1 logical pixel is sufficient here
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
    );
  }
}

class SearchFacetFiltering extends StatefulWidget {
  final SearchingTab tab;

  const SearchFacetFiltering({
    super.key,
    required this.tab,
  });

  @override
  State<SearchFacetFiltering> createState() => _SearchFacetFilteringState();
}

class _SearchFacetFilteringState extends State<SearchFacetFiltering>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final TextEditingController _filterQuery = TextEditingController();
  final Map<String, bool> _expansionState = {};

  @override
  void dispose() {
    _filterQuery.dispose();
    super.dispose();
  }

  void _clearFilter() {
    _filterQuery.clear();
    context.read<SearchBloc>().add(ClearFilter());
  }

  @override
  void initState() {
    _filterQuery.text = context.read<SearchBloc>().state.filterQuery ?? '';
    super.initState();
  }

  void _onQueryChanged(String query) {
    if (query.length >= _kMinQueryLength) {
      context.read<SearchBloc>().add(UpdateFilterQuery(query));
    } else if (query.isEmpty) {
      context.read<SearchBloc>().add(ClearFilter());
    }
  }

  void _handleFacetToggle(BuildContext context, String facet) {
    final searchBloc = context.read<SearchBloc>();
    final state = searchBloc.state;
    if (state.currentFacets.contains(facet)) {
      searchBloc.add(RemoveFacet(facet));
    } else {
      searchBloc.add(AddFacet(facet));
    }
  }

  void _setFacet(BuildContext context, String facet) {
    context.read<SearchBloc>().add(SetFacet(facet));
  }

  Widget _buildSearchField() {
    return Container(
      height: 60, // Same height as the container on the right
      alignment: Alignment.center, // Vertically centers the TextField
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TextField(
        controller: _filterQuery,
        decoration: InputDecoration(
          hintText: 'איתור ספר…',
          prefixIcon: const Icon(FluentIcons.filter_24_regular),
          suffixIcon: IconButton(
            onPressed: _clearFilter,
            icon: const Icon(FluentIcons.dismiss_24_regular),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
        ),
        onChanged: _onQueryChanged,
      ),
    );
  }

  Widget _buildBookTile(Book book, int count, int level,
      {String? categoryPath}) {
    if (count == 0) {
      return const SizedBox.shrink();
    }

    // בניית facet נכון על בסיס נתיב הקטגוריה
    final facet =
        categoryPath != null ? "$categoryPath/${book.title}" : "/${book.title}";
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        final isSelected = state.currentFacets.contains(facet);
        return InkWell(
          onTap: () => HardwareKeyboard.instance.isControlPressed
              ? _handleFacetToggle(context, facet)
              : _setFacet(context, facet),
          onDoubleTap: () => _handleFacetToggle(context, facet),
          onLongPress: () => _handleFacetToggle(context, facet),
          child: Container(
            padding: EdgeInsets.only(
              right: 16.0 + (level * 24.0) + 32.0, // הזחה נוספת לספרים
              left: 16.0,
              top: 10.0,
              bottom: 10.0,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.3)
                  : null,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  FluentIcons.book_24_regular,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    book.title,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                // מספר התוצאות
                if (count != -1)
                  Text(
                    '($count)',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (count == -1)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBooksList(List<Book> books) {
    // אם אין ספרים, הצג הודעה
    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(context.t.search.noBooksFound),
        ),
      );
    }

    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        // יצירת רשימת כל ה-facets בבת אחת
        // עבור רשימת ספרים מסוננת, נשתמש בשם הספר בלבד
        final facets = books.map((book) => "/${book.title}").toList();

        // ספירה מקבצת של כל ה-facets
        final countsFuture = widget.tab.countForMultipleFacets(facets);

        return FutureBuilder<Map<String, int>>(
          key: ValueKey(
              '${state.searchQuery}_books_batch'), // מפתח שמשתנה עם החיפוש
          future: countsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final counts = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  final facet = "/${book.title}";
                  final count = counts[facet] ?? 0;
                  return _buildBookTile(book, count, 0);
                },
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        );
      },
    );
  }

  Widget _buildCategoryTile(Category category, int count, int level) {
    if (count == 0) return const SizedBox.shrink();

    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        final isSelected = state.currentFacets.contains(category.path);
        final isExpanded = _expansionState[category.path] ?? level == 0;

        void toggle() {
          setState(() {
            _expansionState[category.path] = !isExpanded;
          });
        }

        return Column(
          children: [
            // שורת הקטגוריה - סגנון ספרייה
            InkWell(
              onTap: () {
                // Ctrl+לחיצה = toggle, לחיצה רגילה = set
                if (HardwareKeyboard.instance.isControlPressed) {
                  _handleFacetToggle(context, category.path);
                } else {
                  _setFacet(context, category.path);
                }
              },
              onLongPress: () => _handleFacetToggle(context, category.path),
              child: Container(
                padding: EdgeInsets.only(
                  right: 16.0 + (level * 24.0),
                  left: 16.0,
                  top: 12.0,
                  bottom: 12.0,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.3)
                      : null,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpanded
                          ? FluentIcons.folder_open_24_regular
                          : FluentIcons.folder_24_regular,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    // מספר התוצאות
                    if (count != -1)
                      Text(
                        '($count)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (count == -1)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                    const SizedBox(width: 8),
                    // כפתור החץ - מרחיב/מכווץ בלבד
                    InkWell(
                      onTap: toggle,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          isExpanded
                              ? FluentIcons.chevron_up_24_regular
                              : FluentIcons.chevron_down_24_regular,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ילדים
            if (isExpanded)
              Column(children: _buildCategoryChildren(category, level)),
          ],
        );
      },
    );
  }

  List<Widget> _buildCategoryChildren(Category category, int level) {
    final List<Widget> children = [];

    // הוספת תת-קטגוריות
    for (final subCategory in category.subCategories) {
      children.add(BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          final countFuture = widget.tab.countForFacetCached(subCategory.path);
          return FutureBuilder<int>(
            key: ValueKey('${state.searchQuery}_${subCategory.path}'),
            future: countFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final count = snapshot.data!;
                // מציגים את הקטגוריה רק אם יש בה תוצאות או אם אנחנו בטעינה
                if (count > 0 || count == -1) {
                  return _buildCategoryTile(subCategory, count, level + 1);
                }
                return const SizedBox.shrink();
              }
              return _buildCategoryTile(subCategory, -1, level + 1);
            },
          );
        },
      ));
    }

    // הוספת ספרים
    for (final book in category.books) {
      children.add(BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          // בניית facet נכון על בסיס נתיב הקטגוריה
          final categoryPath = category.path;
          final fullFacet = "$categoryPath/${book.title}";
          final topicsOnlyFacet = categoryPath;
          final titleOnlyFacet = "/${book.title}";

          // ננסה קודם עם ה-facet המלא
          final countFuture = widget.tab.countForFacetCached(fullFacet);
          return FutureBuilder<int>(
            key: ValueKey('${state.searchQuery}_$fullFacet'),
            future: countFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final count = snapshot.data!;

                // אם יש תוצאות, נציג את הספר
                if (count > 0 || count == -1) {
                  return _buildBookTile(book, count, level + 1,
                      categoryPath: category.path);
                }

                // אם אין תוצאות עם ה-facet המלא, ננסה עם topics בלבד
                return FutureBuilder<int>(
                  key: ValueKey('${state.searchQuery}_$topicsOnlyFacet'),
                  future: widget.tab.countForFacetCached(topicsOnlyFacet),
                  builder: (context, topicsSnapshot) {
                    if (topicsSnapshot.hasData) {
                      final topicsCount = topicsSnapshot.data!;

                      if (topicsCount > 0 || topicsCount == -1) {
                        // יש תוצאות בקטגוריה, אבל לא בספר הספציפי
                        // לא נציג את הספר כי זה יגרום להצגת ספרים ללא תוצאות
                        return const SizedBox.shrink();
                      }

                      // ננסה עם שם הספר בלבד
                      return FutureBuilder<int>(
                        key: ValueKey('${state.searchQuery}_$titleOnlyFacet'),
                        future: widget.tab.countForFacetCached(titleOnlyFacet),
                        builder: (context, titleSnapshot) {
                          if (titleSnapshot.hasData) {
                            final titleCount = titleSnapshot.data!;

                            if (titleCount > 0 || titleCount == -1) {
                              return _buildBookTile(book, titleCount, level + 1,
                                  categoryPath: category.path);
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      );
                    }
                    return _buildBookTile(book, -1, level + 1);
                  },
                );
              }
              return _buildBookTile(book, -1, level + 1,
                  categoryPath: category.path);
            },
          );
        },
      ));
    }

    return children;
  }

  List<Book> _getAllBooksFromLibrary(Category category) {
    final List<Book> allBooks = [];

    void collectBooks(Category cat) {
      allBooks.addAll(cat.books);
      for (final subCat in cat.subCategories) {
        collectBooks(subCat);
      }
    }

    collectBooks(category);
    return allBooks;
  }

  Widget _buildFacetTree() {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, libraryState) {
        if (libraryState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (libraryState.error != null) {
          return Center(child: Text('Error: ${libraryState.error}'));
        }

        // בדיקה אם יש סינון ספרים - מחוץ ל-BlocBuilder
        if (_filterQuery.text.length >= _kMinQueryLength) {
          if (libraryState.library != null) {
            // סינון ידנית מהספרייה
            final allBooks = _getAllBooksFromLibrary(libraryState.library!);
            final filtered = allBooks
                .where((book) => book.title
                    .toLowerCase()
                    .contains(_filterQuery.text.toLowerCase()))
                .toList();
            return _buildBooksList(filtered);
          }
        }

        return BlocBuilder<SearchBloc, SearchState>(
          builder: (context, searchState) {

            if (libraryState.library == null) {
              return const Center(child: Text('No library data available'));
            }

            final rootCategory = libraryState.library!;
            final countFuture =
                widget.tab.countForFacetCached(rootCategory.path);
            return FutureBuilder<int>(
              key: ValueKey(
                  '${searchState.searchQuery}_${rootCategory.path}'), // מפתח שמשתנה עם החיפוש
              future: countFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return SingleChildScrollView(
                    key: PageStorageKey(widget.tab),
                    child: _buildCategoryTile(rootCategory, snapshot.data!, 0),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        _buildSearchField(),
        const ThinDivider(), // Now perfectly aligned
        Expanded(
          child: _buildFacetTree(),
        ),
      ],
    );
  }
}
