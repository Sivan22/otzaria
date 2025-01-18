import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/tabs.dart';
import 'package:otzaria/screens/full_text_search/tantivy_search_results.dart';
import 'package:otzaria/screens/full_text_search/full_text_left_pane.dart';
import 'package:provider/provider.dart';
import 'package:toggle_switch/toggle_switch.dart';

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

  ValueNotifier isLeftPaneOpen = ValueNotifier(false);
  bool _showIndexWarning = false;

  @override
  void initState() {
    super.initState();
    () async {
      final library = await context.read<AppModel>().library;
      final allBooks = (library).getAllBooks();

      if (widget.tab.booksToSearch.value.isEmpty) {
        widget.tab.booksToSearch.value = allBooks.toSet();
      }

      //Check if index is up to date
      final totalBooks = allBooks.length;
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
            return Column(
              children: [
                if (_showIndexWarning) _buildIndexWarning(),
                Expanded(
                  child: Row(children: [
                    _buildMenuButton(),
                    _buildLeftPane(),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildSearchField(),
                                        ),
                                        _buildSearchParameters(),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Expanded(child: TantivySearchResults(tab: widget.tab))
                        ],
                      ),
                    )
                  ]),
                ),
              ],
            );
          }),
    );
  }

  Padding _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        autofocus: true,
        controller: widget.tab.queryController,
        onSubmitted: (e) => widget.tab.updateResults(),
        decoration: InputDecoration(
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
    );
  }

  Row _buildSearchParameters() {
    return Row(children: [
      SizedBox(
        width: 200,
        child: ValueListenableBuilder(
            valueListenable: widget.tab.numResults,
            builder: (context, numResults, child) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: SpinBox(
                  value: numResults.toDouble(),
                  onChanged: (value) =>
                      widget.tab.numResults.value = (value.toInt()),
                  min: 10,
                  max: 10000,
                  decoration:
                      const InputDecoration(labelText: 'מספר תוצאות להצגה'),
                ),
              );
            }),
      ),
      SizedBox(
        width: 200,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ValueListenableBuilder(
              valueListenable: widget.tab.distance,
              builder: (context, distance, child) {
                return SpinBox(
                  decoration: const InputDecoration(
                      labelText: 'מרווח בין מילות החיפוש'),
                  min: 0,
                  max: 30,
                  value: distance.toDouble(),
                  onChanged: (value) =>
                      widget.tab.distance.value = value.toInt(),
                );
              }),
        ),
      ),
      ValueListenableBuilder(
          valueListenable: widget.tab.fuzzy,
          builder: (context, aproximateSearch, child) {
            return ToggleSwitch(
              minWidth: 120,
              cornerRadius: 20.0,
              inactiveBgColor: Colors.grey,
              inactiveFgColor: Colors.white,
              initialLabelIndex: aproximateSearch ? 1 : 0,
              totalSwitches: 2,
              labels: ['חיפוש מדוייק', 'חיפוש מקורב'],
              radiusStyle: true,
              onToggle: (index) {
                widget.tab.fuzzy.value = index != 0;
              },
            );
          }),
    ]);
  }

  AnimatedSize _buildLeftPane() {
    return AnimatedSize(
        duration: const Duration(milliseconds: 300),
        child: SizedBox(
          width: isLeftPaneOpen.value ? 350 : 0,
          child: FullTextLeftPane(tab: widget.tab),
        ));
  }

  Column _buildMenuButton() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
          child: IconButton(
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
