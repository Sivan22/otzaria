import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/search/bloc/search_bloc.dart';
import 'package:otzaria/search/bloc/search_event.dart';
import 'package:otzaria/search/view/tantivy_full_text_search.dart';

class TantivySearchField extends StatelessWidget {
  const TantivySearchField({
    super.key,
    required this.widget,
  });

  final TantivyFullTextSearch widget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        autofocus: true,
        focusNode: widget.tab.searchFieldFocusNode,
        controller: widget.tab.queryController,
        onSubmitted: (e) {
          context.read<SearchBloc>().add(UpdateSearchQuery(e));
          widget.tab.isLeftPaneOpen.value = false;
          // Keep focus on search field after submission
          widget.tab.searchFieldFocusNode.requestFocus();
        },
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: "חפש כאן..",
          labelText: "לחיפוש הקש אנטר או לחץ על סמל החיפוש",
          prefixIcon: IconButton(
            onPressed: () {
              context
                  .read<SearchBloc>()
                  .add(UpdateSearchQuery(widget.tab.queryController.text));
              // Keep focus on search field after clicking search button
              widget.tab.searchFieldFocusNode.requestFocus();
            },
            icon: const Icon(Icons.search),
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              widget.tab.queryController.clear();
              context.read<SearchBloc>().add(UpdateSearchQuery(''));
              // Keep focus on search field after clearing
              widget.tab.searchFieldFocusNode.requestFocus();
            },
          ),
        ),
      ),
    );
  }
}
