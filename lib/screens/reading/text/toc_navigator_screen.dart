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

  TextEditingController searchController = TextEditingController();

  Widget _buildFilteredList(List<TocEntry> entries, BuildContext context) {
    List<TocEntry> allEntries = [];
    void getAllEntries(List<TocEntry> entries) {
      for (final TocEntry entry in entries) {
        allEntries.add(entry);
        getAllEntries(entry.children);
      }
    }

    getAllEntries(entries);
    allEntries = allEntries
        .where((e) => e.text.contains(searchController.text))
        .toList();

    return ListView.builder(itemBuilder: (context, index) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
            0, 0, 10 * allEntries[index].level.toDouble(), 0),
        child: ListTile(
          title: Text(allEntries[index].text),
          onTap: () {
            widget.scrollController.scrollTo(
              index: allEntries[index].index,
              duration: const Duration(milliseconds: 250),
              curve: Curves.ease,
            );
            if (Platform.isAndroid) {
              widget.closeLeftPaneCallback();
            }
          },
        ),
      );
    });
  }

  Widget _buildTocItem(TocEntry entry) {
    if (entry.children.isEmpty) {
      return Padding(
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
      );
    } else {
      return Padding(
        padding: EdgeInsets.fromLTRB(0, 0, 10 * entry.level.toDouble(), 0),
        child: ExpandableNotifier(
          child: ExpandablePanel(
            controller: ExpandableController(initialExpanded: entry.level == 1),
            key: PageStorageKey(entry),
            collapsed: const SizedBox.shrink(),
            header: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
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
            expanded: ListView.builder(itemBuilder: (context, index) {
              return _buildTocItem(entry.children[index]);
            }),
            theme: ExpandableThemeData(
              tapBodyToCollapse: false,
              tapBodyToExpand: false,
              hasIcon: true,
              iconPlacement: ExpandablePanelIconPlacement.left,
              collapseIcon: Icons.keyboard_arrow_down_outlined,
              expandIcon: Icons.chevron_right_rounded,
              iconPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
              iconColor: Theme.of(context).colorScheme.primary,
              tapHeaderToExpand: false,
            ),
            // Recursively build children,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
        future: widget.toc,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Column(
              children: [
                TextField(
                  controller: searchController,
                  onChanged: (value) => setState(() {}),
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'איתור..',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              searchController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: searchController.text.isEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) =>
                              _buildTocItem(snapshot.data![index]))
                      : _buildFilteredList(snapshot.data!, context),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        });
  }
}
