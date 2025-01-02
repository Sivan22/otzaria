import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PageNumberDisplay extends StatefulWidget {
  final PdfViewerController controller;

  const PageNumberDisplay({super.key, required this.controller});

  @override
  State<PageNumberDisplay> createState() => _PageNumberDisplayState();
}

class _PageNumberDisplayState extends State<PageNumberDisplay> {
  late TextEditingController _dialogTextController;

  @override
  void initState() {
    super.initState();
    _dialogTextController = TextEditingController();
    widget.controller.addListener(_handlePageChange);
  }

  @override
  void dispose() {
    _dialogTextController.dispose();
    widget.controller.removeListener(_handlePageChange);
    super.dispose();
  }

  void _handlePageChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.isReady) {
      return SizedBox(
        width: 60,
        child: Center(
          child: Text(
            '${widget.controller.pageNumber ?? 1}/${widget.controller.pages.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    final pageNumber = widget.controller.pageNumber;
    final pageCount = widget.controller.pages.length;

    if (pageNumber == null || pageCount == 0) {
      return SizedBox(
        width: 60,
        child: Center(
          child: Text(
            '1/${widget.controller.pages.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    return TextButton(
      onPressed: () => _showPageDialog(context),
      child: Text(
        '$pageNumber/$pageCount',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  void _showPageDialog(BuildContext context) {
    _dialogTextController.clear(); // Clear previous text
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('עבור לדף'),
        content: TextField(
          controller: _dialogTextController,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '1-${widget.controller.pages.length}',
          ),
          onSubmitted: (value) {
            final page = int.tryParse(value);
            if (page != null) {
              widget.controller.goToPage(
                pageNumber: page.clamp(1, widget.controller.pages.length),
              );
              Navigator.pop(dialogContext);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(_dialogTextController.text);
              if (page != null) {
                widget.controller.goToPage(
                  pageNumber: page.clamp(1, widget.controller.pages.length),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('עבור'),
          ),
        ],
      ),
    );
  }
}
