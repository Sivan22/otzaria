import 'package:equatable/equatable.dart';

abstract class RefIndexingState extends Equatable {
  final int? booksProcessed;
  final int? totalBooks;

  const RefIndexingState({this.booksProcessed, this.totalBooks});

  @override
  List<Object?> get props => [booksProcessed, totalBooks];
}

class RefIndexingInitial extends RefIndexingState {}

class RefIndexingInProgress extends RefIndexingState {
  const RefIndexingInProgress({super.booksProcessed, super.totalBooks});
}

class RefIndexingComplete extends RefIndexingState {}
