import 'dart:io';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:otzaria/models/books.dart';

class TocViewer extends StatefulWidget {
  const TocViewer({
    super.key,
    required this.toc,
    required this.scrollController,
    required this.closeLeftPaneCallback,
  });

  final void Function() closeLeftPaneCallback;
  final ItemScrollController scrollController;
  final Future<List<TocEntry>> toc;

  @override
  State<TocViewer> createState() => _TocViewerState();
}

class _TocViewerState extends State<TocViewer>
    with AutomaticKeepAliveClientMixin<TocViewer> {
  @override
  bool get wantKeepAlive => true;

  List<Widget> _buildTree(List<TocEntry> entries, BuildContext context) {
    List<Widget> widgets = [];
    for (final TocEntry entry in entries) {
      if (entry.children.isEmpty) {
        // Leaf node (no children)
        widgets.add(
          Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 10 * entry.level.toDouble(), 0),
            child: ListTile(
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
          ),
        );
      } else {
        // Parent node with children
        widgets.add(
          Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 10 * entry.level.toDouble(), 0),
            child: ExpandableNotifier(
              child: ExpandablePanel(
                controller:
                    ExpandableController(initialExpanded: entry.level == 1),
                key: PageStorageKey(entry),
                collapsed: SizedBox.shrink(),
                header: ListTile(
                  contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
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
                expanded: Column(
                  children: _buildTree(entry.children, context),
                ),
                theme: ExpandableThemeData(
                  tapBodyToCollapse: false,
                  tapBodyToExpand: false,
                  hasIcon: true,
                  iconPlacement: ExpandablePanelIconPlacement.left,
                  collapseIcon: Icons.keyboard_arrow_down_outlined,
                  expandIcon: Icons.chevron_right_rounded,
                  iconPadding: EdgeInsets.fromLTRB(0, 12, 0, 0),
                  iconColor: Theme.of(context).colorScheme.primary,
                  tapHeaderToExpand: false,
                ),
                // Recursively build children,
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
        future: widget.toc,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView(
              shrinkWrap: true,
              children: _buildTree(snapshot.data!, context),
            );
          }
          return const Center(child: CircularProgressIndicator());
        });
  }
}
