import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:otzaria/bookmarks/bloc/bookmark_bloc.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/pdf_book/pdf_page_number_dispaly.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/tabs/models/pdf_tab.dart';
import 'package:otzaria/utils/open_book.dart';
import 'package:otzaria/utils/ref_helper.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import 'pdf_search_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_outlines_screen.dart';
import 'package:otzaria/widgets/password_dialog.dart';
import 'pdf_thumbnails_screen.dart';
import 'package:printing/printing.dart';
import 'package:otzaria/utils/page_converter.dart';

class PdfBookScreen extends StatefulWidget {
  final PdfBookTab tab;

  const PdfBookScreen({
    super.key,
    required this.tab,
  });

  @override
  State<PdfBookScreen> createState() => _PdfBookScreenState();
}

class _PdfBookScreenState extends State<PdfBookScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late final textSearcher = PdfTextSearcher(widget.tab.pdfViewerController)
    ..addListener(_update);

  late TabController _tabController;
  final GlobalKey<State<PdfBookSearchView>> _searchViewKey = GlobalKey();

  void _update() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize tab controller with the search tab selected if there's search text
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.tab.searchText.isNotEmpty ? 1 : 0,
    );
    
    widget.tab.pdfViewerController = PdfViewerController();
    widget.tab.pdfViewerController.addListener(() {
      if (widget.tab.pdfViewerController.isReady) {
        widget.tab.pageNumber = widget.tab.pdfViewerController.pageNumber!;
        () async {
          widget.tab.currentTitle.value = await refFromPageNumber(
              widget.tab.pageNumber =
                  widget.tab.pdfViewerController.pageNumber ?? 1,
              widget.tab.outline.value);
        }();
      }
    });
  }

  @override
  void dispose() {
    textSearcher.removeListener(_update);
    widget.tab.pdfViewerController.removeListener(() {});
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(builder: (context, constrains) {
      final wideScreen = (MediaQuery.of(context).size.width >= 600);
      return Scaffold(
        appBar: AppBar(
          title: ValueListenableBuilder(
              valueListenable: widget.tab.currentTitle,
              builder: (context, value, child) => Center(
                    child: SelectionArea(
                      child: Text(
                        value,
                        style: const TextStyle(fontSize: 17),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )),
          leading: IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'חיפוש וניווט',
            onPressed: () {
              widget.tab.showLeftPane.value = !widget.tab.showLeftPane.value;
            },
          ),
          actions: [
            _buildTextButton(context, widget.tab.book,
                widget.tab.outline.value ?? [], widget.tab.pdfViewerController),
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
                    Provider.of<BookmarkBloc>(context, listen: false)
                        .addBookmark(
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
              Provider.of<SettingsBloc>(context, listen: true).state.isDarkMode
                  ? BlendMode.difference
                  : BlendMode.dst),
          child: PdfViewer.file(
            widget.tab.book.path,
            initialPageNumber: widget.tab.pageNumber,
            passwordProvider: () => passwordDialog(context),
            controller: widget.tab.pdfViewerController,
            params: PdfViewerParams(
              enableTextSelection: true,
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
                () async {
                  widget.tab.currentTitle.value = await refFromPageNumber(
                      widget.tab.pageNumber =
                          widget.tab.pdfViewerController.pageNumber ?? 1,
                      widget.tab.outline.value);
                }();
                if (mounted) {
                  widget.tab.showLeftPane.value = true;
                  // No need for _performAutoSearch anymore - the PdfBookSearchView handles it
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
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRect(
                        child: TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'ניווט'),
                            Tab(text: 'חיפוש'),
                            Tab(text: 'דפים'),
                          ],
                        ),
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
                    controller: _tabController,
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
                          key: _searchViewKey,
                          textSearcher: textSearcher,
                          initialSearchText: widget.tab.searchText,
                          shouldNavigateOnInitialSearch: false, // Prevent jumping to beginning
                        ),
                      ),
                      ValueListenableBuilder(
                        valueListenable: widget.tab.documentRef,
                        builder: (context, documentRef, child) => child!,
                        child: ThumbnailsView(
                            documentRef: widget.tab.documentRef.value,
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

  Widget _buildTextButton(BuildContext context, PdfBook book,
      List<PdfOutlineNode> outline, PdfViewerController controller) {
    return FutureBuilder(
      future: DataRepository.instance.library
          .then((library) => library.findBookByTitle(book.title, TextBook)),
      builder: (context, snapshot) => snapshot.hasData
          ? IconButton(
              icon: const Icon(Icons.article),
              tooltip: 'פתח טקסט',
              onPressed: () async {
                final index = await pdfToTextPage(
                    book, outline, controller.pageNumber ?? 1, context);
                openBook(context, snapshot.data!, index ?? 0, '');
              })
          : const SizedBox.shrink(),
    );
  }
}
