import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otzaria/bookmarks/bloc/bookmark_bloc.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/pdf_book/pdf_page_number_dispaly.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_event.dart';
import 'package:otzaria/settings/settings_state.dart';
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
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/utils/page_converter.dart';
import 'package:flutter/gestures.dart';

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

  late final PdfViewerController pdfController;
  late final PdfTextSearcher textSearcher;
  TabController? _leftPaneTabController;
  int _currentLeftPaneTabIndex = 0;
  final FocusNode _searchFieldFocusNode = FocusNode();
  final FocusNode _navigationFieldFocusNode = FocusNode();
  late final ValueNotifier<double> _sidebarWidth;
  late final StreamSubscription<SettingsState> _settingsSub;

  Future<void> _runInitialSearchIfNeeded() async {
    final controller = widget.tab.searchController;
    final String query = controller.text.trim();
    if (query.isEmpty) return;

    print('DEBUG: Triggering search by simulating user input for "$query"');

    // שיטה 1: הוספה והסרה מהירה
    controller.text = '$query '; // הוסף תו זמני

    // המתן רגע קצרצר כדי שהשינוי יתפוס
    await Future.delayed(const Duration(milliseconds: 50));

    controller.text = query; // החזר את הטקסט המקורי
    // הזז את הסמן לסוף הטקסט
    controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length));

    //ברוב המקרים, שינוי הטקסט עצמו יפעיל את ה-listener של הספרייה.
    // אם לא, ייתכן שעדיין צריך לקרוא לזה ידנית:
    textSearcher.startTextSearch(query, goToFirstMatch: false);
  }

  void _ensureSearchTabIsActive() {
    widget.tab.showLeftPane.value = true;
    if (_leftPaneTabController != null && _leftPaneTabController!.index != 1) {
      _leftPaneTabController!.animateTo(1);
    }
    _searchFieldFocusNode.requestFocus();
  }

  late TabController _tabController;
  final GlobalKey<State<PdfBookSearchView>> _searchViewKey = GlobalKey();
  int? _lastProcessedSearchSessionId;

  void _onTextSearcherUpdated() {
    String currentSearchTerm = widget.tab.searchController.text;
    int? persistedIndexFromTab = widget.tab.pdfSearchCurrentMatchIndex;

    widget.tab.searchText = currentSearchTerm;
    widget.tab.pdfSearchMatches = List.from(textSearcher.matches);
    widget.tab.pdfSearchCurrentMatchIndex = textSearcher.currentIndex;

    if (mounted) {
      setState(() {});
    }

    bool isNewSearchExecution =
        (_lastProcessedSearchSessionId != textSearcher.searchSession);
    if (isNewSearchExecution) {
      _lastProcessedSearchSessionId = textSearcher.searchSession;
    }

    if (isNewSearchExecution &&
        currentSearchTerm.isNotEmpty &&
        textSearcher.matches.isNotEmpty &&
        persistedIndexFromTab != null &&
        persistedIndexFromTab >= 0 &&
        persistedIndexFromTab < textSearcher.matches.length &&
        textSearcher.currentIndex != persistedIndexFromTab) {
      textSearcher.goToMatchOfIndex(persistedIndexFromTab);
    }
  }

  void initState() {
    super.initState();

    // 1. צור את הבקר (המכונית) קודם כל.
    pdfController = PdfViewerController();

    // 2. צור את המחפש (השלט) וחבר אותו לבקר שיצרנו הרגע.
    textSearcher = PdfTextSearcher(pdfController)
      ..addListener(_onTextSearcherUpdated);

    // 3. שמור את הבקר בטאב כדי ששאר חלקי האפליקציה יוכלו להשתמש בו.
    widget.tab.pdfViewerController = pdfController;

    _sidebarWidth = ValueNotifier<double>(
        Settings.getValue<double>('key-sidebar-width', defaultValue: 300)!);

    _settingsSub = context.read<SettingsBloc>().stream.listen((state) {
      _sidebarWidth.value = state.sidebarWidth;
    });

    // -- שאר הקוד של initState נשאר כמעט זהה --
    pdfController.addListener(_onPdfViewerControllerUpdate);

    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.tab.searchText.isNotEmpty ? 1 : 0,
    );

    if (widget.tab.searchText.isNotEmpty) {
      _currentLeftPaneTabIndex = 1;
    } else {
      _currentLeftPaneTabIndex = 0;
    }

    _leftPaneTabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _currentLeftPaneTabIndex,
    );
    if (_currentLeftPaneTabIndex == 1) {
      _searchFieldFocusNode.requestFocus();
    } else {
      _navigationFieldFocusNode.requestFocus();
    }
    _leftPaneTabController!.addListener(() {
      if (_currentLeftPaneTabIndex != _leftPaneTabController!.index) {
        setState(() {
          _currentLeftPaneTabIndex = _leftPaneTabController!.index;
        });
        if (_leftPaneTabController!.index == 1) {
          _searchFieldFocusNode.requestFocus();
        } else if (_leftPaneTabController!.index == 0) {
          _navigationFieldFocusNode.requestFocus();
        }
      }
    });
    widget.tab.showLeftPane.addListener(() {
      if (widget.tab.showLeftPane.value) {
        if (_leftPaneTabController!.index == 1) {
          _searchFieldFocusNode.requestFocus();
        } else if (_leftPaneTabController!.index == 0) {
          _navigationFieldFocusNode.requestFocus();
        }
      }
    });
  }

  void _onPdfViewerControllerUpdate() {
    if (widget.tab.pdfViewerController.isReady) {
      widget.tab.pageNumber = widget.tab.pdfViewerController.pageNumber ?? 1;
      () async {
        widget.tab.currentTitle.value = await refFromPageNumber(
            widget.tab.pageNumber,
            widget.tab.outline.value,
            widget.tab.book.title);
      }();
    }
  }

  @override
  void dispose() {
    textSearcher.removeListener(_onTextSearcherUpdated);
    widget.tab.pdfViewerController.removeListener(_onPdfViewerControllerUpdate);
    _leftPaneTabController?.dispose();
    _searchFieldFocusNode.dispose();
    _navigationFieldFocusNode.dispose();
    _sidebarWidth.dispose();
    _settingsSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(builder: (context, constrains) {
      final wideScreen = (MediaQuery.of(context).size.width >= 600);
      return CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
              _ensureSearchTabIsActive,
          LogicalKeySet(LogicalKeyboardKey.arrowRight): _goNextPage,
          LogicalKeySet(LogicalKeyboardKey.arrowLeft): _goPreviousPage,
          LogicalKeySet(LogicalKeyboardKey.arrowDown): _goNextPage,
          LogicalKeySet(LogicalKeyboardKey.arrowUp): _goPreviousPage,
          LogicalKeySet(LogicalKeyboardKey.pageDown): _goNextPage,
          LogicalKeySet(LogicalKeyboardKey.pageUp): _goPreviousPage,
        },
        child: Focus(
          focusNode: FocusNode(),
          autofocus: !Platform.isAndroid,
          child: Scaffold(
            appBar: AppBar(
              centerTitle: false,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              shape: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 0.3,
                ),
              ),
              elevation: 0,
              scrolledUnderElevation: 0,
              title: ValueListenableBuilder(
                valueListenable: widget.tab.currentTitle,
                builder: (context, value, child) {
                  String displayTitle = value;
                  if (value.isNotEmpty &&
                      !value.contains(widget.tab.book.title)) {
                    displayTitle = "${widget.tab.book.title}, $value";
                  }
                  return SelectionArea(
                    child: Text(
                      displayTitle,
                      style: const TextStyle(fontSize: 17),
                      textAlign: TextAlign.end,
                    ),
                  );
                },
              ),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'חיפוש וניווט',
                onPressed: () {
                  widget.tab.showLeftPane.value =
                      !widget.tab.showLeftPane.value;
                },
              ),
              actions: [
                _buildTextButton(
                    context, widget.tab.book, widget.tab.pdfViewerController),
                IconButton(
                  icon: const Icon(Icons.bookmark_add),
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
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(bookmarkAdded
                              ? 'הסימניה נוספה בהצלחה'
                              : 'הסימניה כבר קיימת'),
                          duration: const Duration(milliseconds: 350),
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_in),
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
                    icon: const Icon(Icons.search),
                    tooltip: 'חיפוש',
                    onPressed: _ensureSearchTabIsActive,
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
                              widget.tab.pdfViewerController.pageNumber! - 1,
                              1))
                      : null,
                ),
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
                        pageNumber:
                            widget.tab.pdfViewerController.pages.length),
                  ),
                IconButton(
                  icon: const Icon(Icons.print),
                  tooltip: 'הדפס',
                  onPressed: () async {
                    await Printing.sharePdf(
                      bytes: File(widget.tab.book.path).readAsBytesSync(),
                    );
                  },
                ),
              ],
            ),
            body: Row(
              children: [
                _buildLeftPane(),
                ValueListenableBuilder(
                  valueListenable: widget.tab.showLeftPane,
                  builder: (context, show, child) => show
                      ? MouseRegion(
                          cursor: SystemMouseCursors.resizeColumn,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onHorizontalDragUpdate: (details) {
                              final newWidth =
                                  (_sidebarWidth.value - details.delta.dx)
                                      .clamp(200.0, 600.0);
                              _sidebarWidth.value = newWidth;
                            },
                            onHorizontalDragEnd: (_) {
                              context
                                  .read<SettingsBloc>()
                                  .add(UpdateSidebarWidth(_sidebarWidth.value));
                            },
                            child: const VerticalDivider(width: 4),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: NotificationListener<UserScrollNotification>(
                    onNotification: (notification) {
                      if (!(widget.tab.pinLeftPane.value ||
                          (Settings.getValue<bool>('key-pin-sidebar') ??
                              false))) {
                        Future.microtask(() {
                          widget.tab.showLeftPane.value = false;
                        });
                      }
                      return false;
                    },
                    child: Listener(
                      onPointerSignal: (event) {
                        if (event is PointerScrollEvent &&
                            !(widget.tab.pinLeftPane.value ||
                                (Settings.getValue<bool>('key-pin-sidebar') ??
                                    false))) {
                          widget.tab.showLeftPane.value = false;
                        }
                      },
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.white,
                          Provider.of<SettingsBloc>(context, listen: true)
                                  .state
                                  .isDarkMode
                              ? BlendMode.difference
                              : BlendMode.dst,
                        ),
                        child: PdfViewer.file(
                          widget.tab.book.path,
                          initialPageNumber: widget.tab.pageNumber,
                          passwordProvider: () => passwordDialog(context),
                          controller: widget.tab.pdfViewerController,
                          params: PdfViewerParams(
                            maxScale: 10,
                            horizontalCacheExtent: 5,
                            verticalCacheExtent: 5,
                            onInteractionStart: (_) {
                              if (!(widget.tab.pinLeftPane.value ||
                                  (Settings.getValue<bool>('key-pin-sidebar') ??
                                      false))) {
                                widget.tab.showLeftPane.value = false;
                              }
                            },
                            viewerOverlayBuilder:
                                (context, size, handleLinkTap) => [
                              PdfViewerScrollThumb(
                                controller: widget.tab.pdfViewerController,
                                orientation: ScrollbarOrientation.right,
                                thumbSize: const Size(40, 25),
                                thumbBuilder: (context, thumbSize, pageNumber,
                                        controller) =>
                                    Container(
                                  color: Colors.black,
                                  child: Center(
                                    child: Text(
                                      pageNumber.toString(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                              PdfViewerScrollThumb(
                                controller: widget.tab.pdfViewerController,
                                orientation: ScrollbarOrientation.bottom,
                                thumbSize: const Size(80, 5),
                                thumbBuilder: (context, thumbSize, pageNumber,
                                        controller) =>
                                    Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ],
                            loadingBannerBuilder:
                                (context, bytesDownloaded, totalBytes) =>
                                    Center(
                              child: CircularProgressIndicator(
                                value: totalBytes != null
                                    ? bytesDownloaded / totalBytes
                                    : null,
                                backgroundColor: Colors.grey,
                              ),
                            ),
                            linkWidgetBuilder: (context, link, size) =>
                                Material(
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
                              // 1. הגדרת המידע הראשוני מהמסמך
                              widget.tab.documentRef.value =
                                  controller.documentRef;
                              widget.tab.outline.value =
                                  await document.loadOutline();

                              // 2. עדכון הכותרת הנוכחית
                              widget.tab.currentTitle.value =
                                  await refFromPageNumber(
                                      widget.tab.pdfViewerController
                                              .pageNumber ??
                                          1,
                                      widget.tab.outline.value,
                                      widget.tab.book.title);

                              // 3. הפעלת החיפוש הראשוני (עכשיו עם מנגנון ניסיונות חוזרים)
                              _runInitialSearchIfNeeded();

                              // 4. הצגת חלונית הצד אם צריך
                              if (mounted &&
                                  (widget.tab.showLeftPane.value ||
                                      widget.tab.searchText.isNotEmpty)) {
                                widget.tab.showLeftPane.value = true;
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
        builder: (context, showLeftPane, child) =>
            ValueListenableBuilder<double>(
          valueListenable: _sidebarWidth,
          builder: (context, width, child2) => SizedBox(
            width: showLeftPane ? width : 0,
            child: child2!,
          ),
          child: child,
        ),
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: ClipRect(
                          child: TabBar(
                            controller: _leftPaneTabController,
                            tabs: const [
                              Tab(
                                  child: Center(
                                      child: Text('ניווט',
                                          textAlign: TextAlign.center))),
                              Tab(
                                  child: Center(
                                      child: Text('חיפוש',
                                          textAlign: TextAlign.center))),
                              Tab(
                                  child: Center(
                                      child: Text('דפים',
                                          textAlign: TextAlign.center))),
                            ],
                            isScrollable: false,
                            tabAlignment: TabAlignment.fill,
                            padding: EdgeInsets.zero,
                            indicatorPadding: EdgeInsets.zero,
                            labelPadding:
                                const EdgeInsets.symmetric(horizontal: 2),
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
                                  onPressed: (Settings.getValue<bool>(
                                              'key-pin-sidebar') ??
                                          false)
                                      ? null
                                      : () {
                                          widget.tab.pinLeftPane.value =
                                              !widget.tab.pinLeftPane.value;
                                        },
                                  icon: const Icon(Icons.push_pin),
                                  isSelected: pinLeftPanel ||
                                      (Settings.getValue<bool>(
                                              'key-pin-sidebar') ??
                                          false),
                                ),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _leftPaneTabController,
                    children: [
                      ValueListenableBuilder(
                        valueListenable: widget.tab.outline,
                        builder: (context, outline, child) => OutlineView(
                          outline: outline,
                          controller: widget.tab.pdfViewerController,
                          focusNode: _navigationFieldFocusNode,
                        ),
                      ),
                      ValueListenableBuilder(
                        valueListenable: widget.tab.documentRef,
                        builder: (context, documentRef, child) {
                          if (widget.tab.searchController.text.isNotEmpty) {
                            _lastProcessedSearchSessionId = null;
                          }
                          return child!;
                        },
                        child: PdfBookSearchView(
                          textSearcher: textSearcher,
                          searchController: widget.tab.searchController,
                          focusNode: _searchFieldFocusNode,
                          outline: widget.tab.outline.value,
                          bookTitle: widget.tab.book.title,
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

  void _goNextPage() {
    if (widget.tab.pdfViewerController.isReady) {
      final nextPage = min(widget.tab.pdfViewerController.pageNumber! + 1,
          widget.tab.pdfViewerController.pages.length);
      widget.tab.pdfViewerController.goToPage(pageNumber: nextPage);
    }
  }

  void _goPreviousPage() {
    if (widget.tab.pdfViewerController.isReady) {
      final prevPage = max(widget.tab.pdfViewerController.pageNumber! - 1, 1);
      widget.tab.pdfViewerController.goToPage(pageNumber: prevPage);
    }
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

  Widget _buildTextButton(
      BuildContext context, PdfBook book, PdfViewerController controller) {
    return FutureBuilder(
      future: DataRepository.instance.library
          .then((library) => library.findBookByTitle(book.title, TextBook)),
      builder: (context, snapshot) => snapshot.hasData
          ? IconButton(
              icon: const Icon(Icons.article),
              tooltip: 'פתח טקסט',
              onPressed: () async {
                final index = await pdfToTextPage(
                    book,
                    widget.tab.outline.value ?? [],
                    controller.pageNumber ?? 1,
                    context);
                openBook(context, snapshot.data!, index ?? 0, '');
              })
          : const SizedBox.shrink(),
    );
  }
}
