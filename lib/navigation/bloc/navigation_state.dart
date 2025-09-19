import 'package:equatable/equatable.dart';

enum Screen { library, find, reading, search, more, settings, about }

class NavigationState extends Equatable {
  final Screen currentScreen;
  final bool isLibraryEmpty;

  const NavigationState({
    required this.currentScreen,
    this.isLibraryEmpty = false,
  });

  factory NavigationState.initial(bool hasTabs) {
    return NavigationState(
      currentScreen: hasTabs ? Screen.reading : Screen.library,
      isLibraryEmpty: false,
    );
  }

  NavigationState copyWith({
    Screen? currentScreen,
    bool? isLibraryEmpty,
  }) {
    return NavigationState(
      currentScreen: currentScreen ?? this.currentScreen,
      isLibraryEmpty: isLibraryEmpty ?? this.isLibraryEmpty,
    );
  }

  @override
  List<Object?> get props => [currentScreen, isLibraryEmpty];
}
