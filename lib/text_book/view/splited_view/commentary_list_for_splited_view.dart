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
  final VoidCallback? onClosePane;

  const CommentaryList({
    super.key,
    required this.openBookCallback,
    required this.fontSize,
    required this.index,
    required this.showSplitView,
    this.onClosePane,
  });

  @override
  State<CommentaryList> createState() => _CommentaryListState();
}

class _CommentaryListState extends State<CommentaryList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late Future<List<Link>> thisLinks;
  late List<int> indexes;
  final ScrollOffsetController scrollController = ScrollOffsetController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextBookBloc, TextBookState>(builder: (context, state) {
      if (state is! TextBookLoaded) return const Center();
      final indexes = state.selectedIndex != null
          ? [state.selectedIndex!]
          : state.visibleIndices;

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'חפש בתוך הפרשנים המוצגים...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    iconSize: 18,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClosePane,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: getLinksforIndexs(
                  indexes: indexes,
                  links: state.links,
                  commentatorsToShow: state.activeCommentators),
              builder: (context, thisLinksSnapshot) {
                if (!thisLinksSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (thisLinksSnapshot.data!.isEmpty) {
                  return const Center(child: Text("לא נמצאו פרשנים להצגה"));
                }
                return ProgressiveScroll(
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
                    itemBuilder: (context, index1) => ListTile(
                      title: Text(thisLinksSnapshot.data![index1].heRef),
                      subtitle: CommentaryContent(
                        link: thisLinksSnapshot.data![index1],
                        fontSize: widget.fontSize,
                        openBookCallback: widget.openBookCallback,
                        removeNikud: state.removeNikud,
                        searchQuery: _searchQuery, // העברת החיפוש
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}
