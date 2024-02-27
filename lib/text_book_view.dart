import 'package:flutter/material.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:otzaria/main_window_view.dart';
import 'package:otzaria/text_book_search_view.dart';
import 'dart:io';
import 'package:otzaria/toc_viewer.dart';
import 'dart:math';
import 'html_view.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'links_view.dart';

class TextBookViewer extends StatefulWidget {
  final File file;
  late Future<String> data;
  final BookTabWindow tab;
  final Function(TabWindow) openBookCallback;

  TextBookViewer({
    Key? key,
    required this.file,
    required this.tab,
    required this.openBookCallback,
  }) : super(key: key) {
    data = file.readAsString();
  }

  @override
  State<TextBookViewer> createState() => _TextBookViewerState();
}

class _TextBookViewerState extends State<TextBookViewer>
    with AutomaticKeepAliveClientMixin<TextBookViewer> {
  double textFontSize = Settings.getValue('key-font-size') ?? 25.0;
  final showLeftPane = ValueNotifier<bool>(false);

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

  Expanded buildHTMLViewer() {
    return Expanded(
      child: FutureBuilder(
          future: widget.data.then((value) => value),
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
                            if (searchTextController.text.isEmpty) {
                              Future.microtask(() {
                                //showLeftPane.value = false;
                              });
                            }

                            return false; // Don't block the notification
                          },
                          child: HtmlView(
                            key: PageStorageKey(widget.tab),
                            data: snapshot.data!.split('\n'),
                            scrollController: widget.tab.scrollController,
                            itemPositionsListener: widget.tab.positionsListener,
                            scrollOffsetController:
                                widget.tab.scrollOffsetController,
                            searchQuery: searchTextController.text,
                            textSize: textFontSize,
                            initalIndex: widget.tab.initalIndex,
                          ),
                        )));
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
          width: showLeftPane ? 300 : 0,
          child: child!,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(1, 0, 4, 0),
          child: DefaultTabController(
            length: 3,
            child: Column(children: [
              const TabBar(tabs: [
                Tab(text: 'ניווט'),
                Tab(text: 'חיפוש'),
                Tab(text: 'קישורים')
              ]),
              Expanded(
                child: TabBarView(children: [
                  buildTocViewer(),
                  buildSearchView(),
                  buildLinkView(),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  FutureBuilder<String> buildSearchView() {
    return FutureBuilder(
        future: widget.data.then((value) => value),
        builder: (context, snapshot) =>
            snapshot.connectionState == ConnectionState.done
                ? TextBookSearchView(
                    data: snapshot.data!,
                    scrollControler: widget.tab.scrollController,
                    searchTextController: widget.tab.searchTextController,
                  )
                : const CircularProgressIndicator());
  }

  FutureBuilder<String> buildTocViewer() {
    return FutureBuilder(
        future: widget.data.then((value) => value),
        builder: (context, snapshot) =>
            snapshot.connectionState == ConnectionState.done
                ? TocViewer(
                    data: snapshot.data!,
                    scrollController: widget.tab.scrollController,
                  )
                : const CircularProgressIndicator());
  }

  LinksViewer buildLinkView() {
    return LinksViewer(
      path:
          'links${Platform.pathSeparator}${widget.file.path.split(Platform.pathSeparator).last}_links.json',
      openTabcallback: widget.openBookCallback,
      itemPositionsListener: widget.tab.positionsListener,
    );
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
            }
            // button to scroll all the way down
            ),
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

  @override
  bool get wantKeepAlive => true;
}
