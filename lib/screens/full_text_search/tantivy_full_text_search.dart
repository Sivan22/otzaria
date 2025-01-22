import 'package:flutter/material.dart';
import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/tabs.dart';
import 'package:otzaria/screens/full_text_search/tantivy_search_results.dart';
import 'package:otzaria/screens/full_text_search/full_text_left_pane.dart';
import 'package:provider/provider.dart';

class TantivyFullTextSearch extends StatefulWidget {
  final SearchingTab tab;
  const TantivyFullTextSearch({Key? key, required this.tab}) : super(key: key);
  @override
  State<TantivyFullTextSearch> createState() => _TantivyFullTextSearchState();
}

class _TantivyFullTextSearchState extends State<TantivyFullTextSearch>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  ValueNotifier isLeftPaneOpen = ValueNotifier(true);
  bool _showIndexWarning = false;

  @override
  void initState() {
    super.initState();
    _showIndexWarning = TantivyDataProvider.instance.isIndexing.value;
    () async {
      final library = await context.read<AppModel>().library;
      widget.tab.allBooks = (library).getAllBooks();

      if (widget.tab.booksToSearch.value.isEmpty) {
        widget.tab.booksToSearch.value = widget.tab.allBooks.toSet();
      }

      //Check if index is up to date
      final totalBooks = widget.tab.allBooks.length;
      final indexedBooks = TantivyDataProvider.instance.booksDone.length;
      if (!TantivyDataProvider.instance.isIndexing.value &&
          totalBooks - indexedBooks > 15) {
        DataRepository.instance.addAllTextsToTantivy(library);
        _showIndexWarning = true;
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: ValueListenableBuilder(
          valueListenable: isLeftPaneOpen,
          builder: (context, value, child) {
            return Column(children: [
              if (_showIndexWarning) _buildIndexWarning(),
              Expanded(
                child: Row(
                  children: [
                    _buildMenuButton(),
                    _buildLeftPane(),
                    Expanded(
                      child: _buildSearchField(),
                    )
                  ],
                ),
              ),
            ]);
          }),
    );
  }

  Column _buildSearchField() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            autofocus: true,
            controller: widget.tab.queryController,
            onSubmitted: (e) => widget.tab.updateResults(),
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: "חפש כאן..",
              labelText: "לחיפוש הקש אנטר או לחץ על סמל החיפוש",
              prefixIcon: IconButton(
                  onPressed: () {
                    widget.tab.updateResults();
                  },
                  icon: Icon(Icons.search)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  widget.tab.queryController.clear();
                },
              ),
            ),
          ),
        ),
        TantivySearchResults(tab: widget.tab)
      ],
    );
  }

  AnimatedSize _buildLeftPane() {
    return AnimatedSize(
        duration: const Duration(milliseconds: 300),
        child: SizedBox(
          width: isLeftPaneOpen.value ? 350 : 0,
          height: isLeftPaneOpen.value ? double.infinity : 0,
          child: FullTextLeftPane(
              tab: widget.tab, library: context.read<AppModel>().library),
        ));
  }

  Column _buildMenuButton() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
          child: IconButton(
            tooltip: "הגדרות חיפוש",
            icon: const Icon(Icons.menu),
            onPressed: () {
              isLeftPaneOpen.value = !isLeftPaneOpen.value;
            },
          ),
        ),
        Expanded(child: SizedBox.shrink()),
      ],
    );
  }

  Container _buildIndexWarning() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange[700]),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'אינדקס החיפוש בתהליך עידכון. חלק מהספרים עלולים להיות חסרים בתוצאות החיפוש.',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.black87),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _showIndexWarning = false;
              });
            },
          )
        ],
      ),
    );
  }
}
