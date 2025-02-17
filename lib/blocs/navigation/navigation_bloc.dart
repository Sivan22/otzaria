import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/blocs/navigation/navigation_event.dart';
import 'package:otzaria/blocs/navigation/navigation_repository.dart';
import 'package:otzaria/blocs/navigation/navigation_state.dart';
import 'package:otzaria/blocs/tabs/tabs_bloc.dart';
import 'package:otzaria/blocs/tabs/tabs_event.dart';
import 'package:otzaria/models/tabs/searching_tab.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  final NavigationRepository _repository;

  final TabsBloc _tabsBloc;

  NavigationBloc({
    required NavigationRepository repository,
    required TabsBloc tabsBloc,
  })  : _repository = repository,
        _tabsBloc = tabsBloc,
        super(NavigationState.initial()) {
    on<NavigateToScreen>(_onNavigateToScreen);
    on<CheckLibrary>(_onCheckLibrary);
    on<OpenNewSearchTab>(_onOpenNewSearchTab);
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

  void _onOpenNewSearchTab(
    OpenNewSearchTab event,
    Emitter<NavigationState> emit,
  ) {
    _tabsBloc.add(AddTab(SearchingTab('חיפוש', '')));
    emit(state.copyWith(currentScreen: Screen.reading));
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
