import 'package:equatable/equatable.dart';
import 'package:otzaria/library/models/library.dart';

abstract class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => [];
}

class LoadLibrary extends LibraryEvent {}

class RefreshLibrary extends LibraryEvent {}

class UpdateLibraryPath extends LibraryEvent {
  final String path;

  const UpdateLibraryPath(this.path);

  @override
  List<Object?> get props => [path];
}

class UpdateHebrewBooksPath extends LibraryEvent {
  final String path;

  const UpdateHebrewBooksPath(this.path);

  @override
  List<Object?> get props => [path];
}

class NavigateToCategory extends LibraryEvent {
  final Category category;

  const NavigateToCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class NavigateUp extends LibraryEvent {}

class SearchBooks extends LibraryEvent {
  final String query;
  final List<String>? topics;
  final bool? showOtzarHachochma;
  final bool? showHebrewBooks;

  const SearchBooks(this.query,
      {this.topics, this.showOtzarHachochma, this.showHebrewBooks});

  @override
  List<Object?> get props => [query, topics];
}

class SelectTopics extends LibraryEvent {
  final List<String> topics;

  const SelectTopics(this.topics);

  @override
  List<Object?> get props => [topics];
}
