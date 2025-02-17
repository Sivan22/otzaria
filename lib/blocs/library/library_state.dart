import 'package:equatable/equatable.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/library.dart';

class LibraryState extends Equatable {
  final Library? library;
  final bool isLoading;
  final String? error;
  final Category? currentCategory;
  final List<Book>? searchResults;
  final String? searchQuery;
  final List<String>? selectedTopics;
  final bool showOtzarHachochma;
  final bool showHebrewBooks;

  const LibraryState({
    this.library,
    this.isLoading = false,
    this.error,
    this.currentCategory,
    this.searchResults,
    this.searchQuery,
    this.selectedTopics,
    this.showOtzarHachochma = false,
    this.showHebrewBooks = false,
  });

  factory LibraryState.initial() {
    return const LibraryState();
  }

  LibraryState copyWith({
    Library? library,
    bool? isLoading,
    String? error,
    Category? currentCategory,
    List<Book>? searchResults,
    String? searchQuery,
    List<String>? selectedTopics,
    bool? showOtzarHachochma,
    bool? showHebrewBooks,
  }) {
    return LibraryState(
      library: library ?? this.library,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentCategory: currentCategory ?? this.currentCategory,
      searchResults: searchResults,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTopics: selectedTopics ?? this.selectedTopics,
      showOtzarHachochma: showOtzarHachochma ?? this.showOtzarHachochma,
      showHebrewBooks: showHebrewBooks ?? this.showHebrewBooks,
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
        showOtzarHachochma,
        showHebrewBooks,
      ];
}
