import 'package:equatable/equatable.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/links.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

abstract class TextBookState extends Equatable {
  final TextBook book;
  final int index;
  final bool showLeftPane;
  final List<String> commentators;
  const TextBookState(
      this.book, this.index, this.showLeftPane, this.commentators);

  @override
  List<Object?> get props => [];
}

class TextBookInitial extends TextBookState {
  final String searchText;

  const TextBookInitial(
      super.book, super.index, super.showLeftPane, super.commentators,
      [this.searchText = '']);

  @override
  List<Object?> get props => [book.title, searchText];
}

class TextBookLoading extends TextBookState {
  const TextBookLoading(
      super.book, super.index, super.showLeftPane, super.commentators);

  @override
  List<Object?> get props => [book.title];
}

class TextBookError extends TextBookState {
  final String message;

  const TextBookError(this.message, super.book, super.index, super.showLeftPane,
      super.commentators);

  @override
  List<Object?> get props => [message, book.title];
}

class TextBookLoaded extends TextBookState {
  final List<String> content;
  final double fontSize;
  final bool showSplitView;
  final List<String> activeCommentators;
  final List<String> torahShebichtav;
  final List<String> chazal;
  final List<String> rishonim;
  final List<String> acharonim;
  final List<String> modernCommentators;
  final List<String> availableCommentators;
  final List<Link> links;
  final List<TocEntry> tableOfContents;
  final bool removeNikud;
  final List<int> visibleIndices;
  final int? selectedIndex;
  final bool pinLeftPane;
  final String searchText;
  final String? currentTitle;
  final bool showNotesSidebar;
  final String? selectedTextForNote;
  final int? selectedTextStart;
  final int? selectedTextEnd;

  // Controllers
  final ItemScrollController scrollController;
  final ItemPositionsListener positionsListener;

  const TextBookLoaded({
    required TextBook book,
    required bool showLeftPane,
    required this.content,
    required this.fontSize,
    required this.showSplitView,
    required this.activeCommentators,
    required this.torahShebichtav,
    required this.chazal,
    required this.rishonim,
    required this.acharonim,
    required this.modernCommentators,
    required this.availableCommentators,
    required this.links,
    required this.tableOfContents,
    required this.removeNikud,
    required this.visibleIndices,
    this.selectedIndex,
    required this.pinLeftPane,
    required this.searchText,
    required this.scrollController,
    required this.positionsListener,
    this.currentTitle,
    required this.showNotesSidebar,
    this.selectedTextForNote,
    this.selectedTextStart,
    this.selectedTextEnd,
  }) : super(book, selectedIndex ?? 0, showLeftPane, activeCommentators);

  factory TextBookLoaded.initial({
    required TextBook book,
    required int index,
    required bool showLeftPane,
    required bool splitView,
    List<String>? commentators,
  }) {
    return TextBookLoaded(
      book: book,
      content: const [],
      fontSize: 25.0, // Default font size
      showLeftPane: showLeftPane,
      showSplitView: splitView,
      activeCommentators: commentators ?? const [],
      torahShebichtav: const [],
      chazal: const [],
      rishonim: const [],
      acharonim: const [],
      modernCommentators: const [],
      availableCommentators: const [],
      links: const [],
      tableOfContents: const [],
      removeNikud: false,
      pinLeftPane: Settings.getValue<bool>('key-pin-sidebar') ?? false,
      searchText: '',
      scrollController: ItemScrollController(),
      positionsListener: ItemPositionsListener.create(),
      visibleIndices: [index],
      showNotesSidebar: false,
      selectedTextForNote: null,
      selectedTextStart: null,
      selectedTextEnd: null,
    );
  }

  TextBookLoaded copyWith({
    TextBook? book,
    List<String>? content,
    double? fontSize,
    bool? showLeftPane,
    bool? showSplitView,
    List<String>? activeCommentators,
    List<String>? torahShebichtav,
    List<String>? chazal,
    List<String>? rishonim,
    List<String>? acharonim,
    List<String>? modernCommentators,
    List<String>? availableCommentators,
    List<Link>? links,
    List<TocEntry>? tableOfContents,
    bool? removeNikud,
    int? selectedIndex,
    List<int>? visibleIndices,
    bool? pinLeftPane,
    String? searchText,
    ItemScrollController? scrollController,
    ItemPositionsListener? positionsListener,
    String? currentTitle,
    bool? showNotesSidebar,
    String? selectedTextForNote,
    int? selectedTextStart,
    int? selectedTextEnd,
  }) {
    return TextBookLoaded(
      book: book ?? this.book,
      content: content ?? this.content,
      fontSize: fontSize ?? this.fontSize,
      showLeftPane: showLeftPane ?? this.showLeftPane,
      showSplitView: showSplitView ?? this.showSplitView,
      activeCommentators: activeCommentators ?? this.activeCommentators,
      torahShebichtav: torahShebichtav ?? this.torahShebichtav,
      chazal: chazal ?? this.chazal,
      rishonim: rishonim ?? this.rishonim,
      acharonim: acharonim ?? this.acharonim,
      modernCommentators: modernCommentators ?? this.modernCommentators,
      availableCommentators:
          availableCommentators ?? this.availableCommentators,
      links: links ?? this.links,
      tableOfContents: tableOfContents ?? this.tableOfContents,
      removeNikud: removeNikud ?? this.removeNikud,
      visibleIndices: visibleIndices ?? this.visibleIndices,
      selectedIndex: selectedIndex,
      pinLeftPane: pinLeftPane ?? this.pinLeftPane,
      searchText: searchText ?? this.searchText,
      scrollController: scrollController ?? this.scrollController,
      positionsListener: positionsListener ?? this.positionsListener,
      currentTitle: currentTitle ?? this.currentTitle,
      showNotesSidebar: showNotesSidebar ?? this.showNotesSidebar,
      selectedTextForNote: selectedTextForNote ?? this.selectedTextForNote,
      selectedTextStart: selectedTextStart ?? this.selectedTextStart,
      selectedTextEnd: selectedTextEnd ?? this.selectedTextEnd,
    );
  }

  @override
  List<Object?> get props => [
        book.title,
        content.length,
        fontSize,
        showLeftPane,
        showSplitView,
        activeCommentators.length,
        torahShebichtav,
        chazal,
        rishonim,
        acharonim,
        modernCommentators,
        availableCommentators.length,
        links.length,
        tableOfContents.length,
        removeNikud,
        visibleIndices,
        selectedIndex,
        pinLeftPane,
        searchText,
        currentTitle,
        showNotesSidebar,
        selectedTextForNote,
        selectedTextStart,
        selectedTextEnd,
      ];
}
