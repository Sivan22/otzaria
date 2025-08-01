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
      super.book,
      super.index,
      super.showLeftPane,
      super.commentators,
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

  // Controllers
  final ItemScrollController scrollController;
  final ScrollOffsetController scrollOffsetController;
  final ItemPositionsListener positionsListener;

  const TextBookLoaded({
    required TextBook book,
    required bool showLeftPane,
    required this.content,
    required this.fontSize,
    required this.showSplitView,
    required this.activeCommentators,
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
    required this.scrollOffsetController,
    required this.positionsListener,
    this.currentTitle,
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
      scrollOffsetController: ScrollOffsetController(),
      positionsListener: ItemPositionsListener.create(),
      visibleIndices: [index],
    );
  }

  TextBookLoaded copyWith({
    TextBook? book,
    List<String>? content,
    double? fontSize,
    bool? showLeftPane,
    bool? showSplitView,
    List<String>? activeCommentators,
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
    ScrollOffsetController? scrollOffsetController,
    ItemPositionsListener? positionsListener,
    String? currentTitle,
  }) {
    return TextBookLoaded(
      book: book ?? this.book,
      content: content ?? this.content,
      fontSize: fontSize ?? this.fontSize,
      showLeftPane: showLeftPane ?? this.showLeftPane,
      showSplitView: showSplitView ?? this.showSplitView,
      activeCommentators: activeCommentators ?? this.activeCommentators,
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
      scrollOffsetController:
          scrollOffsetController ?? this.scrollOffsetController,
      positionsListener: positionsListener ?? this.positionsListener,
      currentTitle: currentTitle ?? this.currentTitle,
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
        rishonim, acharonim, modernCommentators,
        availableCommentators.length,
        links.length,
        tableOfContents.length,
        removeNikud,
        visibleIndices,
        selectedIndex,
        pinLeftPane,
        searchText,
        currentTitle,
      ];
}
