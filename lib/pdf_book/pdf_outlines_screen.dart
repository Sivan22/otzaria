import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flutter/scheduler.dart';

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
  final TextEditingController searchController = TextEditingController();

  final ScrollController _tocScrollController = ScrollController();
  final Map<PdfOutlineNode, GlobalKey> _tocItemKeys = {};
  bool _isManuallyScrolling = false;
  int? _lastScrolledPage;
  final Map<PdfOutlineNode, bool> _expanded = {};
  final Map<PdfOutlineNode, ExpansionTileController> _controllers = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant OutlineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _tocScrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      _scrollToActiveItem();
    }
  }

  void _ensureParentsOpen(
      List<PdfOutlineNode> nodes, PdfOutlineNode targetNode) {
    final path = _findPath(nodes, targetNode);
    if (path.isEmpty) return;

    // מוצא את הרמה של הצומת היעד
    int targetLevel = _getNodeLevel(nodes, targetNode);

    // אם הצומת ברמה 2 ומעלה (שזה רמה 3 ומעלה בספירה רגילה), פתח את כל ההורים
    if (targetLevel >= 2) {
      for (final node in path) {
        if (node.children.isNotEmpty && _expanded[node] != true) {
          _expanded[node] = true;
          _controllers[node]?.expand();
        }
      }
    }
  }

  int _getNodeLevel(List<PdfOutlineNode> nodes, PdfOutlineNode targetNode,
      [int currentLevel = 0]) {
    for (final node in nodes) {
      if (node == targetNode) {
        return currentLevel;
      }

      final childLevel =
          _getNodeLevel(node.children, targetNode, currentLevel + 1);
      if (childLevel != -1) {
        return childLevel;
      }
    }
    return -1;
  }

  List<PdfOutlineNode> _findPath(
      List<PdfOutlineNode> nodes, PdfOutlineNode targetNode) {
    for (final node in nodes) {
      if (node == targetNode) {
        return [node];
      }

      final subPath = _findPath(node.children, targetNode);
      if (subPath.isNotEmpty) {
        return [node, ...subPath];
      }
    }
    return [];
  }

  void _scrollToActiveItem() {
    if (_isManuallyScrolling || !widget.controller.isReady) return;

    final currentPage = widget.controller.pageNumber;
    if (currentPage == _lastScrolledPage) return;

    PdfOutlineNode? activeNode;

    PdfOutlineNode? findClosestNode(List<PdfOutlineNode> nodes, int page) {
      PdfOutlineNode? bestMatch;
      for (final node in nodes) {
        if (node.dest?.pageNumber != null && node.dest!.pageNumber <= page) {
          bestMatch = node;
          final childMatch = findClosestNode(node.children, page);
          if (childMatch != null) {
            bestMatch = childMatch;
          }
        } else {
          break;
        }
      }
      return bestMatch;
    }

    if (widget.outline != null && currentPage != null) {
      activeNode = findClosestNode(widget.outline!, currentPage);
    }

    if (activeNode != null && widget.outline != null) {
      _ensureParentsOpen(widget.outline!, activeNode);
    }

    // קריאה ל-setState כדי לוודא שהפריט הנכון מודגש לפני הגלילה
    if (mounted) {
      setState(() {});
    }

    if (activeNode == null) {
      _lastScrolledPage = currentPage;
      return;
    }

    // נחכה פריים אחד כדי שה-setState יסיים וה-UI יתעדכן
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isManuallyScrolling) return;

      final key = _tocItemKeys[activeNode];
      final itemContext = key?.currentContext;
      if (itemContext == null) return;

      final itemRenderObject = itemContext.findRenderObject();
      if (itemRenderObject is! RenderBox) return;

      // --- התחלה: החישוב הנכון והבדוק ---
      // זהו החישוב מההצעה של ה-AI השני, מותאם לקוד שלנו.

      final scrollableBox = _tocScrollController.position.context.storageContext
          .findRenderObject() as RenderBox;

      // המיקום של הפריט ביחס ל-viewport של הגלילה
      final itemOffset = itemRenderObject
          .localToGlobal(Offset.zero, ancestor: scrollableBox)
          .dy;

      // גובה ה-viewport (האזור הנראה)
      final viewportHeight = scrollableBox.size.height;

      // גובה הפריט עצמו
      final itemHeight = itemRenderObject.size.height;

      // מיקום היעד המדויק למירוכז
      final target = _tocScrollController.offset +
          itemOffset -
          (viewportHeight / 2) +
          (itemHeight / 2);
      // --- סיום: החישוב הנכון והבדוק ---

      _tocScrollController.animateTo(
        target.clamp(
          0.0,
          _tocScrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      _lastScrolledPage = currentPage;
    });
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
      children: [
        TextField(
          controller: searchController,
          focusNode: widget.focusNode,
          autofocus: true,
          onChanged: (value) => setState(() {}),
          onSubmitted: (_) {
            widget.focusNode.requestFocus();
          },
          decoration: InputDecoration(
            hintText: 'חיפוש סימניה...',
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
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                setState(() {
                  _isManuallyScrolling = true;
                });
              } else if (notification is ScrollEndNotification) {
                setState(() {
                  _isManuallyScrolling = false;
                });
              }
              return false;
            },
            child: searchController.text.isEmpty
                ? _buildOutlineList(outline)
                : _buildFilteredOutlineList(outline),
          ),
        ),
      ],
    );
  }

  Widget _buildOutlineList(List<PdfOutlineNode> outline) {
    return SingleChildScrollView(
      controller: _tocScrollController,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: outline.length,
        itemBuilder: (context, index) =>
            _buildOutlineItem(outline[index], level: 0),
      ),
    );
  }

  Widget _buildFilteredOutlineList(List<PdfOutlineNode>? outline) {
    List<({PdfOutlineNode node, int level})> allNodes = [];
    void getAllNodes(List<PdfOutlineNode>? outline, int level) {
      if (outline == null) return;
      for (var node in outline) {
        allNodes.add((node: node, level: level));
        getAllNodes(node.children, level + 1);
      }
    }

    getAllNodes(widget.outline, 0);

    final filteredNodes = allNodes
        .where((item) => item.node.title.contains(searchController.text))
        .toList();

    return SingleChildScrollView(
      controller: _tocScrollController,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredNodes.length,
        itemBuilder: (context, index) => _buildOutlineItem(
            filteredNodes[index].node,
            level: filteredNodes[index].level),
      ),
    );
  }

  Widget _buildOutlineItem(PdfOutlineNode node, {int level = 0}) {
    final itemKey = _tocItemKeys.putIfAbsent(node, () => GlobalKey());
    void navigateToEntry() {
      setState(() {
        _isManuallyScrolling = false;
        _lastScrolledPage = null;
      });
      if (node.dest != null) {
        widget.controller.goTo(widget.controller
            .calcMatrixFitWidthForPage(pageNumber: node.dest?.pageNumber ?? 1));
      }
    }

    if (node.children.isNotEmpty) {
      final controller =
          _controllers.putIfAbsent(node, () => ExpansionTileController());
      final bool isExpanded = _expanded[node] ?? (level == 0);

      if (controller.isExpanded != isExpanded) {
        if (isExpanded) {
          controller.expand();
        } else {
          controller.collapse();
        }
      }
    }

    return Padding(
      key: itemKey,
      padding: EdgeInsets.fromLTRB(0, 0, 10 * level.toDouble(), 0),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: node.children.isEmpty
            ? Material(
                color: Colors.transparent,
                child: ListTile(
                  title: Text(node.title),
                  selected: widget.controller.isReady &&
                      node.dest?.pageNumber == widget.controller.pageNumber,
                  selectedColor:
                      Theme.of(context).colorScheme.onSecondaryContainer,
                  selectedTileColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  onTap: navigateToEntry,
                  hoverColor: Theme.of(context).hoverColor,
                  mouseCursor: SystemMouseCursors.click,
                ),
              )
            : Material(
                color: Colors.transparent,
                child: ExpansionTile(
                  key: PageStorageKey(node),
                  controller: _controllers.putIfAbsent(
                      node, () => ExpansionTileController()),
                  initiallyExpanded: _expanded[node] ?? (level == 0),
                  onExpansionChanged: (val) {
                    setState(() {
                      _expanded[node] = val;
                    });
                  },
                  // גם לכותרת של הצומת המורחב נוסיף ListTile
                  title: ListTile(
                    title: Text(node.title),
                    selected: widget.controller.isReady &&
                        node.dest?.pageNumber == widget.controller.pageNumber,
                    selectedColor: Theme.of(context).colorScheme.onSecondary,
                    selectedTileColor: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.2),
                    onTap: navigateToEntry,
                    hoverColor: Theme.of(context).hoverColor,
                    mouseCursor: SystemMouseCursors.click,
                    contentPadding: EdgeInsets.zero, // שלא יזיז ימינה
                  ),
                  leading: const Icon(Icons.chevron_right_rounded),
                  trailing: const SizedBox.shrink(),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  iconColor: Theme.of(context).colorScheme.primary,
                  collapsedIconColor: Theme.of(context).colorScheme.primary,
                  children: node.children
                      .map((c) => _buildOutlineItem(c, level: level + 1))
                      .toList(),
                ),
              ),
      ),
    );
  }
}
