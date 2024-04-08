import 'package:flutter/material.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:otzaria/model/books.dart';
import 'dart:isolate';
import 'dart:io';
import 'package:otzaria/model/links.dart';
import 'package:otzaria/widgets/commentary_content.dart';

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
    thisLinks = getLinksforIndex(
        links: widget.textBookTab.links,
        commentariesNames: widget.textBookTab.commentariesToShow.value,
        index: widget.index);
    // in case we are inside a splited view, we need to listen to the item positions
    if (Settings.getValue<bool>('key-splited-view') ?? false) {
      widget.textBookTab.positionsListener.itemPositions.addListener(() {
        if (mounted) {
          setState(() {
            thisLinks = getLinksforIndex(
                links: widget.textBookTab.links,
                commentariesNames: widget.textBookTab.commentariesToShow.value,
                index: widget.textBookTab.positionsListener.itemPositions.value
                        .isEmpty
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

  Future<List<Link>> getLinksforIndex(
      {required int index,
      required Future<List<Link>> links,
      required List<String> commentariesNames}) async {
    List<Link> doneLinks = await links;
    return Isolate.run(() async {
      List<Link> thisLinks = doneLinks
          .where((link) =>
              link.index1 == index + 1 &&
              (link.connectionType == "commentary" ||
                  link.connectionType == "targum") &&
              commentariesNames.contains(link.path2.split('\\').last))
          .toList();
      //sort the links by the heref in order of the commentariesToShow list
      thisLinks.sort((a, b) => commentariesNames
          .indexOf(a.path2.split(Platform.pathSeparator).last)
          .compareTo(commentariesNames
              .indexOf(b.path2.split(Platform.pathSeparator).last)));

      return thisLinks;
    });
  }
}


// function to highlight a search query in html text