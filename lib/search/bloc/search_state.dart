import 'package:otzaria/models/books.dart';
import 'package:otzaria/search/models/search_configuration.dart';
import 'package:search_engine/search_engine.dart';

class SearchState {
  final String? filterQuery;
  final List<Book>? filteredBooks;
  final List<SearchResult> results;
  final Set<Book> booksToSearch;
  final bool isLoading;
  final String searchQuery;
  final int totalResults;

  // הגדרות החיפוש מרוכזות במחלקה נפרדת
  final SearchConfiguration configuration;

  const SearchState({
    this.results = const [],
    this.booksToSearch = const {},
    this.isLoading = false,
    this.searchQuery = '',
    this.totalResults = 0,
    this.filterQuery,
    this.filteredBooks,
    this.configuration = const SearchConfiguration(),
  });

  SearchState copyWith({
    List<SearchResult>? results,
    Set<Book>? booksToSearch,
    bool? isLoading,
    String? searchQuery,
    int? totalResults,
    String? filterQuery,
    List<Book>? filteredBooks,
    SearchConfiguration? configuration,
  }) {
    return SearchState(
      results: results ?? this.results,
      booksToSearch: booksToSearch ?? this.booksToSearch,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      totalResults: totalResults ?? this.totalResults,
      filterQuery: filterQuery,
      filteredBooks: filteredBooks,
      configuration: configuration ?? this.configuration,
    );
  }

  // Getters לנוחות גישה להגדרות (backward compatibility)
  int get distance => configuration.distance;
  bool get fuzzy => configuration.fuzzy;
  bool get isAdvancedSearchEnabled => configuration.isAdvancedSearchEnabled;
  List<String> get currentFacets => configuration.currentFacets;
  ResultsOrder get sortBy => configuration.sortBy;
  int get numResults => configuration.numResults;

  // Getters חדשים לרגקס
  bool get regexEnabled => configuration.regexEnabled;
  bool get caseSensitive => configuration.caseSensitive;
  bool get multiline => configuration.multiline;
  bool get dotAll => configuration.dotAll;
  bool get unicode => configuration.unicode;
}
