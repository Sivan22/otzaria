import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/text_book/view/splited_view/simple_book_view.dart';
import 'package:otzaria/text_book/view/splited_view/commentary_list_for_splited_view.dart';

class SplitedViewScreen extends StatelessWidget {
  const SplitedViewScreen({
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
    return BlocBuilder<TextBookBloc, TextBookState>(
      builder: (context, state) => MultiSplitView(
        controller: tab.splitController,
        axis: Axis.horizontal,
        resizable: true,
        dividerBuilder:
            (axis, index, resizable, dragging, highlighted, themeData) =>
                const VerticalDivider(),
        children: [
          SelectionArea(
            child: CommentaryList(
              index:
                  0, // we don't need the index here, b/c we listen to the selected index in the commentary list
              textBookTab: tab,
              fontSize: state.fontSize,
              openBookCallback: openBookCallback,
              showSplitView: state.showSplitView,
            ),
          ),
          SimpleBookView(
            tab: tab,
            data: content,
            textSize: state.fontSize,
            openBookCallback: openBookCallback,
            showSplitedView: state.showSplitView,
          )
        ],
      ),
    );
  }
}
