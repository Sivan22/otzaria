/*this class represents the state of the application.
it includes the library, a list of the opened tabs, the current tab, the current view, 
and the some other app settings like dark mode and the seed color*/

import 'dart:math';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:flutter/material.dart';
import 'package:otzaria/data/data.dart';
import 'package:otzaria/data/file_system_data_provider.dart';
import 'package:otzaria/models/library.dart';
import 'package:otzaria/models/tabs.dart';
import 'package:otzaria/models/books.dart';
import 'package:hive/hive.dart';

/// Represents the state of the application.
///
/// It includes the library, a list of the opened tabs, the current tab,
/// the current view, and the some other app settings like dark mode and
/// the seed color.
class AppModel with ChangeNotifier {
  /// The data provider for the application.
  Data data = FileSystemData.instance;

  /// The library of books.
  late Library library;

  /// The list of opened tabs.
  List<OpenedTab> tabs = [];

  /// The index of the current tab.
  int currentTab = 0;

  /// The index of the current view.
  int currentView = 0;

  /// Flag indicating if the app is in dark mode.
  final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(
    Settings.getValue<bool>('key-dark-mode') ?? false,
  );

  /// The color used as seed.
  final ValueNotifier<Color> seedColor = ValueNotifier<Color>(
    ConversionUtils.colorFromString(
        Settings.getValue<String>('key-swatch-color') ?? ('#ff2c1b02')),
  );

  /// Constructs a new AppModel instance.
  ///
  /// This constructor initializes the library and tabs list, and loads the
  /// tabs list from disk.
  AppModel() {
    library = data.getLibrary();

    tabs = List<OpenedTab>.from(
        ((Hive.box(name: 'tabs').get('key-tabs') ?? []) as List)
            .map((e) => OpenedTab.fromJson(e))
            .toList());

    currentTab = Hive.box(name: 'tabs')
        .get('key-current-tab', defaultValue: tabs.length - 1);

    seedColor.addListener(() {
      notifyListeners();
    });
    isDarkMode.addListener(() {
      notifyListeners();
    });
  }

  /// Opens a book in a new tab.
  ///
  /// [book] The book to open.
  /// [index] The index of the book.
  void openBook(Book book, int index) {
    if (book is PdfBook) {
      addTab(PdfBookTab(book, index));
    } else if (book is TextBook) {
      addTab(TextBookTab(book: book, initalIndex: index));
    }
  }

  /// Adds a new tab to the list of opened tabs.
  ///
  /// [tab] The tab to add.
  void addTab(OpenedTab tab) {
    //add the tab after the current tab, or at the beginning if there is no open tab
    tabs.insert(min(currentTab + 1, tabs.length), tab);
    currentTab++;
    notifyListeners();
    saveTabsToDisk();
  }

  /// Closes a tab.
  ///
  /// [tab] The tab to close.
  void closeTab(OpenedTab tab) {
    tabs.remove(tab);
    currentTab = max(currentTab - 1, 0);
    notifyListeners();
    saveTabsToDisk();
  }

  void closeCurrentTab() {
    closeTab(tabs[currentTab]);
  }

  /// Closes all tabs.
  void closeAllTabs() {
    tabs = [];
    currentTab = 0;
    notifyListeners();
    saveTabsToDisk();
  }

  /// Saves the list of tabs and  the current tab index to disk.
  void saveTabsToDisk() {
    Hive.box(name: 'tabs').put("key-tabs", tabs);
    Hive.box(name: 'tabs').put("key-current-tab", currentTab);
  }
}
