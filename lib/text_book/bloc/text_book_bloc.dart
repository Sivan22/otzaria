import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_event.dart';
import 'package:otzaria/text_book/text_book_repository.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/utils/ref_helper.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/data/data_providers/file_system_data_provider.dart';

class TextBookBloc extends Bloc<TextBookEvent, TextBookState> {
  final TextBookRepository _repository;

  TextBookBloc({
    required TextBookRepository repository,
    required TextBookInitial initialState,
  })  : _repository = repository,
        super(initialState) {
    on<LoadContent>(_onLoadContent);
    on<LoadPartialContent>(_onLoadPartialContent);
    on<LoadFullContent>(_onLoadFullContent);
    on<LoadMoreContent>(_onLoadMoreContent);
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
    // הגנה כדי לוודא שאנחנו מתחילים רק מהמצב ההתחלתי
    if (state is! TextBookInitial) {
      if (state is TextBookLoaded) {
        emit(state);
      }
      return;
    }
    // "הטלה" בטוחה של המצב למשתנה מקומי
    final initial = state as TextBookInitial;
    // שמירת הערכים הדרושים במשתנים מקומיים לפני פעולות אסינכרוניות
    final book = initial.book;
    final searchText = initial.searchText;

    emit(TextBookLoading(
        book, initial.index, initial.showLeftPane, initial.commentators));
    try {
      // Use partial loading if requested and we have a specific index
      final List<String> contentLines;
      final bool isPartial;
      final int? partialStart;
      
      if (event.usePartialLoading && initial.index > 0) {
        contentLines = await _repository.getPartialBookContent(book, initial.index);
        isPartial = true;
        partialStart = (initial.index - 50).clamp(0, double.infinity).toInt();
      } else {
        final fullContent = await _repository.getBookContent(book);
        contentLines = fullContent.split('\n');
        isPartial = false;
        partialStart = null;
      }
      
      final links = await _repository.getBookLinks(book);
      final tableOfContents = await _repository.getTableOfContents(book);
      final availableCommentators =
          await _repository.getAvailableCommentators(links);
      // ממיינים את רשימת המפרשים לקבוצות לפי תקופה
      final eras = await utils.splitByEra(availableCommentators);

      final defaultRemoveNikud =
          Settings.getValue<bool>('key-default-nikud') ?? false;
      final removeNikudFromTanach =
          Settings.getValue<bool>('key-remove-nikud-tanach') ?? false;
      final isTanach = await FileSystemData.instance.isTanachBook(book.title);
      final removeNikud =
          defaultRemoveNikud && (removeNikudFromTanach || !isTanach);

      // Create controllers if this is the first load
      final ItemScrollController scrollController = ItemScrollController();
      final ScrollOffsetController scrollOffsetController =
          ScrollOffsetController();
      final ItemPositionsListener positionsListener =
          ItemPositionsListener.create();

      // Set up position listener
      positionsListener.itemPositions.addListener(() {
        final visibleInecies =
            positionsListener.itemPositions.value.map((e) => e.index).toList();
        if (visibleInecies.isNotEmpty) {
          add(UpdateVisibleIndecies(visibleInecies));
        }
      });

      emit(TextBookLoaded(
        book: book, // שימוש במשתנה המקומי
        content: contentLines,
        isPartialContent: isPartial,
        partialStartIndex: partialStart,
        links: links,
        availableCommentators: availableCommentators,
        tableOfContents: tableOfContents,
        fontSize: event.fontSize,
        // הצג את סרגל הצד אם ההגדרה דורשת זאת, או אם הגענו מחיפוש
        showLeftPane: initial.showLeftPane || initial.searchText.isNotEmpty,
        showSplitView: event.showSplitView,
        activeCommentators: initial.commentators, // שימוש במשתנה המקומי
        torahShebichtav: eras['תורה שבכתב'] ?? [],
        chazal: eras['חז"ל'] ?? [],
        rishonim: eras['ראשונים'] ?? [],
        acharonim: eras['אחרונים'] ?? [],
        modernCommentators: eras['מחברי זמננו'] ?? [],
        removeNikud: removeNikud,
        visibleIndices: [initial.index], // שימוש במשתנה המקומי
        pinLeftPane: Settings.getValue<bool>('key-pin-sidebar') ?? false,
        searchText: searchText,
        scrollController: scrollController,
        scrollOffsetController: scrollOffsetController,
        positionsListener: positionsListener,
      ));
    } catch (e) {
      emit(TextBookError(e.toString(), book, initial.index,
          initial.showLeftPane, initial.commentators));
    }
  }

  Future<void> _onLoadPartialContent(
    LoadPartialContent event,
    Emitter<TextBookState> emit,
  ) async {
    if (state is! TextBookLoaded) return;
    
    final currentState = state as TextBookLoaded;
    final book = currentState.book;
    
    try {
      // Load partial content around the current index
      final partialContent = await _repository.getPartialBookContent(
        book, 
        event.currentIndex, 
        sectionsAround: event.sectionsAround
      );
      
      final startIndex = (event.currentIndex - event.sectionsAround).clamp(0, double.infinity).toInt();
      
      emit(currentState.copyWith(
        content: partialContent,
        isPartialContent: true,
        partialStartIndex: startIndex,
        selectedIndex: event.currentIndex,
      ));
    } catch (e) {
      // If partial loading fails, keep the current state
      print('Error loading partial content: $e');
    }
  }

  Future<void> _onLoadFullContent(
    LoadFullContent event,
    Emitter<TextBookState> emit,
  ) async {
    if (state is! TextBookLoaded) return;
    
    final currentState = state as TextBookLoaded;
    final book = currentState.book;
    
    try {
      // Load the full content
      final fullContent = await _repository.getBookContent(book);
      final contentLines = fullContent.split('\n');
      
      emit(currentState.copyWith(
        content: contentLines,
        isPartialContent: false,
        partialStartIndex: null,
      ));
    } catch (e) {
      print('Error loading full content: $e');
    }
  }

  Future<void> _onLoadMoreContent(
    LoadMoreContent event,
    Emitter<TextBookState> emit,
  ) async {
    if (state is! TextBookLoaded) return;
    
    final currentState = state as TextBookLoaded;
    if (!currentState.isPartialContent) return; // Already have full content
    
    final book = currentState.book;
    final currentContent = currentState.content;
    final partialStart = currentState.partialStartIndex ?? 0;
    
    try {
      if (event.loadBefore) {
        // Load content before current content
        final newStartIndex = (partialStart - 100).clamp(0, double.infinity).toInt();
        if (newStartIndex < partialStart) {
          final beforeContent = await _repository.getPartialBookContent(
            book, 
            newStartIndex + 50, // Center around this index
            sectionsAround: 50
          );
          
          // Merge with existing content (avoid duplicates)
          final mergedContent = [...beforeContent, ...currentContent];
          
          emit(currentState.copyWith(
            content: mergedContent,
            partialStartIndex: newStartIndex,
          ));
        }
      } else {
        // Load content after current content
        final currentEndIndex = partialStart + currentContent.length;
        final newContent = await _repository.getPartialBookContent(
          book, 
          currentEndIndex + 50, // Center around this index
          sectionsAround: 50
        );
        
        // Merge with existing content (avoid duplicates)
        final mergedContent = [...currentContent, ...newContent];
        
        emit(currentState.copyWith(
          content: mergedContent,
        ));
      }
    } catch (e) {
      print('Error loading more content: $e');
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

      // Check if we need to load more content (if we're using partial content)
      if (currentState.isPartialContent && event.visibleIndecies.isNotEmpty) {
        final maxVisibleIndex = event.visibleIndecies.reduce((a, b) => a > b ? a : b);
        final minVisibleIndex = event.visibleIndecies.reduce((a, b) => a < b ? a : b);
        
        // If we're near the end of loaded content, load more
        if (maxVisibleIndex >= currentState.content.length - 10) {
          final actualIndex = (currentState.partialStartIndex ?? 0) + maxVisibleIndex;
          add(LoadPartialContent(currentIndex: actualIndex + 50));
        }
        // If we're near the beginning of loaded content, load more
        else if (minVisibleIndex <= 10 && (currentState.partialStartIndex ?? 0) > 0) {
          final actualIndex = (currentState.partialStartIndex ?? 0) + minVisibleIndex;
          add(LoadPartialContent(currentIndex: actualIndex - 50));
        }
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
