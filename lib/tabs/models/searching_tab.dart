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

  // אפשרויות חיפוש לכל מילה (מילה_אינדקס -> אפשרויות)
  final Map<String, Map<String, bool>> searchOptions = {};

  // מילים חילופיות לכל מילה (אינדקס_מילה -> רשימת מילים חילופיות)
  final Map<int, List<String>> alternativeWords = {};

  // מרווחים בין מילים (מפתח_מרווח -> ערך_מרווח)
  final Map<String, String> spacingValues = {};

  // notifier לעדכון התצוגה כשמשתמש משנה אפשרויות
  final ValueNotifier<int> searchOptionsChanged = ValueNotifier(0);

  // notifier לעדכון התצוגה כשמשתמש משנה מילים חילופיות
  final ValueNotifier<int> alternativeWordsChanged = ValueNotifier(0);

  // notifier לעדכון התצוגה כשמשתמש משנה מרווחים
  final ValueNotifier<int> spacingValuesChanged = ValueNotifier(0);

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
    return searchBloc.countForFacet(
      facet,
      customSpacing: spacingValues,
      alternativeWords: alternativeWords,
      searchOptions: searchOptions,
    );
  }

  /// ספירה מקבצת של תוצאות עבור מספר facets בבת אחת - לשיפור ביצועים
  Future<Map<String, int>> countForMultipleFacets(List<String> facets) {
    return searchBloc.countForMultipleFacets(
      facets,
      customSpacing: spacingValues,
      alternativeWords: alternativeWords,
      searchOptions: searchOptions,
    );
  }

  /// ספירה חכמה - מחזירה תוצאות מהירות מה-state או מבצעת ספירה
  Future<int> countForFacetCached(String facet) async {
    // קודם נבדוק אם יש ספירה ב-state של ה-bloc (כולל 0)
    final stateCount = searchBloc.getFacetCountFromState(facet);
    if (searchBloc.state.facetCounts.containsKey(facet)) {
      print('💾 Cache hit for $facet: $stateCount');
      return stateCount;
    }

    print('🔄 Cache miss for $facet, performing direct count...');
    print(
        '📍 Stack trace: ${StackTrace.current.toString().split('\n').take(5).join('\n')}');
    final stopwatch = Stopwatch()..start();
    // אם אין ב-state, נבצע ספירה ישירה
    final result = await countForFacet(facet);
    stopwatch.stop();
    print(
        '⏱️ Direct count for $facet took ${stopwatch.elapsedMilliseconds}ms: $result');

    // Update SearchBloc state cache
    searchBloc.add(UpdateFacetCounts({facet: result}));

    return result;
  }

  /// מחזיר ספירה סינכרונית מה-state (אם קיימת)
  int getFacetCountFromState(String facet) {
    return searchBloc.getFacetCountFromState(facet);
  }

  @override
  void dispose() {
    searchFieldFocusNode.dispose();
    searchOptionsChanged.dispose();
    alternativeWordsChanged.dispose();
    spacingValuesChanged.dispose();
    super.dispose();
  }

  @override
  factory SearchingTab.fromJson(Map<String, dynamic> json) {
    final tab = SearchingTab(json['title'], json['searchText']);
    return tab;
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
