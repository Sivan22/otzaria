import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/bookmarks/bloc/bookmark_bloc.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/pdf_book/bloc/pdf_book_bloc.dart';
import 'package:otzaria/pdf_book/bloc/pdf_book_event.dart';
import 'package:otzaria/pdf_book/bloc/pdf_book_state.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/utils/open_book.dart';
import 'package:otzaria/utils/page_converter.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:otzaria/pdf_book/view/pdf_page_number_dispaly.dart';
import 'pdf_search_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_outlines_screen.dart';
import 'package:otzaria/widgets/password_dialog.dart';
import 'pdf_thumbnails_screen.dart';
import 'package:printing/printing.dart';

class PdfBookScreen extends StatefulWidget {
  final PdfBook book;
  final int initialPage;

  const PdfBookScreen({
    super.key,
    required this.book,
    this.initialPage = 1,
  });

  @override
  State<PdfBookScreen> createState() => _PdfBookScreenState();
}

class _PdfBookScreenState extends State<PdfBookScreen>
    with AutomaticKeepAliveClientMixin<PdfBookScreen> {
  late final PdfBookBloc _bloc;
  late final TextEditingController searchController;
  PdfTextSearcher? textSearcher;

  @override
  void initState() {
    super.initState();
    _bloc = PdfBookBloc();
    _bloc.add(LoadPdfBook(
      path: widget.book.path,
      initialPage: widget.initialPage,
    ));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<PdfBookBloc, PdfBookState>(
      bloc: _bloc,
      builder: (context, state) {
        if (state is PdfBookInitial || state is PdfBookLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PdfBookError) {
          return Center(child: Text('Error: ${state.message}'));
        }

        if (state is PdfBookLoaded) {
          return _buildLoadedState(state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTitle(PdfBookLoaded state) {
    return state.currentTitle != null
        ? Center(
            child: SelectionArea(
              child: Text(
                state.currentTitle!,
                style: const TextStyle(fontSize: 17),
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  Widget _buildLoadedState(PdfBookLoaded state) {
    return LayoutBuilder(builder: (context, constrains) {
      final wideScreen = (MediaQuery.of(context).size.width >= 600);
      return Scaffold(
        appBar: AppBar(
          title: _buildTitle(state),
          leading: IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'חיפוש וניווט',
            onPressed: () => _bloc.add(const ToggleLeftPane()),
          ),
          actions: [
            _buildTextButton(context, widget.book, state),
            IconButton(
              icon: const Icon(
                Icons.bookmark_add,
              ),
              tooltip: 'הוספת סימניה',
              onPressed: () {
                int index = state.controller.pageNumber ?? 1;
                bool bookmarkAdded = context.read<BookmarkBloc>().addBookmark(
                    ref: '${widget.book.title} עמוד $index',
                    book: widget.book,
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
              icon: const Icon(Icons.zoom_in),
              tooltip: 'הגדל',
              onPressed: () => _bloc.add(const ZoomIn()),
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              tooltip: 'הקטן',
              onPressed: () => _bloc.add(const ZoomOut()),
            ),
            if (wideScreen)
              IconButton(
                icon: const Icon(Icons.first_page),
                tooltip: 'תחילת הספר',
                onPressed: () => _bloc.add(const ChangePage(1)),
              ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'הקודם',
              onPressed: () => state.controller.isReady
                  ? _bloc.add(ChangePage(max(state.currentPage - 1, 1)))
                  : null,
            ),
            PageNumberDisplay(controller: state.controller),
            IconButton(
              onPressed: () => state.controller.isReady
                  ? _bloc.add(
                      ChangePage(min(state.currentPage + 1, state.totalPages)))
                  : null,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'הבא',
            ),
            if (wideScreen)
              IconButton(
                icon: const Icon(Icons.last_page),
                tooltip: 'סוף הספר',
                onPressed: () => _bloc.add(ChangePage(state.totalPages)),
              ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'שיתוף',
              onPressed: () async {
                await Printing.sharePdf(
                  bytes: File(widget.book.path).readAsBytesSync(),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            PdfViewer.file(
              widget.book.path,
              initialPageNumber: widget.initialPage,
              passwordProvider: () => passwordDialog(context),
              controller: state.controller,
              params: PdfViewerParams(
                pageAnchor: PdfPageAnchor.topLeft,
                pageAnchorEnd: PdfPageAnchor.topRight,
                loadingBannerBuilder: (context, bytesDownloaded, totalBytes) =>
                    Center(
                  child: CircularProgressIndicator(
                      value: totalBytes == null
                          ? null
                          : (bytesDownloaded / totalBytes)),
                ),
                maxScale: 10,
                onInteractionStart: (_) {
                  if (!state.isLeftPanePinned && state.isLeftPaneVisible) {
                    _bloc.add(const ToggleLeftPane());
                  }
                },
                onPageChanged: (page) => _bloc.add(const UpdateCurrentTitle()),
                viewerOverlayBuilder: (context, size, handleLinkTap) => [
                  PdfViewerScrollThumb(
                    controller: state.controller,
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
                  PdfViewerScrollThumb(
                    controller: state.controller,
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
                  _buildLeftPane(state),
                ],
                linkWidgetBuilder: (context, link, size) => Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      if (link.url != null) {
                        await _navigateToUrl(link.url!);
                      } else if (link.dest != null) {
                        state.controller.goToDest(link.dest);
                      }
                    },
                    hoverColor: Colors.blue.withOpacity(0.2),
                  ),
                ),
                onDocumentChanged: (document) {
                  if (document == null) {
                    _bloc.add(const UpdateDocumentRef(null));
                  }
                },
                onViewerReady: (document, controller) {
                  textSearcher = PdfTextSearcher(controller);
                  searchController = TextEditingController();
                  _bloc.add(OnViewerReady(document, controller));
                  controller.goTo(controller.calcMatrixFitWidthForPage(
                      pageNumber: controller.pageNumber ?? 1));
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLeftPane(PdfBookLoaded state) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: SizedBox(
        width: state.isLeftPaneVisible ? 300 : 0,
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
                      if (MediaQuery.of(context).size.width >= 600)
                        IconButton(
                          onPressed: () => _bloc.add(const TogglePinLeftPane()),
                          icon: const Icon(Icons.push_pin),
                          isSelected: state.isLeftPanePinned,
                        ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        OutlineView(
                          outline: state.outline,
                          controller: state.controller,
                        ),
                        textSearcher != null
                            ? PdfBookSearchView(
                                textSearcher: textSearcher!,
                                searchTextController: searchController,
                              )
                            : const Center(
                                child: CircularProgressIndicator(),
                              ),
                        ThumbnailsView(
                          controller: state.controller,
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

  Future<void> _navigateToUrl(Uri url) async {
    if (await _shouldOpenUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<bool> _shouldOpenUrl(Uri url) async {
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

  Widget _buildTextButton(
      BuildContext context, PdfBook book, PdfBookState state) {
    return FutureBuilder(
      future: DataRepository.instance.library
          .then((library) => library.findBookByTitle(book.title, TextBook)),
      builder: (context, snapshot) => snapshot.hasData
          ? IconButton(
              icon: const Icon(Icons.article),
              tooltip: 'פתח טקסט',
              onPressed: () async {
                if (state is PdfBookLoaded && state.outline != null) {
                  final index = await pdfToTextPage(book, state.outline!,
                      state.controller.pageNumber ?? 1, context);
                  openBook(context, snapshot.data!, index ?? 0, '');
                }
              })
          : const SizedBox.shrink(),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
