// a widget that takes an html strings array and displays it as a widget
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'links_view.dart';
import 'dart:io';
import 'main_window_view.dart';

class CombinedView extends StatefulWidget {
  final List<String> data;
  final ValueNotifier<List<String>> commentariesToShow;
  final Future<List<Link>> links;
  final int initalIndex;
  final double textSize;
  final ItemScrollController scrollController;
  final ScrollOffsetController scrollOffsetController;
  final ItemPositionsListener itemPositionsListener;
  final String searchQuery;
  final Function(TabWindow) openBookCallback;

  const CombinedView(
      {super.key,
      required this.data,
      required this.commentariesToShow,
      required this.initalIndex,
      required this.scrollController,
      required this.scrollOffsetController,
      required this.itemPositionsListener,
      required this.searchQuery,
      required this.links,
      required this.openBookCallback,
      required this.textSize});

  @override
  State<CombinedView> createState() => _CombinedViewState();
}

class _CombinedViewState extends State<CombinedView>
    with AutomaticKeepAliveClientMixin<CombinedView> {
  FocusNode focusNode = FocusNode();

  late List<String> combinedData;
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return buildKeyboardListener();
    //return buildSelectionArea();
  }

  KeyboardListener buildKeyboardListener() {
    return KeyboardListener(
        focusNode: focusNode,
        onKeyEvent: (KeyEvent event) {
          if (event.logicalKey.keyLabel == 'Arrow Down') {
            widget.scrollOffsetController.animateScroll(
                offset: 150,
                duration: const Duration(
                    milliseconds: 300)); // Adjust scroll amount as needed
          } else if (event.logicalKey.keyLabel == 'Arrow Up') {
            widget.scrollOffsetController.animateScroll(
                offset: -150,
                duration: const Duration(
                    milliseconds: 300)); // Adjust scroll amount as needed
          }
        },
        child: buildSelectionArea());
  }

  SelectionArea buildSelectionArea() {
    return SelectionArea(
        child: ScrollablePositionedList.builder(
            initialScrollIndex: widget.initalIndex,
            itemPositionsListener: widget.itemPositionsListener,
            itemScrollController: widget.scrollController,
            scrollOffsetController: widget.scrollOffsetController,
            itemCount: widget.data.length,
            itemBuilder: (context, index) => ExpansionTile(
                shape: const Border(),
                key: PageStorageKey(widget.data[index]),
                iconColor: Colors.transparent,
                collapsedIconColor: Colors.transparent,
                title: Html(
                    data: highLight(widget.data[index], widget.searchQuery),
                    style: {
                      'body': Style(
                          fontSize: FontSize(widget.textSize),
                          fontFamily:
                              Settings.getValue('key-font-family') ?? 'candara',
                          textAlign: TextAlign.justify),
                    }),
                children: [buildInnerListView(index)])));
  }

  ListenableBuilder buildInnerListView(int index) {
    return ListenableBuilder(
        listenable: widget.commentariesToShow,
        builder: (context, child) {
          return FutureBuilder(
              future: widget.links,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<Link> thisLinks = snapshot.data!
                      .where((link) =>
                          link.index1 == index + 1 &&
                          (link.connectionType == "commentary" ||
                              link.connectionType == "targum") &&
                          widget.commentariesToShow.value.contains(
                              link.path2.split(Platform.pathSeparator).last))
                      .toList();
                  //sort the links by the heref in order of the commentariesToShow list
                  thisLinks.sort((a, b) => widget.commentariesToShow.value
                      .indexOf(a.path2.split(Platform.pathSeparator).last)
                      .compareTo(widget.commentariesToShow.value.indexOf(
                          b.path2.split(Platform.pathSeparator).last)));

                  return buildDynamicContent(thisLinks);
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              });
        });
  }

  Widget buildDynamicContent(List<Link> thisLinks) {
    return thisLinks.isEmpty
        ? const SizedBox.shrink()
        : DynamicContent(
            fixedHeight: 200.0,
            listView: ListView.builder(
              key: PageStorageKey(thisLinks[0].heRef),
              primary: true,
              shrinkWrap: true,
              itemCount: thisLinks.length,
              itemBuilder: (context, smallindex) => ListTile(
                title: Text(thisLinks[smallindex].heRef),
                subtitle: buildCommentaryContent(thisLinks, smallindex),
                onTap: () {
                  //open the reference in a new tab
                  widget.openBookCallback(BookTabWindow(
                    thisLinks[smallindex]
                        .path2
                        .replaceFirst('..\\..\\refs\\', ''),
                    thisLinks[smallindex].index2 - 1,
                  ));
                },
              ),
            ),
          );
  }

  FutureBuilder<String> buildCommentaryContent(
      List<Link> thisLinks, int smallindex) {
    return FutureBuilder(
        future: getContent(
            thisLinks[smallindex].path2, thisLinks[smallindex].index2),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Html(data: snapshot.data, style: {
              'body': Style(
                  fontSize: FontSize(widget.textSize / 1.2),
                  fontFamily: Settings.getValue('key-font-family') ?? 'candara',
                  textAlign: TextAlign.justify),
            });
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        });
  }

  @override
  bool get wantKeepAlive => true;
}

// function to highlight a search query in html text
String highLight(String data, String searchQuery) {
  if (searchQuery.isNotEmpty) {
    return data.replaceAll(searchQuery, '<font color=red>$searchQuery</font>');
  }
  return data;
}

Future<String> getContent(String path, int index) async {
  path = path.replaceFirst('..\\..\\refs\\', '');
  List<String> lines = await File(path).readAsLines();
  String line = lines[index - 1];
  return line;
}

class DynamicContent extends StatefulWidget {
  final ListView listView;
  final double fixedHeight;
  const DynamicContent(
      {Key? key, required this.listView, required this.fixedHeight})
      : super(key: key);

  @override
  State<DynamicContent> createState() => _DynamicContentState();
}

class _DynamicContentState extends State<DynamicContent> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.ease,
          height: isExpanded ? null : widget.fixedHeight,
          child: widget.listView),
    );
  }
}
