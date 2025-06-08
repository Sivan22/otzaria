import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/text_book/bloc/text_book_event.dart';
import 'package:otzaria/text_book/text_book_repository.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/utils/ref_helper.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class TextBookBloc extends Bloc<TextBookEvent, TextBookState> {
  final TextBookRepository _repository;

  TextBookBloc({
    required TextBookRepository repository,
    required TextBookInitial initialState,
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
  }

  Future<void> _onLoadContent(
    LoadContent event,
    Emitter<TextBookState> emit,
  ) async {
    if (state is TextBookLoading) {
      return;
    }
    if (state is TextBookLoaded) {
      emit(state);
    }

    if (state is TextBookInitial) {
      final book = state.book;
      emit(TextBookLoading(
          book, state.index, state.showLeftPane, state.commentators));
      try {
        final content = await _repository.getBookContent(book);
        final links = await _repository.getBookLinks(book);
        final tableOfContents = await _repository.getTableOfContents(book);
        final availableCommentators =
            await _repository.getAvailableCommentators(links);

        // Create controllers if this is the first load
        final ItemScrollController scrollController = ItemScrollController();
        final ScrollOffsetController scrollOffsetController =
            ScrollOffsetController();
        final ItemPositionsListener positionsListener =
            ItemPositionsListener.create();

        // Set up position listener
        positionsListener.itemPositions.addListener(() {
          final visibleInecies = positionsListener.itemPositions.value
              .map((e) => e.index)
              .toList();
          if (visibleInecies.isNotEmpty) {
            add(UpdateVisibleIndecies(visibleInecies));
          }
        });

        emit(TextBookLoaded(
          book: state.book,
          content: content.split('\n'),
          links: links,
          availableCommentators: availableCommentators,
          tableOfContents: tableOfContents,
          fontSize: Settings.getValue<double>('key-font-size') ?? 25.0,
          showLeftPane: state.showLeftPane,
          showSplitView: Settings.getValue<bool>('key-splited-view') ?? false,
          activeCommentators: state.commentators,
          removeNikud: false,
          visibleIndices: [state.index],
          pinLeftPane: false,
          searchText: '',
          scrollController: scrollController,
          scrollOffsetController: scrollOffsetController,
          positionsListener: positionsListener,
        ));
      } catch (e) {
        emit(TextBookError(e.toString(), book, state.index, state.showLeftPane,
            state.commentators));
      }
    }
  }

  void _onUpdateFontSize(
    UpdateFontSize event,
    Emitter<TextBookState> emit,
  ) {
    if (state is TextBookLoaded) {
      final currentState = state as TextBookLoaded;
      emit(currentState.copyWith(
        fontSize: event.fontSize,
        selectedIndex: currentState.selectedIndex,
      ));
    }
  }

  void _onToggleLeftPane(
    ToggleLeftPane event,
    Emitter<TextBookState> emit,
  ) {
    if (state is TextBookLoaded) {
      final currentState = state as TextBookLoaded;
      emit(currentState.copyWith(
        showLeftPane: event.show,
        selectedIndex: currentState.selectedIndex,
      ));
    }
  }

  void _onToggleSplitView(
    ToggleSplitView event,
    Emitter<TextBookState> emit,
  ) {
    if (state is TextBookLoaded) {
      final currentState = state as TextBookLoaded;
      emit(currentState.copyWith(
        showSplitView: event.show,
        selectedIndex: currentState.selectedIndex,
      ));
    }
  }

  void _onUpdateCommentators(
    UpdateCommentators event,
    Emitter<TextBookState> emit,
  ) async {
    if (state is TextBookLoaded) {
      final currentState = state as TextBookLoaded;
      emit(currentState.copyWith(
        activeCommentators: event.commentators,
        selectedIndex: currentState.selectedIndex,
      ));
    }
  }

  void _onToggleNikud(
    ToggleNikud event,
    Emitter<TextBookState> emit,
  ) {
    if (state is TextBookLoaded) {
      final currentState = state as TextBookLoaded;
      emit(currentState.copyWith(
        removeNikud: event.remove,
        selectedIndex: currentState.selectedIndex,
      ));
    }
  }

  void _onUpdateVisibleIndecies(
    UpdateVisibleIndecies event,
    Emitter<TextBookState> emit,
  ) async {
    if (state is TextBookLoaded) {
      final currentState = state as TextBookLoaded;
      String? newTitle;

      if (event.visibleIndecies.isNotEmpty) {
        newTitle = await refFromIndex(event.visibleIndecies.first,
            Future.value(currentState.tableOfContents));
      }

      int? index = currentState.selectedIndex;
      if (!event.visibleIndecies.contains(index)) {
        index = null;
      }

      emit(currentState.copyWith(
          visibleIndices: event.visibleIndecies,
          currentTitle: newTitle,
          selectedIndex: index));
    }
  }

  void _onUpdateSelectedIndex(
    UpdateSelectedIndex event,
    Emitter<TextBookState> emit,
  ) {
    if (state is TextBookLoaded) {
      final currentState = state as TextBookLoaded;
      emit(currentState.copyWith(selectedIndex: event.index));
    }
  }

  void _onTogglePinLeftPane(
    TogglePinLeftPane event,
    Emitter<TextBookState> emit,
  ) {
    if (state is TextBookLoaded) {
      final currentState = state as TextBookLoaded;
      emit(currentState.copyWith(
        pinLeftPane: event.pin,
        selectedIndex: currentState.selectedIndex,
      ));
    }
  }

  void _onUpdateSearchText(
    UpdateSearchText event,
    Emitter<TextBookState> emit,
  ) {
    if (state is TextBookLoaded) {
      final currentState = state as TextBookLoaded;
      emit(currentState.copyWith(
        searchText: event.text,
        selectedIndex: currentState.selectedIndex,
      ));
    }
  }
}
