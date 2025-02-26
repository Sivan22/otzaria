import 'package:equatable/equatable.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/library/models/library.dart';

class LibraryState extends Equatable {
  final Library? library;
  final bool isLoading;
  final String? error;
  final Category? currentCategory;
  final List<Book>? searchResults;
  final String? searchQuery;
  final List<String>? selectedTopics;

  const LibraryState({
    this.library,
    this.isLoading = false,
    this.error,
    this.currentCategory,
    this.searchResults,
    this.searchQuery,
    this.selectedTopics,
  });

  factory LibraryState.initial() {
    return const LibraryState(isLoading: true);
  }

  LibraryState copyWith({
    Library? library,
    bool? isLoading,
    String? error,
    Category? currentCategory,
    List<Book>? searchResults,
    String? searchQuery,
    List<String>? selectedTopics,
  }) {
    return LibraryState(
      library: library ?? this.library,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentCategory: currentCategory ?? this.currentCategory,
      searchResults: searchResults,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTopics: selectedTopics ?? this.selectedTopics,
    );
  }

  @override
  List<Object?> get props => [
        library,
        isLoading,
        error,
        currentCategory,
        searchResults,
        searchQuery,
        selectedTopics,
      ];
}
