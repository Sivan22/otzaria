import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_event.dart';
import 'package:otzaria/text_book/text_book_repository.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/links.dart';
import 'package:otzaria/tabs/models/tab.dart';
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
    super.dispose();
  }
}
