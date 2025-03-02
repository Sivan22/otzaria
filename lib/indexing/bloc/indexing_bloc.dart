import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/indexing/bloc/indexing_event.dart';
import 'package:otzaria/indexing/bloc/indexing_state.dart';
import 'package:otzaria/indexing/repository/indexing_repository.dart';
import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';

class IndexingBloc extends Bloc<IndexingEvent, IndexingState> {
  final IndexingRepository _repository;

  IndexingBloc(this._repository) : super(IndexingInitial()) {
    on<StartIndexing>(_onStartIndexing);
    on<CancelIndexing>(_onCancelIndexing);
    on<UpdateIndexingProgress>(_onUpdateProgress);
  }

  /// Factory constructor that creates an IndexingBloc with a default repository
  factory IndexingBloc.create() {
    return IndexingBloc(
      IndexingRepository(TantivyDataProvider.instance),
    );
  }

  /// Handles the StartIndexing event
  Future<void> _onStartIndexing(
    StartIndexing event,
    Emitter<IndexingState> emit,
  ) async {
    // Set initial state
    emit(IndexingInProgress(
      booksProcessed: 0,
      totalBooks: 0,
      booksDone: _repository.getIndexedBooks(),
    ));

    try {
      // Start indexing process
      await _repository.indexAllBooks(
        event.library,
        (processed, total) {
          // Update progress through event
          add(UpdateIndexingProgress(
            processed: processed,
            total: total,
          ));
        },
      );
    } catch (e) {
      emit(IndexingError(e.toString(),
          booksProcessed: state.booksProcessed,
          totalBooks: state.totalBooks,
          booksDone: _repository.getIndexedBooks()));
    }
  }

  /// Handles the CancelIndexing event
  void _onCancelIndexing(
    CancelIndexing event,
    Emitter<IndexingState> emit,
  ) {
    _repository.cancelIndexing();
    emit(IndexingInitial());
  }

  /// Handles the UpdateIndexingProgress event
  void _onUpdateProgress(
    UpdateIndexingProgress event,
    Emitter<IndexingState> emit,
  ) {
    // If indexing is complete
    if (event.processed >= event.total) {
      emit(IndexingComplete());
    } else {
      // Update progress state
      emit(IndexingInProgress(
        booksProcessed: event.processed,
        totalBooks: event.total,
      ));
    }
  }
}
