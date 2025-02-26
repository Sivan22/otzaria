import 'package:otzaria/models/books.dart'; // Import Book model
import 'package:equatable/equatable.dart';
import 'package:otzaria/models/isar_collections/ref.dart';

abstract class FindRefState extends Equatable {
  const FindRefState();

  @override
  List<Object> get props => [];
}

class FindRefInitial extends FindRefState {}

class FindRefLoading extends FindRefState {}

class FindRefSuccess extends FindRefState {
  final List<Ref> refs;
  const FindRefSuccess(this.refs);

  @override
  List<Object> get props => [refs];
}

class FindRefError extends FindRefState {
  final String message;
  const FindRefError(this.message);

  @override
  List<Object> get props => [message];
}

class FindRefIndexingStatus extends FindRefState {
  final int? booksProcessed;
  final int? totalBooks;

  const FindRefIndexingStatus({this.booksProcessed, this.totalBooks});

  @override
  List<Object> get props => [booksProcessed ?? 0, totalBooks ?? 0];
}

class FindRefBookOpening extends FindRefState {
  // Add BookOpening state
  final Book book;
  final int index;

  const FindRefBookOpening({required this.book, required this.index});

  @override
  List<Object> get props => [book, index];
}
