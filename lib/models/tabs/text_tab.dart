import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/links.dart';
import 'package:otzaria/models/tabs/tabs.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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

  /// The index of the scrollable list.
  int index;

  /// if the user selects particular section, we save it in order to show the comentaries of that section
  ValueNotifier<int?> selectedIndex = ValueNotifier(null);

  /// The future that resolves to the list of available commentators.
  late Future<List<String>> availableCommentators;

  /// The list of commentaries to show.
  ValueNotifier<List<String>> commentatorsToShow = ValueNotifier([]);

  ///the size of the font to view this book
  double textFontSize = Settings.getValue('key-font-size') ?? 25.0;

  ///a flag that tells if the left pane should be shown
  late final ValueNotifier<bool> showLeftPane;

  ///a flag that tells if the left pane should be pinned on scrolling
  final pinLeftPane = ValueNotifier<bool>(false);

  /// a flag that tells if the comentaries should be shown in splited view or not
  late ValueNotifier<bool> showSplitedView;

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
  /// The [index] parameter represents the initial index of the item in the scrollable list,
  /// and the [book] parameter represents the text book.
  /// The [searchText] parameter represents the initial search text,
  /// and the [commentators] parameter represents the list of commentaries to show.
  TextBookTab(
      {required this.book,
      required this.index,
      String searchText = '',
      List<String>? commentators,
      bool openLeftPane = false,
      bool splitedView = true})
      : super(book.title) {
    ///load the text
    text = (() async => await book.text)();

    ///load the links
    links = (() async => await book.links)();

    ///load the table of contents
    tableOfContents = (() async => await book.tableOfContents)();

    ///init the left pane flag
    showLeftPane = ValueNotifier<bool>(openLeftPane);

    ///init the splited view flag
    showSplitedView = ValueNotifier<bool>(
        Settings.getValue('key-splited-view') ?? splitedView);

    //sync the the index with the scroll positions
    positionsListener.itemPositions.addListener(() {
      index = positionsListener.itemPositions.value.first.index;
      selectedIndex.value = null;
    });

    //get the available commentaries
    availableCommentators = getAvailableCommentators(book.links);
    if (searchText != '') {
      searchTextController.text = searchText;
    }
    //set the list of commentaries to show
    if (commentators != null && commentators.isNotEmpty) {
      commentatorsToShow.value = commentators;
    }
  }

  /// Returns a list of available commentators.
  ///
  /// Filters the links in the book to find commentaries and targums,
  /// and returns a list of unique commentaries.
  Future<List<String>> getAvailableCommentators(
      Future<List<Link>> links) async {
    List<Link> filteredLinks = (await links)
        .where((link) =>
            link.connectionType == 'commentary' ||
            link.connectionType == 'targum')
        .toList();
    List<String> paths = filteredLinks.map((e) => e.path2).toList();
    List<String> uniquePaths = paths.toSet().toList();
    List<String> commentatorTitles = uniquePaths
        .map(
          (e) => getTitleFromPath(e),
        )
        .toList();

    // Filter commentators asynchronously
    List<String> availableCommentators = [];
    for (String title in commentatorTitles) {
      if (await FileSystemData.instance.bookExists(title)) {
        availableCommentators.add(title);
      }
    }

    availableCommentators.sort(
      (a, b) => a.compareTo(b),
    );
    return availableCommentators;
  }

  /// Creates a new instance of [TextBookTab] from a JSON map.
  ///
  /// The JSON map should have 'initalIndex', 'title', 'commentaries',
  /// and 'type' keys.
  factory TextBookTab.fromJson(Map<String, dynamic> json) {
    return TextBookTab(
      index: json['initalIndex'],
      book: TextBook(
        title: json['title'],
      ),
      commentators: List<String>.from(json['commentators']),
      splitedView: json['splitedView'],
    );
  }

  /// Converts the [TextBookTab] instance into a JSON map.
  ///
  /// The JSON map contains 'title', 'initalIndex', 'commentaries',
  /// and 'type' keys.
  @override
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'initalIndex': index,
      'commentators': commentatorsToShow.value,
      'splitedView': showSplitedView.value,
      'type': 'TextBookTab'
    };
  }
}
