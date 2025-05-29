import 'package:equatable/equatable.dart';
import 'package:otzaria/library/models/library.dart';

abstract class IndexingEvent extends Equatable {
  const IndexingEvent();

  @override
  List<Object?> get props => [];
}

class StartIndexing extends IndexingEvent {
  final Library library;

  const StartIndexing(this.library);

  @override
  List<Object?> get props => [library];
}

class ClearIndex extends IndexingEvent {}

class CancelIndexing extends IndexingEvent {}

class UpdateIndexingProgress extends IndexingEvent {
  final int processed;
  final int total;

  const UpdateIndexingProgress({
    required this.processed,
    required this.total,
  });

  @override
  List<Object?> get props => [
        processed,
        total,
      ];
}
