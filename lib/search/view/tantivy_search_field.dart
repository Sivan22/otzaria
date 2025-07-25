import 'package:flutter/material.dart';
import 'package:otzaria/search/view/tantivy_full_text_search.dart';
import 'package:otzaria/search/view/enhanced_search_field.dart';

class TantivySearchField extends StatelessWidget {
  const TantivySearchField({
    super.key,
    required this.widget,
  });

  final TantivyFullTextSearch widget;

  @override
  Widget build(BuildContext context) {
    // נבדוק את השדה החדש
    return EnhancedSearchField(widget: widget);
  }
}
