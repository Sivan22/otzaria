import 'package:flutter/material.dart';
import 'package:otzaria/screens/full_text_search/tantivy_full_text_search.dart';

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
        controller: widget.tab.queryController,
        onSubmitted: (e) {
          widget.tab.updateResults();
        },
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: "חפש כאן..",
          labelText: "לחיפוש הקש אנטר או לחץ על סמל החיפוש",
          prefixIcon: IconButton(
              onPressed: () {
                widget.tab.updateResults();
              },
              icon: const Icon(Icons.search)),
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
}
