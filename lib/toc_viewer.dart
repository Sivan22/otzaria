import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class TocViewer extends StatefulWidget {
  final String data;
  final ItemScrollController scrollController;
  final void Function() closeLeftPaneCallback;

  TocViewer({
    super.key,
    required this.data,
    required this.scrollController,
    required this.closeLeftPaneCallback,
  });

  @override
  State<TocViewer> createState() => _TocViewerState();
}

class _TocViewerState extends State<TocViewer>
    with AutomaticKeepAliveClientMixin<TocViewer> {
  late List<TocEntry> _toc;

  @override
  void initState() {
    super.initState();
    _toc = _parseToc(widget.data);
  }

  List<TocEntry> _parseToc(String data) {
    List<String> lines = data.split('\n');
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      children: _buildTree(_toc),
    );
  }

  List<Widget> _buildTree(List<TocEntry> entries) {
    List<Widget> widgets = [];
    for (final TocEntry entry in entries) {
      if (entry.children.isEmpty) {
        // Leaf node (no children)
        widgets.add(
          ListTile(
            title: Text(entry.text),
            onTap: () {
              widget.scrollController.scrollTo(
                index: entry.index,
                duration: const Duration(milliseconds: 250),
                curve: Curves.ease,
              );
              if (Platform.isAndroid) {
                widget.closeLeftPaneCallback();
              }
            },
          ),
        );
      } else {
        // Parent node with children
        widgets.add(
          ExpansionTile(
            title: Text(entry.text),
            children: _buildTree(entry.children), // Recursively build children
          ),
        );
      }
    }
    return widgets;
  }

  @override
  bool get wantKeepAlive => true;
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
