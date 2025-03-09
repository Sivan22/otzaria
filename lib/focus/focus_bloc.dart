import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/focus/focus_event.dart';
import 'package:otzaria/focus/focus_state.dart';

class FocusBloc extends Bloc<FocusEvent, FocusState> {
  FocusBloc() : super(FocusState()) {
    on<RequestLibrarySearchFocus>(_onRequestLibrarySearchFocus);
    on<RequestFindRefSearchFocus>(_onRequestFindRefSearchFocus);
    on<ClearFocus>(_onClearFocus);
  }

  void _onRequestLibrarySearchFocus(
      RequestLibrarySearchFocus event, Emitter<FocusState> emit) {
    state.librarySearchFocusNode.requestFocus();
    if (event.selectAll) {
      state.librarySearchController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: state.librarySearchController.text.length);
    }
    emit(state.copyWith(focusTarget: FocusTarget.librarySearch));
  }

  void _onRequestFindRefSearchFocus(
      RequestFindRefSearchFocus event, Emitter<FocusState> emit) {
    state.findRefSearchFocusNode.requestFocus();
    if (event.selectAll) {
      state.findRefSearchController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: state.findRefSearchController.text.length);
    }
    emit(state.copyWith(focusTarget: FocusTarget.findRefSearch));
  }

  void _onClearFocus(ClearFocus event, Emitter<FocusState> emit) {
    emit(state.copyWith(focusTarget: FocusTarget.none));
  }
}
