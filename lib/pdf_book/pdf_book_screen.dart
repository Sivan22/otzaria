import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:otzaria/bookmarks/bloc/bookmark_bloc.dart';
import 'package:otzaria/core/scaffold_messenger.dart';
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
import 'package:otzaria/i18n/translations.g.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/utils/page_converter.dart';
import 'package:flutter/gestures.dart';
import 'package:otzaria/widgets/responsive_action_bar.dart';

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

    debugPrint(
        'DEBUG: Triggering search by simulating user input for "$query"');

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

  @override
  void initState() {
    super.initState();

    pdfController = PdfViewerController();

    textSearcher = PdfTextSearcher(pdfController)
      ..addListener(_onTextSearcherUpdated);

    widget.tab.pdfViewerController = pdfController;

    debugPrint('DEBUG: אתחול PDF טאב - דף התחלתי: ${widget.tab.pageNumber}');

    _sidebarWidth = ValueNotifier<double>(
        Settings.getValue<double>('key-sidebar-width', defaultValue: 300)!);

    _settingsSub = context.read<SettingsBloc>().stream.listen((state) {
      _sidebarWidth.value = state.sidebarWidth;
    });

    pdfController.addListener(_onPdfViewerControllerUpdate);
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

  int _lastComputedForPage = -1;
  void _onPdfViewerControllerUpdate() async {
    if (!widget.tab.pdfViewerController.isReady) return;
    final newPage = widget.tab.pdfViewerController.pageNumber ?? 1;
    if (newPage == widget.tab.pageNumber) return;
    widget.tab.pageNumber = newPage;
    final token = _lastComputedForPage = newPage;
    final title = await refFromPageNumber(
        newPage, widget.tab.outline.value ?? [], widget.tab.book.title);
    if (token == _lastComputedForPage) {
      widget.tab.currentTitle.value = title;
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
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.equal):
              _zoomIn,
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.add):
              _zoomIn,
          LogicalKeySet(
                  LogicalKeyboardKey.control, LogicalKeyboardKey.numpadAdd):
              _zoomIn,
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.minus):
              _zoomOut,
          LogicalKeySet(LogicalKeyboardKey.control,
              LogicalKeyboardKey.numpadSubtract): _zoomOut,
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
                icon: const Icon(FluentIcons.navigation_24_regular),
                tooltip: 'חיפוש וניווט',
                onPressed: () {
                  widget.tab.showLeftPane.value =
                      !widget.tab.showLeftPane.value;
                },
              ),
              actions: _buildPdfActions(context, wideScreen),
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
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surface, // צבע רקע המסך, בתצוגת ספרי PDF
                            maxScale: 10,
                            horizontalCacheExtent: 1,
                            verticalCacheExtent: 1,
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
                                hoverColor: Colors.blue.withValues(alpha: 0.2),
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
                              final currentPage =
                                  widget.tab.pdfViewerController.isReady
                                      ? (widget.tab.pdfViewerController
                                              .pageNumber ??
                                          1)
                                      : 1;
                              widget.tab.currentTitle.value =
                                  await refFromPageNumber(
                                      currentPage,
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
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _buildCustomTab('ניווט', 0)),
                                  Container(
                                      height: 24,
                                      width: 1,
                                      color: Colors.grey.shade400,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 2)),
                                  Expanded(child: _buildCustomTab('חיפוש', 1)),
                                  Container(
                                      height: 24,
                                      width: 1,
                                      color: Colors.grey.shade400,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 2)),
                                  Expanded(child: _buildCustomTab('דפים', 2)),
                                ],
                              ),
                              Container(
                                height: 1,
                                color: Theme.of(context).dividerColor,
                              ),
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
                                  onPressed: (Settings.getValue<bool>(
                                              'key-pin-sidebar') ??
                                          false)
                                      ? null
                                      : () {
                                          widget.tab.pinLeftPane.value =
                                              !widget.tab.pinLeftPane.value;
                                        },
                                  icon: const Icon(FluentIcons.pin_24_regular),
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

  void _zoomIn() {
    widget.tab.pdfViewerController.zoomUp();
  }

  void _zoomOut() {
    widget.tab.pdfViewerController.zoomDown();
  }

  void _goNextPage() {
    if (widget.tab.pdfViewerController.isReady) {
      final currentPage = widget.tab.pdfViewerController.pageNumber ?? 1;
      final nextPage =
          min(currentPage + 1, widget.tab.pdfViewerController.pageCount);
      widget.tab.pdfViewerController.goToPage(pageNumber: nextPage);
    }
  }

  void _goPreviousPage() {
    if (widget.tab.pdfViewerController.isReady) {
      final currentPage = widget.tab.pdfViewerController.pageNumber ?? 1;
      final prevPage = max(currentPage - 1, 1);
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
          title: Text(context.t.pdfBook.navigateToUrl), // Old: 'לעבור לURL?'
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
              child: Text(context.t.common.cancel), // Old: 'ביטול'
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.t.pdfBook.go), // Old: 'עבור'
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Widget _buildCustomTab(String text, int index) {
    final controller = _leftPaneTabController;
    if (controller == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final isSelected = controller.index == index;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              controller.animateTo(index);
            },
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  controller.animateTo(index);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    border: isSelected
                        ? Border(
                            bottom: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2))
                        : null,
                  ),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Theme.of(context).primaryColor : null,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// בניית כפתורי ה-AppBar עבור PDF
  List<Widget> _buildPdfActions(BuildContext context, bool wideScreen) {
    final screenWidth = MediaQuery.of(context).size.width;

    // נקבע כמה כפתורים להציג בהתאם לרוחב המסך
    int maxButtons;

    if (screenWidth < 400) {
      maxButtons = 2; // 2 כפתורים + "..." במסכים קטנים מאוד
    } else if (screenWidth < 500) {
      maxButtons = 4; // 4 כפתורים + "..." במסכים קטנים
    } else if (screenWidth < 600) {
      maxButtons = 6; // 6 כפתורים + "..." במסכים בינוניים קטנים
    } else if (screenWidth < 700) {
      maxButtons = 8; // 8 כפתורים + "..." במסכים בינוניים
    } else if (screenWidth < 900) {
      maxButtons = 10; // 10 כפתורים + "..." במסכים גדולים
    } else {
      maxButtons =
          999; // כל הכפתורים החיצוניים במסכים רחבים (ההדפסה תמיד בתפריט)
    }

    return [
      ResponsiveActionBar(
        key: ValueKey('pdf_actions_$screenWidth'),
        actions: _buildDisplayOrderPdfActions(context),
        alwaysInMenu: _buildAlwaysInMenuPdfActions(context),
        maxVisibleButtons: maxButtons,
      ),
    ];
  }

  /// בניית רשימת כפתורים בסדר ההצגה (מימין לשמאל ב-RTL)
  List<ActionButtonData> _buildDisplayOrderPdfActions(BuildContext context) {
    return [
      // 1) Text Button
      ActionButtonData(
        widget: _buildTextButton(
            context, widget.tab.book, widget.tab.pdfViewerController),
        icon: FluentIcons.document_text_24_regular,
        tooltip: 'פתח ספר במהדורת טקסט',
        onPressed: () => _handleTextButtonPress(context),
      ),

      // 2) Zoom In Button
      ActionButtonData(
        widget: IconButton(
          icon: const Icon(FluentIcons.zoom_in_24_regular),
          tooltip: 'הגדל',
          onPressed: () => widget.tab.pdfViewerController.zoomUp(),
        ),
        icon: FluentIcons.zoom_in_24_regular,
        tooltip: 'הגדל',
        onPressed: () => widget.tab.pdfViewerController.zoomUp(),
      ),

      // 3) Zoom Out Button
      ActionButtonData(
        widget: IconButton(
          icon: const Icon(FluentIcons.zoom_out_24_regular),
          tooltip: 'הקטן',
          onPressed: () => widget.tab.pdfViewerController.zoomDown(),
        ),
        icon: FluentIcons.zoom_out_24_regular,
        tooltip: 'הקטן',
        onPressed: () => widget.tab.pdfViewerController.zoomDown(),
      ),

      // 4) Search Button
      ActionButtonData(
        widget: IconButton(
          icon: const Icon(FluentIcons.search_24_regular),
          tooltip: 'חיפוש',
          onPressed: _ensureSearchTabIsActive,
        ),
        icon: FluentIcons.search_24_regular,
        tooltip: 'חיפוש',
        onPressed: _ensureSearchTabIsActive,
      ),

      // 5) First Page Button
      ActionButtonData(
        widget: IconButton(
          icon: const Icon(FluentIcons.arrow_previous_24_regular),
          tooltip: 'תחילת הספר',
          onPressed: () =>
              widget.tab.pdfViewerController.goToPage(pageNumber: 1),
        ),
        icon: FluentIcons.arrow_previous_24_regular,
        tooltip: 'תחילת הספר',
        onPressed: () => widget.tab.pdfViewerController.goToPage(pageNumber: 1),
      ),

      // 6) Previous Page Button
      ActionButtonData(
        widget: IconButton(
          icon: const Icon(FluentIcons.chevron_left_24_regular),
          tooltip: 'הקודם',
          onPressed: () {
            if (widget.tab.pdfViewerController.isReady) {
              final currentPage =
                  widget.tab.pdfViewerController.pageNumber ?? 1;
              widget.tab.pdfViewerController.goToPage(
                pageNumber: max(currentPage - 1, 1),
              );
            }
          },
        ),
        icon: FluentIcons.chevron_left_24_regular,
        tooltip: 'הקודם',
        onPressed: () {
          if (widget.tab.pdfViewerController.isReady) {
            final currentPage = widget.tab.pdfViewerController.pageNumber ?? 1;
            widget.tab.pdfViewerController.goToPage(
              pageNumber: max(currentPage - 1, 1),
            );
          }
        },
      ),

      // 7) Page Number Display - תמיד מוצג!
      ActionButtonData(
        widget: PageNumberDisplay(controller: widget.tab.pdfViewerController),
        icon: FluentIcons.text_font_24_regular,
        tooltip: 'מספר עמוד',
        onPressed: null, // לא ניתן ללחיצה
      ),

      // 8) Next Page Button
      ActionButtonData(
        widget: IconButton(
          onPressed: () {
            if (widget.tab.pdfViewerController.isReady) {
              final currentPage =
                  widget.tab.pdfViewerController.pageNumber ?? 1;
              widget.tab.pdfViewerController.goToPage(
                pageNumber: min(
                    currentPage + 1, widget.tab.pdfViewerController.pageCount),
              );
            }
          },
          icon: const Icon(FluentIcons.chevron_right_24_regular),
          tooltip: 'הבא',
        ),
        icon: FluentIcons.chevron_right_24_regular,
        tooltip: 'הבא',
        onPressed: () {
          if (widget.tab.pdfViewerController.isReady) {
            final currentPage = widget.tab.pdfViewerController.pageNumber ?? 1;
            widget.tab.pdfViewerController.goToPage(
              pageNumber: min(
                  currentPage + 1, widget.tab.pdfViewerController.pageCount),
            );
          }
        },
      ),

      // 9) Last Page Button
      ActionButtonData(
        widget: IconButton(
          icon: const Icon(FluentIcons.arrow_next_24_filled),
          tooltip: 'סוף הספר',
          onPressed: () => widget.tab.pdfViewerController
              .goToPage(pageNumber: widget.tab.pdfViewerController.pageCount),
        ),
        icon: FluentIcons.arrow_next_24_filled,
        tooltip: 'סוף הספר',
        onPressed: () => widget.tab.pdfViewerController
            .goToPage(pageNumber: widget.tab.pdfViewerController.pageCount),
      ),
    ];
  }

  /// כפתורים שתמיד יהיו בתפריט "..."
  List<ActionButtonData> _buildAlwaysInMenuPdfActions(BuildContext context) {
    return [
      // 1) הוספת סימניה
      ActionButtonData(
        widget: IconButton(
          icon: const Icon(FluentIcons.bookmark_add_24_regular),
          tooltip: 'הוספת סימניה',
          onPressed: () => _handleBookmarkPress(context),
        ),
        icon: FluentIcons.bookmark_add_24_regular,
        tooltip: 'הוספת סימניה',
        onPressed: () => _handleBookmarkPress(context),
      ),

      // 2) הדפסה
      ActionButtonData(
        widget: IconButton(
          icon: const Icon(FluentIcons.print_24_regular),
          tooltip: 'הדפס',
          onPressed: () => _handlePrintPress(context),
        ),
        icon: FluentIcons.print_24_regular,
        tooltip: 'הדפס',
        onPressed: () => _handlePrintPress(context),
      ),
    ];
  }

  /// טיפול בלחיצה על כפתור הטקסט
  Future<void> _handleTextButtonPress(BuildContext context) async {
    final currentPage = widget.tab.pdfViewerController.isReady
        ? widget.tab.pdfViewerController.pageNumber ?? 1
        : widget.tab.pageNumber;
    widget.tab.pageNumber = currentPage;
    final currentOutline = widget.tab.outline.value ?? [];

    final library = await DataRepository.instance.library;
    final textBook = library.findBookByTitle(widget.tab.book.title, TextBook);
    if (textBook == null) return;

    if (!context.mounted) return;

    final index = await pdfToTextPage(
        widget.tab.book, currentOutline, currentPage, context);

    if (!context.mounted) return;

    openBook(context, textBook, index ?? 0, '', ignoreHistory: true);
  }

  /// טיפול בלחיצה על כפתור הסימניה
  void _handleBookmarkPress(BuildContext context) {
    int index = widget.tab.pdfViewerController.isReady
        ? (widget.tab.pdfViewerController.pageNumber ?? 1)
        : 1;
    bool bookmarkAdded = Provider.of<BookmarkBloc>(context, listen: false)
        .addBookmark(
            ref: '${widget.tab.title} עמוד $index',
            book: widget.tab.book,
            index: index);
    if (mounted) {
      UiSnack.show(
          bookmarkAdded ? 'הסימניה נוספה בהצלחה' : 'הסימניה כבר קיימת');
    }
  }

  /// טיפול בלחיצה על כפתור ההדפסה
  Future<void> _handlePrintPress(BuildContext context) async {
    final file = File(widget.tab.book.path);
    final fileName = file.uri.pathSegments.last;
    await Printing.sharePdf(
      bytes: await file.readAsBytes(),
      filename: fileName,
    );
  }

  Widget _buildTextButton(
      BuildContext context, PdfBook book, PdfViewerController controller) {
    return FutureBuilder(
      future: DataRepository.instance.library
          .then((library) => library.findBookByTitle(book.title, TextBook)),
      builder: (context, snapshot) => snapshot.hasData
          ? IconButton(
              icon: const Icon(FluentIcons.document_text_24_regular),
              tooltip: 'פתח ספר במהדורת טקסט',
              onPressed: () async {
                final currentPage = controller.isReady
                    ? controller.pageNumber ?? 1
                    : widget.tab.pageNumber;
                widget.tab.pageNumber = currentPage;
                final currentOutline = widget.tab.outline.value ?? [];

                final index = await pdfToTextPage(
                    book, currentOutline, currentPage, context);

                if (!context.mounted) return;

                openBook(context, snapshot.data!, index ?? 0, '',
                    ignoreHistory: true);
              })
          : const SizedBox.shrink(),
    );
  }
}
