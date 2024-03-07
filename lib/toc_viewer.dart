// a widget that takes an html strings array, finds all the headings, and displays it in a listview. on pressed the scrollcontroller scrolls to the index of the heading.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class TocViewer extends StatefulWidget {
  final String data;
  final ItemScrollController scrollController;
  late List<TocEntry> toc;
  final void Function() closeLeftPaneCallback;

  TocViewer({
    super.key,
    required this.data,
    required this.scrollController,
    required this.closeLeftPaneCallback,
  }) {
    final List<String> data = this.data.split('\n');
    toc = [];
    int index = 0;
    for (String line in data) {
      if (line.startsWith('<h')) {
        toc.add(TocEntry(text: line, index: index));
      }
      index++;
    }
  }

  @override
  State<TocViewer> createState() => _TocViewerState();
}

class _TocViewerState extends State<TocViewer>
    with AutomaticKeepAliveClientMixin<TocViewer> {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView.builder(
      itemCount: widget.toc.length,
      itemBuilder: (context, index) => ListTile(
        title: Text((stripHtmlIfNeeded(widget.toc[index].text))),
        onTap: () {
          widget.scrollController.scrollTo(
              index: widget.toc[index].index,
              duration: const Duration(milliseconds: 250),
              curve: Curves.ease);
          if (Platform.isAndroid) {
            widget.closeLeftPaneCallback();
          }
        },
      ),
    );
  }

  @override
  get wantKeepAlive => true;
}

class TocEntry {
  final String text;
  final int index;
  TocEntry({required this.text, required this.index});
}

String stripHtmlIfNeeded(String text) {
  return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
}
