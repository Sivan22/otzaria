import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/blocs/library/library_event.dart';
import 'package:otzaria/blocs/library/library_state.dart';
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
  }

  Future<void> _onLoadLibrary(
    LoadLibrary event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final Library library = await _repository.getLibrary();
      emit(state.copyWith(
        library: library,
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
      final Library library = await _repository.getLibrary();
      TantivyDataProvider.instance.reopenIndex();
      emit(state.copyWith(
        library: library,
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
      final Library library = await _repository.getLibrary();
      emit(state.copyWith(
        library: library,
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
      final Library library = await _repository.getLibrary();
      emit(state.copyWith(
        library: library,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }
}
