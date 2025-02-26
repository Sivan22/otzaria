import 'package:equatable/equatable.dart';

abstract class FocusEvent extends Equatable {
  const FocusEvent();

  @override
  List<Object?> get props => [];
}

class RequestLibrarySearchFocus extends FocusEvent {
  final bool selectAll;

  const RequestLibrarySearchFocus({required this.selectAll});
}

class RequestFindRefSearchFocus extends FocusEvent {
  final bool selectAll;

  const RequestFindRefSearchFocus({required this.selectAll});
}

class ClearFocus extends FocusEvent {}
