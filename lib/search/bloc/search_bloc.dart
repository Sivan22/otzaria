import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/search/bloc/search_event.dart';
import 'package:otzaria/search/bloc/search_state.dart';
import 'package:otzaria/search/models/search_configuration.dart';
import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/search/search_repository.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository _repository = SearchRepository();

  SearchBloc() : super(const SearchState()) {
    on<UpdateSearchQuery>(_onUpdateSearchQuery);
    on<UpdateDistance>(_onUpdateDistance);
    on<ToggleSearchMode>(_onToggleSearchMode);
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
    on<UpdateFacetCounts>(_onUpdateFacetCounts);
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

    // Clear global cache for new search
    TantivyDataProvider.clearGlobalCache();

    emit(state.copyWith(
      searchQuery: event.query,
      isLoading: true,
      facetCounts: {}, // Clear facet counts for new search
    ));

    final booksToSearch = state.booksToSearch.map((e) => e.title).toList();

    try {
      final totalResults = await TantivyDataProvider.instance.countTexts(
        event.query.replaceAll('"', '\\"'),
        booksToSearch,
        state.currentFacets,
        fuzzy: state.fuzzy,
        distance: state.distance,
        customSpacing: event.customSpacing,
        alternativeWords: event.alternativeWords,
        searchOptions: event.searchOptions,
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
        alternativeWords: event.alternativeWords,
        searchOptions: event.searchOptions,
      );

      emit(state.copyWith(
        results: results,
        totalResults: totalResults,
        isLoading: false,
        facetCounts: {}, // Start with empty facet counts, will be filled by individual requests
      ));

      // Prefetch disabled - too slow and causes duplicates
      // _prefetchCommonFacetCounts(event.query, event.customSpacing,
      //     event.alternativeWords, event.searchOptions);
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
      facetCounts: {}, // ניקוי ספירות הפאסטים כשמנקים את הסינון
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

  void _onToggleSearchMode(
    ToggleSearchMode event,
    Emitter<SearchState> emit,
  ) {
    // מעבר בין שלושת המצבים: מתקדם -> מדוייק -> מקורב -> מתקדם
    SearchMode newMode;
    switch (state.configuration.searchMode) {
      case SearchMode.advanced:
        newMode = SearchMode.exact;
        break;
      case SearchMode.exact:
        newMode = SearchMode.fuzzy;
        break;
      case SearchMode.fuzzy:
        newMode = SearchMode.advanced;
        break;
    }

    final newConfig = state.configuration.copyWith(searchMode: newMode);
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

  Future<int> countForFacet(
    String facet, {
    Map<String, String>? customSpacing,
    Map<int, List<String>>? alternativeWords,
    Map<String, Map<String, bool>>? searchOptions,
  }) async {
    if (state.searchQuery.isEmpty) {
      return 0;
    }

    // קודם נבדוק אם יש לנו את הספירה ב-state
    if (state.facetCounts.containsKey(facet)) {
      return state.facetCounts[facet]!;
    }

    // אם אין, נבצע ספירה ישירה (fallback)
    print('🔢 Counting texts for facet: $facet');
    print('🔢 Query: ${state.searchQuery}');
    print(
        '🔢 Books to search: ${state.booksToSearch.map((e) => e.title).toList()}');
    final result = await TantivyDataProvider.instance.countTexts(
      state.searchQuery.replaceAll('"', '\\"'),
      state.booksToSearch.map((e) => e.title).toList(),
      [facet],
      fuzzy: state.fuzzy,
      distance: state.distance,
      customSpacing: customSpacing,
      alternativeWords: alternativeWords,
      searchOptions: searchOptions,
    );
    print('🔢 Count result for $facet: $result');
    return result;
  }

  /// ספירה מקבצת של תוצאות עבור מספר facets בבת אחת - לשיפור ביצועים
  Future<Map<String, int>> countForMultipleFacets(
    List<String> facets, {
    Map<String, String>? customSpacing,
    Map<int, List<String>>? alternativeWords,
    Map<String, Map<String, bool>>? searchOptions,
  }) async {
    if (state.searchQuery.isEmpty) {
      return {for (final facet in facets) facet: 0};
    }

    // קודם נבדוק כמה facets יש לנו כבר ב-state
    final results = <String, int>{};
    final missingFacets = <String>[];

    for (final facet in facets) {
      if (state.facetCounts.containsKey(facet)) {
        results[facet] = state.facetCounts[facet]!;
      } else {
        missingFacets.add(facet);
      }
    }

    // אם יש facets חסרים, נבצע ספירה רק עבורם
    if (missingFacets.isNotEmpty) {
      final missingResults =
          await TantivyDataProvider.instance.countTextsForMultipleFacets(
        state.searchQuery.replaceAll('"', '\\"'),
        state.booksToSearch.map((e) => e.title).toList(),
        missingFacets,
        fuzzy: state.fuzzy,
        distance: state.distance,
        customSpacing: customSpacing,
        alternativeWords: alternativeWords,
        searchOptions: searchOptions,
      );
      results.addAll(missingResults);
    }

    return results;
  }

  /// מחזיר ספירה סינכרונית מה-state (אם קיימת)
  int getFacetCountFromState(String facet) {
    final result = state.facetCounts[facet] ?? 0;
    print(
        '🔍 getFacetCountFromState($facet) = $result, cache has ${state.facetCounts.length} entries');
    return result;
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

  void _onUpdateFacetCounts(
    UpdateFacetCounts event,
    Emitter<SearchState> emit,
  ) {
    print(
        '📝 Updating facet counts: ${event.facetCounts.entries.where((e) => e.value > 0).map((e) => '${e.key}: ${e.value}').join(', ')}');
    final newFacetCounts = event.facetCounts.isEmpty
        ? <String, int>{} // אם מעבירים מפה ריקה, מנקים הכל
        : {...state.facetCounts, ...event.facetCounts};
    emit(state.copyWith(
      facetCounts: newFacetCounts,
    ));
    print('📊 Total facets in state: ${newFacetCounts.length}');
    if (newFacetCounts.isNotEmpty) {
      print(
          '📋 All cached facets: ${newFacetCounts.keys.take(10).join(', ')}...');
    } else {
      print('🧹 Facet counts cleared');
    }
  }
}
