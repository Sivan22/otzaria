import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

enum FocusTarget { none, librarySearch, findRefSearch }

class FocusState extends Equatable {
  final FocusTarget focusTarget;
  final TextEditingController librarySearchController = TextEditingController();
  final TextEditingController findRefSearchController = TextEditingController();

  FocusState({this.focusTarget = FocusTarget.none});

  FocusState copyWith({
    FocusTarget? focusTarget,
  }) {
    return FocusState(
      focusTarget: focusTarget ?? this.focusTarget,
    );
  }

  @override
  List<Object?> get props => [focusTarget];
}
