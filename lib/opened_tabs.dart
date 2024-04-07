import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'library_searcher.dart';
import 'dart:convert';
import 'links_view.dart';
import 'dart:isolate';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:pdfrx/pdfrx.dart';

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
  final String path;
  ValueNotifier<List<String>> commentariesToShow = ValueNotifier([]);
  late Future<List<Link>> links;
  late Future<List<TocEntry>> toc;
  late Future<String> data;
  int initalIndex;
  ItemScrollController scrollController = ItemScrollController();
  ScrollOffsetController scrollOffsetController = ScrollOffsetController();
  TextEditingController searchTextController = TextEditingController();
  ItemPositionsListener positionsListener = ItemPositionsListener.create();

  TextBookTab(this.path, this.initalIndex,
      {String searchText = '', List<String>? commentaries})
      : super(path.split(Platform.pathSeparator).last) {
    if (searchText != '') {
      searchTextController.text = searchText;
    }
    if (commentaries != null && commentaries.isNotEmpty) {
      commentariesToShow.value = commentaries;
    }

    links = Isolate.run(() async {
      String libraryRootPath = path.split('אוצריא').first;
      return await getAllLinksFromJson(
          '$libraryRootPath${Platform.pathSeparator}links${Platform.pathSeparator}${path.split(Platform.pathSeparator).last}_links.json');
    });
    data = getBookData(path);
    toc = _parseToc(data);
  }

  @override
  factory TextBookTab.fromJson(Map<String, dynamic> json) {
    return TextBookTab(json['path'], json['initalIndex'],
        commentaries: json['commentaries']
            .map<String>((json) => json.toString())
            .toList());
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'initalIndex': positionsListener.itemPositions.value.isNotEmpty
          ? positionsListener.itemPositions.value.first.index
          : 0,
      'commentaries': commentariesToShow.value,
      'type': 'BookTabWindow'
    };
  }

  Future<List<Link>> getAllLinksFromJson(String path) async {
    try {
      final jsonString = await File(path).readAsString();
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => Link.fromJson(json)).toList();
    } on Exception {
      return [];
    }
  }

  Future<String> getBookData(String path) {
    return Isolate.run(() async {
      File file = File(path);
      if (path.endsWith('.docx')) {
        final bytes = await file.readAsBytes();
        return docxToText(bytes);
      } else {
        return await file.readAsString();
      }
    });
  }

  Future<List<TocEntry>> _parseToc(Future<String> data) async {
    List<String> lines = (await data).split('\n');
    List<TocEntry> toc = [];
    Map<int, TocEntry> parents = {}; // Keep track of parent nodes

    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      if (line.startsWith('<h')) {
        final int level =
            int.parse(line[2]); // Extract heading level (h1, h2, etc.)
        final String text = stripHtmlIfNeeded(line);

        // Create the TocEntry
        TocEntry entry = TocEntry(text: text, index: i, level: level);

        if (level == 1) {
          // If it's an h1, add it as a root node
          toc.add(entry);
          parents[level] = entry;
        } else {
          // Find the parent node based on the previous level
          final TocEntry? parent = parents[level - 1];
          if (parent != null) {
            parent.children.add(entry);
            parents[level] = entry;
          } else {
            // Handle cases where heading levels might be skipped
            print("Warning: Found h$level without a parent h${level - 1}");
            toc.add(entry);
          }
        }
      }
    }

    return toc;
  }
}

class TocEntry {
  final String text;
  final int index;
  final int level;
  List<TocEntry> children = [];

  TocEntry({
    required this.text,
    required this.index,
    this.level = 1,
  });
}

String stripHtmlIfNeeded(String text) {
  return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
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
