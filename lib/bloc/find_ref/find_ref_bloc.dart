import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/bloc/find_ref/find_ref_event.dart';
import 'package:otzaria/bloc/find_ref/find_ref_repository.dart';
import 'package:otzaria/bloc/find_ref/find_ref_state.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/models/app_model.dart'; // Import AppModel
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/isar_collections/ref.dart';
import 'package:otzaria/data/data_providers/isar_data_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class FindRefBloc extends Bloc<FindRefEvent, FindRefState> {
  final FindRefRepository findRefRepository;

  FindRefBloc({required this.findRefRepository}) : super(FindRefInitial()) {
    on<SearchRefRequested>(_onSearchRefRequested);
    on<ClearSearchRequested>(_onClearSearchRequested);
    on<CheckIndexStatusRequested>(_onCheckIndexStatusRequested);
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
      final List<Ref> refs = await findRefRepository.findRefs(event.refText);
      emit(FindRefSuccess(refs));
    } catch (e) {
      emit(FindRefError(e.toString()));
    }
  }

  void _onClearSearchRequested(
      ClearSearchRequested event, Emitter<FindRefState> emit) {
    emit(FindRefInitial());
  }

  Future<void> _onCheckIndexStatusRequested(
      CheckIndexStatusRequested event, Emitter<FindRefState> emit) async {
    final booksProcessed = IsarDataProvider.instance.refsNumOfbooksDone.value;
    final totalBooks = IsarDataProvider.instance.refsNumOfbooksTotal.value;
    emit(FindRefIndexingStatus(
        booksProcessed: booksProcessed, totalBooks: totalBooks));

    final booksWithRefs = await findRefRepository.getNumberOfBooksWithRefs();
    if (booksWithRefs == 0) {
      // TODO: move createRefsFromLibrary to bloc/repository if needed
      // appModel.createRefsFromLibrary(0);
    }
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
