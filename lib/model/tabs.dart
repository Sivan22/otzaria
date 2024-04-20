/* this is a class that will hold all the tabs that have been opened */

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:otzaria/data/file_system_data.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:isolate';
import 'package:pdfrx/pdfrx.dart';
import 'package:otzaria/model/links.dart';
import 'package:otzaria/model/library_searcher.dart';
import 'package:otzaria/model/books.dart';

class OpenedTab {
  String title;

  OpenedTab(this.title);

  factory OpenedTab.fromJson(Map<String, dynamic> json) {
    String type = json['type'];
    if (type == 'BookTabWindow') {
      return TextBookTab.fromJson(json);
    } else if (type == 'SearchingTabWindow') {
      return SearchingTab.fromJson(json);
    }
    return PdfBookTab.fromJson(json);
  }
}

class PdfBookTab extends OpenedTab {
  final String path;
  final int pageNumber;
  final PdfViewerController pdfViewerController = PdfViewerController();

  PdfBookTab(this.path, this.pageNumber)
      : super(path.split(Platform.pathSeparator).last);

  @override
  factory PdfBookTab.fromJson(Map<String, dynamic> json) {
    return PdfBookTab(json['path'], json['pageNumber']);
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'pageNumber':
          (pdfViewerController.isReady ? pdfViewerController.pageNumber : 0),
      'type': 'PdfPageTab'
    };
  }
}

class TextBookTab extends OpenedTab {
  late Book book;
  late Future<String> bookData;
  late Future<List<Link>> links;
  late Future<List<TocEntry>> toc;
  late Future<List<Book>> availableCommentators;
  ValueNotifier<List<Book>> commentariesToShow = ValueNotifier([]);
  int initalIndex;
  ItemScrollController scrollController = ItemScrollController();
  ScrollOffsetController scrollOffsetController = ScrollOffsetController();
  TextEditingController searchTextController = TextEditingController();
  ItemPositionsListener positionsListener = ItemPositionsListener.create();

  TextBookTab(this.initalIndex,
      {required String title, String searchText = '', List<Book>? commentaries})
      : super(title) {
    book = Book(
      title: title,
    );
    bookData = book.text;
    links = book.links;
    toc = book.tableOfContents;
    availableCommentators = getAvailableCommentators(book.links);
    if (searchText != '') {
      searchTextController.text = searchText;
    }
    if (commentaries != null && commentaries.isNotEmpty) {
      commentariesToShow.value = commentaries;
    }
  }
  Future<List<Book>> getAvailableCommentators(Future<List<Link>> links) async {
    List<Link> filteredLinks = (await links)
        .where((link) =>
            link.connectionType == 'commentary' ||
            link.connectionType == 'targum')
        .toList();
    List<String> paths = filteredLinks.map((e) => e.path2).toList();
    List<String> uniquePaths = paths.toSet().toList();
    uniquePaths.sort();
    List<Book> uniqueCommentaries = uniquePaths
        .map((e) => Book(
              title: getTitleFromPath(e),
            ))
        .toList();
    return uniqueCommentaries;
  }

  Future<Map<String, String>> cacheCommentators(
      Future<List<Book>> availableCommentators) async {
    List<Book> availableCommentatorsList = await availableCommentators;
    Map<String, String> availableCommentatorsData = {};
    for (int av = 0; av < availableCommentatorsList.length; av++) {
      availableCommentatorsData[availableCommentatorsList[av].title] =
          await availableCommentatorsList[av].text;
    }
    return availableCommentatorsData;
  }

  @override
  factory TextBookTab.fromJson(Map<String, dynamic> json) {
    return TextBookTab(json['initalIndex'],
        title: json['title'],
        commentaries: json['commentaries']
            .map<Book>((json) => Book(title: json.toString()))
            .toList());
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'initalIndex': positionsListener.itemPositions.value.isNotEmpty
          ? positionsListener.itemPositions.value.first.index
          : 0,
      'commentaries': commentariesToShow.value,
      'type': 'BookTabWindow'
    };
  }
}

class SearchingTab extends OpenedTab {
  LibrarySearcher searcher = LibrarySearcher(
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
