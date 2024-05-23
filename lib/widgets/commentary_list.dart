import 'package:flutter/material.dart';
import 'package:otzaria/models/tabs.dart';
import 'package:otzaria/models/links.dart';
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

class _CommentaryListState extends State<CommentaryList> {
  late Future<List<Link>> thisLinks;
  late List<int> indexes;

  void _updateThisLinks() {
    thisLinks = getLinksforIndexs(
        links: widget.textBookTab.links,
        commentatorsToShow: widget.textBookTab.commentatorsToShow.value,
        indexes: indexes);
  }

  @override
  void initState() {
    super.initState();
    indexes = [widget.index];
    _updateThisLinks();

    //we listen to the commentators
    widget.textBookTab.commentatorsToShow.addListener(() => setState(() {
          _updateThisLinks();
        }));

    // in case we are inside a splited view, we need to listen to the selected item and item positions
    if (widget.showSplitView.value) {
      /// listen to the selected item
      widget.textBookTab.selectedIndex.addListener(() {
        if (widget.textBookTab.selectedIndex.value != null) {
          setState(() {
            indexes = [widget.textBookTab.selectedIndex.value!];
            _updateThisLinks();
          });
        }
      });
      //listen to item positions
      widget.textBookTab.positionsListener.itemPositions.addListener(() {
        if (mounted) {
          setState(() {
            indexes = widget.textBookTab.positionsListener.itemPositions.value
                .map((e) => e.index)
                .toList();
            _updateThisLinks();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    widget.textBookTab.positionsListener.itemPositions.removeListener(() {});
    widget.textBookTab.commentatorsToShow.removeListener(() {});
    widget.textBookTab.selectedIndex.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: thisLinks,
      builder: (context, thisLinksSnapshot) {
        if (thisLinksSnapshot.hasData) {
          return thisLinksSnapshot.data!.isEmpty
              ? const SizedBox.shrink()
              : ValueListenableBuilder(
                  valueListenable: widget.textBookTab.removeNikud,
                  builder: (context, _, child) {
                    return ListView.builder(
                      key: PageStorageKey(thisLinksSnapshot.data![0].heRef),
                      physics: const ClampingScrollPhysics(),
                      primary: true,
                      shrinkWrap: true,
                      itemCount: thisLinksSnapshot.data!.length,
                      itemBuilder: (context, index1) => GestureDetector(
                        child: ListTile(
                          title: Text(thisLinksSnapshot.data![index1].heRef),
                          subtitle: CommentaryContent(
                            link: thisLinksSnapshot.data![index1],
                            fontSize: widget.fontSize,
                            openBookCallback: widget.openBookCallback,
                            removeNikud: widget.textBookTab.removeNikud.value,
                          ),
                        ),
                      ),
                    );
                  });
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
