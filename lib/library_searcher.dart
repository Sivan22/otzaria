import 'package:flutter/material.dart';
import 'dart:io';
import 'text_book_search_view.dart';
import 'dart:math';

class LibrarySearcher {
  final List<String> booksToSearch;
  final TextEditingController queryController;
  final ValueNotifier<List<BookTextSearchResult>> searchResults;
  DateTime? searchStarted;
  DateTime? searchFinished;
  ValueNotifier<bool> isSearching = ValueNotifier(false);
  int sectionIndex = 0;
  int bookIndex = 0;

  bool searchInProgress = false;
  LibrarySearcher(
    this.booksToSearch,
    this.queryController,
    this.searchResults,
  );

  void search() async {
    isSearching.value = true;
    searchResults.value = [];
    searchStarted = DateTime.now();
    sectionIndex = 0;
    bookIndex = 0;

    for (final entry in booksToSearch) {
      if (FileSystemEntity.isFileSync(entry) && !entry.endsWith('.pdf')) {
        final file = File(entry);
        final contents = await file.readAsLines();
        List<String> address = [];

        for (String line in contents) {
          if (line.startsWith('<h')) {
            if (address.isNotEmpty &&
                address.any((element) =>
                    element.substring(0, 4) == line.substring(0, 4))) {
              address.removeRange(
                  address.indexWhere((element) =>
                      element.substring(0, 4) == line.substring(0, 4)),
                  address.length);
            }
            address.add(line);
          }
          // get results from clean text
          String section = removeVolwels(stripHtmlIfNeeded(line));
          int index = section.indexOf(queryController.text);
          if (index > 0) {
            searchResults.value.add(BookTextSearchResult(
                path: entry,
                snippet: section.substring(
                    max(0, index - 200),
                    min(section.length - 1,
                        index + queryController.text.length + 200)),
                index: sectionIndex,
                query: queryController.text,
                address: stripHtmlIfNeeded(address.join(''))));

            searchFinished = DateTime.now();
            searchResults.notifyListeners();
          }
          sectionIndex++;
        }
      }
      bookIndex++;
    }
    isSearching.value = false;
  }
}

class BookTextSearchResult extends TextSearchResult {
  final String path;
  BookTextSearchResult(
      {required this.path,
      required String snippet,
      required int index,
      required String query,
      required String address})
      : super(snippet: snippet, index: index, query: query, address: address);
}
