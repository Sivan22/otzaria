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
  int _currentSearchIndex = 0;
  int _totalSearchResults = 0;
  final Map<int, int> _searchResultsPerItem = {};

  int _getItemSearchIndex(int itemIndex) {
    int cumulativeIndex = 0;
    for (int i = 0; i < itemIndex; i++) {
      cumulativeIndex += _searchResultsPerItem[i] ?? 0;
    }

    final itemResults = _searchResultsPerItem[itemIndex] ?? 0;
    if (itemResults == 0) return -1;

    final relativeIndex = _currentSearchIndex - cumulativeIndex;
    return (relativeIndex >= 0 && relativeIndex < itemResults)
        ? relativeIndex
        : -1;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToSearchResult() {
    if (_totalSearchResults == 0) return;

    // מחשבים באיזה פריט נמצאת התוצאה הנוכחית
    int cumulativeIndex = 0;
    int targetItemIndex = 0;

    for (int i = 0; i < _searchResultsPerItem.length; i++) {
      final itemResults = _searchResultsPerItem[i] ?? 0;
      if (_currentSearchIndex < cumulativeIndex + itemResults) {
        targetItemIndex = i;
        break;
      }
      cumulativeIndex += itemResults;
    }

    // גוללים לפריט הרלוונטי
    try {
      scrollController.animateScroll(
        offset: targetItemIndex * 100.0, // הערכה גסה של גובה פריט
        duration: const Duration(milliseconds: 300),
      );
    } catch (e) {
      // אם יש בעיה עם הגלילה, נתעלם מהשגיאה
    }
  }

  void _updateSearchResultsCount(int itemIndex, int count) {
    if (mounted) {
      setState(() {
        _searchResultsPerItem[itemIndex] = count;
        _totalSearchResults =
            _searchResultsPerItem.values.fold(0, (sum, count) => sum + count);
        if (_currentSearchIndex >= _totalSearchResults &&
            _totalSearchResults > 0) {
          _currentSearchIndex = _totalSearchResults - 1;
        }
      });
    }
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
                      hintText: 'חפש בתוך המפרשים המוצגים...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_totalSearchResults > 1) ...[
                                  Text(
                                    '${_currentSearchIndex + 1}/$_totalSearchResults',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.keyboard_arrow_up),
                                    iconSize: 20,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                    onPressed: _currentSearchIndex > 0
                                        ? () {
                                            setState(() {
                                              _currentSearchIndex--;
                                            });
                                            _scrollToSearchResult();
                                          }
                                        : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.keyboard_arrow_down),
                                    iconSize: 20,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                    onPressed: _currentSearchIndex <
                                            _totalSearchResults - 1
                                        ? () {
                                            setState(() {
                                              _currentSearchIndex++;
                                            });
                                            _scrollToSearchResult();
                                          }
                                        : null,
                                  ),
                                ],
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _currentSearchIndex = 0;
                                      _totalSearchResults = 0;
                                      _searchResultsPerItem.clear();
                                    });
                                  },
                                ),
                              ],
                            )
                          : null,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _currentSearchIndex = 0;
                        if (value.isEmpty) {
                          _totalSearchResults = 0;
                          _searchResultsPerItem.clear();
                        }
                      });
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
                  return const Center(child: Text("לא נמצאו מפרשים להצגה"));
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
                        currentSearchIndex: _getItemSearchIndex(index1),
                        onSearchResultsCountChanged: (count) =>
                            _updateSearchResultsCount(index1, count),
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
