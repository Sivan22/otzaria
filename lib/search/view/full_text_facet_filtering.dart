import 'package:flutter/material.dart';
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

// Constants
const double _kTreePadding = 15.0;
const double _kTreeLevelIndent = 3.0;
const double _kMinQueryLength = 2;
const double _kBackgroundOpacity = 0.1;

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
    Key? key,
    required this.tab,
  }) : super(key: key);

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
          prefixIcon: const Icon(Icons.filter_list_alt),
          suffixIcon: IconButton(
            onPressed: _clearFilter,
            icon: const Icon(Icons.close),
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
          onDoubleTap: () => _handleFacetToggle(context, facet),
          child: ListTile(
            contentPadding: EdgeInsets.only(
              right: (_kTreePadding * 2) + (level * _kTreeLevelIndent),
            ),
            tileColor: isSelected
                ? Theme.of(context)
                    .colorScheme
                    .surfaceTint
                    .withValues(alpha: _kBackgroundOpacity)
                : null,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                    child:
                        Text("${book.title} ${count == -1 ? '' : '($count)'}")),
                if (count == -1)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
              ],
            ),
            onTap: () => HardwareKeyboard.instance.isControlPressed
                ? _handleFacetToggle(context, facet)
                : _setFacet(context, facet),
            onLongPress: () => _handleFacetToggle(context, facet),
          ),
        );
      },
    );
  }

  Widget _buildBooksList(List<Book> books) {
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
        final primaryColor = Theme.of(context).colorScheme.primary;
        final isExpanded = _expansionState[category.path] ?? level == 0;

        void toggle() {
          setState(() {
            _expansionState[category.path] = !isExpanded;
          });
        }

        return Column(
          children: [
            // ─────────── שורת-הכותרת ───────────
            Container(
              color: isSelected
                  ? Theme.of(context)
                      .colorScheme
                      .surfaceTint
                      .withValues(alpha: _kBackgroundOpacity)
                  : null,
              child: Row(
                textDirection:
                    TextDirection.rtl, // RTL: הטקסט מימין, המספר משמאל
                children: [
                  // אזור-החץ – רוחב ~1 ס"מ
                  SizedBox(
                    width: 40,
                    height: 48,
                    child: InkWell(
                      onTap: toggle,
                      child: Icon(
                        isExpanded
                            ? Icons.expand_more // חץ מטה כשהשורה פתוחה
                            : Icons.chevron_right_rounded,
                        color: primaryColor,
                      ),
                    ),
                  ),

                  // פס-הפרדה אפור דק
                  Container(width: 1, height: 32, color: Colors.grey.shade300),

                  // השורה עצמה
                  Expanded(
                    child: InkWell(
                      onTap: () => HardwareKeyboard.instance.isControlPressed
                          ? _handleFacetToggle(context, category.path)
                          : _setFacet(context, category.path),
                      onDoubleTap: () =>
                          _handleFacetToggle(context, category.path),
                      onLongPress: () =>
                          _handleFacetToggle(context, category.path),
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: _kTreePadding + (level * _kTreeLevelIndent),
                          top: 8,
                          bottom: 8,
                        ),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            // כותרת הקטגוריה
                            Expanded(child: Text(category.title)),
                            // המספר – בקצה השמאלי
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(count == -1 ? '' : '($count)'),
                            ),
                            if (count == -1)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child:
                                    CircularProgressIndicator(strokeWidth: 1.5),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─────────── ילדים ───────────
            if (isExpanded)
              Padding(
                padding: EdgeInsets.only(
                    right: _kTreePadding +
                        (level * _kTreeLevelIndent)), // הזחה פנימה
                child:
                    Column(children: _buildCategoryChildren(category, level)),
              ),
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

          print(
              '🔍 Checking facets for book "${book.title}" in category "${category.path}":');
          print('  - Full: $fullFacet');
          print('  - Topics only: $topicsOnlyFacet');
          print('  - Title only: $titleOnlyFacet');

          // ננסה קודם עם ה-facet המלא
          final countFuture = widget.tab.countForFacetCached(fullFacet);
          return FutureBuilder<int>(
            key: ValueKey('${state.searchQuery}_$fullFacet'),
            future: countFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final count = snapshot.data!;
                print('📊 Count for "${book.title}" ($fullFacet): $count');

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
                      print(
                          '📊 Count for "${book.title}" ($topicsOnlyFacet): $topicsCount');

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
                            print(
                                '📊 Count for "${book.title}" ($titleOnlyFacet): $titleCount');

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

  Widget _buildFacetTree() {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, libraryState) {
        if (libraryState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (libraryState.error != null) {
          return Center(child: Text('Error: ${libraryState.error}'));
        }

        if (_filterQuery.text.length >= _kMinQueryLength) {
          return _buildBooksList(
              context.read<SearchBloc>().state.filteredBooks ?? []);
        }

        if (libraryState.library == null) {
          return const Center(child: Text('No library data available'));
        }

        return BlocBuilder<SearchBloc, SearchState>(
          builder: (context, searchState) {
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
