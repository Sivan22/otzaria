import 'dart:async';
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
  final ItemScrollController scrollController;
  final ItemPositionsListener positionsListener;

  TextBookBloc({
    required TextBookRepository repository,
    required TextBookInitial initialState,
    required this.scrollController,
    required this.positionsListener,
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
    on<ToggleNotesSidebar>(_onToggleNotesSidebar);
    on<CreateNoteFromToolbar>(_onCreateNoteFromToolbar);
    on<UpdateSelectedTextForNote>(_onUpdateSelectedTextForNote);
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

    print('DEBUG: TextBookBloc טוען תוכן עם אינדקס ראשוני: ${initial.index}');

    emit(TextBookLoading(
        book, initial.index, initial.showLeftPane, initial.commentators));
    try {
      final content = await _repository.getBookContent(book);
      final links = await _repository.getBookLinks(book);
      final tableOfContents = await _repository.getTableOfContents(book);
      // Pre-compute initial current title (location) so it appears immediately on open
      String? initialTitle;
      try {
        initialTitle = await refFromIndex(
          initial.index,
          Future.value(tableOfContents),
        );
      } catch (_) {
        initialTitle = null;
      }
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

      // Set up position listener with debouncing to prevent excessive updates
      Timer? debounceTimer;
      positionsListener.itemPositions.addListener(() {
        // Cancel previous timer if exists
        debounceTimer?.cancel();

        // Set new timer with 100ms delay
        debounceTimer = Timer(const Duration(milliseconds: 100), () {
          final visibleInecies = positionsListener.itemPositions.value
              .map((e) => e.index)
              .toList();
          if (visibleInecies.isNotEmpty) {
            add(UpdateVisibleIndecies(visibleInecies));
            // עדכון המיקום בטאב כדי למנוע בלבול במעבר בין תצוגות
            if (state is TextBookLoaded) {
              final currentState = state as TextBookLoaded;
              // מעדכנים את המיקום בטאב רק אם יש שינוי משמעותי
              final newIndex = visibleInecies.first;
              if ((currentState.visibleIndices.isEmpty ||
                  (currentState.visibleIndices.first - newIndex).abs() > 5)) {
                // כאן נצטרך לעדכן את הטאב - נעשה זאת בהמשך
              }
            }
          }
        });
      });

      emit(TextBookLoaded(
        book: book, // שימוש במשתנה המקומי
        content: content.split('\n'),
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
        positionsListener: positionsListener,
        currentTitle: initialTitle,
        showNotesSidebar: false,
        selectedTextForNote: null,
        selectedTextStart: null,
        selectedTextEnd: null,
      ));
    } catch (e) {
      emit(TextBookError(e.toString(), book, initial.index,
          initial.showLeftPane, initial.commentators));
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

      // בדיקה אם האינדקסים באמת השתנו
      if (_listsEqual(currentState.visibleIndices, event.visibleIndecies)) {
        return; // אין שינוי, לא צריך לעדכן
      }

      String? newTitle = currentState.currentTitle;

      // עדכון הכותרת רק אם האינדקס הראשון השתנה
      if (event.visibleIndecies.isNotEmpty &&
          (currentState.visibleIndices.isEmpty ||
              currentState.visibleIndices.first !=
                  event.visibleIndecies.first)) {
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

  /// בדיקה אם שתי רשימות שוות
  bool _listsEqual(List<int> list1, List<int> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
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

  void _onToggleNotesSidebar(
    ToggleNotesSidebar event,
    Emitter<TextBookState> emit,
  ) {
    if (state is TextBookLoaded) {
      final currentState = state as TextBookLoaded;
      emit(currentState.copyWith(
        showNotesSidebar: !currentState.showNotesSidebar,
      ));
    }
  }

  void _onCreateNoteFromToolbar(
    CreateNoteFromToolbar event,
    Emitter<TextBookState> emit,
  ) {
    // כרגע זה רק מציין שהאירוע התקבל
    // הלוגיקה האמיתית תהיה בכפתור בשורת הכלים
  }

  void _onUpdateSelectedTextForNote(
    UpdateSelectedTextForNote event,
    Emitter<TextBookState> emit,
  ) {
    if (state is TextBookLoaded) {
      final currentState = state as TextBookLoaded;
      emit(currentState.copyWith(
        selectedTextForNote: event.text,
        selectedTextStart: event.start,
        selectedTextEnd: event.end,
      ));
    }
  }
}
