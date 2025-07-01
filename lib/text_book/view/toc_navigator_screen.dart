import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/utils/ref_helper.dart';

class TocViewer extends StatefulWidget {
  const TocViewer({
    super.key,
    required this.scrollController,
    required this.closeLeftPaneCallback,
    required this.focusNode,
  });

  final void Function() closeLeftPaneCallback;
  final ItemScrollController scrollController;
  final FocusNode focusNode;

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

    return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: allEntries.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                0, 0, 10 * allEntries[index].level.toDouble(), 0),
            child: allEntries[index].children.isEmpty
                ? ListTile(
                    title: Text(allEntries[index].fullText),
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
                  )
                : _buildTocItem(allEntries[index], showFullText: true),
          );
        });
  }

  Widget _buildTocItem(TocEntry entry, {bool showFullText = false}) {
    void navigateToEntry() {
      widget.scrollController.scrollTo(
        index: entry.index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
      );
      if (Platform.isAndroid) {
        widget.closeLeftPaneCallback();
      }
    }

    if (entry.children.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(0, 0, 10 * entry.level.toDouble(), 0),
        child: BlocBuilder<TextBookBloc, TextBookState>(
          builder: (context, state) {
            final int? autoIndex = state is TextBookLoaded &&
                    state.selectedIndex == null &&
                    state.visibleIndices.isNotEmpty
                ? closestTocEntryIndex(
                    state.tableOfContents, state.visibleIndices.first)
                : null;
            final bool selected = state is TextBookLoaded &&
                ((state.selectedIndex != null &&
                        state.selectedIndex == entry.index) ||
                    autoIndex == entry.index);
            return ListTile(
              title: Text(entry.text),
              selected: selected,
              selectedColor: Theme.of(context).colorScheme.onSecondaryContainer,
              selectedTileColor:
                  Theme.of(context).colorScheme.secondaryContainer,
              onTap: navigateToEntry,
            );
          },
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.fromLTRB(0, 0, 10 * entry.level.toDouble(), 0),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            initiallyExpanded: entry.level == 1,
            title: BlocBuilder<TextBookBloc, TextBookState>(
              builder: (context, state) {
                final int? autoIndex = state is TextBookLoaded &&
                        state.selectedIndex == null &&
                        state.visibleIndices.isNotEmpty
                    ? closestTocEntryIndex(
                        state.tableOfContents, state.visibleIndices.first)
                    : null;
                final bool selected = state is TextBookLoaded &&
                    ((state.selectedIndex != null &&
                            state.selectedIndex == entry.index) ||
                        autoIndex == entry.index);
                return ListTile(
                  title: Text(showFullText ? entry.fullText : entry.text),
                  selected: selected,
                  selectedColor: Theme.of(context).colorScheme.onSecondary,
                  selectedTileColor:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                  onTap: navigateToEntry,
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
            leading: const Icon(Icons.chevron_right_rounded),
            trailing: const SizedBox.shrink(),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            iconColor: Theme.of(context).colorScheme.primary,
            collapsedIconColor: Theme.of(context).colorScheme.primary,
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entry.children.length,
                itemBuilder: (context, index) {
                  return _buildTocItem(entry.children[index]);
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<TextBookBloc, TextBookState>(
        bloc: context.read<TextBookBloc>(),
        builder: (context, state) {
          if (state is! TextBookLoaded) return const Center();
          return Column(
            children: [
              TextField(
                controller: searchController,
                onChanged: (value) => setState(() {}),
                focusNode: widget.focusNode,
                autofocus: true,
                onSubmitted: (_) {
                  widget.focusNode.requestFocus();
                },
                decoration: InputDecoration(
                  hintText: 'איתור כותרת...',
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
                child: SingleChildScrollView(
                  child: searchController.text.isEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.tableOfContents.length,
                          itemBuilder: (context, index) =>
                              _buildTocItem(state.tableOfContents[index]))
                      : _buildFilteredList(state.tableOfContents, context),
                ),
              ),
            ],
          );
        });
  }
}
