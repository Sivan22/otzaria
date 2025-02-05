import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PageNumberDisplay extends StatefulWidget {
  final PdfViewerController controller;

  const PageNumberDisplay({super.key, required this.controller});

  @override
  State<PageNumberDisplay> createState() => _PageNumberDisplayState();
}

class _PageNumberDisplayState extends State<PageNumberDisplay> {
  late TextEditingController _textController;
  bool _isEditing = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    widget.controller.addListener(_handlePageChange);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        setState(() {
          _isEditing = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    widget.controller.removeListener(_handlePageChange);
    super.dispose();
  }

  void _handlePageChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleSubmitted(String value) {
    final page = int.tryParse(value);
    if (page != null) {
      widget.controller.goToPage(
        pageNumber: page.clamp(1, widget.controller.pages.length),
      );
    }
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.isReady) {
      return SizedBox.shrink();
    }

    final pageNumber = widget.controller.pageNumber ?? 1;
    final pageCount = widget.controller.pages.length;

    return Center(
      child: _isEditing
          ? SizedBox(
              width: 80,
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  isDense: true,
                  hintText: '1-$pageCount',
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: _handleSubmitted,
              ),
            )
          : Center(
              child: Tooltip(
                message: "הזן מספר דף",
                child: InkWell(
                    mouseCursor: SystemMouseCursors.click,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                          _textController.text = pageNumber.toString();
                        });
                        // Ensure the text is selected when editing starts
                        Future.delayed(const Duration(milliseconds: 50), () {
                          _focusNode.requestFocus();
                          _textController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: _textController.text.length,
                          );
                        });
                      },
                      child: Text(
                        '$pageNumber/$pageCount',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    )),
              ),
            ),
    );
  }
}
