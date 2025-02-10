import 'package:flutter/material.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/tabs/text_tab.dart';
import 'package:otzaria/screens/reading/text/combined_book_screen.dart';
import 'package:otzaria/screens/printing_screen.dart';
import 'package:otzaria/screens/reading/text/splited_view_screen.dart';
import 'package:otzaria/utils/page_converter.dart';
import 'package:provider/provider.dart';
import 'package:otzaria/screens/reading/text/text_book_search_screen.dart';
import 'dart:io';
import 'package:otzaria/screens/reading/text/toc_navigator_screen.dart';
import 'dart:math';
import 'links_screen.dart';
import 'commentators_list_screen.dart';
import 'package:flutter/services.dart';
import 'package:otzaria/models/tabs/tab.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;
import 'package:url_launcher/url_launcher.dart';

/// A [StatefulWidget] that displays a text book.
///
/// This widget takes a [TextBookTab] that contains the details of the book
/// and the data to display, and a [Future<String>] that represents the
/// contents of the book. It also takes two callbacks: [openBookCallback]
/// which is called when the user wants to open another book, and
/// [addBookmarkCallback] which is called when the user wants to add a bookmark.
///
/// [TextBookViewer] is responsible for displaying the book's contents and
/// allowing the user to interact with it, such as adjusting the font size
/// and searching for text within the book.
class TextBookViewer extends StatefulWidget {
  final TextBookTab tab;
  final void Function(OpenedTab) openBookCallback;
  final Future<String> data;

  /// Creates a new [TextBookViewer].
  ///
  /// The [tab] parameter is the [TextBookTab] that contains the details of the
  /// book, the [openBookCallback] parameter is the callback that is called
  /// when the user wants to open another book, and the [addBookmarkCallback]
  /// parameter is the callback that is called when the user wants to add a bookmark.
  /// The [data] parameter is the [Future<String>] that represents the contents
  /// of the book.
  const TextBookViewer({
    Key? key,
    required this.tab,
    required this.openBookCallback,
    required this.data,
  }) : super(key: key);

  /// Creates the mutable state for this widget at a given location in the tree.
  @override
  State<TextBookViewer> createState() => _TextBookViewerState();
}

class _TextBookViewerState extends State<TextBookViewer>
    with TickerProviderStateMixin {
  final FocusNode textSearchFocusNode = FocusNode();
  late TabController tabController;

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constrains) {
      final wideScreen = (MediaQuery.of(context).size.width >= 600);
      return Scaffold(
          appBar: AppBar(
            title: ListenableBuilder(
                listenable: widget.tab.positionsListener.itemPositions,
                builder: (context, _) {
                  return FutureBuilder(
                    future: utils.refFromIndex(
                        widget.tab.positionsListener.itemPositions.value
                                .isNotEmpty
                            ? widget.tab.positionsListener.itemPositions.value
                                .first.index
                            : 0,
                        widget.tab.tableOfContents),
                    builder: (context, snapshot) => snapshot.hasData
                        ? Center(
                            child: SelectionArea(
                              child: Text(snapshot.data!,
                                  style: const TextStyle(fontSize: 17)),
                            ),
                          )
                        : const SizedBox.shrink(),
                  );
                }),
            leading: IconButton(
                icon: const Icon(Icons.menu),
                tooltip: "ניווט וחיפוש",
                onPressed: () {
                  widget.tab.showLeftPane.value =
                      !widget.tab.showLeftPane.value;
                }),
            actions: [
              FutureBuilder(
                  future: context.read<AppModel>().library.then((library) =>
                      library.findBookByTitle(widget.tab.book.title, PdfBook)),
                  builder: (context, snapshot) => snapshot.hasData
                      ? IconButton(
                          icon: const Icon(Icons.picture_as_pdf),
                          tooltip: 'פתח ספר במהדורה מודפסת ',
                          onPressed: () async {
                            final appModel = context.read<AppModel>();
                            final book = await appModel.library.then(
                                (library) => library.findBookByTitle(
                                    widget.tab.title, PdfBook));
                            final index = await textToPdfPage(
                                widget.tab.title,
                                widget.tab.positionsListener.itemPositions.value
                                        .isNotEmpty
                                    ? widget.tab.positionsListener.itemPositions
                                        .value.first.index
                                    : 0,
                                // ignore: use_build_context_synchronously
                                context);
                            appModel.openBook(book!, index ?? 0);
                          })
                      : const SizedBox.shrink()),

              // button to switch between splitted view and combined view
              ValueListenableBuilder(
                valueListenable: widget.tab.showSplitedView,
                builder: (context, showSplitedViewValue, child) => IconButton(
                  onPressed: () {
                    widget.tab.showSplitedView.value =
                        !widget.tab.showSplitedView.value;
                  },
                  icon: Icon(!widget.tab.showSplitedView.value
                      ? Icons.vertical_split_outlined
                      : Icons.horizontal_split_outlined),
                  tooltip: !widget.tab.showSplitedView.value
                      ? ' הצגת מפרשים בצד הטקסט'
                      : 'הצגת מפרשים מתחת הטקסט',
                ),
              ),

              // button to toggle remove nikud
              IconButton(
                onPressed: () {
                  widget.tab.removeNikud.value = !widget.tab.removeNikud.value;
                },
                icon: const Icon(Icons.format_overline),
                tooltip: 'הצג או הסתר ניקוד',
              ),
              //button to add a bookmark
              IconButton(
                onPressed: () async {
                  int index = widget
                      .tab.positionsListener.itemPositions.value.first.index;
                  String ref = await utils.refFromIndex(
                      index, widget.tab.tableOfContents);
                  bool bookmarkAdded =
                      // ignore: use_build_context_synchronously
                      Provider.of<AppModel>(context, listen: false).addBookmark(
                          ref: ref, book: widget.tab.book, index: index);
                  // notify user
                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(bookmarkAdded
                            ? 'הסימניה נוספה בהצלחה'
                            : 'הסימניה כבר קיימת'),
                      ),
                    );
                  }
                },
                icon: const Icon(
                  Icons.bookmark_add,
                ),
                tooltip: 'הוספת סימניה',
              ),

              // button to search
              if (wideScreen)
                IconButton(
                  onPressed: () {
                    widget.tab.showLeftPane.value = true;
                    tabController.index = 1;
                    textSearchFocusNode.requestFocus();
                  },
                  icon: const Icon(
                    Icons.search,
                  ),
                  tooltip: 'חיפוש',
                ),

              // button to zoom in
              if (wideScreen)
                IconButton(
                    icon: const Icon(
                      Icons.zoom_in,
                    ),
                    tooltip: 'הגדלת טקסט',
                    onPressed: () => setState(() {
                          widget.tab.textFontSize =
                              min(50.0, widget.tab.textFontSize + 3);
                        })),
              if (wideScreen)
                IconButton(
                  icon: const Icon(
                    Icons.zoom_out,
                  ),
                  tooltip: 'הקטנת טקסט',
                  onPressed: () => setState(() {
                    widget.tab.textFontSize =
                        max(15.0, widget.tab.textFontSize - 3);
                  }),
                ),
              // button to scroll all the way up
              if (wideScreen)
                IconButton(
                    icon: const Icon(Icons.first_page),
                    tooltip: 'תחילת הספר',
                    onPressed: () {
                      widget.tab.scrollController.scrollTo(
                          index: 0,
                          duration: const Duration(milliseconds: 300));
                    }),
              //button to scroll to previous section
              if (wideScreen)
                IconButton(
                    icon: const Icon(Icons.navigate_before),
                    tooltip: 'הקטע הקודם',
                    onPressed: () {
                      widget.tab.scrollController.scrollTo(
                          duration: const Duration(milliseconds: 300),
                          index: max(
                            0,
                            widget.tab.positionsListener.itemPositions.value
                                    .first.index -
                                1,
                          ));
                    }),

              //button to scroll to next section
              if (wideScreen)
                IconButton(
                    icon: const Icon(Icons.navigate_next),
                    tooltip: 'הקטע הבא',
                    onPressed: () {
                      widget.tab.scrollController.scrollTo(
                          index: max(
                              widget.tab.positionsListener.itemPositions.value
                                      .first.index +
                                  1,
                              widget.tab.positionsListener.itemPositions.value
                                      .length -
                                  1),
                          duration: const Duration(milliseconds: 300));
                    }),

              // button to scroll all the way down

              if (wideScreen)
                IconButton(
                    icon: const Icon(Icons.last_page),
                    tooltip: 'סוף הספר',
                    onPressed: () async {
                      widget.tab.scrollController.scrollTo(
                          index:
                              await widget.data.then((value) => value.length),
                          duration: const Duration(milliseconds: 300));
                    }),
              //button to print
              IconButton(
                icon: const Icon(Icons.print),
                tooltip: 'הדפסה',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PrintingScreen(
                      data: widget.tab.removeNikud.value
                          ? widget.data
                          : widget.data,
                      startLine: widget.tab.index,
                      removeNikud: widget.tab.removeNikud.value,
                    ),
                  ),
                ),
              ),
              // Report bug button
              IconButton(
                icon: const Icon(Icons.error_outline),
                tooltip: 'דווח על טעות בספר',
                onPressed: () async {
                  final currentRef = await utils.refFromIndex(
                    widget.tab.positionsListener.itemPositions.value.isNotEmpty
                        ? widget.tab.positionsListener.itemPositions.value.first
                            .index
                        : 0,
                    widget.tab.tableOfContents,
                  );

                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'otzaria.1@gmail.com',
                    query: encodeQueryParameters(<String, String>{
                      'subject': 'דיווח על טעות: ${widget.tab.book.title}',
                      'body':
                          'שם הספר: ${widget.tab.book.title}\nמיקום: $currentRef\n\nפירוט הטעות:\n',
                    }),
                  );

                  try {
                    if (!await launchUrl(emailLaunchUri,
                        mode: LaunchMode.externalApplication)) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('לא ניתן לפתוח את תוכנת הדואר'),
                        ),
                      );
                    }
                  } catch (e) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('לא ניתן לפתוח את תוכנת הדואר'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          body: LayoutBuilder(
              builder: (context, constraints) =>
                  //if the screen is small, display the tab bar ontop of the viewer
                  MediaQuery.of(context).size.width < 600
                      ? Stack(children: [
                          buildHTMLViewer(),
                          Container(
                              color: Theme.of(context).colorScheme.surface,
                              child: buildTabBar()),
                        ])
                      : Row(
                          children: [
                            buildTabBar(),
                            Expanded(child: buildHTMLViewer()),
                          ],
                        )));
    });
  }

  Widget buildHTMLViewer() {
    return FutureBuilder(
        future: widget.data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.hasData) {
              return ValueListenableBuilder(
                  valueListenable: widget.tab.searchTextController,
                  builder: (context, searchTextController, child) => Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 5, 5),
                      //zoom in or zoom out fe
                      child: GestureDetector(
                        onScaleUpdate: (details) {
                          widget.tab.textFontSize =
                              (widget.tab.textFontSize * details.scale)
                                  .clamp(15, 60);
                          setState(() {});
                        },
                        child: NotificationListener<UserScrollNotification>(
                            onNotification: (scrollNotification) {
                              //unless links is shown, close left pane on scrolling
                              if (!widget.tab.pinLeftPane.value) {
                                Future.microtask(() {
                                  widget.tab.showLeftPane.value = false;
                                });
                              }

                              return false; // Don't block the notification
                            },
                            child: CallbackShortcuts(
                                bindings: <ShortcutActivator, VoidCallback>{
                                  LogicalKeySet(LogicalKeyboardKey.control,
                                      LogicalKeyboardKey.keyF): () {
                                    widget.tab.showLeftPane.value = true;
                                    tabController.index = 1;
                                    textSearchFocusNode.requestFocus();
                                  },
                                },
                                child: Focus(
                                    focusNode: FocusNode(),
                                    //don't autofocus on android, so that the keyboard doesn't appear
                                    autofocus:
                                        Platform.isAndroid ? false : true,
                                    child: buildSplitedOrCombinedView(
                                        snapshot, searchTextController)))),
                      )));
            }
          }
          return const Center(child: CircularProgressIndicator());
        });
  }

  ValueListenableBuilder<bool> buildSplitedOrCombinedView(
      AsyncSnapshot<String> snapshot, TextEditingValue searchTextController) {
    return ValueListenableBuilder(
        valueListenable: widget.tab.showSplitedView,
        builder: (context, value, child) => ValueListenableBuilder(
            valueListenable: widget.tab.commentatorsToShow,
            builder: (context, value, child) {
              if (widget.tab.showSplitedView.value &&
                  widget.tab.commentatorsToShow.value.isNotEmpty) {
                return SplitedViewScreen(
                    widget: widget,
                    snapshot: snapshot,
                    searchTextController: searchTextController);
              } else {
                return ValueListenableBuilder(
                    valueListenable: Provider.of<AppModel>(context).paddingSize,
                    builder: (context, value, child) {
                      return ValueListenableBuilder(
                          valueListenable: widget.tab.showLeftPane,
                          builder: (context, showLeftPAne, child) {
                            return Padding(
                              padding: widget.tab.showLeftPane.value
                                  ? //if left pane is opened, we don't want the padding
                                  EdgeInsets.zero
                                  : EdgeInsets.symmetric(horizontal: value),
                              child: buildCombinedView(
                                  snapshot, searchTextController),
                            );
                          });
                    });
              }
            }));
  }

  Widget buildCombinedView(
      AsyncSnapshot<String> snapshot, TextEditingValue searchTextController) {
    return CombinedView(
      tab: widget.tab,
      data: snapshot.data!.split('\n'),
      textSize: widget.tab.textFontSize,
      openBookCallback: widget.openBookCallback,
      showSplitedView: widget.tab.showSplitedView,
    );
  }

  AnimatedSize buildTabBar() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: ValueListenableBuilder(
        valueListenable: widget.tab.showLeftPane,
        builder: (context, showLeftPane, child) => SizedBox(
          width: showLeftPane ? 400 : 0,
          child: child!,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(1, 0, 4, 0),
          child: Column(children: [
            Row(
              children: [
                Expanded(
                  child: TabBar(
                    tabs: const [
                      Tab(text: 'ניווט'),
                      Tab(text: 'חיפוש'),
                      Tab(text: 'פרשנות'),
                      Tab(text: 'קישורים')
                    ],
                    controller: tabController,
                    onTap: (value) {
                      if (value == 1 && !Platform.isAndroid) {
                        textSearchFocusNode.requestFocus();
                      }
                    },
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
                              icon: const Icon(
                                Icons.push_pin,
                              ),
                              isSelected: pinLeftPanel,
                            ),
                )
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  buildTocViewer(),
                  CallbackShortcuts(bindings: <ShortcutActivator, VoidCallback>{
                    LogicalKeySet(LogicalKeyboardKey.control,
                        LogicalKeyboardKey.keyF): () {
                      widget.tab.showLeftPane.value = true;
                      tabController.index = 1;
                      textSearchFocusNode.requestFocus();
                    },
                  }, child: buildSearchView()),
                  buildCommentaryView(),
                  buildLinkView(),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  FutureBuilder<String> buildSearchView() {
    return FutureBuilder(
        future: widget.data,
        builder: (context, snapshot) =>
            snapshot.connectionState == ConnectionState.done
                ? TextBookSearchView(
                    focusNode: textSearchFocusNode,
                    data: snapshot.data!,
                    scrollControler: widget.tab.scrollController,
                    searchTextController: widget.tab.searchTextController,
                    closeLeftPaneCallback: closeLeftPane,
                  )
                : const Center(child: CircularProgressIndicator()));
  }

  Widget buildTocViewer() {
    return TocViewer(
      toc: widget.tab.book.tableOfContents,
      scrollController: widget.tab.scrollController,
      closeLeftPaneCallback: closeLeftPane,
    );
  }

  LinksViewer buildLinkView() {
    return LinksViewer(
      links: widget.tab.links,
      openTabcallback: widget.openBookCallback,
      itemPositionsListener: widget.tab.positionsListener,
      closeLeftPanelCallback: closeLeftPane,
    );
  }

  CommentatorsListView buildCommentaryView() {
    return CommentatorsListView(
      tab: widget.tab,
    );
  }

  void closeLeftPane() {
    widget.tab.showLeftPane.value = false;
  }
}
