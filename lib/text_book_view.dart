import 'package:flutter/material.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:otzaria/combined_book_commentary_view.dart';
import 'package:otzaria/main_window_view.dart';
import 'package:otzaria/text_book_search_view.dart';
import 'dart:io';
import 'package:otzaria/toc_viewer.dart';
import 'dart:math';
import 'links_view.dart';
import 'commentary_list_view.dart';
import 'package:flutter/services.dart';

class TextBookViewer extends StatefulWidget {
  final String path;
  final BookTabWindow tab;
  final Function(TabWindow) openBookCallback;
  final Future<String> data;

  const TextBookViewer({
    Key? key,
    required this.path,
    required this.tab,
    required this.openBookCallback,
    required this.data,
  }) : super(key: key);

  @override
  State<TextBookViewer> createState() => _TextBookViewerState();
}

class _TextBookViewerState extends State<TextBookViewer>
    with
        AutomaticKeepAliveClientMixin<TextBookViewer>,
        TickerProviderStateMixin {
  double textFontSize = Settings.getValue('key-font-size') ?? 25.0;
  final showLeftPane = ValueNotifier<bool>(false);
  final FocusNode textSearchFocusNode = FocusNode();
  final ValueNotifier<bool> allTilesCollapsed = ValueNotifier<bool>(true);
  late TabController tabController;

  @override
  initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        appBar: buildAppBar(),
        body: Row(children: [
          buildTabBar(),
          buildHTMLViewer(),
        ]));
  }

  Widget buildHTMLViewer() {
    return Expanded(
      child: FutureBuilder(
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
                        child: NotificationListener<UserScrollNotification>(
                            onNotification: (scrollNotification) {
                              //unless links is shown, close left pane on scrolling
                              if (tabController.index != 3 &&
                                  (Settings.getValue<bool>(
                                          'key-close-left-pane-on-scroll') ??
                                      true)) {
                                Future.microtask(() {
                                  showLeftPane.value = false;
                                });
                              }

                              return false; // Don't block the notification
                            },
                            child: CallbackShortcuts(
                                bindings: <ShortcutActivator, VoidCallback>{
                                  LogicalKeySet(LogicalKeyboardKey.control,
                                      LogicalKeyboardKey.keyF): () {
                                    showLeftPane.value = true;
                                    tabController.index = 1;
                                  },
                                },
                                child: Focus(
                                  focusNode: FocusNode(),
                                  //don't autofocus on android, so that the keyboard doesn't appear
                                  autofocus: Platform.isAndroid ? false : true,
                                  child: CombinedView(
                                    commentariesToShow:
                                        widget.tab.commentariesNames,
                                    links: widget.tab.links,
                                    key: PageStorageKey(widget.tab),
                                    data: snapshot.data!.split('\n'),
                                    scrollController:
                                        widget.tab.scrollController,
                                    itemPositionsListener:
                                        widget.tab.positionsListener,
                                    scrollOffsetController:
                                        widget.tab.scrollOffsetController,
                                    searchQuery: searchTextController.text,
                                    textSize: textFontSize,
                                    initalIndex: widget.tab.initalIndex,
                                    openBookCallback: widget.openBookCallback,
                                    libraryRootPath:
                                        widget.path.split('אוצריא').first,
                                  ),
                                )))));
              }
            }
            return const Center(child: CircularProgressIndicator());
          }),
    );
  }

  AnimatedSize buildTabBar() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: ValueListenableBuilder(
        valueListenable: showLeftPane,
        builder: (context, showLeftPane, child) => SizedBox(
          width: showLeftPane ? 350 : 0,
          child: child!,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(1, 0, 4, 0),
          child: Column(children: [
            TabBar(
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
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  buildTocViewer(),
                  buildSearchView(),
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

  FutureBuilder<String> buildTocViewer() {
    return FutureBuilder(
        future: widget.data,
        builder: (context, snapshot) =>
            snapshot.connectionState == ConnectionState.done
                ? TocViewer(
                    data: snapshot.data!,
                    scrollController: widget.tab.scrollController,
                    closeLeftPaneCallback: closeLeftPane,
                  )
                : const Center(child: CircularProgressIndicator()));
  }

  LinksViewer buildLinkView() {
    return LinksViewer(
      links: widget.tab.links,
      openTabcallback: widget.openBookCallback,
      itemPositionsListener: widget.tab.positionsListener,
      closeLeftPanelCallback: closeLeftPane,
      libraryRootPath: widget.path.split('אוצריא').first,
    );
  }

  CommentaryListView buildCommentaryView() {
    return CommentaryListView(
        links: widget.tab.links, commentaries: widget.tab.commentariesNames);
  }

  AppBar buildAppBar() {
    return AppBar(
      leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: "ניווט וחיפוש",
          onPressed: () {
            showLeftPane.value = !showLeftPane.value;
          }),
      actions: [
        //button to collapse all tiles
        // IconButton(
        //     icon: const Icon(Icons.expand_rounded),
        //     tooltip: 'הצג/הסתר פרשנות',
        //     onPressed: () => setState(() {
        //           allTilesCollapsed.value = !allTilesCollapsed.value;
        //         })),

        // button to open the search field
        IconButton(
          onPressed: () {
            showLeftPane.value = true;
            tabController.index = 1;
            textSearchFocusNode.requestFocus();
          },
          icon: const Icon(
            Icons.search,
          ),
          tooltip: 'חיפוש',
        ),

        // button to zoom in
        IconButton(
            icon: const Icon(
              Icons.zoom_in,
            ),
            tooltip: 'הגדל טקסט',
            onPressed: () => setState(() {
                  textFontSize = min(50.0, textFontSize + 3);
                })),
        IconButton(
          icon: const Icon(
            Icons.zoom_out,
          ),
          tooltip: 'הקטן טקסט',
          onPressed: () => setState(() {
            textFontSize = max(15.0, textFontSize - 3);
          }),
        ),
        // button to scroll all the way up
        IconButton(
            icon: const Icon(Icons.first_page),
            tooltip: 'תחילת הספר',
            onPressed: () {
              widget.tab.scrollController.scrollTo(
                  index: 0, duration: const Duration(milliseconds: 300));
            }),
        //button to scroll to previous section
        IconButton(
            icon: const Icon(Icons.navigate_before),
            tooltip: 'הקטע הקודם',
            onPressed: () {
              widget.tab.scrollController.scrollTo(
                  duration: const Duration(milliseconds: 300),
                  index: max(
                    0,
                    widget.tab.positionsListener.itemPositions.value.first
                            .index -
                        1,
                  ));
            }),
        //button to scroll to next section
        IconButton(
            icon: const Icon(Icons.navigate_next),
            tooltip: 'הקטע הבא',
            onPressed: () {
              widget.tab.scrollController.scrollTo(
                  index: max(
                      widget.tab.positionsListener.itemPositions.value.first
                              .index +
                          1,
                      widget.tab.positionsListener.itemPositions.value.length -
                          1),
                  duration: const Duration(milliseconds: 300));
            }),

        // button to scroll all the way down
        IconButton(
            icon: const Icon(Icons.last_page),
            tooltip: 'סוף הספר',
            onPressed: () async {
              widget.tab.scrollController.scrollTo(
                  index: await widget.data.then((value) => value.length),
                  duration: const Duration(milliseconds: 300));
            }),
      ],
    );
  }

  void closeLeftPane() {
    showLeftPane.value = false;
  }

  @override
  bool get wantKeepAlive => true;
}
