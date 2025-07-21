import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/bookmarks/models/bookmark.dart';
import 'package:otzaria/history/bloc/history_event.dart';
import 'package:otzaria/history/bloc/history_state.dart';
import 'package:otzaria/history/history_repository.dart';
import 'package:otzaria/tabs/models/pdf_tab.dart';
import 'package:otzaria/tabs/models/searching_tab.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/utils/ref_helper.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final HistoryRepository _repository;
  Timer? _debounce;
  final Map<String, Bookmark> _pendingSnapshots = {};

  HistoryBloc(this._repository) : super(HistoryInitial()) {
    on<LoadHistory>(_onLoadHistory);
    on<AddHistory>(_onAddHistory);
    on<BulkAddHistory>(_onBulkAddHistory);
    on<RemoveHistory>(_onRemoveHistory);
    on<ClearHistory>(_onClearHistory);
    on<CaptureStateForHistory>(_onCaptureStateForHistory);
    on<FlushHistory>(_onFlushHistory);

    add(LoadHistory());
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    if (_pendingSnapshots.isNotEmpty) {
      final snapshots = _pendingSnapshots.values.toList();
      _pendingSnapshots.clear();
      _saveSnapshotsToHistory(snapshots);
    }
    return super.close();
  }

  Future<void> _saveSnapshotsToHistory(List<Bookmark> snapshots) async {
    final updatedHistory = List<Bookmark>.from(state.history);

    for (final bookmark in snapshots) {
      final existingIndex =
          updatedHistory.indexWhere((b) => b.historyKey == bookmark.historyKey);
      if (existingIndex >= 0) {
        updatedHistory.removeAt(existingIndex);
      }
      updatedHistory.insert(0, bookmark);
    }

    const maxHistorySize = 200;
    if (updatedHistory.length > maxHistorySize) {
      updatedHistory.removeRange(maxHistorySize, updatedHistory.length);
    }

    await _repository.saveHistory(updatedHistory);
    if (!isClosed) {
      emit(HistoryLoaded(updatedHistory));
    }
  }

  Future<Bookmark?> _bookmarkFromTab(OpenedTab tab) async {
    if (tab is SearchingTab) return null;

    if (tab is TextBookTab) {
      final blocState = tab.bloc.state;
      if (blocState is TextBookLoaded && blocState.visibleIndices.isNotEmpty) {
        final index = blocState.visibleIndices.first;
        final ref =
            await refFromIndex(index, Future.value(blocState.tableOfContents));
        return Bookmark(
          ref: ref,
          book: blocState.book,
          index: index,
          commentatorsToShow: blocState.activeCommentators,
        );
      }
    } else if (tab is PdfBookTab) {
      if (!tab.pdfViewerController.isReady) return null;
      final page = tab.pdfViewerController.pageNumber ?? 1;
      return Bookmark(
        ref: '${tab.title} עמוד $page',
        book: tab.book,
        index: page,
      );
    }
    return null;
  }

  Future<void> _onCaptureStateForHistory(
      CaptureStateForHistory event, Emitter<HistoryState> emit) async {
    _debounce?.cancel();
    final bookmark = await _bookmarkFromTab(event.tab);
    if (bookmark != null) {
      _pendingSnapshots[bookmark.historyKey] = bookmark;
    }
    _debounce = Timer(const Duration(milliseconds: 1500), () {
      if (_pendingSnapshots.isNotEmpty) {
        add(BulkAddHistory(List.from(_pendingSnapshots.values)));
        _pendingSnapshots.clear();
      }
    });
  }

  void _onFlushHistory(FlushHistory event, Emitter<HistoryState> emit) {
    _debounce?.cancel();
    if (_pendingSnapshots.isNotEmpty) {
      add(BulkAddHistory(List.from(_pendingSnapshots.values)));
      _pendingSnapshots.clear();
    }
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
    try {
      final bookmark = await _bookmarkFromTab(event.tab);
      if (bookmark == null) return;
      add(BulkAddHistory([bookmark]));
    } catch (e) {
      emit(HistoryError(state.history, e.toString()));
    }
  }

  Future<void> _onBulkAddHistory(
      BulkAddHistory event, Emitter<HistoryState> emit) async {
    if (event.snapshots.isEmpty) return;
    try {
      await _saveSnapshotsToHistory(event.snapshots);
    } catch (e) {
      emit(HistoryError(state.history, e.toString()));
    }
  }

  Future<void> _onRemoveHistory(
      RemoveHistory event, Emitter<HistoryState> emit) async {
    try {
      final updatedHistory = List<Bookmark>.from(state.history)
        ..removeAt(event.index);
      await _repository.saveHistory(updatedHistory);
      emit(HistoryLoaded(updatedHistory));
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
