import 'dart:math';

import 'package:flutter/material.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import 'pdf_search_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_outlines_screen.dart';
import '../widgets/password_dialog.dart';
import 'pdf_thumbnails_screen.dart';
import 'package:otzaria/models/tabs.dart';

class PdfBookViewr extends StatefulWidget {
  final PdfBookTab tab;

  const PdfBookViewr({
    super.key,
    required this.tab,
  });

  @override
  State<PdfBookViewr> createState() => _PdfBookViewrState();
}

class _PdfBookViewrState extends State<PdfBookViewr>
    with AutomaticKeepAliveClientMixin<PdfBookViewr> {
  late final textSearcher = PdfTextSearcher(widget.tab.pdfViewerController)
    ..addListener(_update);

  void _update() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    textSearcher.removeListener(_update);
    textSearcher.dispose();
    widget.tab.outline.dispose();
    widget.tab.documentRef.dispose();
    widget.tab.showLeftPane.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'חיפוש וניווט',
          onPressed: () {
            widget.tab.showLeftPane.value = !widget.tab.showLeftPane.value;
          },
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.bookmark_add),
              tooltip: 'הוספת סימניה',
              onPressed: () {
                int index = widget.tab.pdfViewerController.isReady
                    ? widget.tab.pdfViewerController.pageNumber!
                    : 1;
                Provider.of<AppModel>(context, listen: false).addBookmark(
                    ref: '${widget.tab.title} עמוד $index',
                    book: widget.tab.book,
                    index: index);
                // notify user
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('הסימניה נוספה בהצלחה'),
                    ),
                  );
                }
              }),
          IconButton(
            icon: const Icon(
              Icons.zoom_in,
            ),
            tooltip: 'הגדל',
            onPressed: () => widget..tab.pdfViewerController.zoomUp(),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            tooltip: 'הקטן',
            onPressed: () => widget.tab.pdfViewerController.zoomDown(),
          ),
          IconButton(
            icon: const Icon(Icons.first_page),
            tooltip: 'תחילת הספר',
            onPressed: () =>
                widget.tab.pdfViewerController.goToPage(pageNumber: 1),
          ),
          IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'הקודם',
              onPressed: () => widget.tab.pdfViewerController.isReady
                  ? widget.tab.pdfViewerController.goToPage(
                      pageNumber: max(
                          widget.tab.pdfViewerController.pageNumber! - 1, 1))
                  : null),
          IconButton(
            onPressed: () => widget.tab.pdfViewerController.isReady
                ? widget.tab.pdfViewerController.goToPage(
                    pageNumber: min(
                        widget.tab.pdfViewerController.pageNumber! + 1,
                        widget.tab.pdfViewerController.pages.length))
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            tooltip: 'סוף הספר',
            onPressed: () => widget.tab.pdfViewerController.goToPage(
                pageNumber: widget.tab.pdfViewerController.pages.length),
          ),
        ],
      ),
      body: Row(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: ValueListenableBuilder(
              valueListenable: widget.tab.showLeftPane,
              builder: (context, showLeftPane, child) => SizedBox(
                width: showLeftPane ? 300 : 0,
                child: child!,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(1, 0, 4, 0),
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      const TabBar(tabs: [
                        Tab(text: 'ניווט'),
                        Tab(text: 'חיפוש'),
                        Tab(text: 'דפים'),
                      ]),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // NOTE: documentRef is not explicitly used but it indicates that
                            // the document is changed.

                            ValueListenableBuilder(
                              valueListenable: widget.tab.outline,
                              builder: (context, outline, child) => OutlineView(
                                outline: outline,
                                controller: widget.tab.pdfViewerController,
                              ),
                            ),
                            ValueListenableBuilder(
                              valueListenable: widget.tab.documentRef,
                              builder: (context, documentRef, child) => child!,
                              child:
                                  PdfBookSearchView(textSearcher: textSearcher),
                            ),
                            ValueListenableBuilder(
                              valueListenable: widget.tab.documentRef,
                              builder: (context, documentRef, child) => child!,
                              child: ThumbnailsView(
                                  controller: widget.tab.pdfViewerController),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                      Colors.white,
                      Provider.of<AppModel>(context).isDarkMode.value
                          ? BlendMode.difference
                          : BlendMode.dst),
                  child: PdfViewer.file(
                    widget.tab.book.path,
                    initialPageNumber: widget.tab.pageNumber,
                    // PdfViewer.file(
                    //   r"D:\pdfrx\example\assets\hello.pdf",
                    // PdfViewer.uri(
                    //   Uri.parse(
                    //       'https://espresso3389.github.io/pdfrx/assets/assets/PDF32000_2008.pdf'),
                    // PdfViewer.uri(
                    //   Uri.parse(kIsWeb
                    //       ? 'assets/assets/hello.pdf'
                    //       : 'https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf'),
                    // Set password provider to show password dialog
                    passwordProvider: () => passwordDialog(context),
                    controller: widget.tab.pdfViewerController,
                    params: PdfViewerParams(
                      enableTextSelection: true,
                      maxScale: 8,
                      // code to display pages horizontally
                      // layoutPages: (pages, params) {
                      //   final height = pages.fold(
                      //           templatePage.height,
                      //           (prev, page) => max(prev, page.height)) +
                      //       params.margin * 2;
                      //   final pageLayouts = <Rect>[];
                      //   double x = params.margin;
                      //   for (var page in pages) {
                      //     page ??= templatePage; // in case the page is not loaded yet
                      //     pageLayouts.add(
                      //       Rect.fromLTWH(
                      //         x,
                      //         (height - page.height) / 2, // center vertically
                      //         page.width,
                      //         page.height,
                      //       ),
                      //     );
                      //     x += page.width + params.margin;
                      //   }
                      //   return PdfPageLayout(
                      //     pageLayouts: pageLayouts,
                      //     documentSize: Size(x, height),
                      //   );
                      // },
                      //
                      // Scroll-thumbs example
                      //
                      viewerOverlayBuilder: (context, size) => [
                        // Show vertical scroll thumb on the right; it has page number on it
                        PdfViewerScrollThumb(
                          controller: widget.tab.pdfViewerController,
                          orientation: ScrollbarOrientation.right,
                          thumbSize: const Size(40, 25),
                          thumbBuilder:
                              (context, thumbSize, pageNumber, controller) =>
                                  Container(
                            color: Colors.black,
                            child: Center(
                              child: Text(
                                pageNumber.toString(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        // Just a simple horizontal scroll thumb on the bottom
                        PdfViewerScrollThumb(
                          controller: widget.tab.pdfViewerController,
                          orientation: ScrollbarOrientation.bottom,
                          thumbSize: const Size(80, 5),
                          thumbBuilder:
                              (context, thumbSize, pageNumber, controller) =>
                                  Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                      //
                      // Loading progress indicator example
                      //
                      loadingBannerBuilder:
                          (context, bytesDownloaded, totalBytes) => Center(
                        child: CircularProgressIndicator(
                          value: totalBytes != null
                              ? bytesDownloaded / totalBytes
                              : null,
                          backgroundColor: Colors.grey,
                        ),
                      ),
                      //
                      // Link handling example
                      //

                      linkWidgetBuilder: (context, link, size) => Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            if (link.url != null) {
                              navigateToUrl(link.url!);
                            } else if (link.dest != null) {
                              widget.tab.pdfViewerController
                                  .goToDest(link.dest);
                            }
                          },
                          hoverColor: Colors.blue.withOpacity(0.2),
                        ),
                      ),
                      pagePaintCallbacks: [
                        textSearcher.pageTextMatchPaintCallback
                      ],
                      onDocumentChanged: (document) async {
                        if (document == null) {
                          widget.tab.documentRef.value = null;
                          widget.tab.outline.value = null;
                        }
                      },
                      onViewerReady: (document, controller) async {
                        widget.tab.documentRef.value = controller.documentRef;
                        widget.tab.outline.value = await document.loadOutline();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> navigateToUrl(Uri url) async {
    if (await shouldOpenUrl(context, url)) {
      await launchUrl(url);
    }
  }

  Future<bool> shouldOpenUrl(BuildContext context, Uri url) async {
    final result = await showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('לעבור לURL?'),
          content: SelectionArea(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'האם לעבור לכתובת הבאה\n'),
                  TextSpan(
                    text: url.toString(),
                    style: const TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ביטול'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('עבור'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  bool get wantKeepAlive => true;
}
