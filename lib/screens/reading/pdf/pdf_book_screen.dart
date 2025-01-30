import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/tabs/pdf_tab.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import 'package:otzaria/widgets/page_number_dispaly.dart';
import 'pdf_search_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_outlines_screen.dart';
import 'package:otzaria/widgets/password_dialog.dart';
import 'pdf_thumbnails_screen.dart';
import 'package:otzaria/models/tabs/tabs.dart';
import 'package:printing/printing.dart';
import 'package:otzaria/utils/page_converter.dart';

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
    widget.tab.outline.dispose();
    widget.tab.documentRef.dispose();
    widget.tab.showLeftPane.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(builder: (context, constrains) {
      final wideScreen = (MediaQuery.of(context).size.width >= 600);
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
            FutureBuilder(
                future: (context.read<AppModel>().library.then((library) =>
                    library.findBookByTitle(widget.tab.title, TextBook))),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                      onPressed: () async {
                        final appModel = context.read<AppModel>();
                        final textBook = await appModel.library.then(
                            (library) => library.findBookByTitle(
                                widget.tab.title, TextBook));

                        if (textBook != null) {
                          final currentPage =
                              widget.tab.pdfViewerController.pageNumber ?? 0;
                          final textIndex = await pdfToTextPage(
                              // ignore: use_build_context_synchronously
                              widget.tab.title,
                              currentPage,
                              context);

                          if (textIndex != null) {
                            appModel.openBook(textBook, textIndex);
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.text_snippet,
                      ),
                      tooltip: 'פתח ספר טקסט');
                }),
            IconButton(
              icon: const Icon(
                Icons.bookmark_add,
              ),
              tooltip: 'הוספת סימניה',
              onPressed: () {
                int index = widget.tab.pdfViewerController.isReady
                    ? widget.tab.pdfViewerController.pageNumber!
                    : 1;
                bool bookmarkAdded =
                    Provider.of<AppModel>(context, listen: false).addBookmark(
                        ref: '${widget.tab.title} עמוד $index',
                        book: widget.tab.book,
                        index: index);
                // notify user
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(bookmarkAdded
                          ? 'הסימניה נוספה בהצלחה'
                          : 'הסימניה כבר קיימת'),
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.zoom_in,
              ),
              tooltip: 'הגדל',
              onPressed: () => widget.tab.pdfViewerController.zoomUp(),
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              tooltip: 'הקטן',
              onPressed: () => widget.tab.pdfViewerController.zoomDown(),
            ),
            if (wideScreen)
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
            PageNumberDisplay(controller: widget.tab.pdfViewerController),
            IconButton(
              onPressed: () => widget.tab.pdfViewerController.isReady
                  ? widget.tab.pdfViewerController.goToPage(
                      pageNumber: min(
                          widget.tab.pdfViewerController.pageNumber! + 1,
                          widget.tab.pdfViewerController.pages.length))
                  : null,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'הבא',
            ),
            if (wideScreen)
              IconButton(
                icon: const Icon(Icons.last_page),
                tooltip: 'סוף הספר',
                onPressed: () => widget.tab.pdfViewerController.goToPage(
                    pageNumber: widget.tab.pdfViewerController.pages.length),
              ),
            IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'שיתוף',
                onPressed: () async {
                  await Printing.sharePdf(
                    bytes: File(widget.tab.book.path).readAsBytesSync(),
                  );
                }),
          ],
        ),
        body: ColorFiltered(
          colorFilter: ColorFilter.mode(
              Colors.white,
              Provider.of<AppModel>(context).isDarkMode.value
                  ? BlendMode.difference
                  : BlendMode.dst),
          child: PdfViewer.file(
            widget.tab.book.path,
            initialPageNumber: widget.tab.pageNumber,
            passwordProvider: () => passwordDialog(context),
            controller: widget.tab.pdfViewerController,
            params: PdfViewerParams(
              //enableTextSelection: true,
              maxScale: 10,
              onInteractionStart: (_) {
                if (!widget.tab.pinLeftPane.value) {
                  widget.tab.showLeftPane.value = false;
                }
              },
              viewerOverlayBuilder: (context, size, handleLinkTap) => [
                PdfViewerScrollThumb(
                  controller: widget.tab.pdfViewerController,
                  orientation: ScrollbarOrientation.right,
                  thumbSize: const Size(40, 25),
                  thumbBuilder: (context, thumbSize, pageNumber, controller) =>
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
                PdfViewerScrollThumb(
                  controller: widget.tab.pdfViewerController,
                  orientation: ScrollbarOrientation.bottom,
                  thumbSize: const Size(80, 5),
                  thumbBuilder: (context, thumbSize, pageNumber, controller) =>
                      Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                _buildLeftPane(),
              ],
              loadingBannerBuilder: (context, bytesDownloaded, totalBytes) =>
                  Center(
                child: CircularProgressIndicator(
                  value:
                      totalBytes != null ? bytesDownloaded / totalBytes : null,
                  backgroundColor: Colors.grey,
                ),
              ),
              linkWidgetBuilder: (context, link, size) => Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    if (link.url != null) {
                      navigateToUrl(link.url!);
                    } else if (link.dest != null) {
                      widget.tab.pdfViewerController.goToDest(link.dest);
                    }
                  },
                  hoverColor: Colors.blue.withOpacity(0.2),
                ),
              ),
              pagePaintCallbacks: [textSearcher.pageTextMatchPaintCallback],
              onDocumentChanged: (document) async {
                if (document == null) {
                  widget.tab.documentRef.value = null;
                  widget.tab.outline.value = null;
                }
              },
              onViewerReady: (document, controller) async {
                widget.tab.documentRef.value = controller.documentRef;
                widget.tab.outline.value = await document.loadOutline();
                if (mounted) {
                  widget.tab.showLeftPane.value = true;
                }
              },
            ),
          ),
        ),
      );
    });
  }

  AnimatedSize _buildLeftPane() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: ValueListenableBuilder(
        valueListenable: widget.tab.showLeftPane,
        builder: (context, showLeftPane, child) => SizedBox(
          width: showLeftPane ? 300 : 0,
          child: child!,
        ),
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(1, 0, 4, 0),
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: TabBar(
                          tabs: [
                            Tab(text: 'ניווט'),
                            Tab(text: 'חיפוש'),
                            Tab(text: 'דפים'),
                          ],
                        ),
                      ),
                      ValueListenableBuilder(
                        valueListenable: widget.tab.pinLeftPane,
                        builder: (context, pinLeftPanel, child) =>
                            MediaQuery.of(context).size.width < 600
                                ? const SizedBox.shrink()
                                : IconButton(
                                    onPressed: () {
                                      widget.tab.pinLeftPane.value =
                                          !widget.tab.pinLeftPane.value;
                                    },
                                    icon: const Icon(Icons.push_pin),
                                    isSelected: pinLeftPanel,
                                  ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
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
                          child: PdfBookSearchView(
                            textSearcher: textSearcher,
                            searchTextController: widget.tab.searchController,
                          ),
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
