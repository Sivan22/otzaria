import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class OutlineView extends StatefulWidget {
  const OutlineView({
    super.key,
    required this.outline,
    required this.controller,
    required this.focusNode,
  });

  final List<PdfOutlineNode>? outline;
  final PdfViewerController controller;
  final FocusNode focusNode;

  @override
  State<OutlineView> createState() => _OutlineViewState();
}

class _OutlineViewState extends State<OutlineView>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  final _itemScrollController = ItemScrollController();
  List<({PdfOutlineNode node, int level})>? _flattenedOutline;
  bool _isManuallyScrolling = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _flattenedOutline = _flattenOutline(widget.outline, 0);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant OutlineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _flattenedOutline = _flattenOutline(widget.outline, 0);
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
    if (widget.outline != oldWidget.outline) {
      _flattenedOutline = _flattenOutline(widget.outline, 0);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
    _scrollToCurrent();
  }

  void _scrollToCurrent() {
    if (!mounted ||
        !widget.controller.isReady ||
        _isManuallyScrolling ||
        _flattenedOutline == null ||
        !_itemScrollController.isAttached) return;

    final currentPage = widget.controller.pageNumber;
    if (currentPage == null) return;

    int targetIndex = -1;
    for (int i = 0; i < _flattenedOutline!.length; i++) {
      final page = _flattenedOutline![i].node.dest?.pageNumber;
      if (page != null && page <= currentPage) {
        targetIndex = i;
      } else if (page != null && page > currentPage) {
        break;
      }
    }

    if (targetIndex != -1) {
      // Use SchedulerBinding to ensure the scroll happens after the build phase
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && _itemScrollController.isAttached) {
          _itemScrollController.scrollTo(
              index: targetIndex,
              duration: const Duration(milliseconds: 300),
              alignment: 0.5,
              curve: Curves.ease);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final outline = widget.outline;
    if (outline == null || outline.isEmpty) {
      return const Center(
        child: Text('אין תוכן עניינים'),
      );
    }

    return Column(
      key: PageStorageKey(widget.key),
      children: [
        TextField(
          controller: _searchController,
          focusNode: widget.focusNode,
          autofocus: true,
          onChanged: (value) => setState(() {}),
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
            child: _buildList(),
          ),
        ),
      ],
    );
  }

  List<({PdfOutlineNode node, int level})> _flattenOutline(
      List<PdfOutlineNode>? outline, int level) {
    if (outline == null) return [];
    final List<({PdfOutlineNode node, int level})> list = [];
    for (final node in outline) {
      list.add((node: node, level: level));
      if (node.children.isNotEmpty) {
        list.addAll(_flattenOutline(node.children, level + 1));
      }
    }
    return list;
  }

  Widget _buildList() {
    final items = _flattenedOutline;
    if (items == null) return const SizedBox.shrink();

    final filteredNodes = _searchController.text.isEmpty
        ? items
        : items
            .where((item) => item.node.title
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();

    return ScrollablePositionedList.builder(
        itemScrollController: _itemScrollController,
        itemCount: filteredNodes.length,
        itemBuilder: (context, index) => _buildOutlineItem(
            filteredNodes[index].node,
            level: filteredNodes[index].level));
  }

  Widget _buildOutlineItem(PdfOutlineNode node, {int level = 0}) {
    void navigateToEntry(bool isTap) {
      if (isTap) {
        setState(() {
          _isManuallyScrolling = false;
        });
      }
      if (node.dest != null) {
        // --- FIX IS HERE ---
        widget.controller.goToDest(node.dest!);
        // --- END OF FIX ---
      }
    }

    return Padding(
        padding: EdgeInsets.fromLTRB(0, 0, 10 * level.toDouble(), 0),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            title: Text(node.title, overflow: TextOverflow.ellipsis),
            selected: widget.controller.isReady &&
                node.dest?.pageNumber == widget.controller.pageNumber,
            selectedColor: Theme.of(context).colorScheme.onSecondaryContainer,
            selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
            onTap: () => navigateToEntry(true),
            hoverColor: Theme.of(context).hoverColor,
            mouseCursor: SystemMouseCursors.click,
          ),
        ));
  }
}