import 'package:otzaria/models/books.dart';
import 'package:otzaria/search/models/search_configuration.dart';
import 'package:search_engine/search_engine.dart';

abstract class SearchEvent {
  const SearchEvent();
}

class UpdateFilterQuery extends SearchEvent {
  final String query;
  UpdateFilterQuery(this.query);
}

class ClearFilter extends SearchEvent {
  ClearFilter();
}

class UpdateSearchQuery extends SearchEvent {
  final String query;
  final Map<String, String>? customSpacing;
  final Map<int, List<String>>? alternativeWords;
  final Map<String, Map<String, bool>>? searchOptions;
  UpdateSearchQuery(this.query,
      {this.customSpacing, this.alternativeWords, this.searchOptions});
}

class UpdateDistance extends SearchEvent {
  final int distance;
  UpdateDistance(this.distance);
}

class ToggleSearchMode extends SearchEvent {}

class SetSearchMode extends SearchEvent {
  final SearchMode searchMode;
  SetSearchMode(this.searchMode);
}

class UpdateBooksToSearch extends SearchEvent {
  final Set<Book> books;
  UpdateBooksToSearch(this.books);
}

class AddFacet extends SearchEvent {
  final String facet;
  AddFacet(this.facet);
}

class RemoveFacet extends SearchEvent {
  final String facet;
  RemoveFacet(this.facet);
}

class SetFacet extends SearchEvent {
  final String facet;
  SetFacet(this.facet);
}

class UpdateSortOrder extends SearchEvent {
  final ResultsOrder order;
  UpdateSortOrder(this.order);
}

class UpdateNumResults extends SearchEvent {
  final int numResults;
  UpdateNumResults(this.numResults);
}

class ResetSearch extends SearchEvent {}

// Events חדשים להגדרות רגקס
class ToggleRegex extends SearchEvent {}

class ToggleCaseSensitive extends SearchEvent {}

class ToggleMultiline extends SearchEvent {}

class ToggleDotAll extends SearchEvent {}

class ToggleUnicode extends SearchEvent {}

// Event פנימי לעדכון facet counts
class UpdateFacetCounts extends SearchEvent {
  final Map<String, int> facetCounts;
  UpdateFacetCounts(this.facetCounts);
}
