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
  }

  Widget _buildOutlineList(List<PdfOutlineNode> outline) {
    return SingleChildScrollView(
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
    void navigateToEntry() {
      if (node.dest != null) {
        widget.controller.goTo(widget.controller
            .calcMatrixFitWidthForPage(pageNumber: node.dest?.pageNumber ?? 1));
      }
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 10 * level.toDouble(), 0),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: node.children.isEmpty
            ? InkWell(
                onTap: navigateToEntry,
                child: ListTile(
                  title: Text(node.title),
                ),
              )
            : ExpansionTile(
                key: PageStorageKey(node),
                initiallyExpanded: level == 0,
                title: InkWell(
                  onTap: navigateToEntry,
                  child: Text(node.title),
                ),
                leading: const Icon(Icons.chevron_right_rounded),
                trailing: const SizedBox.shrink(),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                iconColor: Theme.of(context).colorScheme.primary,
                collapsedIconColor: Theme.of(context).colorScheme.primary,
                children: node.children
                    .map((childNode) =>
                        _buildOutlineItem(childNode, level: level + 1))
                    .toList(),
              ),
      ),
    );
  }
}
