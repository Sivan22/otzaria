import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/bookmarks/models/bookmark.dart';
import 'package:otzaria/history/bloc/history_event.dart';
import 'package:otzaria/history/bloc/history_state.dart';
import 'package:otzaria/history/history_repository.dart';
import 'package:otzaria/pdf_book/bloc/pdf_book_state.dart';
import 'package:otzaria/tabs/models/pdf_tab.dart';
import 'package:otzaria/tabs/models/searching_tab.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/utils/ref_helper.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final HistoryRepository _repository;

  HistoryBloc(this._repository) : super(HistoryInitial()) {
    on<LoadHistory>(_onLoadHistory);
    on<AddHistory>(_onAddHistory);
    on<RemoveHistory>(_onRemoveHistory);
    on<ClearHistory>(_onClearHistory);

    add(LoadHistory());
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
    Bookmark? bookmark;
    try {
      if (event.tab is SearchingTab) return;
      if (event.tab is TextBookTab) {
        final tab = event.tab as TextBookTab;
        final bloc = tab.bloc;
        if (bloc.state is TextBookLoaded) {
          final state = bloc.state as TextBookLoaded;
          bookmark = Bookmark(
            ref: await refFromIndex(state.visibleIndices.first,
                Future.value(state.tableOfContents)),
            book: state.book,
            index: state.visibleIndices.first,
            commentatorsToShow: state.activeCommentators,
          );
        }
      } else {
        final tab = event.tab as PdfBookTab;
        final state = tab.bloc.state;
        bookmark = Bookmark(
          ref: '${tab.title} עמוד ${state.controller?.pageNumber ?? 1}',
          book: tab.book,
          index: state.controller?.pageNumber ?? 1,
        );
      }
      if (state.history.any((b) => b.ref == bookmark?.ref)) return;
      if (bookmark == null) return;
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
