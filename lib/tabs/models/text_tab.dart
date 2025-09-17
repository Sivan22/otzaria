import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/text_book_repository.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

/// Represents a tab that contains a text book.
///
/// It contains the book itself and a TextBookBloc that manages all the state
/// and business logic for the text book viewing experience.
class TextBookTab extends OpenedTab {
  /// The text book.
  final TextBook book;

  /// The index of the scrollable list.
  int index;

  /// The initial search text for this tab.
  final String searchText;

  /// The bloc that manages the text book state and logic.
  late final TextBookBloc bloc;

  final ItemScrollController scrollController = ItemScrollController();
  final ItemPositionsListener positionsListener =
      ItemPositionsListener.create();
  // בקרים נוספים עבור תצוגה מפוצלת או רשימות מקבילות
  final ItemScrollController auxScrollController = ItemScrollController();
  final ItemPositionsListener auxPositionsListener =
      ItemPositionsListener.create();
  final ScrollOffsetController mainOffsetController = ScrollOffsetController();
  final ScrollOffsetController auxOffsetController = ScrollOffsetController();

  List<String>? commentators;

  /// Creates a new instance of [TextBookTab].
  ///
  /// The [index] parameter represents the initial index of the item in the scrollable list,
  /// and the [book] parameter represents the text book.
  /// The [searchText] parameter represents the initial search text,
  /// and the [commentators] parameter represents the list of commentaries to show.
  TextBookTab({
    required this.book,
    required this.index,
    this.searchText = '',
    this.commentators,
    bool openLeftPane = false,
    bool splitedView = true,
  }) : super(book.title) {
    print('DEBUG: TextBookTab נוצר עם אינדקס: $index לספר: ${book.title}');
    // Initialize the bloc with initial state
    bloc = TextBookBloc(
      repository: TextBookRepository(
        fileSystem: FileSystemData.instance,
      ),
      initialState: TextBookInitial(
        book,
        index,
        openLeftPane,
        commentators ?? [],
        searchText,
      ),
      scrollController: scrollController,
      positionsListener: positionsListener,
    );
  }

  /// Creates a new instance of [TextBookTab] from a JSON map.
  ///
  /// The JSON map should have 'initalIndex', 'title', 'commentaries',
  /// and 'type' keys.
  factory TextBookTab.fromJson(Map<String, dynamic> json) {
    final bool shouldOpenLeftPane =
        (Settings.getValue<bool>('key-pin-sidebar') ?? false) ||
            (Settings.getValue<bool>('key-default-sidebar-open') ?? false);

    return TextBookTab(
      index: json['initalIndex'],
      book: TextBook(
        title: json['title'],
      ),
      commentators: List<String>.from(json['commentators']),
      splitedView: json['splitedView'],
      openLeftPane: shouldOpenLeftPane,
    );
  }

  /// Converts the [TextBookTab] instance into a JSON map.
  ///
  /// The JSON map contains 'title', 'initalIndex', 'commentaries',
  /// and 'type' keys.
  @override
  Map<String, dynamic> toJson() {
    List<String> commentators = [];
    bool splitedView = false;
    int index = 0;
    if (bloc.state is TextBookLoaded) {
      final loadedState = bloc.state as TextBookLoaded;
      commentators = loadedState.activeCommentators;
      splitedView = loadedState.showSplitView;
      index = loadedState.visibleIndices.first;
    }

    return {
      'title': title,
      'initalIndex': index,
      'commentators': commentators,
      'splitedView': splitedView,
      'type': 'TextBookTab'
    };
  }
}
