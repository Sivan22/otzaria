import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/find_ref/find_ref_event.dart';
import 'package:otzaria/find_ref/find_ref_repository.dart';
import 'package:otzaria/find_ref/find_ref_state.dart';
import 'package:otzaria/models/books.dart';
import 'package:search_engine/search_engine.dart';

class FindRefBloc extends Bloc<FindRefEvent, FindRefState> {
  final FindRefRepository findRefRepository;

  FindRefBloc({required this.findRefRepository}) : super(FindRefInitial()) {
    on<SearchRefRequested>(_onSearchRefRequested);
    on<ClearSearchRequested>(_onClearSearchRequested);
    on<OpenBookRequested>(_onOpenBookRequested);
  }

  Future<void> _onSearchRefRequested(
      SearchRefRequested event, Emitter<FindRefState> emit) async {
    if (event.refText.length < 3) {
      emit(const FindRefSuccess([]));
      return;
    }
    emit(FindRefLoading());
    try {
      final List<ReferenceSearchResult> refs =
          await findRefRepository.findRefs(event.refText);
      emit(FindRefSuccess(refs));
    } catch (e) {
      emit(FindRefError(e.toString()));
    }
  }

  void _onClearSearchRequested(
      ClearSearchRequested event, Emitter<FindRefState> emit) {
    emit(FindRefInitial());
  }

  void _onOpenBookRequested(
      OpenBookRequested event, Emitter<FindRefState> emit) {
    final book = event.book;
    final index = event.index;
    emit(
        FindRefBookOpening(book: book, index: index)); // Emit BookOpening state
  }
}

class FindRefBookOpening extends FindRefState {
  // Define BookOpening state
  final Book book;
  final int index;

  const FindRefBookOpening({required this.book, required this.index});

  @override
  List<Object> get props => [book, index];
}
