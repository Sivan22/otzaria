import 'package:otzaria/models/books.dart';
import 'package:search_engine/search_engine.dart';

class SearchState {
  final String? filterQuery;
  final List<Book>? filteredBooks;
  final int distance;
  final bool fuzzy;
  final List<SearchResult> results;
  final Set<Book> booksToSearch;
  final List<String> currentFacets;
  final ResultsOrder sortBy;
  final int numResults;
  final bool isLoading;
  final String searchQuery;
  final int totalResults;

  const SearchState({
    this.distance = 2,
    this.fuzzy = false,
    this.results = const [],
    this.booksToSearch = const {},
    this.currentFacets = const ["/"],
    this.sortBy = ResultsOrder.catalogue,
    this.numResults = 100,
    this.isLoading = false,
    this.searchQuery = '',
    this.totalResults = 0,
    this.filterQuery,
    this.filteredBooks,
  });

  SearchState copyWith({
    int? distance,
    bool? fuzzy,
    List<SearchResult>? results,
    Set<Book>? booksToSearch,
    List<String>? currentFacets,
    ResultsOrder? sortBy,
    int? numResults,
    bool? isLoading,
    String? searchQuery,
    int? totalResults,
    String? filterQuery,
    List<Book>? filteredBooks,
  }) {
    return SearchState(
        distance: distance ?? this.distance,
        fuzzy: fuzzy ?? this.fuzzy,
        results: results ?? this.results,
        booksToSearch: booksToSearch ?? this.booksToSearch,
        currentFacets: currentFacets ?? this.currentFacets,
        sortBy: sortBy ?? this.sortBy,
        numResults: numResults ?? this.numResults,
        isLoading: isLoading ?? this.isLoading,
        searchQuery: searchQuery ?? this.searchQuery,
        totalResults: totalResults ?? this.totalResults,
        filterQuery: filterQuery,
        filteredBooks: filteredBooks);
  }
}
