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
const double _kTreePadding = 6.0;
const double _kTreeLevelIndent = 10.0;
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

  Widget _buildBookTile(Book book, int count, int level) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    final facet = "/${book.topics.replaceAll(', ', '/')}/${book.title}";
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
                    .withOpacity(_kBackgroundOpacity)
                : null,
            title: Text("${book.title} ($count)"),
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
    return ListView.builder(
      shrinkWrap: true,
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final facet = "/${book.topics.replaceAll(', ', '/')}/${book.title}";
        return Builder(
          builder: (context) {
            final countFuture = context.read<SearchBloc>().countForFacet(facet);
            return FutureBuilder<int>(
              future: countFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return _buildBookTile(book, snapshot.data!, 0);
                }
                return const SizedBox.shrink();
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryTile(Category category, int count, int level) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        final isSelected = state.currentFacets.contains(category.path);
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey(category.path),
            backgroundColor: isSelected
                ? Theme.of(context)
                    .colorScheme
                    .surfaceTint
                    .withOpacity(_kBackgroundOpacity)
                : null,
            collapsedBackgroundColor: isSelected
                ? Theme.of(context)
                    .colorScheme
                    .surfaceTint
                    .withOpacity(_kBackgroundOpacity)
                : null,
            leading: const Icon(Icons.chevron_right_rounded),
            trailing: const SizedBox.shrink(),
            iconColor: Theme.of(context).colorScheme.primary,
            collapsedIconColor: Theme.of(context).colorScheme.primary,
            title: GestureDetector(
                onTap: () => HardwareKeyboard.instance.isControlPressed
                    ? _handleFacetToggle(context, category.path)
                    : _setFacet(context, category.path),
                onDoubleTap: () => _handleFacetToggle(context, category.path),
                onLongPress: () => _handleFacetToggle(context, category.path),
                child: Text("${category.title} ($count)")),
            initiallyExpanded: level == 0,
            tilePadding: EdgeInsets.only(
              right: _kTreePadding + (level * _kTreeLevelIndent),
            ),
            children: _buildCategoryChildren(category, level),
          ),
        );
      },
    );
  }

  List<Widget> _buildCategoryChildren(Category category, int level) {
    return [
      ...category.subCategories.map((subCategory) {
        final countFuture =
            context.read<SearchBloc>().countForFacet(subCategory.path);
        return FutureBuilder<int>(
          future: countFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return _buildCategoryTile(subCategory, snapshot.data!, level + 1);
            }
            return const SizedBox.shrink();
          },
        );
      }),
      ...category.books.map((book) {
        final facet = "/${book.topics.replaceAll(', ', '/')}/${book.title}";
        final countFuture = context.read<SearchBloc>().countForFacet(facet);
        return FutureBuilder<int>(
          future: countFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return _buildBookTile(book, snapshot.data!, level + 1);
            }
            return const SizedBox.shrink();
          },
        );
      }),
    ];
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

        final rootCategory = libraryState.library!;
        final countFuture =
            context.read<SearchBloc>().countForFacet(rootCategory.path);
        return FutureBuilder<int>(
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
