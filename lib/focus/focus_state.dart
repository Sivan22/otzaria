import 'package:equatable/equatable.dart';

enum FocusTarget { none, librarySearch, findRefSearch }

class FocusState extends Equatable {
  final FocusTarget focusTarget;

  const FocusState({this.focusTarget = FocusTarget.none});

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
