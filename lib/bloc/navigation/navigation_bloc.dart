import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/bloc/navigation/navigation_event.dart';
import 'package:otzaria/bloc/navigation/navigation_repository.dart';
import 'package:otzaria/bloc/navigation/navigation_state.dart';
import 'package:otzaria/bloc/tabs/tabs_bloc.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  final NavigationRepository _repository;

  NavigationBloc({
    required NavigationRepository repository,
    required TabsBloc tabsBloc,
  })  : _repository = repository,
        super(NavigationState.initial()) {
    on<NavigateToScreen>(_onNavigateToScreen);
    on<CheckLibrary>(_onCheckLibrary);
    on<UpdateLibraryStatus>(_onUpdateLibraryStatus);
  }

  void _onNavigateToScreen(
    NavigateToScreen event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(currentScreen: event.screen));
  }

  void _onCheckLibrary(
    CheckLibrary event,
    Emitter<NavigationState> emit,
  ) {
    final isEmpty = _repository.checkLibraryIsEmpty();
    emit(state.copyWith(isLibraryEmpty: isEmpty));
  }

  void _onUpdateLibraryStatus(
    UpdateLibraryStatus event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(isLibraryEmpty: event.isEmpty));
  }

  Future<void> refreshLibrary() async {
    await _repository.refreshLibrary();
    add(const CheckLibrary());
  }
}
