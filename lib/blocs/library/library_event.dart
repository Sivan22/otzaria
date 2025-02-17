import 'package:equatable/equatable.dart';

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
