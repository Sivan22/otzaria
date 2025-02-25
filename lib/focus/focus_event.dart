import 'package:equatable/equatable.dart';

abstract class FocusEvent extends Equatable {
  const FocusEvent();

  @override
  List<Object?> get props => [];
}

class RequestLibrarySearchFocus extends FocusEvent {}

class RequestFindRefSearchFocus extends FocusEvent {}

class ClearFocus extends FocusEvent {}
