import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_event.dart';
import 'package:otzaria/text_book/text_book_repository.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/utils/ref_helper.dart';
import 'package:otzaria/utils/text_manipulation.dart';

class TextBookBloc extends Bloc<TextBookEvent, TextBookState> {
  final TextBookRepository _repository;

  TextBookBloc({
    required TextBookRepository repository,
    required TextBookState initialState,
  })  : _repository = repository,
        super(initialState) {
    on<LoadContent>(_onLoadContent);
    on<UpdateFontSize>(_onUpdateFontSize);
    on<ToggleLeftPane>(_onToggleLeftPane);
    on<ToggleSplitView>(_onToggleSplitView);
    on<UpdateCommentators>(_onUpdateCommentators);
    on<ToggleNikud>(_onToggleNikud);
    on<UpdateVisibleIndecies>(_onUpdateVisibleIndecies);
    on<UpdateSelectedIndex>(_onUpdateSelectedIndex);
    on<TogglePinLeftPane>(_onTogglePinLeftPane);
    on<UpdateSearchText>(_onUpdateSearchText);

    // Load initial content
    add(LoadContent(book: initialState.book));

    //listen to index changes
    initialState.positionsListener.itemPositions.addListener(() {
      final visibleInecies = state.positionsListener.itemPositions.value
          .map((e) => e.index)
          .toList();
      add(UpdateVisibleIndecies(visibleInecies));
      if (state.selectedIndex != null &&
          !visibleInecies.contains(state.selectedIndex)) {
        add(UpdateSelectedIndex(null));
      }
    });
  }

  Future<void> _onLoadContent(
    LoadContent event,
    Emitter<TextBookState> emit,
  ) async {
    try {
      emit(state.copyWith(status: TextBookStatus.loading));

      final content = await _repository.getBookContent(event.book);
      final links = await _repository.getBookLinks(event.book);
      final tableOfContents = await _repository.getTableOfContents(event.book);

      final availableCommentators =
          await _repository.getAvailableCommentators(links);

      emit(state.copyWith(
        book: event.book,
        content: content.split('\n'),
        links: links,
        availableCommentators: availableCommentators,
        tableOfContents: tableOfContents,
        status: TextBookStatus.loaded,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TextBookStatus.error,
        error: e.toString(),
      ));
    }
  }

  void _onUpdateFontSize(
    UpdateFontSize event,
    Emitter<TextBookState> emit,
  ) {
    emit(state.copyWith(fontSize: event.fontSize));
  }

  void _onToggleLeftPane(
    ToggleLeftPane event,
    Emitter<TextBookState> emit,
  ) {
    emit(state.copyWith(showLeftPane: event.show));
  }

  void _onToggleSplitView(
    ToggleSplitView event,
    Emitter<TextBookState> emit,
  ) {
    emit(state.copyWith(showSplitView: event.show));
  }

  void _onUpdateCommentators(
    UpdateCommentators event,
    Emitter<TextBookState> emit,
  ) async {
    emit(state.copyWith(activeCommentators: event.commentators));
  }

  void _onToggleNikud(
    ToggleNikud event,
    Emitter<TextBookState> emit,
  ) {
    emit(state.copyWith(removeNikud: event.remove));
  }

  void _onUpdateVisibleIndecies(
    UpdateVisibleIndecies event,
    Emitter<TextBookState> emit,
  ) async {
    emit(state.copyWith(
      visibleIndices: event.visibleIndecies,
      currentTitle: await refFromIndex(
          event.visibleIndecies.first, Future.value(state.tableOfContents)),
    ));
  }

  void _onUpdateSelectedIndex(
    UpdateSelectedIndex event,
    Emitter<TextBookState> emit,
  ) {
    emit(state.copyWith(selectedIndex: event.index));
  }

  void _onTogglePinLeftPane(
    TogglePinLeftPane event,
    Emitter<TextBookState> emit,
  ) {
    emit(state.copyWith(pinLeftPane: event.pin));
  }

  void _onUpdateSearchText(
    UpdateSearchText event,
    Emitter<TextBookState> emit,
  ) {
    emit(state.copyWith(searchText: event.text));
  }
}
