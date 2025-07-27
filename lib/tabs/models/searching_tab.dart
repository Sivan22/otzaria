import 'package:flutter/material.dart';
import 'package:otzaria/search/bloc/search_bloc.dart';
import 'package:otzaria/search/bloc/search_event.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:otzaria/models/books.dart';

class SearchingTab extends OpenedTab {
  final searchBloc = SearchBloc();
  final queryController = TextEditingController();
  final searchFieldFocusNode = FocusNode();
  final ValueNotifier<bool> isLeftPaneOpen = ValueNotifier(true);
  final ItemScrollController scrollController = ItemScrollController();
  List<Book> allBooks = [];
  
  // מצב חיפוש מתקדם
  bool isAdvancedSearchEnabled = true;

  SearchingTab(
    super.title,
    String? searchText,
  ) {
    if (searchText != null) {
      queryController.text = searchText;
      searchBloc.add(UpdateSearchQuery(searchText));
    }
  }

  Future<int> countForFacet(String facet) {
    return searchBloc.countForFacet(facet);
  }

  @override
  void dispose() {
    searchFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  factory SearchingTab.fromJson(Map<String, dynamic> json) {
    final tab = SearchingTab(json['title'], json['searchText']);
    tab.isAdvancedSearchEnabled = json['isAdvancedSearchEnabled'] ?? true;
    return tab;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'searchText': queryController.text,
      'isAdvancedSearchEnabled': isAdvancedSearchEnabled,
      'type': 'SearchingTabWindow'
    };
  }
}
