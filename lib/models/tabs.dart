/* this is a representation of the tabs that could be open in the app.
a tab is either a pdf book or a text book, or a full text search window*/

import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:otzaria/models/links.dart';
import 'package:otzaria/models/full_text_search.dart';
import 'package:otzaria/models/books.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';

class OpenedTab {
  String title;

  OpenedTab(this.title);

  factory OpenedTab.fromJson(Map<String, dynamic> json) {
    String type = json['type'];
    if (type == 'TextBookTab') {
      return TextBookTab.fromJson(json);
    } else if (type == 'PdfBookTab') {
      return PdfBookTab.fromJson(json);
    }
    return SearchingTab.fromJson(json);
  }
}

/// Represents a tab with a PDF book.
///
/// The [PdfBookTab] class contains information about the PDF book,
/// such as its [book] and the current [pageNumber].
/// It also contains a [pdfViewerController] to control the viewer.
class PdfBookTab extends OpenedTab {
  /// The PDF book.
  final PdfBook book;

  /// The current page number.
  int pageNumber;

  /// The pdf viewer controller.
  final PdfViewerController pdfViewerController = PdfViewerController();

  final outline = ValueNotifier<List<PdfOutlineNode>?>(null);

  final documentRef = ValueNotifier<PdfDocumentRef?>(null);

  final showLeftPane = ValueNotifier<bool>(false);

  /// Creates a new instance of [PdfBookTab].
  ///
  /// The [book] parameter represents the PDF book, and the [pageNumber]
  /// parameter represents the current page number.
  PdfBookTab(this.book, this.pageNumber) : super(book.title);

  /// Creates a new instance of [PdfBookTab] from a JSON map.
  ///
  /// The JSON map should have 'path' and 'pageNumber' keys.
  factory PdfBookTab.fromJson(Map<String, dynamic> json) {
    return PdfBookTab(
        PdfBook(title: getTitleFromPath(json['path']), path: json['path']),
        json['pageNumber']);
  }

  /// Converts the [PdfBookTab] instance into a JSON map.
  ///
  /// The JSON map contains 'path', 'pageNumber' and 'type' keys.
  Map<String, dynamic> toJson() {
    return {
      'path': book.path,
      'pageNumber':
          (pdfViewerController.isReady ? pdfViewerController.pageNumber : 1),
      'type': 'PdfBookTab'
    };
  }
}

/// Represents a tab that contains a text book.
///
/// It contains various properties such as the book itself,
/// the book's data, links, table of contents, list of available
/// commentators, and more. It also contains controllers for
/// scrolling, searching, and storing scroll positions.
class TextBookTab extends OpenedTab {
  /// The text book.
  final TextBook book;

  ///caching the text, since it takes a while to load
  late final Future<String> text;

  ///caching the links, since it takes a while to load
  late final Future<List<Link>> links;

  //caching the table of contents, since it takes a while to load
  late final Future<List<TocEntry>> tableOfContents;

  /// The initial index of the scrollable list.
  int initalIndex;

  /// The future that resolves to the list of available commentators.
  late Future<List<Book>> availableCommentators;

  /// The list of commentaries to show.
  ValueNotifier<List<Book>> commentatorsToShow = ValueNotifier([]);

  ///the size of the font to view this book
  double textFontSize = Settings.getValue('key-font-size') ?? 25.0;

  ///a flag that tells if the left pane should be shown
  late final ValueNotifier<bool> showLeftPane;

  ///a flag that tells if the left pane should be pinned on scrolling
  final pinLeftPane = ValueNotifier<bool>(false);

  /// a flag that tells if the comentaries should be shown in splited view or not
  final ValueNotifier<bool> showSplitedView = ValueNotifier<bool>(true);

  /// The split contloller.
  MultiSplitViewController splitController =
      MultiSplitViewController(areas: Area.weights([0.4, 0.6]));

  /// The controller for scrolling by index.
  ItemScrollController scrollController = ItemScrollController();

  /// The controller for scrolling by offset.
  ScrollOffsetController scrollOffsetController = ScrollOffsetController();

  /// The controller for searching.
  TextEditingController searchTextController = TextEditingController();

  /// The controller for storing scroll positions.
  ItemPositionsListener positionsListener = ItemPositionsListener.create();

  /// a flag that tells if to remove Nikud from the text
  final ValueNotifier<bool> removeNikud = ValueNotifier<bool>(false);

  /// Creates a new instance of [TextBookTab].
  ///
  /// The [initalIndex] parameter represents the initial index of the item in the scrollable list,
  /// and the [book] parameter represents the text book.
  /// The [searchText] parameter represents the initial search text,
  /// and the [commentaries] parameter represents the list of commentaries.
  TextBookTab(
      {required this.book,
      required this.initalIndex,
      String searchText = '',
      List<Book>? commentaries,
      bool openLeftPane = false})
      : super(book.title) {
    ///load the text
    text = (() async => await book.text)();
    links = (() async => await book.links)();
    tableOfContents = (() async => await book.tableOfContents)();
    showLeftPane = ValueNotifier<bool>(openLeftPane);
    availableCommentators = getAvailableCommentators(book.links);
    if (searchText != '') {
      searchTextController.text = searchText;
    }
    if (commentaries != null && commentaries.isNotEmpty) {
      commentatorsToShow.value = commentaries;
    }
  }

  /// Returns a list of available commentators.
  ///
  /// Filters the links in the book to find commentaries and targums,
  /// and returns a list of unique commentaries.
  Future<List<Book>> getAvailableCommentators(Future<List<Link>> links) async {
    List<Link> filteredLinks = (await links)
        .where((link) =>
            link.connectionType == 'commentary' ||
            link.connectionType == 'targum')
        .toList();
    List<String> paths = filteredLinks.map((e) => e.path2).toList();
    List<String> uniquePaths = paths.toSet().toList();
    uniquePaths.sort();
    List<Book> availableCommentators = uniquePaths
        .map((e) => TextBook(
              title: getTitleFromPath(e),
            ))
        .toList();
    return availableCommentators;
  }

  /// Creates a new instance of [TextBookTab] from a JSON map.
  ///
  /// The JSON map should have 'initalIndex', 'title', 'commentaries',
  /// and 'type' keys.
  factory TextBookTab.fromJson(Map<String, dynamic> json) {
    return TextBookTab(
      initalIndex: json['initalIndex'],
      book: TextBook(
        title: json['title'],
      ),
      // commentaries: json['commentators']
      //     .map<Book>((json) => TextBook(title: json.toString()))
      //     .toList()
    );
  }

  /// Converts the [TextBookTab] instance into a JSON map.
  ///
  /// The JSON map contains 'title', 'initalIndex', 'commentaries',
  /// and 'type' keys.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'initalIndex': positionsListener.itemPositions.value.isNotEmpty
          ? positionsListener.itemPositions.value.first.index
          : 0,
      'commentators':
          commentatorsToShow.value.map((book) => book.title).toList(),
      'type': 'TextBookTab'
    };
  }
}

class SearchingTab extends OpenedTab {
  FullTextSearcher searcher = FullTextSearcher(
    [],
    TextEditingController(),
    ValueNotifier([]),
  );
  final ItemScrollController scrollController = ItemScrollController();

  SearchingTab(
    super.title,
  );

  @override
  factory SearchingTab.fromJson(Map<String, dynamic> json) {
    return SearchingTab(json['title']);
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'type': 'SearchingTabWindow'};
  }
}
