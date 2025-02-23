import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/text_book/view/simple_book_view.dart';
import 'package:otzaria/text_book/view/commentary_list.dart';

class SplitedViewScreenBloc extends StatelessWidget {
  const SplitedViewScreenBloc({
    super.key,
    required this.tab,
    required this.content,
    required this.openBookCallback,
    required this.searchTextController,
  });

  final TextBookTab tab;
  final List<String> content;
  final void Function(OpenedTab) openBookCallback;
  final TextEditingValue searchTextController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: tab.commentatorsToShow,
      builder: (context, commentariesNames, child) => MultiSplitView(
        controller: tab.splitController,
        axis: Axis.horizontal,
        resizable: true,
        dividerBuilder:
            (axis, index, resizable, dragging, highlighted, themeData) =>
                const VerticalDivider(),
        children: [
          SelectionArea(
            child: ValueListenableBuilder(
              valueListenable: tab.selectedIndex,
              builder: (context, selectedIndex, child) {
                return CommentaryList(
                  index:
                      0, // we don't need the index here, b/c we listen to the selected index in the commentary list
                  textBookTab: tab,
                  fontSize: tab.textFontSize,
                  openBookCallback: openBookCallback,
                  showSplitView: tab.showSplitedView,
                );
              },
            ),
          ),
          SimpleBookView(
            tab: tab,
            data: content,
            textSize: tab.textFontSize,
            openBookCallback: openBookCallback,
            showSplitedView: tab.showSplitedView,
          )
        ],
      ),
    );
  }
}
