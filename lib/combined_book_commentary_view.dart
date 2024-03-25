// a widget that takes an html strings array and displays it as a widget
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'links_view.dart';
import 'dart:io';
import 'tab_window.dart';
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
  final Function(TabWindow) openBookCallback;
  final String libraryRootPath;

  const CombinedView({
    super.key,
    required this.data,
    required this.commentariesToShow,
    required this.initalIndex,
    required this.scrollController,
    required this.scrollOffsetController,
    required this.itemPositionsListener,
    required this.searchQuery,
    required this.links,
    required this.openBookCallback,
    required this.libraryRootPath,
    required this.textSize,
  });

  @override
  State<CombinedView> createState() => _CombinedViewState();
}

class _CombinedViewState extends State<CombinedView>
    with AutomaticKeepAliveClientMixin<CombinedView> {
  FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return buildKeyboardListener();
  }

  KeyboardListener buildKeyboardListener() {
    return KeyboardListener(
        focusNode: focusNode,
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
        child: buildOuterList());
  }

  Widget buildOuterList() {
    return SelectionArea(
      selectionControls: DesktopTextSelectionControls(),
      child: ScrollablePositionedList.builder(
          initialScrollIndex: widget.initalIndex,
          itemPositionsListener: widget.itemPositionsListener,
          itemScrollController: widget.scrollController,
          scrollOffsetController: widget.scrollOffsetController,
          itemCount: widget.data.length,
          itemBuilder: (context, index) {
            ExpansionTileController controller = ExpansionTileController();
            return buildExpansiomTile(controller, index);
          }),
    );
  }

  ExpansionTile buildExpansiomTile(
      ExpansionTileController controller, int index) {
    return ExpansionTile(
        shape: const Border(),
        //maintainState: true,
        controller: controller,
        key: PageStorageKey(widget.data[index]),
        iconColor: Colors.transparent,
        tilePadding: const EdgeInsets.all(0.0),
        collapsedIconColor: Colors.transparent,
        title: Html(
            data: highLight(widget.data[index], widget.searchQuery),
            style: {
              'body': Style(
                  fontSize: FontSize(widget.textSize),
                  fontFamily: Settings.getValue('key-font-family') ?? 'candara',
                  textAlign: TextAlign.justify),
            }),
        children: [linksFutureBuilder(index, controller)]);
  }

  Widget linksFutureBuilder(index, ExpansionTileController controller) {
    //first get all the links
    return FutureBuilder(
        future: widget.links,
        builder: (context, linksSnapshot) {
          if (linksSnapshot.hasData) {
            //then get the links for this index
            Future<List<Link>> thisLinks = getThisLinks(
                linksSnapshot.data!, widget.commentariesToShow.value, index);
            return thisLinksFutureBuilder(thisLinks, controller);
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        });
  }

  FutureBuilder<List<Link>> thisLinksFutureBuilder(
      Future<List<Link>> thisLinks, ExpansionTileController controller) {
    return FutureBuilder(
        future: thisLinks,
        builder: (context, thisLinksSnapshot) {
          if (thisLinksSnapshot.hasData) {
            return thisLinksSnapshot.data!.isEmpty
                ? const SizedBox.shrink()
                : buildInnerList(thisLinksSnapshot, controller);
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        });
  }

  ListView buildInnerList(AsyncSnapshot<List<Link>> thisLinksSnapshot,
      ExpansionTileController controller) {
    return ListView.builder(
      key: PageStorageKey(thisLinksSnapshot.data![0].heRef),
      physics: const ClampingScrollPhysics(),
      primary: true,
      shrinkWrap: true,
      itemCount: thisLinksSnapshot.data!.length,
      itemBuilder: (context, smallindex) => GestureDetector(
        onTap: () {
          int lasIindex =
              widget.itemPositionsListener.itemPositions.value.first.index;
          controller.collapse();
          widget.scrollController.jumpTo(index: lasIindex);
        },
        child: ListTile(
          title: Text(thisLinksSnapshot.data![smallindex].heRef),
          subtitle: buildCommentaryContent(thisLinksSnapshot.data!, smallindex),
        ),
      ),
    );
  }

  Widget buildCommentaryContent(List<Link> thisLinks, int smallindex) {
    return CommentaryContent(
      widget: widget,
      smallindex: smallindex,
      thisLinks: thisLinks,
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class CommentaryContent extends StatefulWidget {
  const CommentaryContent({
    super.key,
    required this.widget,
    required this.smallindex,
    required this.thisLinks,
  });
  final List<Link> thisLinks;
  final int smallindex;
  final CombinedView widget;

  @override
  State<CommentaryContent> createState() => _CommentaryContentState();
}

class _CommentaryContentState extends State<CommentaryContent>
    with AutomaticKeepAliveClientMixin<CommentaryContent> {
  late Future<String> content;

  @override
  void initState() {
    content = getContent(
        widget.widget.libraryRootPath,
        widget.thisLinks[widget.smallindex].path2,
        widget.thisLinks[widget.smallindex].index2);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
        future: content,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return GestureDetector(
              onDoubleTap: () {
                String path = widget.widget.libraryRootPath +
                    widget.thisLinks[widget.smallindex].path2
                        .replaceAll('\\', Platform.pathSeparator);
                widget.widget.openBookCallback(BookTabWindow(
                  path,
                  widget.thisLinks[widget.smallindex].index2 - 1,
                ));
              },
              child: Html(data: snapshot.data, style: {
                'body': Style(
                    fontSize: FontSize(widget.widget.textSize / 1.2),
                    fontFamily:
                        Settings.getValue('key-font-family') ?? 'candara',
                    textAlign: TextAlign.justify),
              }),
            );
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

Future<List<Link>> getThisLinks(
    List<Link> links, List<String> commentariesToShow, int index) async {
  return Isolate.run(() {
    List<Link> thisLinks = links
        .where((link) =>
            link.index1 == index + 1 &&
            (link.connectionType == "commentary" ||
                link.connectionType == "targum") &&
            commentariesToShow.contains(link.path2.split('\\').last))
        .toList();
    //sort the links by the heref in order of the commentariesToShow list
    thisLinks.sort((a, b) => commentariesToShow
        .indexOf(a.path2.split(Platform.pathSeparator).last)
        .compareTo(commentariesToShow
            .indexOf(b.path2.split(Platform.pathSeparator).last)));

    return thisLinks;
  });
}

Future<String> getContent(
    String libraryRootPath, String path, int index) async {
  return Isolate.run(() async {
    path = libraryRootPath + path.replaceAll('\\', Platform.pathSeparator);
    List<String> lines = await File(path).readAsLines();
    String line = lines[index - 1];
    return line;
  });
}
