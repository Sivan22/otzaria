import 'package:otzaria/models/books.dart';
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
  UpdateSearchQuery(this.query);
}

class UpdateDistance extends SearchEvent {
  final int distance;
  UpdateDistance(this.distance);
}

class ToggleFuzzy extends SearchEvent {}

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
