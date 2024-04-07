import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:otzaria/links_view.dart';
import 'dart:io';
import 'package:otzaria/opened_tabs.dart';
import 'dart:isolate';

import 'package:otzaria/provider_combined_view.dart';

class CommentaryList extends StatefulWidget {
  final Function(TextBookTab) openBookCallback;
  final TextBookTab textBookTab;
  final double fontSize;
  final int index;

  const CommentaryList({
    super.key,
    required this.openBookCallback,
    required this.textBookTab,
    required this.fontSize,
    required this.index,
  });

  @override
  State<CommentaryList> createState() => _CommentaryListState();
}

class _CommentaryListState extends State<CommentaryList>
    with AutomaticKeepAliveClientMixin<CommentaryList> {
  late Future<String> content;
  late Future<List<Link>> thisLinks;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    thisLinks = getThisLinks(widget.textBookTab.links,
        widget.textBookTab.commentariesToShow.value, widget.index);
    // in case we are inside a splited view, we need to listen to the item positions
    if (Settings.getValue<bool>('key-splited-view') ?? false) {
      widget.textBookTab.positionsListener.itemPositions.addListener(() {
        if (mounted) {
          setState(() {
            thisLinks = getThisLinks(
                widget.textBookTab.links,
                widget.textBookTab.commentariesToShow.value,
                widget.textBookTab.positionsListener.itemPositions.value.isEmpty
                    ? 0
                    : widget.textBookTab.positionsListener.itemPositions.value
                        .first.index);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    widget.textBookTab.positionsListener.itemPositions.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
      future: thisLinks,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.data!.isEmpty
              ? const SizedBox.shrink()
              : ListView.builder(
                  key: PageStorageKey(snapshot.data![0].heRef),
                  physics: const ClampingScrollPhysics(),
                  primary: true,
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, smallindex) => GestureDetector(
                    child: ListTile(
                      title: Text(snapshot.data![smallindex].heRef),
                      subtitle: CommentaryContent(
                        smallindex: smallindex,
                        thisLinks: snapshot.data!,
                        fontSize: widget.fontSize,
                        openBookCallback: widget.openBookCallback,
                      ),
                    ),
                  ),
                );
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}

class CommentaryContent extends StatefulWidget {
  const CommentaryContent({
    super.key,
    required this.smallindex,
    required this.thisLinks,
    required this.fontSize,
    required this.openBookCallback,
  });
  final List<Link> thisLinks;
  final int smallindex;
  final double fontSize;
  final Function(TextBookTab) openBookCallback;

  @override
  State<CommentaryContent> createState() => _CommentaryContentState();
}

class _CommentaryContentState extends State<CommentaryContent>
    with AutomaticKeepAliveClientMixin<CommentaryContent> {
  late Future<String> content;

  @override
  void initState() {
    content = getContent(
        Settings.getValue<String>('key-library-path') ?? './',
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
                String path =
                    (Settings.getValue<String>('key-library-path') ?? './') +
                        Platform.pathSeparator +
                        widget.thisLinks[widget.smallindex].path2
                            .replaceAll('\\', Platform.pathSeparator);
                widget.openBookCallback(TextBookTab(
                  path,
                  widget.thisLinks[widget.smallindex].index2 - 1,
                ));
              },
              child: Html(data: snapshot.data, style: {
                'body': Style(
                    fontSize: FontSize(widget.fontSize / 1.2),
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

Future<String> getContent(
    String libraryRootPath, String path, int index) async {
  path = libraryRootPath +
      Platform.pathSeparator +
      path.replaceAll('\\', Platform.pathSeparator);
  return Isolate.run(() async {
    List<String> lines = await File(path).readAsLines();
    String line = lines[index - 1];
    return line;
  });
}

// function to highlight a search query in html text