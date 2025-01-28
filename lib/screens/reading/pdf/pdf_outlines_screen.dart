import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class OutlineView extends StatelessWidget {
  const OutlineView({
    super.key,
    required this.outline,
    required this.controller,
  });

  final List<PdfOutlineNode>? outline;
  final PdfViewerController controller;

  @override
  Widget build(BuildContext context) {
    if (outline == null || outline!.isEmpty) {
      return const Center(
        child: Text('אין תוכן עניינים'),
      );
    }

    final list = _getOutlineList(outline, 0).toList();
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return InkWell(
          onTap: () {
            if (item.node.dest != null) {
              controller.goToDest(item.node.dest);
            }
          },
          child: Container(
            margin: EdgeInsets.only(
              left: item.level * 16.0 + 8,
              top: 8,
              bottom: 8,
            ),
            child: Text(
              item.node.title,
              softWrap: false,
            ),
          ),
        );
      },
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
