import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/bloc/ref_indexing/ref_indexing_event.dart';
import 'package:otzaria/bloc/ref_indexing/ref_indexing_repository.dart';
import 'package:otzaria/bloc/ref_indexing/ref_indexing_state.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/bloc/library/library_bloc.dart'; // Import LibraryBloc

class RefIndexingBloc extends Bloc<RefIndexingEvent, RefIndexingState> {
  final RefIndexingRepository refIndexingRepository;
  RefIndexingBloc(
      {required this.refIndexingRepository, required LibraryBloc libraryBloc})
      : // Correct initializer list
        super(RefIndexingInitial()) {
    on<StartRefIndexing>(_onStartRefIndexing);
  }

  Future<void> _onStartRefIndexing(
      StartRefIndexing event, Emitter<RefIndexingState> emit) async {
    emit(RefIndexingInProgress());
    final library = await DataRepository.instance.library;
    assert(library != null,
        'Library should not be null when starting ref indexing');
    await refIndexingRepository.createRefsFromLibrary(library, 0);
    emit(RefIndexingComplete());
  }
}
