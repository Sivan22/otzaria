import 'package:flutter/material.dart';
import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/tabs/searching_tab.dart';
import 'package:otzaria/screens/full_text_search/full_text_settings_screen.dart';
import 'package:otzaria/screens/full_text_search/tantivy_search_field.dart';
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //_buildMenuButton(),
                  Expanded(
                    child: TantivySearchField(widget: widget),
                  ),
                  FuzzyDistance(tab: widget.tab),
                  FuzzyToggle(tab: widget.tab)
                ],
              ),
              Expanded(
                  child: ListenableBuilder(
                      listenable: widget.tab.results,
                      builder: (context, _) {
                        return FutureBuilder(
                            future: widget.tab.results.value,
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                    child: Text('Error: ${snapshot.error}'));
                              }
                              if (widget.tab.queryController.text.isEmpty) {
                                return const Center(
                                    child: Text("לא בוצע חיפוש"));
                              }
                              if (snapshot.hasData && snapshot.data!.isEmpty) {
                                return const Center(
                                    child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('אין תוצאות'),
                                ));
                              }
                              return Row(
                                children: [
                                  SizedBox(
                                    width: 350,
                                    child: SearchFacetFiltering(
                                        tab: widget.tab,
                                        library:
                                            context.read<AppModel>().library),
                                  ),
                                  Expanded(
                                      child:
                                          TantivySearchResults(tab: widget.tab))
                                ],
                              );
                            });
                      }))
            ]);
          }),
    );
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
        const Expanded(child: SizedBox.shrink()),
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
