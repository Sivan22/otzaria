import 'package:flutter/material.dart';
import 'dart:io';
import 'package:otzaria/utils/text_manipulation.dart';
import 'dart:math';
import 'package:otzaria/models/search_results.dart';

class FullTextSearcher {
  final List<String> booksToSearch;
  final TextEditingController queryController;
  final ValueNotifier<List<BookTextSearchResult>> searchResults;
  DateTime? searchStarted;
  DateTime? searchFinished;
  ValueNotifier<bool> isSearching = ValueNotifier(false);
  int lineIndex = 0;
  int bookIndex = 0;

  FullTextSearcher(
    this.booksToSearch,
    this.queryController,
    this.searchResults,
  );

  void search() async {
    isSearching.value = true;
    searchResults.value = [];
    searchStarted = DateTime.now();
    lineIndex = 0;
    bookIndex = 0;

    // finish search imidiatly if search string is empty.
    if (queryController.text.isEmpty) {
      isSearching.value = false;
      return;
    }

    for (final entry in booksToSearch) {
      if (FileSystemEntity.isFileSync(entry) && !entry.endsWith('.pdf')) {
        final file = File(entry);
        final contents = await file.readAsLines();
        List<String> address = [];
        lineIndex = 0;

        for (String line in contents) {
          if (!isSearching.value) return;

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
                index: lineIndex,
                query: queryController.text,
                address: stripHtmlIfNeeded(address.join(''))));

            searchFinished = DateTime.now();
            searchResults.notifyListeners();
          }
          lineIndex++;
        }
      }
      bookIndex++;
    }
    isSearching.value = false;
  }
}
