import 'package:equatable/equatable.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/links.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

enum TextBookStatus { initial, loading, loaded, error }

class TextBookState extends Equatable {
  final TextBook book;
  final List<String>? content;
  final double fontSize;
  final bool showLeftPane;
  final bool showSplitView;
  final List<String> activeCommentators;
  final List<String>? availableCommentators;
  final List<Link>? links;
  final List<TocEntry>? tableOfContents;
  final bool removeNikud;
  final List<int>? visibleIndices;
  final int? selectedIndex;
  final bool pinLeftPane;
  final String searchText;
  final TextBookStatus status;
  final String? error;
  final String? currentTitle;

  // Controllers
  final ItemScrollController scrollController;
  final ScrollOffsetController scrollOffsetController;
  final ItemPositionsListener positionsListener;

  const TextBookState(
      {required this.book,
      this.content,
      required this.fontSize,
      required this.showLeftPane,
      required this.showSplitView,
      required this.activeCommentators,
      this.availableCommentators,
      this.links,
      this.tableOfContents,
      required this.removeNikud,
      this.visibleIndices,
      this.selectedIndex,
      required this.pinLeftPane,
      required this.searchText,
      required this.status,
      this.error,
      required this.scrollController,
      required this.scrollOffsetController,
      required this.positionsListener,
      this.currentTitle});

  factory TextBookState.initial({
    required TextBook book,
    required int index,
    required bool showLeftPane,
    required bool splitView,
    List<String>? commentators,
  }) {
    return TextBookState(
      book: book,
      fontSize: 25.0, // Default font size
      showLeftPane: showLeftPane,
      showSplitView: splitView,
      activeCommentators:
          commentators ?? const [], // Use commentators for activeCommentators
      availableCommentators: const [], // This will be populated later in the bloc
      removeNikud: false,
      pinLeftPane: false,
      searchText: '',
      status: TextBookStatus.initial,
      scrollController: ItemScrollController(),
      scrollOffsetController: ScrollOffsetController(),
      positionsListener: ItemPositionsListener.create(),
      visibleIndices: [index],
    );
  }

  TextBookState copyWith(
      {TextBook? book,
      List<String>? content,
      double? fontSize,
      bool? showLeftPane,
      bool? showSplitView,
      List<String>? activeCommentators,
      List<String>? availableCommentators,
      List<Link>? links,
      List<TocEntry>? tableOfContents,
      bool? removeNikud,
      int? selectedIndex,
      List<int>? visibleIndices,
      bool? pinLeftPane,
      String? searchText,
      TextBookStatus? status,
      String? error,
      ItemScrollController? scrollController,
      ScrollOffsetController? scrollOffsetController,
      ItemPositionsListener? positionsListener,
      String? currentTitle}) {
    return TextBookState(
      book: book ?? this.book,
      content: content ?? this.content,
      fontSize: fontSize ?? this.fontSize,
      showLeftPane: showLeftPane ?? this.showLeftPane,
      showSplitView: showSplitView ?? this.showSplitView,
      activeCommentators: activeCommentators ?? this.activeCommentators,
      availableCommentators:
          availableCommentators ?? this.availableCommentators,
      links: links ?? this.links,
      tableOfContents: tableOfContents ?? this.tableOfContents,
      removeNikud: removeNikud ?? this.removeNikud,
      visibleIndices: visibleIndices ?? this.visibleIndices,
      selectedIndex: selectedIndex,
      pinLeftPane: pinLeftPane ?? this.pinLeftPane,
      searchText: searchText ?? this.searchText,
      status: status ?? this.status,
      error: error ?? this.error,
      scrollController: scrollController ?? this.scrollController,
      scrollOffsetController:
          scrollOffsetController ?? this.scrollOffsetController,
      positionsListener: positionsListener ?? this.positionsListener,
      currentTitle: currentTitle ?? this.currentTitle,
    );
  }

  @override
  List<Object?> get props => [
        book?.title,
        content?.length,
        fontSize,
        showLeftPane,
        showSplitView,
        activeCommentators?.length,
        links?.length,
        tableOfContents,
        removeNikud,
        visibleIndices,
        selectedIndex,
        pinLeftPane,
        searchText,
        status,
        error,
        currentTitle,
      ];
}
