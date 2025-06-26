import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/search/models/legacy_full_text_searcher.dart';
import 'package:otzaria/tabs/models/searching_tab.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/search/view/tantivy_full_text_search.dart';
import 'package:otzaria/search/view/legacy_full_text_search_screen.dart';

class FullTextSearchScreen extends StatelessWidget {
  final void Function(OpenedTab) openBookCallback;
  final SearchingTab tab;
  const FullTextSearchScreen(
      {Key? key, required this.tab, required this.openBookCallback})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return context.read<SettingsBloc>().state.useFastSearch
        ? BlocProvider.value(
            value: tab.searchBloc,
            child: TantivyFullTextSearch(
              tab: tab,
            ),
          )
        : TextFileSearchScreen(
            searcher: FullTextSearcher(
              [],
              TextEditingController(),
              ValueNotifier([]),
            ),
            openBookCallback: openBookCallback,
          );
  }
}
