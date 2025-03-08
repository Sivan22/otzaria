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
import 'package:otzaria/tabs/models/pdf_tab.dart';
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
  final PdfBookTab tab;

  const PdfBookScreen({
    super.key,
    required this.tab,
  });

  @override
  State<PdfBookScreen> createState() => _PdfBookScreenState();
}

class _PdfBookScreenState extends State<PdfBookScreen>
    with AutomaticKeepAliveClientMixin<PdfBookScreen> {
  PdfViewerController controller = PdfViewerController();
  late final PdfTextSearcher textSearcher;

  void _update() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    textSearcher = PdfTextSearcher(controller)..addListener(_update);
    controller
        .addListener(() => widget.tab.pageNumber = controller.pageNumber ?? 1);
  }

  @override
  void dispose() {
    textSearcher.removeListener(_update);
    controller.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<PdfBookBloc, PdfBookState>(
      builder: (context, state) {
        if (state.status == PdfBookStatus.error) {
          return Center(child: Text('Error: ${state.errorMessage}'));
        }

        return _buildLoadedState(state);
      },
    );
  }

  Widget _buildTitle(PdfBookState state) {
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

  Widget _buildLoadedState(PdfBookState state) {
    return LayoutBuilder(builder: (context, constrains) {
      final wideScreen = (MediaQuery.of(context).size.width >= 600);
      return Scaffold(
        appBar: AppBar(
          title: _buildTitle(state),
          leading: IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'חיפוש וניווט',
            onPressed: () =>
                context.read<PdfBookBloc>().add(const ToggleLeftPane()),
          ),
          actions: [
            _buildTextButton(context, widget.tab.book, state),
            IconButton(
              icon: const Icon(
                Icons.bookmark_add,
              ),
              tooltip: 'הוספת סימניה',
              onPressed: () {
                int index = controller.pageNumber ?? 1;
                bool bookmarkAdded = context.read<BookmarkBloc>().addBookmark(
                    ref: '${widget.tab.book.title} עמוד $index',
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
              icon: const Icon(Icons.zoom_in),
              tooltip: 'הגדל',
              onPressed: () => context.read<PdfBookBloc>().add(const ZoomIn()),
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              tooltip: 'הקטן',
              onPressed: () => context.read<PdfBookBloc>().add(const ZoomOut()),
            ),
            if (wideScreen)
              IconButton(
                icon: const Icon(Icons.first_page),
                tooltip: 'תחילת הספר',
                onPressed: () =>
                    context.read<PdfBookBloc>().add(const ChangePage(1)),
              ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'הקודם',
              onPressed: () => context
                  .read<PdfBookBloc>()
                  .add(ChangePage(max(state.currentPage - 1, 1))),
            ),
            if (controller.isReady) PageNumberDisplay(controller: controller),
            IconButton(
              onPressed: () => context.read<PdfBookBloc>().add(ChangePage(
                  min(state.currentPage + 1, state.totalPages ?? 1))),
              icon: const Icon(Icons.chevron_right),
              tooltip: 'הבא',
            ),
            if (wideScreen)
              IconButton(
                icon: const Icon(Icons.last_page),
                tooltip: 'סוף הספר',
                onPressed: () => context
                    .read<PdfBookBloc>()
                    .add(ChangePage(state.totalPages ?? 1)),
              ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'שיתוף',
              onPressed: () async {
                await Printing.sharePdf(
                  bytes: File(widget.tab.book.path).readAsBytesSync(),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            PdfViewer.file(
              controller: controller,
              widget.tab.book.path,
              initialPageNumber: state.currentPage,
              passwordProvider: () => passwordDialog(context),
              params: PdfViewerParams(
                  pageAnchor: PdfPageAnchor.topLeft,
                  pageAnchorEnd: PdfPageAnchor.topRight,
                  loadingBannerBuilder:
                      (context, bytesDownloaded, totalBytes) => Center(
                            child: CircularProgressIndicator(
                                value: totalBytes == null
                                    ? null
                                    : (bytesDownloaded / totalBytes)),
                          ),
                  maxScale: 10,
                  onInteractionStart: (_) {
                    if (!state.isLeftPanePinned && state.isLeftPaneVisible) {
                      context.read<PdfBookBloc>().add(const ToggleLeftPane());
                    }
                  },
                  onPageChanged: (page) => context
                      .read<PdfBookBloc>()
                      .add(const UpdateCurrentTitle()),
                  viewerOverlayBuilder: (context, size, handleLinkTap) => [
                        PdfViewerScrollThumb(
                          controller: controller,
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
                          controller: controller,
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
                              controller.goToDest(link.dest);
                            }
                          },
                          hoverColor: Colors.blue.withOpacity(0.2),
                        ),
                      ),
                  onViewerReady: (document, controller) {
                    context
                        .read<PdfBookBloc>()
                        .add(OnViewerReady(document, controller));
                  }),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLeftPane(PdfBookState state) {
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
                          onPressed: () => context
                              .read<PdfBookBloc>()
                              .add(const TogglePinLeftPane()),
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
                          controller: controller,
                        ),
                        PdfBookSearchView(
                          textSearcher: textSearcher,
                          searchTextController: state.searchController,
                        ),
                        ThumbnailsView(
                          controller: controller,
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
                if (state.outline != null) {
                  final index = await pdfToTextPage(book, state.outline!,
                      controller.pageNumber ?? 1, context);
                  openBook(context, snapshot.data!, index ?? 0, '');
                }
              })
          : const SizedBox.shrink(),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
