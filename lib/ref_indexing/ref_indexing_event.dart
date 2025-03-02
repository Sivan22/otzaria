import 'package:equatable/equatable.dart';

abstract class RefIndexingEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class StartRefIndexing extends RefIndexingEvent {}

class UpdateProgress extends RefIndexingEvent {
  final int processed;
  final int total;

  UpdateProgress({required this.processed, required this.total});

  @override
  List<Object> get props => [processed, total];
}
