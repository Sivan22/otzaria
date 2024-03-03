// a widget that takes an html strings array and displays it as a widget
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'links_view.dart';
import 'dart:io';
import 'dart:isolate';

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
      required this.textSize});

  @override
  State<CombinedView> createState() => _CombinedViewState();
}

class _CombinedViewState extends State<CombinedView>
    with AutomaticKeepAliveClientMixin<CombinedView> {
  static const Map<String, FontWeight> fontWeights = {
    'normal': FontWeight.normal,
    'bold': FontWeight.bold,
    'w600': FontWeight.w600,
  };
  late List<String> combinedData;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return buildKeyboardListener();
  }

  KeyboardListener buildKeyboardListener() {
    return KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
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
                          fontWeight: fontWeights[
                              Settings.getValue('key-font-weight') ?? 'normal'],
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

                  return thisLinks.isEmpty
                      ? const SizedBox.shrink()
                      : SizedBox.fromSize(
                          size: const Size.fromHeight(250),
                          child: ListView.builder(
                            key: PageStorageKey(thisLinks[0].heRef),
                            itemCount: thisLinks.length,
                            itemBuilder: (context, smallindex) => ListTile(
                                title: Text(thisLinks[smallindex].heRef),
                                subtitle: buildCommentaryContent(
                                    thisLinks, smallindex)),
                          ),
                        );
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              });
        });
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
                  fontWeight: fontWeights[
                      Settings.getValue('key-font-weight') ?? 'normal'],
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
