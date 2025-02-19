import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/bloc/library/library_event.dart';
import 'package:otzaria/bloc/library/library_state.dart';
import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/models/library.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final DataRepository _repository = DataRepository.instance;

  LibraryBloc() : super(LibraryState.initial()) {
    on<LoadLibrary>(_onLoadLibrary);
    on<RefreshLibrary>(_onRefreshLibrary);
    on<UpdateLibraryPath>(_onUpdateLibraryPath);
    on<UpdateHebrewBooksPath>(_onUpdateHebrewBooksPath);
    on<NavigateToCategory>(_onNavigateToCategory);
    on<NavigateUp>(_onNavigateUp);
    on<SearchBooks>(_onSearchBooks);
    on<ToggleExternalBooks>(_onToggleExternalBooks);
    on<SelectTopics>(_onSelectTopics);
  }

  Future<void> _onLoadLibrary(
    LoadLibrary event,
    Emitter<LibraryState> emit,
  ) async {
    Library library = await _repository.library;
    emit(state.copyWith(isLoading: true));
    try {
      emit(state.copyWith(
        library: library,
        currentCategory: library,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onRefreshLibrary(
    RefreshLibrary event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final libraryPath = Settings.getValue<String>('key-library-path');
      if (libraryPath != null) {
        FileSystemData.instance.libraryPath = libraryPath;
      }
      final library = await _repository.library;
      TantivyDataProvider.instance.reopenIndex();
      emit(state.copyWith(
        library: library,
        currentCategory: library,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onUpdateLibraryPath(
    UpdateLibraryPath event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await Settings.setValue<String>('key-library-path', event.path);
      FileSystemData.instance.libraryPath = event.path;
      DataRepository.instance.library = FileSystemData.instance.getLibrary();
      final library = await _repository.library;
      emit(state.copyWith(
        library: library,
        currentCategory: library,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onUpdateHebrewBooksPath(
    UpdateHebrewBooksPath event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await Settings.setValue<String>('key-hebrew-books-path', event.path);
      final library = await _repository.library;
      emit(state.copyWith(
        library: library,
        currentCategory: library,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  void _onNavigateToCategory(
    NavigateToCategory event,
    Emitter<LibraryState> emit,
  ) {
    emit(state.copyWith(
      currentCategory: event.category,
      searchQuery: null,
      searchResults: null,
      selectedTopics: null,
    ));
  }

  void _onNavigateUp(
    NavigateUp event,
    Emitter<LibraryState> emit,
  ) {
    if (state.currentCategory?.parent != null) {
      emit(state.copyWith(
        currentCategory: state.currentCategory!.parent!,
        searchQuery: null,
        searchResults: null,
        selectedTopics: null,
      ));
    }
  }

  Future<void> _onSearchBooks(
    SearchBooks event,
    Emitter<LibraryState> emit,
  ) async {
    if (event.query.length < 3) {
      emit(state.copyWith(
        searchQuery: event.query,
        searchResults: null,
        selectedTopics: event.topics,
      ));
      return;
    }

    try {
      final results = await _repository.findBooks(
        event.query,
        state.currentCategory,
        topics: event.topics,
        includeOtzar: state.showOtzarHachochma,
        includeHebrewBooks: state.showHebrewBooks,
      );

      emit(state.copyWith(
        searchQuery: event.query,
        searchResults: results,
        selectedTopics: event.topics,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        searchResults: null,
      ));
    }
  }

  void _onToggleExternalBooks(
    ToggleExternalBooks event,
    Emitter<LibraryState> emit,
  ) {
    if (event.source == 'otzar') {
      Settings.setValue<bool>('key-show-otzar-hachochma', event.enabled);
      emit(state.copyWith(showOtzarHachochma: event.enabled));
    } else if (event.source == 'hebrew') {
      Settings.setValue<bool>('key-show-hebrew-books', event.enabled);
      emit(state.copyWith(showHebrewBooks: event.enabled));
    }

    // Refresh search results if there's an active search
    if (state.searchQuery != null && state.searchQuery!.length >= 3) {
      add(SearchBooks(state.searchQuery!, topics: state.selectedTopics));
    }
  }

  void _onSelectTopics(
    SelectTopics event,
    Emitter<LibraryState> emit,
  ) {
    emit(state.copyWith(selectedTopics: event.topics));

    // Refresh search results if there's an active search
    if (state.searchQuery != null && state.searchQuery!.length >= 3) {
      add(SearchBooks(state.searchQuery!, topics: event.topics));
    }
  }
}
