import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/models/links.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/text_book/view/combined_view/commentary_content.dart';
import 'package:otzaria/widgets/progressive_scrolling.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class CommentaryList extends StatefulWidget {
  final Function(TextBookTab) openBookCallback;
  final double fontSize;
  final int index;
  final bool showSplitView;

  const CommentaryList({
    super.key,
    required this.openBookCallback,
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
  final ScrollOffsetController scrollController = ScrollOffsetController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextBookBloc, TextBookState>(builder: (context, state) {
      if (state is! TextBookLoaded) return const Center();
      final indexes = state.selectedIndex != null
          ? [state.selectedIndex!]
          : state.visibleIndices;
      return FutureBuilder(
        future: getLinksforIndexs(
            indexes: indexes,
            links: state.links,
            commentatorsToShow: state.activeCommentators),
        builder: (context, thisLinksSnapshot) {
          if (thisLinksSnapshot.hasData) {
            return thisLinksSnapshot.data!.isEmpty
                ? const SizedBox.shrink()
                : ProgressiveScroll(
                    scrollController: scrollController,
                    maxSpeed: 10000.0,
                    curve: 10.0,
                    accelerationFactor: 5,
                    child: ScrollablePositionedList.builder(
                      key: PageStorageKey(thisLinksSnapshot.data![0].heRef),
                      physics: const ClampingScrollPhysics(),
                      scrollOffsetController: scrollController,
                      shrinkWrap: true,
                      itemCount: thisLinksSnapshot.data!.length,
                      itemBuilder: (context, index1) => GestureDetector(
                        child: ListTile(
                          title: Text(thisLinksSnapshot.data![index1].heRef),
                          subtitle: CommentaryContent(
                            link: thisLinksSnapshot.data![index1],
                            fontSize: widget.fontSize,
                            openBookCallback: widget.openBookCallback,
                            removeNikud: state.removeNikud,
                          ),
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
    });
  }
}
