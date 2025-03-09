import 'package:equatable/equatable.dart';

abstract class IndexingState extends Equatable {
  final int? booksProcessed;
  final int? totalBooks;
  final List<String>? booksDone;

  const IndexingState({this.booksProcessed, this.totalBooks, this.booksDone});

  @override
  List<Object?> get props => [booksProcessed, totalBooks, booksDone];
}

class IndexingInitial extends IndexingState {}

class IndexingInProgress extends IndexingState {
  const IndexingInProgress(
      {super.booksProcessed, super.totalBooks, super.booksDone});
}

class IndexingComplete extends IndexingState {
  const IndexingComplete();
}

class IndexingError extends IndexingState {
  final String error;

  const IndexingError(this.error,
      {super.booksProcessed, super.totalBooks, super.booksDone});

  @override
  List<Object?> get props => [error, booksProcessed, totalBooks, booksDone];
}
