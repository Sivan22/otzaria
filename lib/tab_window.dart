import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'library_searcher.dart';
import 'dart:convert';
import 'links_view.dart';
import 'dart:isolate';
import 'package:docx_to_text/docx_to_text.dart';

class TabWindow {
  String title;

  TabWindow(this.title);
}

class BookTabWindow extends TabWindow {
  final String path;
  ValueNotifier<List<String>> commentariesNames = ValueNotifier([]);
  late Future<List<Link>> links;
  late Future<List<TocEntry>> toc;
  late Future<String> data;
  int initalIndex;
  ItemScrollController scrollController = ItemScrollController();
  ScrollOffsetController scrollOffsetController = ScrollOffsetController();
  TextEditingController searchTextController = TextEditingController();
  ItemPositionsListener positionsListener = ItemPositionsListener.create();

  BookTabWindow(this.path, this.initalIndex, {String searchText = ''})
      : super(path.split(Platform.pathSeparator).last) {
    if (searchText != '') {
      searchTextController.text = searchText;
    }
    links = Isolate.run(() async {
      String libraryRootPath = path.split('אוצריא').first;
      return await getAllLinksFromJson(
          '$libraryRootPath${Platform.pathSeparator}links${Platform.pathSeparator}${path.split(Platform.pathSeparator).last}_links.json');
    });
    data = getBookData(path);
    toc = _parseToc(data);
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

class SearchingTabWindow extends TabWindow {
  LibrarySearcher searcher = LibrarySearcher(
    [],
    TextEditingController(),
    ValueNotifier([]),
  );
  final ItemScrollController scrollController = ItemScrollController();

  SearchingTabWindow(
    super.title,
  );
}
