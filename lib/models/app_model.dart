/// AppModel is the central state management class for the Otzaria application.
///
/// This class manages:
/// * Library and book data
/// * Tab management and navigation
/// * User preferences and settings
/// * Bookmarks and reading history
/// * Workspaces for organizing multiple reading sessions
/// * Search functionality
///
/// The model uses [ChangeNotifier] to notify listeners of state changes,
/// making it suitable for use with Flutter's Provider pattern.
import 'dart:isolate';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:hive/hive.dart';
import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/models/bookmark.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/library.dart';
import 'package:otzaria/models/tabs.dart';
import 'package:otzaria/models/workspace.dart';
import 'package:otzaria/utils/calendar.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;

class AppModel with ChangeNotifier {
  /// The singleton data repository instance for accessing application data
  DataRepository data = DataRepository.instance;

  /// The filesystem path to the library's root directory
  late String _libraryPath;

  /// Getter for the library path
  String get libraryPath => _libraryPath;

  /// Setter for the library path. Updates settings and reloads the library
  set libraryPath(String path) {
    _libraryPath = path;
    Settings.setValue('key-library-path', path);
    library = data.getLibrary();
    notifyListeners();
  }

  /// Future containing the main library of books
  late Future<Library> library;

  /// Future containing the list of books from Otzar HaChochma
  late Future<List<ExternalBook>> otzarBooks;

  /// Future containing the list of books from HebrewBooks
  late Future<List<Book>> hebrewBooks;

  /// List of currently opened tabs in the application
  List<OpenedTab> tabs = [];

  /// Index of the currently active tab
  int currentTab = 0;

  /// The currently active view/screen in the application
  ValueNotifier<Screens> currentView = ValueNotifier(Screens.library);

  /// List of user-created bookmarks
  late List<Bookmark> bookmarks;

  /// Reading history tracking previously opened books and locations
  late List<Bookmark> history;

  /// List of saved workspaces (collections of opened tabs)
  late List<Workspace> workspaces;

  /// Controls the application's theme mode
  final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(
    Settings.getValue<bool>('key-dark-mode') ?? false,
  );

  /// The primary color used for theming the application
  final ValueNotifier<Color> seedColor = ValueNotifier<Color>(
    ConversionUtils.colorFromString(
        Settings.getValue<String>('key-swatch-color') ?? ('#ff2c1b02')),
  );

  /// Controls the padding size used in the application's UI
  final ValueNotifier<double> paddingSize = ValueNotifier<double>(
      Settings.getValue<double>('key-padding-size') ?? 10);

  /// Controls the default font size used in the application
  final ValueNotifier<double> fontSize =
      ValueNotifier<double>(Settings.getValue<double>('key-font-size') ?? 16);

  /// Controls the default font family used in the application
  final ValueNotifier<String> fontFamily = ValueNotifier<String>(
      Settings.getValue<String>('key-font-family') ?? 'FrankRuhlCLM');

  /// Controls visibility of Otzar HaChochma books in search results
  final ValueNotifier<bool> showOtzarHachochma = ValueNotifier<bool>(
    Settings.getValue<bool>('key-show-otzar-hachochma') ?? false,
  );

  /// Controls visibility of HebrewBooks.org books in search results
  final ValueNotifier<bool> showHebrewBooks = ValueNotifier<bool>(
    Settings.getValue<bool>('key-show-hebrew-books') ?? false,
  );

  /// Master switch for showing/hiding all external books
  final ValueNotifier<bool> showExternalBooks = ValueNotifier<bool>(
    Settings.getValue<bool>('key-show-external-books') ?? false,
  );

  final ValueNotifier<bool> showTeamim = ValueNotifier<bool>(
    Settings.getValue<bool>('key-show-teamim') ?? true,
  );

  /// Controls whether to use fast search functionality
  final ValueNotifier<bool> useFastSearch = ValueNotifier<bool>(
    Settings.getValue<bool>('key-use-fast-search') ?? true,
  );

  /// Focus node for the book locator search field
  FocusNode bookLocatorFocusNode = FocusNode();

//// Controller for the book locator search field
  TextEditingController bookLocatorController = TextEditingController();

  /// Focus node for the reference finder search field
  FocusNode findReferenceFocusNode = FocusNode();

  /// Controller for the reference finder search field
  TextEditingController findReferenceController = TextEditingController();

  /// Creates a new AppModel instance and initializes the application state.
  ///
  /// [libraryPath] specifies the root directory containing the book library.
  ///
  /// The constructor:
  /// * Initializes the library and external book sources
  /// * Loads saved tabs from persistent storage
  /// * Loads bookmarks and reading history
  /// * Loads saved workspaces
  /// * Sets up theme and UI preference listeners
  AppModel(String libraryPath) {
    _libraryPath = libraryPath;
    library = data.getLibrary();
    otzarBooks = data.getOtzarBooks();
    hebrewBooks = data.getHebrewBooks();

    fontFamily.addListener(() => notifyListeners());

    // Load tabs from disk, handle corrupted data gracefully
    try {
      tabs = List<OpenedTab>.from(
          ((Hive.box(name: 'tabs').get('key-tabs', defaultValue: [])) as List)
              .map((e) => OpenedTab.fromJson(e))
              .toList());
    } catch (e) {
      print('error loading tabs from disk: $e');
      Hive.box(name: 'tabs').put('key-tabs', []);
    }

    // Restore the last active tab
    currentTab = Hive.box(name: 'tabs').get('key-current-tab', defaultValue: 0);

    // Set reading view if tabs exist
    if (tabs.isNotEmpty) {
      currentView.value = Screens.reading;
    }

    // Load bookmarks with error handling
    try {
      final List<dynamic> rawBookmarks =
          Hive.box(name: 'bookmarks').get('key-bookmarks') ?? [];
      bookmarks = rawBookmarks.map((e) => Bookmark.fromJson(e)).toList();
    } catch (e) {
      bookmarks = [];
      print('error loading bookmarks from disk: $e');
      Hive.box(name: 'bookmarks').put('key-bookmarks', []);
    }

    // Load reading history with error handling
    try {
      final List<dynamic> rawHistory =
          Hive.box(name: 'history').get('key-history') ?? [];
      history = rawHistory.map((e) => Bookmark.fromJson(e)).toList();
    } catch (e) {
      history = [];
      print('error loading history from disk: $e');
      Hive.box(name: 'history').put('key-history', []);
    }

    // Load workspaces with error handling
    try {
      final List<dynamic> rawWorkspaces =
          Hive.box(name: 'workspaces').get('key-workspaces') ?? [];
      workspaces = rawWorkspaces.map((e) => Workspace.fromJson(e)).toList();
    } catch (e) {
      workspaces = [];
      print('error loading workspaces from disk: $e');
      Hive.box(name: 'workspaces').put('key-workspaces', []);
    }

    seedColor.addListener(() {
      notifyListeners();
    });
    isDarkMode.addListener(() {
      notifyListeners();
    });
  }

  /// Opens a book in a new tab.
  ///
  /// Creates either a [PdfBookTab] or [TextBookTab] depending on the book type.
  /// The new tab is inserted after the current tab.
  ///
  /// [book] The book to open
  /// [index] The page or section index to open to
  /// [openLeftPane] Whether to open the left pane (for TextBooks only)
  void openBook(Book book, int index, {bool openLeftPane = false}) {
    if (book is PdfBook) {
      _addTab(PdfBookTab(book, max(index, 1)));
    } else if (book is TextBook) {
      _addTab(
          TextBookTab(book: book, index: index, openLeftPane: openLeftPane));
    }
    currentView.value = Screens.reading;
  }

  /// Searches for a book by its exact title.
  ///
  /// Returns the first exact match, or the closest match if no exact match is found.
  /// Returns null if no matches are found.
  Future<Book?> findBookByTitle(String title) async {
    final books = await findBooks(title, null);

    if (books.isEmpty) {
      return null;
    }

    final exactMatch = books.firstWhere(
      (book) => book.title == title,
      orElse: () => books.first,
    );

    return exactMatch;
  }

  /// Opens a new search tab with default title "חיפוש"
  void openNewSearchTab() {
    _addTab(SearchingTab('חיפוש', ''));
  }

  /// Internal helper to add a new tab to the tabs list.
  ///
  /// Inserts the tab after the current tab and updates the current tab index.
  void _addTab(OpenedTab tab) {
    tabs.insert(min(currentTab + 1, tabs.length), tab);
    currentTab = min(currentTab + 1, tabs.length - 1);
    notifyListeners();
    saveTabsToDisk();
  }

  /// Opens an existing tab at the specified index.
  ///
  /// Handles both PDF and text books appropriately.
  void openTab(OpenedTab tab, {int index = 1}) {
    if (tab is PdfBookTab) {
      openBook(tab.book, index);
      return;
    } else {
      _addTab(tab);
      currentView.value = Screens.reading;
    }
  }

  /// Closes the specified tab and adds it to history.
  void closeTab(OpenedTab tab) {
    addTabToHistory(tab);
    tabs.remove(tab);
    currentTab = max(currentTab - 1, 0);
    notifyListeners();
    saveTabsToDisk();
  }

  /// Adds a tab's current state to the reading history.
  ///
  /// Handles both PDF and text books, saving their current page/position.
  void addTabToHistory(OpenedTab tab) {
    if (tab is PdfBookTab) {
      int index = tab.pdfViewerController.isReady
          ? tab.pdfViewerController.pageNumber!
          : 1;
      addHistory(
        ref: '${tab.title} עמוד $index',
        book: tab.book,
        index: index,
      );
    }
    if (tab is TextBookTab) {
      final index = tab.positionsListener.itemPositions.value.isEmpty
          ? 0
          : tab.positionsListener.itemPositions.value.first.index;
      (() async => addHistory(
          ref: await utils.refFromIndex(index, tab.tableOfContents),
          book: tab.book,
          index: index))();
    }
  }

  /// Closes the currently active tab
  void closeCurrentTab() {
    closeTab(tabs[currentTab]);
  }

  /// Navigates to the previous tab if available
  void goToPreviousTab() {
    if (currentTab > 0) {
      currentTab--;
      notifyListeners();
    }
  }

  /// Navigates to the next tab if available
  void goToNextTab() {
    if (currentTab < tabs.length - 1) {
      currentTab++;
      notifyListeners();
    }
  }

  /// Closes all open tabs, saving their state to history
  void closeAllTabs() {
    for (final tab in tabs) {
      addTabToHistory(tab);
    }
    tabs = [];
    currentTab = 0;
    notifyListeners();
    saveTabsToDisk();
  }

  /// Closes all tabs except the specified one
  void closeOthers(OpenedTab tab) {
    for (int i = 0; i < tabs.length; i++) {
      if (tabs[i] != tab) {
        addTabToHistory(tabs[i]);
      }
    }
    tabs = [tab];
    currentTab = 0;
    notifyListeners();
    saveTabsToDisk();
  }

  /// Creates a duplicate of the specified tab
  void cloneTab(OpenedTab tab) {
    _addTab(OpenedTab.from(tab));
  }

  /// Moves a tab to a new position in the tabs list
  void moveTab(OpenedTab tab, int newIndex) {
    tabs.remove(tab);
    tabs.insert(
      newIndex,
      tab,
    );
    notifyListeners();
  }

  /// Persists the current tabs state to disk storage
  void saveTabsToDisk() {
    Hive.box(name: 'tabs').put("key-tabs", tabs);
    Hive.box(name: 'tabs').put("key-current-tab", currentTab);
  }

  /// Adds a new bookmark if it doesn't already exist.
  ///
  /// Returns true if the bookmark was added, false if it already existed.
  bool addBookmark(
      {required String ref, required Book book, required int index}) {
    bool bookmarkExists = bookmarks.any((bookmark) =>
        bookmark.ref == ref &&
        bookmark.book.title == book.title &&
        bookmark.index == index);

    if (!bookmarkExists) {
      bookmarks.add(Bookmark(ref: ref, book: book, index: index));
      Hive.box(name: 'bookmarks').put('key-bookmarks', bookmarks);
      return true;
    }
    return false;
  }

  /// Removes a bookmark at the specified index
  void removeBookmark(int index) {
    bookmarks.removeAt(index);
    Hive.box(name: 'bookmarks').put('key-bookmarks', bookmarks);
  }

  /// Removes all bookmarks
  void clearBookmarks() {
    bookmarks.clear();
    Hive.box(name: 'bookmarks').clear();
  }

  /// Adds a new entry to the reading history
  void addHistory(
      {required String ref, required Book book, required int index}) {
    history.insert(0, Bookmark(ref: ref, book: book, index: index));
    Hive.box(name: 'history').put('key-history', history);
  }

  /// Removes a history entry at the specified index
  void removeHistory(int index) {
    history.removeAt(index);
    Hive.box(name: 'history').put('key-history', history);
  }

  /// Clears all reading history
  void clearHistory() {
    history.clear();
    Hive.box(name: 'history').clear();
  }

  /// Switches to a different workspace, saving the current workspace first
  void switchWorkspace(Workspace workspace) {
    saveCurrentWorkspace(getHebrewTimeStamp());
    tabs = workspace.bookmarks
        .map((b) => b.book is PdfBook
            ? PdfBookTab(b.book as PdfBook, b.index)
            : TextBookTab(
                book: b.book as TextBook,
                index: b.index,
                commentators: b.commentatorsToShow))
        .toList();
    currentTab = workspace.currentTab;
    notifyListeners();
    saveTabsToDisk();
  }

  /// Saves the current set of tabs as a new workspace
  void saveCurrentWorkspace(String name) {
    Workspace workspace = Workspace(
      name: name,
      currentTab: currentTab,
      bookmarks: tabs
          .where((t) => t is! SearchingTab)
          .map((t) => Bookmark(
                ref: '',
                book: t is PdfBookTab ? (t).book : (t as TextBookTab).book,
                index: t is PdfBookTab
                    ? (t).pdfViewerController.isReady
                        ? (t).pdfViewerController.pageNumber!
                        : 1
                    : (t as TextBookTab).index,
                commentatorsToShow:
                    t is TextBookTab ? t.commentatorsToShow.value : [],
              ))
          .toList(),
    );
    workspaces.add(workspace);
    saveWorkspacesToDisk();
    notifyListeners();
  }

  /// Persists workspaces to disk storage
  void saveWorkspacesToDisk() {
    Hive.box(name: 'workspaces').put('key-workspaces', workspaces);
  }

  /// Removes a workspace at the specified index
  void removeWorkspace(int index) {
    workspaces.removeAt(index);
    saveWorkspacesToDisk();
    notifyListeners();
  }

  /// Removes all workspaces
  void clearWorkspaces() {
    workspaces.clear();
    Hive.box(name: 'workspaces').clear();
  }

  /// Searches for books based on query text and optional filters.
  ///
  /// [query] The search text to match against book titles
  /// [category] Optional category to filter results
  /// [topics] Optional list of topics to filter results
  ///
  /// Returns a sorted list of books matching the search criteria
  Future<List<Book>> findBooks(String query, Category? category,
      {List<String>? topics}) async {
    final queryWords = query.split(RegExp(r'\s+'));
    var allBooks = category?.getAllBooks() ?? (await library).getAllBooks();
    if (showOtzarHachochma.value) {
      allBooks += await otzarBooks;
    }
    if (showHebrewBooks.value) {
      allBooks += await hebrewBooks;
    }

    // Filter books based on query and topics
    var filteredBooks = allBooks.where((book) {
      final title = book.title.toLowerCase();
      final bookTopics = book.topics.split(', ');

      bool matchesQuery = queryWords.every((word) => title.contains(word));
      bool matchesTopics = topics == null ||
          topics.isEmpty ||
          topics.every((t) => bookTopics.contains(t));

      return matchesQuery && matchesTopics;
    }).toList();

    if (filteredBooks.isEmpty) {
      return [];
    }

    // Prepare data for isolate processing
    final List<Map<String, dynamic>> sortData = filteredBooks
        .asMap()
        .map((i, book) => MapEntry(i, {
              'index': i,
              'title': book.title,
            }))
        .values
        .toList();

    // Sort results by relevance in isolate
    final sortedIndices = getSortedIndices(sortData, query);

    return (await sortedIndices).map((index) => filteredBooks[index]).toList();
  }

  /// Creates reference data for books in the library starting from [startIndex]
  Future<void> createRefsFromLibrary(int startIndex) async {
    data.createRefsFromLibrary(await library, startIndex);
  }

  /// Adds text content to the Tantivy search index
  ///
  /// [start] Starting index in the library
  /// [end] Ending index in the library
  Future<void> addAllTextsToTantivy({int start = 0, int end = 100000}) async {
    data.addAllTextsToTantivy(await library, start: start, end: end);
  }

  /// Reloads the library from disk
  Future<void> refreshLibrary() async {
    libraryPath = Settings.getValue<String>('key-library-path') ?? libraryPath;
    FileSystemData.instance.libraryPath = libraryPath;
    library = data.getLibrary();
    notifyListeners();
  }
}

/// Represents the different screens/views available in the application
enum Screens { library, find, reading, search, favorites, settings }

/// Sorts book indices based on title similarity to query string.
///
/// Uses fuzzy string matching to sort books by relevance to the search query.
/// Runs in a separate isolate to avoid blocking the main thread.
Future<List<int>> getSortedIndices(
    List<Map<String, dynamic>> data, String query) async {
  return await Isolate.run(() {
    List<int> indices = List<int>.generate(data.length, (i) => i);
    indices.sort((a, b) {
      final scoreA = ratio(query, data[a]['title'] as String);
      final scoreB = ratio(query, data[b]['title'] as String);
      return scoreB.compareTo(scoreA);
    });
    return indices;
  });
}
