import 'package:flutter/material.dart';
import 'package:otzaria/screens/text_book_screen.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:otzaria/widgets/commentary_list.dart';
import 'package:otzaria/screens/simple_book_view.dart';

class SplitedViewScreen extends StatelessWidget {
  const SplitedViewScreen({
    super.key,
    required this.widget,
    required this.snapshot,
    required this.searchTextController,
  });

  final TextBookViewer widget;
  final AsyncSnapshot<String> snapshot;
  final TextEditingValue searchTextController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: widget.tab.commentatorsToShow,
        builder: (context, commentariesNames, child) => MultiSplitView(
                controller: widget.tab.splitController,
                axis: Axis.horizontal,
                resizable: true,
                dividerBuilder: (axis, index, resizable, dragging, highlighted,
                        themeData) =>
                    const VerticalDivider(),
                children: [
                  SelectionArea(
                    child: ValueListenableBuilder(
                        valueListenable: widget.tab.selectedIndex,
                        builder: (context, selectedIndex, child) {
                          return CommentaryList(
                            index:
                                0, // we don't need the index here, b/c we listen to the selected index in the commentary list
                            textBookTab: widget.tab,
                            fontSize: widget.tab.textFontSize,
                            openBookCallback: widget.openBookCallback,
                            showSplitView: widget.tab.showSplitedView,
                          );
                        }),
                  ),
                  SimpleBookView(
                    tab: widget.tab,
                    data: snapshot.data!.split('\n'),
                    textSize: widget.tab.textFontSize,
                    openBookCallback: widget.openBookCallback,
                    showSplitedView: widget.tab.showSplitedView,
                  )
                ]));
  }
}
