import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/focus/focus_event.dart';
import 'package:otzaria/focus/focus_state.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_state.dart';

class FocusBloc extends Bloc<FocusEvent, FocusState> {
  final NavigationBloc _navigationBloc;

  FocusBloc({required NavigationBloc navigationBloc})
      : _navigationBloc = navigationBloc,
        super(const FocusState()) {
    on<RequestLibrarySearchFocus>(_onRequestLibrarySearchFocus);
    on<RequestFindRefSearchFocus>(_onRequestFindRefSearchFocus);
    on<ClearFocus>(_onClearFocus);

    // Listen to navigation changes
    _navigationBloc.stream.listen((navigationState) {
      if (navigationState.currentScreen == Screen.library) {
        add(RequestLibrarySearchFocus());
      } else if (navigationState.currentScreen == Screen.find) {
        add(RequestFindRefSearchFocus());
      } else {
        add(ClearFocus());
      }
    });
  }

  void _onRequestLibrarySearchFocus(
      RequestLibrarySearchFocus event, Emitter<FocusState> emit) {
    emit(state.copyWith(focusTarget: FocusTarget.librarySearch));
  }

  void _onRequestFindRefSearchFocus(
      RequestFindRefSearchFocus event, Emitter<FocusState> emit) {
    emit(state.copyWith(focusTarget: FocusTarget.findRefSearch));
  }

  void _onClearFocus(ClearFocus event, Emitter<FocusState> emit) {
    emit(state.copyWith(focusTarget: FocusTarget.none));
  }
}
