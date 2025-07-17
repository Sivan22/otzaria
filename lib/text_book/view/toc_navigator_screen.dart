import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/utils/ref_helper.dart';
import 'package:flutter/scheduler.dart';

class TocViewer extends StatefulWidget {
  const TocViewer({
    super.key,
    required this.scrollController,
    required this.closeLeftPaneCallback,
    required this.focusNode,
  });

  final void Function() closeLeftPaneCallback;
  final ItemScrollController scrollController;
  final FocusNode focusNode;

  @override
  State<TocViewer> createState() => _TocViewerState();
}

class _TocViewerState extends State<TocViewer>
    with AutomaticKeepAliveClientMixin<TocViewer> {
  @override
  bool get wantKeepAlive => true;

final TextEditingController searchController = TextEditingController();
  final ScrollController _tocScrollController = ScrollController();
  final Map<int, GlobalKey> _tocItemKeys = {};
  bool _isManuallyScrolling = false;
  int? _lastScrolledTocIndex;

  @override
  void dispose() {
    _tocScrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _scrollToActiveItem(TextBookLoaded state) {
    if (_isManuallyScrolling) return;

    final int? activeIndex = state.selectedIndex ??
        (state.visibleIndices.isNotEmpty
            ? closestTocEntryIndex(
                state.tableOfContents, state.visibleIndices.first)
            : null);
 
    if (activeIndex == null || activeIndex == _lastScrolledTocIndex) return;

    // נחכה פריים אחד נוסף כדי שה-setState יסיים וה-UI יתעדכן
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isManuallyScrolling) return;

      final key = _tocItemKeys[activeIndex];
      final itemContext = key?.currentContext;
      if (itemContext == null) return;
      
      final itemRenderObject = itemContext.findRenderObject();
      if (itemRenderObject is! RenderBox) return;

      final scrollableBox = _tocScrollController.position.context.storageContext.findRenderObject() as RenderBox;
      
      final itemOffset = itemRenderObject.localToGlobal(Offset.zero, ancestor: scrollableBox).dy;
      final viewportHeight = scrollableBox.size.height;
      final itemHeight = itemRenderObject.size.height;
      
      final target = _tocScrollController.offset + itemOffset - (viewportHeight / 2) + (itemHeight / 2);
      
      _tocScrollController.animateTo(
        target.clamp(
          0.0,
          _tocScrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      _lastScrolledTocIndex = activeIndex;
    });
  }

  Widget _buildFilteredList(List<TocEntry> entries, BuildContext context) {
    List<TocEntry> allEntries = [];
    void getAllEntries(List<TocEntry> entries) {
      for (final TocEntry entry in entries) {
        allEntries.add(entry);
        getAllEntries(entry.children);
      }
    }

    getAllEntries(entries);
    allEntries = allEntries
        .where((e) => e.text.contains(searchController.text))
        .toList();

    return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: allEntries.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                0, 0, 10 * allEntries[index].level.toDouble(), 0),
        child: allEntries[index].children.isEmpty
            ? Material(
                color: Colors.transparent,
                child: ListTile(
                  title: Text(allEntries[index].fullText),
                  onTap: () {
                      setState(() {
                        _isManuallyScrolling = false;
                        _lastScrolledTocIndex = null;
                      });
                      widget.scrollController.scrollTo(
                        index: allEntries[index].index,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.ease,
                      );
                      if (Platform.isAndroid) {
                        widget.closeLeftPaneCallback();
                      }
                    },
                  ),
                )
                : _buildTocItem(allEntries[index], showFullText: true),
          );
        });
  }

  Widget _buildTocItem(TocEntry entry, {bool showFullText = false}) {
    final itemKey = _tocItemKeys.putIfAbsent(entry.index, () => GlobalKey());
    void navigateToEntry() {
      setState(() {
        _isManuallyScrolling = false;
        _lastScrolledTocIndex = null;
      });
      widget.scrollController.scrollTo(
        index: entry.index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
      );
      if (Platform.isAndroid) {
        widget.closeLeftPaneCallback();
      }
    }

    if (entry.children.isEmpty) {
      return Padding(
        key: itemKey,
        padding: EdgeInsets.fromLTRB(0, 0, 10 * entry.level.toDouble(), 0),
        child: BlocBuilder<TextBookBloc, TextBookState>(
          builder: (context, state) {
            final int? autoIndex = state is TextBookLoaded &&
                    state.selectedIndex == null &&
                    state.visibleIndices.isNotEmpty
                ? closestTocEntryIndex(
                    state.tableOfContents, state.visibleIndices.first)
                : null;
            final bool selected = state is TextBookLoaded &&
                ((state.selectedIndex != null &&
                        state.selectedIndex == entry.index) ||
                    autoIndex == entry.index);
            return Material(
              color: Colors.transparent,
              child: ListTile(
                title: Text(entry.text),
                selected: selected,
                selectedColor: Theme.of(context).colorScheme.onSecondaryContainer,
                selectedTileColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                onTap: navigateToEntry,
              ),
            );
          },
        ),
      );
    } else {
      return Padding(
        key: itemKey,
        padding: EdgeInsets.fromLTRB(0, 0, 10 * entry.level.toDouble(), 0),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            initiallyExpanded: entry.level == 1,
            title: BlocBuilder<TextBookBloc, TextBookState>(
              builder: (context, state) {
                final int? autoIndex = state is TextBookLoaded &&
                        state.selectedIndex == null &&
                        state.visibleIndices.isNotEmpty
                    ? closestTocEntryIndex(
                        state.tableOfContents, state.visibleIndices.first)
                    : null;
                final bool selected = state is TextBookLoaded &&
                    ((state.selectedIndex != null &&
                            state.selectedIndex == entry.index) ||
                        autoIndex == entry.index);
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    title: Text(showFullText ? entry.fullText : entry.text),
                    selected: selected,
                    selectedColor: Theme.of(context).colorScheme.onSecondary,
                    selectedTileColor:
                        Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                    onTap: navigateToEntry,
                    contentPadding: EdgeInsets.zero,
                  ),
                );
              },
            ),
            leading: const Icon(Icons.chevron_right_rounded),
            trailing: const SizedBox.shrink(),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            iconColor: Theme.of(context).colorScheme.primary,
            collapsedIconColor: Theme.of(context).colorScheme.primary,
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entry.children.length,
                itemBuilder: (context, index) {
                  return _buildTocItem(entry.children[index]);
                },
              ),
            ],
          ),
        ),
      );
    }
  }

@override
Widget build(BuildContext context) {
  super.build(context);
  // הוספנו BlocListener שעוטף את כל מה שהיה קודם
  return BlocListener<TextBookBloc, TextBookState>(
    // listenWhen קובע מתי ה-listener יופעל, כדי למנוע הפעלות מיותרות
    listenWhen: (previous, current) {
      if (current is! TextBookLoaded) return false;
      if (previous is! TextBookLoaded) return true; // הפעלה ראשונה

      // הפעל רק אם האינדקס הנבחר או האינדקס הנראה השתנו
      final prevVisibleIndex = previous.visibleIndices.isNotEmpty ? previous.visibleIndices.first : -1;
      final currVisibleIndex = current.visibleIndices.isNotEmpty ? current.visibleIndices.first : -1;
      
      return previous.selectedIndex != current.selectedIndex || prevVisibleIndex != currVisibleIndex;
    },
    // listener היא הפונקציה שתרוץ כשהתנאי ב-listenWhen מתקיים
    listener: (context, state) {
      if (state is TextBookLoaded) {
        _scrollToActiveItem(state);
      }
    },
    // ה-child הוא ה-UI הקיים שלא השתנה
    child: BlocBuilder<TextBookBloc, TextBookState>(
      bloc: context.read<TextBookBloc>(),
      builder: (context, state) {
        if (state is! TextBookLoaded) return const Center();
        // שימו לב שכאן כבר אין קריאה ל-_scrollToActiveItem
        return Column(
          children: [
            TextField(
                controller: searchController,
                onChanged: (value) => setState(() {}),
                focusNode: widget.focusNode,
                autofocus: true,
                onSubmitted: (_) {
                  widget.focusNode.requestFocus();
                },
                decoration: InputDecoration(
                  hintText: 'איתור כותרת...',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            searchController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollStartNotification && notification.dragDetails != null) {
                      setState(() {
                        _isManuallyScrolling = true;
                      });
                    } else if (notification is ScrollEndNotification) {
                      setState(() {
                        _isManuallyScrolling = false;
                      });
                    }
                    return false;
                  },
                  child: SingleChildScrollView( // אנחנו עדיין משאירים את המבנה המקורי שלך
                    controller: _tocScrollController,
                    child: searchController.text.isEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.tableOfContents.length,
                          itemBuilder: (context, index) =>
                              _buildTocItem(state.tableOfContents[index]))
                      : _buildFilteredList(state.tableOfContents, context),
                ),
              ),
            ),
            ],
          );
        }),
  );
  }
}
