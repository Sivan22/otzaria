import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:otzaria/bloc/text_book/text_book_bloc.dart';
import 'package:otzaria/bloc/text_book/text_book_event.dart';
import 'package:otzaria/bloc/text_book/text_book_repository.dart';
import 'package:otzaria/bloc/text_book/text_book_state.dart';
import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/links.dart';
import 'package:otzaria/models/tabs/tab.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// Represents a tab that contains a text book.
///
/// It contains the book itself and a TextBookBloc that manages all the state
/// and business logic for the text book viewing experience.
class TextBookTab extends OpenedTab {
  /// The text book.
  final TextBook book;

  /// The index of the scrollable list.
  int index;

  /// The bloc that manages the text book state and logic.
  late final TextBookBloc bloc;

  /// The split controller.
  final MultiSplitViewController splitController =
      MultiSplitViewController(areas: Area.weights([0.4, 0.6]));

  // Getters that delegate to bloc state
  Future<String> get text => bloc.state.book.text;
  Future<List<Link>> get links => bloc.state.book.links;
  Future<List<TocEntry>> get tableOfContents => bloc.state.book.tableOfContents;
  Future<List<String>> get availableCommentators async {
    final repository = TextBookRepository(fileSystem: FileSystemData.instance);
    final links = await bloc.state.book.links;
    return repository.getAvailableCommentators(links);
  }

  ValueNotifier<int?> get selectedIndex =>
      ValueNotifier(bloc.state.selectedIndex);
  ValueNotifier<List<String>> get commentatorsToShow =>
      ValueNotifier(bloc.state.activeCommentators);
  double get textFontSize => bloc.state.fontSize;
  set textFontSize(double value) => bloc.add(UpdateFontSize(value));
  ValueNotifier<bool> get showLeftPane =>
      ValueNotifier(bloc.state.showLeftPane);
  ValueNotifier<bool> get pinLeftPane => ValueNotifier(bloc.state.pinLeftPane);
  ValueNotifier<bool> get showSplitedView =>
      ValueNotifier(bloc.state.showSplitView);
  ValueNotifier<bool> get removeNikud => ValueNotifier(bloc.state.removeNikud);
  ItemScrollController get scrollController => bloc.state.scrollController;
  ScrollOffsetController get scrollOffsetController =>
      bloc.state.scrollOffsetController;
  ItemPositionsListener get positionsListener => bloc.state.positionsListener;
  TextEditingController get searchTextController =>
      TextEditingController(text: bloc.state.searchText);

  /// Creates a new instance of [TextBookTab].
  ///
  /// The [index] parameter represents the initial index of the item in the scrollable list,
  /// and the [book] parameter represents the text book.
  /// The [searchText] parameter represents the initial search text,
  /// and the [commentators] parameter represents the list of commentaries to show.
  TextBookTab({
    required this.book,
    required this.index,
    String searchText = '',
    List<String>? commentators,
    bool openLeftPane = false,
    bool splitedView = true,
  }) : super(book.title) {
    // Initialize the bloc with initial state
    bloc = TextBookBloc(
      repository: TextBookRepository(
        fileSystem: FileSystemData.instance,
      ),
      initialState: TextBookState.initial(
        book: book,
        index: index,
        showLeftPane: openLeftPane,
        splitView: Settings.getValue('key-splited-view') ?? splitedView,
        commentators: commentators,
      ),
    );
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
      'commentators': bloc.state.activeCommentators,
      'splitedView': bloc.state.showSplitView,
      'type': 'TextBookTab'
    };
  }

  @override
  void dispose() {
    bloc.close();
    selectedIndex.dispose();
    commentatorsToShow.dispose();
    showLeftPane.dispose();
    pinLeftPane.dispose();
    showSplitedView.dispose();
    removeNikud.dispose();
    searchTextController.dispose();
    super.dispose();
  }
}
