import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/search/bloc/search_event.dart';
import 'package:otzaria/search/bloc/search_state.dart';
import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/search/search_repository.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository _repository = SearchRepository();

  SearchBloc() : super(const SearchState()) {
    on<UpdateSearchQuery>(_onUpdateSearchQuery);
    on<UpdateDistance>(_onUpdateDistance);
    on<ToggleFuzzy>(_onToggleFuzzy);
    on<UpdateBooksToSearch>(_onUpdateBooksToSearch);
    on<AddFacet>(_onAddFacet);
    on<RemoveFacet>(_onRemoveFacet);
    on<SetFacet>(_onSetFacet);
    on<UpdateSortOrder>(_onUpdateSortOrder);
    on<UpdateNumResults>(_onUpdateNumResults);
    on<ResetSearch>(_onResetSearch);
    on<UpdateFilterQuery>(_onUpdateFilterQuery);
    on<ClearFilter>(_onClearFilter);

    // Handlers חדשים לרגקס
    on<ToggleRegex>(_onToggleRegex);
    on<ToggleCaseSensitive>(_onToggleCaseSensitive);
    on<ToggleMultiline>(_onToggleMultiline);
    on<ToggleDotAll>(_onToggleDotAll);
    on<ToggleUnicode>(_onToggleUnicode);
  }
  Future<void> _onUpdateSearchQuery(
    UpdateSearchQuery event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(state.copyWith(
        searchQuery: event.query,
        results: [],
        totalResults: 0,
      ));
      return;
    }

    emit(state.copyWith(
      searchQuery: event.query,
      isLoading: true,
    ));

    final booksToSearch = state.booksToSearch.map((e) => e.title).toList();

    try {
      final totalResults = await TantivyDataProvider.instance.countTexts(
        event.query.replaceAll('"', '\\"'),
        booksToSearch,
        state.currentFacets,
        fuzzy: state.fuzzy,
        distance: state.distance,
      );

      // If no results with current facets, try root facet
      if (totalResults == 0 && !state.currentFacets.contains("/")) {
        add(AddFacet("/"));
        return;
      }

      final results = await _repository.searchTexts(
        event.query.replaceAll('"', '\\"'),
        state.currentFacets,
        state.numResults,
        fuzzy: state.fuzzy,
        distance: state.distance,
        order: state.sortBy,
        customSpacing: event.customSpacing,
      );

      emit(state.copyWith(
        results: results,
        totalResults: totalResults,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        results: [],
        totalResults: 0,
        isLoading: false,
      ));
    }
  }

  void _onUpdateFilterQuery(
    UpdateFilterQuery event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.length < 3) {
      emit(state.copyWith(
        filterQuery: event.query,
        filteredBooks: null,
      ));
      return;
    }

    try {
      final results = await DataRepository.instance
          .findBooks(event.query, null, sortByRatio: false);

      emit(state.copyWith(
        filterQuery: event.query,
        filteredBooks: results,
      ));
    } catch (e) {
      emit(state.copyWith(
        filterQuery: event.query,
        filteredBooks: null,
      ));
    }
  }

  void _onClearFilter(
    ClearFilter event,
    Emitter<SearchState> emit,
  ) {
    emit(state.copyWith(
      filterQuery: null,
      filteredBooks: null,
    ));
  }

  void _onUpdateDistance(
    UpdateDistance event,
    Emitter<SearchState> emit,
  ) {
    final newConfig = state.configuration.copyWith(distance: event.distance);
    emit(state.copyWith(configuration: newConfig));
    add(UpdateSearchQuery(state.searchQuery));
  }

  void _onToggleFuzzy(
    ToggleFuzzy event,
    Emitter<SearchState> emit,
  ) {
    final newConfig = state.configuration.copyWith(fuzzy: !state.fuzzy);
    emit(state.copyWith(configuration: newConfig));
    add(UpdateSearchQuery(state.searchQuery));
  }

  void _onUpdateBooksToSearch(
    UpdateBooksToSearch event,
    Emitter<SearchState> emit,
  ) {
    emit(state.copyWith(booksToSearch: event.books));
    add(UpdateSearchQuery(state.searchQuery));
  }

  void _onAddFacet(
    AddFacet event,
    Emitter<SearchState> emit,
  ) {
    final newFacets = List<String>.from(state.currentFacets);
    if (!newFacets.contains(event.facet)) {
      newFacets.add(event.facet);
      final newConfig = state.configuration.copyWith(currentFacets: newFacets);
      emit(state.copyWith(configuration: newConfig));
      add(UpdateSearchQuery(state.searchQuery));
    }
  }

  void _onRemoveFacet(
    RemoveFacet event,
    Emitter<SearchState> emit,
  ) {
    final newFacets = List<String>.from(state.currentFacets);
    if (newFacets.contains(event.facet)) {
      newFacets.remove(event.facet);
      final newConfig = state.configuration.copyWith(currentFacets: newFacets);
      emit(state.copyWith(configuration: newConfig));
      add(UpdateSearchQuery(state.searchQuery));
    }
  }

  void _onSetFacet(
    SetFacet event,
    Emitter<SearchState> emit,
  ) {
    final newConfig =
        state.configuration.copyWith(currentFacets: [event.facet]);
    emit(state.copyWith(configuration: newConfig));
    add(UpdateSearchQuery(state.searchQuery));
  }

  void _onUpdateSortOrder(
    UpdateSortOrder event,
    Emitter<SearchState> emit,
  ) {
    final newConfig = state.configuration.copyWith(sortBy: event.order);
    emit(state.copyWith(configuration: newConfig));
    add(UpdateSearchQuery(state.searchQuery));
  }

  void _onUpdateNumResults(
    UpdateNumResults event,
    Emitter<SearchState> emit,
  ) {
    final newConfig =
        state.configuration.copyWith(numResults: event.numResults);
    emit(state.copyWith(configuration: newConfig));
    add(UpdateSearchQuery(state.searchQuery));
  }

  void _onResetSearch(
    ResetSearch event,
    Emitter<SearchState> emit,
  ) {
    emit(const SearchState());
  }

  Future<int> countForFacet(String facet) async {
    if (state.searchQuery.isEmpty) {
      return 0;
    }
    return TantivyDataProvider.instance.countTexts(
      state.searchQuery.replaceAll('"', '\\"'),
      state.booksToSearch.map((e) => e.title).toList(),
      [facet],
      fuzzy: state.fuzzy,
      distance: state.distance,
    );
  }

  // Handlers חדשים לרגקס
  void _onToggleRegex(
    ToggleRegex event,
    Emitter<SearchState> emit,
  ) {
    final newConfig =
        state.configuration.copyWith(regexEnabled: !state.regexEnabled);
    emit(state.copyWith(configuration: newConfig));
    add(UpdateSearchQuery(state.searchQuery));
  }

  void _onToggleCaseSensitive(
    ToggleCaseSensitive event,
    Emitter<SearchState> emit,
  ) {
    final newConfig =
        state.configuration.copyWith(caseSensitive: !state.caseSensitive);
    emit(state.copyWith(configuration: newConfig));
    add(UpdateSearchQuery(state.searchQuery));
  }

  void _onToggleMultiline(
    ToggleMultiline event,
    Emitter<SearchState> emit,
  ) {
    final newConfig = state.configuration.copyWith(multiline: !state.multiline);
    emit(state.copyWith(configuration: newConfig));
    add(UpdateSearchQuery(state.searchQuery));
  }

  void _onToggleDotAll(
    ToggleDotAll event,
    Emitter<SearchState> emit,
  ) {
    final newConfig = state.configuration.copyWith(dotAll: !state.dotAll);
    emit(state.copyWith(configuration: newConfig));
    add(UpdateSearchQuery(state.searchQuery));
  }

  void _onToggleUnicode(
    ToggleUnicode event,
    Emitter<SearchState> emit,
  ) {
    final newConfig = state.configuration.copyWith(unicode: !state.unicode);
    emit(state.copyWith(configuration: newConfig));
    add(UpdateSearchQuery(state.searchQuery));
  }
}
