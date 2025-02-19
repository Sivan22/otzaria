import 'package:flutter/material.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/full_text_search.dart';
import 'package:otzaria/models/tabs/searching_tab.dart';
import 'package:otzaria/models/tabs/tab.dart';
import 'package:otzaria/screens/full_text_search/tantivy_full_text_search.dart';
import 'package:otzaria/screens/full_text_search/legacy_full_text_search_screen.dart';
import 'package:provider/provider.dart';

class FullTextSearchScreen extends StatelessWidget {
  final void Function(OpenedTab) openBookCallback;
  final SearchingTab tab;
  const FullTextSearchScreen(
      {Key? key, required this.tab, required this.openBookCallback})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: context.read<AppModel>().useFastSearch,
      builder: (context, value, child) => value
          ? TantivyFullTextSearch(
              tab: tab,
            )
          : TextFileSearchScreen(
              searcher: FullTextSearcher([], TextEditingController(), []),
              openBookCallback: openBookCallback,
            ),
    );
  }
}
