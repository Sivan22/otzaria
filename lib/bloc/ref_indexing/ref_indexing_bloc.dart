import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/bloc/ref_indexing/ref_indexing_event.dart';
import 'package:otzaria/bloc/ref_indexing/ref_indexing_repository.dart';
import 'package:otzaria/bloc/ref_indexing/ref_indexing_state.dart';
import 'package:otzaria/models/library.dart';
import 'package:otzaria/bloc/library/library_bloc.dart'; // Import LibraryBloc

class RefIndexingBloc extends Bloc<RefIndexingEvent, RefIndexingState> {
  final RefIndexingRepository refIndexingRepository;
  final LibraryBloc libraryBloc; // Use LibraryBloc instead of AppModel

  RefIndexingBloc(
      {required this.refIndexingRepository, required LibraryBloc libraryBloc})
      : libraryBloc = libraryBloc, // Correct initializer list
        super(RefIndexingInitial()) {
    on<StartRefIndexing>(_onStartRefIndexing);
  }

  Future<void> _onStartRefIndexing(
      StartRefIndexing event, Emitter<RefIndexingState> emit) async {
    emit(RefIndexingInProgress());
    final library =
        libraryBloc.state.library; // Use libraryBloc instead of _libraryBloc
    assert(library != null,
        'Library should not be null when starting ref indexing');
    await refIndexingRepository.createRefsFromLibrary(library!, 0);
    emit(RefIndexingComplete());
  }
}
