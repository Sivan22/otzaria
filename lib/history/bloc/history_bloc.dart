import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/bookmarks/models/bookmark.dart';
import 'package:otzaria/history/history_repository.dart';
import 'package:otzaria/pdf_book/bloc/pdf_book_state.dart';
import 'package:otzaria/tabs/models/pdf_tab.dart';
import 'package:otzaria/tabs/models/searching_tab.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/utils/ref_helper.dart';

// Events
abstract class HistoryEvent {}

class LoadHistory extends HistoryEvent {}

class AddHistory extends HistoryEvent {
  final OpenedTab tab;
  AddHistory(this.tab);
}

class RemoveHistory extends HistoryEvent {
  final int index;
  RemoveHistory(this.index);
}

class ClearHistory extends HistoryEvent {}

// States
abstract class HistoryState {
  final List<Bookmark> history;
  HistoryState(this.history);
}

class HistoryInitial extends HistoryState {
  HistoryInitial() : super([]);
}

class HistoryLoading extends HistoryState {
  HistoryLoading(super.history);
}

class HistoryLoaded extends HistoryState {
  HistoryLoaded(super.history);
}

class HistoryError extends HistoryState {
  final String message;
  HistoryError(super.history, this.message);
}

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final HistoryRepository _repository;

  HistoryBloc(this._repository) : super(HistoryInitial()) {
    on<LoadHistory>(_onLoadHistory);
    on<AddHistory>(_onAddHistory);
    on<RemoveHistory>(_onRemoveHistory);
    on<ClearHistory>(_onClearHistory);
  }

  Future<void> _onLoadHistory(
      LoadHistory event, Emitter<HistoryState> emit) async {
    try {
      emit(HistoryLoading(state.history));
      final history = await _repository.loadHistory();
      emit(HistoryLoaded(history));
    } catch (e) {
      emit(HistoryError(state.history, e.toString()));
    }
  }

  Future<void> _onAddHistory(
      AddHistory event, Emitter<HistoryState> emit) async {
    Bookmark bookmark;
    try {
      if (event.tab is SearchingTab) return;
      if (event.tab is TextBookTab) {
        final tab = event.tab as TextBookTab;
        bookmark = Bookmark(
          ref: await refFromIndex(tab.bloc.state.visibleIndices?.first ?? 0,
              tab.book.tableOfContents),
          book: tab.book,
          index: tab.bloc.state.visibleIndices?.first ?? 0,
          commentatorsToShow: tab.bloc.state.activeCommentators,
        );
      } else {
        final tab = event.tab as PdfBookTab;
        final state = tab.bloc.state as PdfBookLoaded;
        bookmark = Bookmark(
          ref: '${tab.title} עמוד ${state.controller.pageNumber ?? 1}',
          book: tab.book,
          index: state.controller.pageNumber ?? 1,
        );
      }
      final updatedHistory = [...state.history, bookmark];
      await _repository.saveHistory(updatedHistory);
      emit(HistoryLoaded(updatedHistory));
    } catch (e) {
      emit(HistoryError(state.history, e.toString()));
    }
  }

  Future<void> _onRemoveHistory(
      RemoveHistory event, Emitter<HistoryState> emit) async {
    try {
      await _repository.removeHistoryItem(event.index);
      final history = await _repository.loadHistory();
      emit(HistoryLoaded(history));
    } catch (e) {
      emit(HistoryError(state.history, e.toString()));
    }
  }

  Future<void> _onClearHistory(
      ClearHistory event, Emitter<HistoryState> emit) async {
    try {
      await _repository.clearHistory();
      emit(HistoryLoaded([]));
    } catch (e) {
      emit(HistoryError(state.history, e.toString()));
    }
  }
}
