import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class OutlineView extends StatefulWidget {
  const OutlineView({
    super.key,
    required this.outline,
    required this.controller,
  });

  final List<PdfOutlineNode>? outline;
  final PdfViewerController controller;

  @override
  State<OutlineView> createState() => _OutlineViewState();
}

class _OutlineViewState extends State<OutlineView> {
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final outline = widget.outline;
    if (outline == null || outline.isEmpty) {
      return const Center(
        child: Text('אין תוכן עניינים'),
      );
    }

    return ListenableBuilder(
        listenable: widget.controller,
        builder: (context, snapshot) {
          return Column(
            children: [
              TextField(
                controller: searchController,
                onChanged: (value) => setState(() {}),
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
                child: searchController.text.isEmpty
                    ? _buildOutlineList(outline)
                    : _buildFilteredOutlineList(outline),
              ),
            ],
          );
        });
  }

  Widget _buildOutlineList(List<PdfOutlineNode>? outline) {
    final list = _getOutlineList(outline, 0).toList();
    return SingleChildScrollView(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (context, index) => _buildOutlineItem(list[index]),
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
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredNodes.length,
        itemBuilder: (context, index) =>
            _buildOutlineItem(filteredNodes[index]),
      ),
    );
  }

  Widget _buildOutlineItem(({PdfOutlineNode node, int level}) entry) {
    void navigateToEntry() {
      if (entry.node.dest != null) {
        widget.controller.goTo(widget.controller.calcMatrixFitWidthForPage(
            pageNumber: entry.node.dest?.pageNumber ?? 1));
      }
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 10 * entry.level.toDouble(), 0),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: entry.node.children.isEmpty
            ? InkWell(
                onTap: navigateToEntry,
                child: ListTile(
                  title: Text(entry.node.title),
                ),
              )
            : ExpansionTile(
                key: PageStorageKey(entry),
                initiallyExpanded: entry.level == 0,
                title: InkWell(
                  onTap: navigateToEntry,
                  child: Text(entry.node.title),
                ),
                leading: const Icon(Icons.chevron_right_rounded),
                trailing: const SizedBox.shrink(),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                iconColor: Theme.of(context).colorScheme.primary,
                collapsedIconColor: Theme.of(context).colorScheme.primary,
                children: entry.node.children
                    .map((childNode) => _buildOutlineItem(
                        (node: childNode, level: entry.level + 1)))
                    .toList(),
              ),
      ),
    );
  }

  /// Recursively create outline indent structure
  Iterable<({PdfOutlineNode node, int level})> _getOutlineList(
      List<PdfOutlineNode>? outline, int level) sync* {
    if (outline == null) return;
    for (var node in outline) {
      yield (node: node, level: level);
      yield* _getOutlineList(node.children, level + 1);
    }
  }
}
