import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/text_book/bloc/text_book_event.dart'; // <--- השורה שהוספתי
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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
  final _searchController = TextEditingController();
  final _itemScrollController = ItemScrollController();
  bool _isManuallyScrolling = false;

  @override
  bool get wantKeepAlive => true;

  List<({TocEntry entry, int level})> _flattenToc(
      List<TocEntry> entries, int level) {
    final List<({TocEntry entry, int level})> list = [];
    for (final entry in entries) {
      list.add((entry: entry, level: level));
      if (entry.children.isNotEmpty) {
        list.addAll(_flattenToc(entry.children, level + 1));
      }
    }
    return list;
  }

  void _scrollToCurrent(TextBookLoaded state) {
    if (_isManuallyScrolling || !_itemScrollController.isAttached) return;

    final flattenedToc = _flattenToc(state.tableOfContents, 0);
    final currentContentIndex =
        state.selectedIndex ?? state.visibleIndices.first;

    int targetTocIndex = -1;
    for (int i = 0; i < flattenedToc.length; i++) {
      if (flattenedToc[i].entry.index <= currentContentIndex) {
        targetTocIndex = i;
      } else {
        break;
      }
    }

    if (targetTocIndex != -1) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && _itemScrollController.isAttached) {
          _itemScrollController.scrollTo(
            index: targetTocIndex,
            duration: const Duration(milliseconds: 300),
            alignment: 0.5,
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Widget _buildTocItem(TocEntry entry, int level, bool isSelected) {
    void navigateToEntry(bool isTap) {
      if (isTap) {
        setState(() {
          _isManuallyScrolling = false;
        });
      }
      widget.scrollController.scrollTo(
        index: entry.index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
      );
      if (Platform.isAndroid || Platform.isIOS) {
        context.read<TextBookBloc>().add(const ToggleLeftPane(false));
      }
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 10.0 * level, 0),
      child: ListTile(
        title: Text(entry.text, overflow: TextOverflow.ellipsis),
        selected: isSelected,
        selectedColor: Theme.of(context).colorScheme.onSecondaryContainer,
        selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
        onTap: () => navigateToEntry(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<TextBookBloc, TextBookState>(builder: (context, state) {
      if (state is! TextBookLoaded) return const Center();

      _scrollToCurrent(state);

      final flattenedToc = _flattenToc(state.tableOfContents, 0);

      final filteredToc = _searchController.text.isEmpty
          ? flattenedToc
          : flattenedToc
              .where((item) => item.entry.text
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()))
              .toList();

      final currentContentIndex =
          state.selectedIndex ?? state.visibleIndices.first;

      TocEntry? currentTocEntry;
      if (flattenedToc.isNotEmpty) {
        for (int i = flattenedToc.length - 1; i >= 0; i--) {
          if (flattenedToc[i].entry.index <= currentContentIndex) {
            currentTocEntry = flattenedToc[i].entry;
            break;
          }
        }
      }

      return Column(
        key: PageStorageKey(widget.key),
        children: [
          TextField(
            controller: _searchController,
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
                        _searchController.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollStartNotification>(
              onNotification: (notification) {
                if (notification.dragDetails != null) {
                  setState(() {
                    _isManuallyScrolling = true;
                  });
                }
                return false;
              },
              child: ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemCount: filteredToc.length,
                  itemBuilder: (context, index) {
                    final item = filteredToc[index];
                    bool isSelected = item.entry == currentTocEntry;
                    return _buildTocItem(item.entry, item.level, isSelected);
                  }),
            ),
          ),
        ],
      );
    });
  }
}