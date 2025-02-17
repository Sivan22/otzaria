import 'package:equatable/equatable.dart';
import 'package:otzaria/models/library.dart';

class LibraryState extends Equatable {
  final Library? library;
  final bool isLoading;
  final String? error;

  const LibraryState({
    this.library,
    this.isLoading = false,
    this.error,
  });

  factory LibraryState.initial() {
    return const LibraryState();
  }

  LibraryState copyWith({
    Library? library,
    bool? isLoading,
    String? error,
  }) {
    return LibraryState(
      library: library ?? this.library,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [library, isLoading, error];
}
