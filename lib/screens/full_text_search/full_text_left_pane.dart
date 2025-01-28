// Core Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Model imports
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/library.dart';
import 'package:otzaria/models/tabs/searching_tab.dart';

// Screen imports
import 'package:otzaria/screens/full_text_search/full_text_settings_screen.dart';

// Constants
const double _kSettingsHeight = 120.0;
const double _kTreePadding = 6.0;
const double _kTreeLevelIndent = 10.0;
const double _kBookTilePadding = 16.0;
const double _kMinQueryLength = 2;
const double _kBackgroundOpacity = 0.1;

class FullTextLeftPane extends StatefulWidget {
  final SearchingTab tab;
  final Future<Library> library;

  const FullTextLeftPane({
    Key? key,
    required this.tab,
    required this.library,
  }) : super(key: key);

  @override
  State<FullTextLeftPane> createState() => _FullTextLeftPaneState();
  State<FullTextLeftPane> createState() => _FullTextLeftPaneState();
}

class _FullTextLeftPaneState extends State<FullTextLeftPane>
    with SingleTickerProviderStateMixin {
  List<Book> allBooks = [];
  List<Book> books = [];
  final TextEditingController _filterQuery = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeBooks();
  }

  void _initializeBooks() async {
    allBooks = (await widget.library).getAllBooks();
  }

  void _updateFilteredBooks() {
    var filteredList =
        allBooks.where((book) => book.title.contains(_filterQuery.text));
    setState(() {
      books = filteredList.toList();
    });
  }

  void _clearFilter() {
    setState(() => _filterQuery.text = '');
  }

  void _handleFacetToggle(String facet) {
    setState(() {
      if (widget.tab.currentFacets.value.contains(facet)) {
        widget.tab.currentFacets.value.remove(facet);
      } else {
        widget.tab.currentFacets.value.add(facet);
      }
      widget.tab.currentFacets.notifyListeners();
      widget.tab.updateResults();
    });
  }

  void _setFacet(String facet) {
    widget.tab.currentFacets.value = [facet];
    widget.tab.currentFacets.notifyListeners();
    widget.tab.updateResults();
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _filterQuery,
      decoration: InputDecoration(
        hintText: "איתור ספר...",
        prefixIcon: const Icon(Icons.filter_list_alt),
        suffixIcon: IconButton(
          onPressed: _clearFilter,
          icon: const Icon(Icons.close),
        ),
      ),
      onChanged: (_) => setState(() => _updateFilteredBooks()),
    );
  }

  Widget _buildBookTile(Book book, AsyncSnapshot<int> snapshot, int level) {
    if (!snapshot.hasData || snapshot.data! <= 0) {
      return const SizedBox.shrink();
    }

    final facet = "/${book.topics.replaceAll(', ', '/')}/${book.title}";
    final isSelected = isChecked(book);

    return InkWell(
      onDoubleTap: () => _handleFacetToggle(facet),
      child: ListTile(
        contentPadding: EdgeInsets.only(
            right: (_kTreePadding * 2) + (level * _kTreeLevelIndent)),
        tileColor: isSelected
            ? Theme.of(context)
                .colorScheme
                .surfaceTint
                .withOpacity(_kBackgroundOpacity)
            : null,
        title: Text(
          snapshot.hasData ? "${book.title} (${snapshot.data})" : book.title,
        ),
        onTap: () => HardwareKeyboard.instance.isControlPressed
            ? _handleFacetToggle(facet)
            : _setFacet(facet),
        onLongPress: () => _handleFacetToggle(facet),
      ),
    );
  }

  Widget _buildBooksList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: books.length,
            itemBuilder: (context, index) => FutureBuilder<int>(
              future: widget.tab.countForFacet(
                "/${books[index].topics.replaceAll(', ', '/')}/${books[index].title}",
              ),
              builder: (context, snapshot) =>
                  _buildBookTile(books[index], snapshot, 0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTile(
      Category category, AsyncSnapshot<int> snapshot, int level) {
    if (!snapshot.hasData || snapshot.data! <= 0) {
      return const SizedBox.shrink();
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        backgroundColor: isChecked(category)
            ? Theme.of(context)
                .colorScheme
                .surfaceTint
                .withOpacity(_kBackgroundOpacity)
            : null,
        collapsedBackgroundColor: isChecked(category)
            ? Theme.of(context)
                .colorScheme
                .surfaceTint
                .withOpacity(_kBackgroundOpacity)
            : null,
        leading: const Icon(Icons.chevron_right_rounded),
        trailing: const SizedBox.shrink(),
        iconColor: Theme.of(context).colorScheme.primary,
        collapsedIconColor: Theme.of(context).colorScheme.primary,
        title: _buildCategoryTitle(category, snapshot),
        initiallyExpanded: level == 0,
        tilePadding: EdgeInsets.only(
          right: _kTreePadding + (level * _kTreeLevelIndent),
        ),
        children: _buildCategoryChildren(category, level),
      ),
    );
  }

  Widget _buildCategoryTitle(Category category, AsyncSnapshot<int> snapshot) {
    if (!snapshot.hasData || snapshot.data! <= 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => HardwareKeyboard.instance.isControlPressed
          ? _handleFacetToggle(category.path)
          : _setFacet(category.path),
      onLongPress: () => _handleFacetToggle(category.path),
      onDoubleTap: () {
        if (!isChecked(category)) {
          _handleFacetToggle(category.path);
        }
      },
      child: Text("${category.title} (${snapshot.data})"),
    );
  }

  List<Widget> _buildCategoryChildren(Category category, int level) {
    return ([] + category.subCategories + category.books).map((entity) {
      if (entity is Category) {
        return _buildTree(entity, level: level + 1);
      } else if (entity is Book) {
        return ListenableBuilder(
          listenable: widget.tab.results,
          builder: (context, _) {
            final count = widget.tab.countForFacet(
              "/${entity.topics.replaceAll(', ', '/')}/${entity.title}",
            );
            return FutureBuilder<int>(
              future: count,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (snapshot.hasData && snapshot.data! > 0) {
                  return _buildBookTile(entity as Book, snapshot, level + 1);
                }
                return const SizedBox.shrink();
              },
            );
          },
        );
      }
      return const SizedBox.shrink();
    }).toList();
  }

  Widget _buildTree(Category category, {int level = 0}) {
    return ListenableBuilder(
      listenable: widget.tab.results,
      builder: (context, _) {
        final count = widget.tab.countForFacet(category.path);
        return FutureBuilder<int>(
          future: count,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            return _buildCategoryTile(category, snapshot, level);
          },
        );
      },
    );
  }

  Widget _buildBooksTree(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.tab.results,
      builder: (context, _) {
        return ValueListenableBuilder(
          valueListenable: widget.tab.booksToSearch,
          builder: (context, value, child) {
            return FutureBuilder<Library>(
              future: Provider.of<AppModel>(context, listen: false).library,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                return SingleChildScrollView(
                  child: _buildTree(snapshot.data!),
                );
              },
            );
          },
        );
      },
    );
  }

  bool isChecked(dynamic entity) {
    if (entity is Category) {
      return widget.tab.currentFacets.value.contains(entity.path) ||
          (entity.title != "ספריית אוצריא" && isChecked(entity.parent));
    }
    return isChecked(entity.category) ||
        widget.tab.currentFacets.value.contains(
            "/${entity.topics.replaceAll(', ', '/')}/${entity.title}");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox.fromSize(
          size: const Size.fromHeight(_kSettingsHeight),
          child: FullTextSettingsScreen(tab: widget.tab),
        ),
        _buildSearchField(),
        _filterQuery.text.length < _kMinQueryLength
            ? Expanded(child: _buildBooksTree(context))
            : Expanded(child: _buildBooksList()),
      ],
    );
  }
}
