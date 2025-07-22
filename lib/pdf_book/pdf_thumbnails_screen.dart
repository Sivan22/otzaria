//
// Super simple thumbnails view
//
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class ThumbnailsView extends StatefulWidget {
  const ThumbnailsView(
      {required this.documentRef, required this.controller, super.key});

  final PdfDocumentRef? documentRef;
  final PdfViewerController? controller;

  @override
  State<ThumbnailsView> createState() => _ThumbnailsViewState();
}

class _ThumbnailsViewState extends State<ThumbnailsView>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isManuallyScrolling = false;
  int? _lastScrolledPage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActiveItem());
  }

  @override
  void didUpdateWidget(covariant ThumbnailsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
    }
    if (oldWidget.documentRef != widget.documentRef) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToActiveItem());
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      _scrollToActiveItem();
    }
  }

  void _scrollToActiveItem() {
    if (_isManuallyScrolling || !(widget.controller?.isReady ?? false)) return;
    final currentPage = widget.controller?.pageNumber;
    if (currentPage == null || _lastScrolledPage == currentPage) return;
    if (!_scrollController.hasClients) return;

    const itemExtent = 256.0; // container height + margin
    final viewportHeight = _scrollController.position.viewportDimension;
    final target =
        itemExtent * (currentPage - 1) - (viewportHeight / 2) + (itemExtent / 2);
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _lastScrolledPage = currentPage;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      color: Colors.grey,
      child: widget.documentRef == null
          ? null
          : PdfDocumentViewBuilder(
              documentRef: widget.documentRef!,
              builder: (context, document) => NotificationListener<
                      ScrollNotification>(
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
                    child: ListView.builder(
                      key: const PageStorageKey('pdfThumbnails'),
                      controller: _scrollController,
                      itemCount: document?.pages.length ?? 0,
                      itemBuilder: (context, index) {
                        final isSelected = widget.controller != null &&
                            widget.controller!.isReady &&
                            widget.controller!.pageNumber == index + 1;
                        return Container(
                          margin: const EdgeInsets.all(8),
                          height: 240,
                          decoration: isSelected
                              ? BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                )
                              : null,
                          child: Column(
                            children: [
                              SizedBox(
                                height: 220,
                                child: InkWell(
                                  onTap: () => widget.controller?.goToPage(
                                    pageNumber: index + 1,
                                    anchor: PdfPageAnchor.top,
                                  ),
                                  child: PdfPageView(
                                    document: document,
                                    pageNumber: index + 1,
                                    alignment: Alignment.center,
                                  ),
                                ),
                              ),
                              Text('${index + 1}'),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
            ),
    );
  }
}
