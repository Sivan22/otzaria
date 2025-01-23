import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/models/tabs/tabs.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:otzaria/models/full_text_search.dart';
import 'package:otzaria/models/books.dart';
import 'package:search_engine/search_engine.dart';

class SearchingTab extends OpenedTab {
  ///the distance between words in the search
  ValueNotifier<int> distance = ValueNotifier<int>(2);

  ///the flag that tells if to perform fuzzy search
  ValueNotifier<bool> fuzzy = ValueNotifier<bool>(false);

  final queryController = TextEditingController();

  Future<int> totalResultsNum = Future.value(0);

  List<String> booksNamesToSearch = [];

  List<Book> allBooks = [];

  ValueNotifier<ResultsOrder> sortBy =
      ValueNotifier<ResultsOrder>(ResultsOrder.catalogue);

  ///the list of books to search in
  ValueNotifier<Set<Book>> booksToSearch = ValueNotifier({});

  ///the list of search results
  ValueNotifier<Future<List<SearchResult>>> results =
      ValueNotifier(Future.value([]));

  ValueNotifier<int> numResults = ValueNotifier(100);
  FullTextSearcher searcher = FullTextSearcher(
    [],
    TextEditingController(),
    ValueNotifier([]),
  );
  final ItemScrollController scrollController = ItemScrollController();

  SearchingTab(
    super.title,
    String? searchText,
  ) {
    if (searchText != null) {
      queryController.text = searchText;
      updateResults();
    }
    fuzzy.addListener(() => updateResults());
    distance.addListener(() => updateResults());
    booksToSearch.addListener(() => updateResults());
    numResults.addListener(() => updateResults());
    sortBy.addListener(() => updateResults());
  }

  void updateResults() {
    if (queryController.text.isEmpty) {
      results.value = Future.value([]);
    } else {
      booksNamesToSearch =
          booksToSearch.value.map<String>((e) => e.title).toList();

      totalResultsNum = TantivyDataProvider.instance.countTexts(
          queryController.text.replaceAll('"', '\\"'), booksNamesToSearch, "/",
          fuzzy: fuzzy.value, distance: distance.value);

      results.value = TantivyDataProvider.instance.searchTexts(
          queryController.text.replaceAll('"', '\\"'),
          booksNamesToSearch,
          numResults.value,
          fuzzy: fuzzy.value,
          distance: distance.value,
          order: sortBy.value);
    }
  }

  Future<int> countForBook(String bookTitle) async {
    if (queryController.text.isEmpty) {
      return 0;
    }
    return TantivyDataProvider.instance.countTexts(
        queryController.text.replaceAll('"', '\\"'), [bookTitle], "/",
        fuzzy: fuzzy.value, distance: distance.value);
  }

  Future<int> countForFacet(String facet) async {
    if (queryController.text.isEmpty) {
      return 0;
    }
    return TantivyDataProvider.instance.countTexts(
        queryController.text.replaceAll('"', '\\"'),
        allBooks.map((e) => e.title).toList(),
        facet,
        fuzzy: fuzzy.value,
        distance: distance.value);
  }

  @override
  factory SearchingTab.fromJson(Map<String, dynamic> json) {
    return SearchingTab(json['title'], json['searchText']);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'searchText': queryController.text,
      'type': 'SearchingTabWindow'
    };
  }
}
