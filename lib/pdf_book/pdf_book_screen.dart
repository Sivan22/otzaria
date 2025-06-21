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
    ..addListener(_onTextSearcherUpdated);
  TabController? _leftPaneTabController;
  int _currentLeftPaneTabIndex = 0;
  final FocusNode _searchFieldFocusNode = FocusNode();

  void _ensureSearchTabIsActive() {
    if (_leftPaneTabController != null && _leftPaneTabController!.index != 1) {
      _leftPaneTabController!.animateTo(1);
    }
    _searchFieldFocusNode.requestFocus();
  }

  late TabController _tabController;
  final GlobalKey<State<PdfBookSearchView>> _searchViewKey = GlobalKey();
  int? _lastProcessedSearchSessionId;

  void _onTextSearcherUpdated() {
    // Get the current search term from the controller
    String currentSearchTerm = widget.tab.searchController.text;

    // Capture the persisted index from the tab *before* any updates from the current textSearcher state
    int? persistedIndexFromTab = widget.tab.pdfSearchCurrentMatchIndex;

    // Update the tab's state with the latest from the textSearcher
    widget.tab.searchText = currentSearchTerm;
    widget.tab.pdfSearchMatches = List.from(textSearcher.matches); // Ensure matches are saved
    widget.tab.pdfSearchCurrentMatchIndex = textSearcher.currentIndex;

    // Standard UI update
    if (mounted) {
      setState(() {});
    }

    // Determine if this is a new search execution vs. just a navigation within existing results
    bool isNewSearchExecution = (_lastProcessedSearchSessionId != textSearcher.searchSession);
    if (isNewSearchExecution) {
      _lastProcessedSearchSessionId = textSearcher.searchSession;
    }

    // Logic to restore currentIndex only on a new search execution, if applicable
    if (isNewSearchExecution &&
        currentSearchTerm.isNotEmpty &&
        textSearcher.matches.isNotEmpty &&
        persistedIndexFromTab != null &&
        persistedIndexFromTab >= 0 &&
        persistedIndexFromTab < textSearcher.matches.length &&
        textSearcher.currentIndex != persistedIndexFromTab) {
      textSearcher.goToMatchOfIndex(persistedIndexFromTab);
      // This call to goToMatchOfIndex will trigger _onTextSearcherUpdated again.
      // In that subsequent call, isNewSearchExecution will be false (as _lastProcessedSearchSessionId
      // will match textSearcher.searchSession), preventing an infinite loop.
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
    widget.tab.pdfViewerController.addListener(_onPdfViewerControllerUpdate);

    if (widget.tab.searchText.isNotEmpty) {
      _currentLeftPaneTabIndex = 1; // Index for "Search" tab
    } else {
      _currentLeftPaneTabIndex = 0; // Default to "Navigation"
    }

    _leftPaneTabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _currentLeftPaneTabIndex,
    );
    if (_currentLeftPaneTabIndex == 1) {
      _searchFieldFocusNode.requestFocus();
    }
    _leftPaneTabController!.addListener(() {
      if (_currentLeftPaneTabIndex != _leftPaneTabController!.index) {
        setState(() {
          _currentLeftPaneTabIndex = _leftPaneTabController!.index;
        });
        if (_leftPaneTabController!.index == 1) {
          _searchFieldFocusNode.requestFocus();
        }
      }
    });
  }

  void _onPdfViewerControllerUpdate() {
    if (widget.tab.pdfViewerController.isReady) {
      widget.tab.pageNumber = widget.tab.pdfViewerController.pageNumber!;
      () async {
        widget.tab.currentTitle.value = await refFromPageNumber(
            widget.tab.pageNumber =
                widget.tab.pdfViewerController.pageNumber ?? 1,
            widget.tab.outline.value);
      }();
    }
  }

  @override
  void dispose() {
    textSearcher.removeListener(_onTextSearcherUpdated);

    widget.tab.pdfViewerController
        .removeListener(_onPdfViewerControllerUpdate);
    _leftPaneTabController?.dispose();
    _searchFieldFocusNode.dispose();

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
        body: Row(
          children: [
            _buildLeftPane(),
            Expanded(
              child: ColorFiltered(
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
        )],
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
                      child: Material(
                        color: Colors.transparent,
                        child: ClipRect(
                          child: TabBar(
                            controller: _leftPaneTabController, // Use the managed controller
                            tabs: const [
                              Tab(text: 'ניווט'),
                              Tab(text: 'חיפוש'),
                              Tab(text: 'דפים'),
                            ],
                          ),
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

                    controller: _leftPaneTabController, // Use the managed controller

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
                        builder: (context, documentRef, child) {
                          // Check if PdfBookSearchView will trigger an initial search
                          if (widget.tab.searchController.text.isNotEmpty) {
                            // If there's text in the search controller, it implies that
                            // PdfBookSearchView.initState will trigger an initial search.
                            // We reset _lastProcessedSearchSessionId here
                            // to ensure that the completion of this initial search is unequivocally
                            // treated as a new search session by the _onTextSearcherUpdated listener.
                            _lastProcessedSearchSessionId = null;
                          }
                          return child!;
                        },
                        child: PdfBookSearchView(
                          textSearcher: textSearcher,
                          searchController: widget.tab.searchController,
                          focusNode: _searchFieldFocusNode,
                          initialSearchText: widget.tab.searchText,
                          onSearchResultNavigated: _ensureSearchTabIsActive,
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
