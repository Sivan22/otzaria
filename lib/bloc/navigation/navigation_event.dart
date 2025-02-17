import 'package:equatable/equatable.dart';
import 'package:otzaria/bloc/navigation/navigation_state.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

class NavigateToScreen extends NavigationEvent {
  final Screen screen;

  const NavigateToScreen(this.screen);

  @override
  List<Object?> get props => [screen];
}

class CheckLibrary extends NavigationEvent {
  const CheckLibrary();
}

class OpenNewSearchTab extends NavigationEvent {
  const OpenNewSearchTab();
}

class UpdateLibraryStatus extends NavigationEvent {
  final bool isEmpty;

  const UpdateLibraryStatus(this.isEmpty);

  @override
  List<Object?> get props => [isEmpty];
}
