import 'package:flutter/material.dart';
import 'package:otzaria/model/tabs.dart';
import 'package:otzaria/model/links.dart';
import 'package:otzaria/widgets/commentary_content.dart';

class CommentaryList extends StatefulWidget {
  final Function(TextBookTab) openBookCallback;
  final TextBookTab textBookTab;
  final double fontSize;
  final int index;
  final ValueNotifier<bool> showSplitView;

  const CommentaryList({
    super.key,
    required this.openBookCallback,
    required this.textBookTab,
    required this.fontSize,
    required this.index,
    required this.showSplitView,
  });

  @override
  State<CommentaryList> createState() => _CommentaryListState();
}

class _CommentaryListState extends State<CommentaryList>
    with AutomaticKeepAliveClientMixin<CommentaryList> {
  late Future<List<Link>> thisLinks;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    thisLinks = getLinksforIndexs(
        links: widget.textBookTab.links,
        commentatorsToShow: widget.textBookTab.commentariesToShow.value,
        indexes: [widget.index]);

    // in case we are inside a splited view, we need to listen to the item positions
    if (widget.showSplitView.value) {
      widget.textBookTab.positionsListener.itemPositions.addListener(() {
        if (mounted) {
          setState(() {
            thisLinks = getLinksforIndexs(
              links: widget.textBookTab.links,
              commentatorsToShow: widget.textBookTab.commentariesToShow.value,
              indexes: widget.textBookTab.positionsListener.itemPositions.value
                  .map((e) => e.index)
                  .toList(),
            );
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
      builder: (context, thisLinksSnapshot) {
        if (thisLinksSnapshot.hasData) {
          return thisLinksSnapshot.data!.isEmpty
              ? const SizedBox.shrink()
              : ListView.builder(
                  key: PageStorageKey(thisLinksSnapshot.data![0].heRef),
                  physics: const ClampingScrollPhysics(),
                  primary: true,
                  shrinkWrap: true,
                  itemCount: thisLinksSnapshot.data!.length,
                  itemBuilder: (context, index1) => GestureDetector(
                    child: ListTile(
                      title: Text(thisLinksSnapshot.data![index1].heRef),
                      subtitle:
                          buildCommentaryContent(index1, thisLinksSnapshot),
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

  Widget buildCommentaryContent(
      int smallindex, AsyncSnapshot<List<Link>> snapshot) {
    return CommentaryContent(
      link: snapshot.data![smallindex],
      fontSize: widget.fontSize,
      openBookCallback: widget.openBookCallback,
    );
  }
}
