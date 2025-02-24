import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/ref_indexing/ref_indexing_event.dart';
import 'package:otzaria/ref_indexing/ref_indexing_repository.dart';
import 'package:otzaria/ref_indexing/ref_indexing_state.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/library/bloc/library_bloc.dart'; // Import LibraryBloc

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
    emit(const RefIndexingInProgress());
    final library = await DataRepository.instance.library;
    await refIndexingRepository.createRefsFromLibrary(library, 0);
    emit(RefIndexingComplete());
  }
}
