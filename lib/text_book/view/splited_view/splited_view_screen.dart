import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/text_book/view/splited_view/simple_book_view.dart';
import 'package:otzaria/text_book/view/splited_view/commentary_list_for_splited_view.dart';

class SplitedViewScreen extends StatelessWidget {
  SplitedViewScreen({
    super.key,
    required this.content,
    required this.openBookCallback,
    required this.searchTextController,
    required this.openLeftPaneTab,
    required this.tab,
  });
  final List<String> content;
  final void Function(OpenedTab) openBookCallback;
  final TextEditingValue searchTextController;
  final void Function(int) openLeftPaneTab;
  final TextBookTab tab;

  static final GlobalKey<SelectionAreaState> _selectionKey =
      GlobalKey<SelectionAreaState>();

  ContextMenu _buildContextMenu(TextBookLoaded state) {
    return ContextMenu(
      entries: [
        MenuItem(label: 'חיפוש', onSelected: () => openLeftPaneTab(1)),
        const MenuDivider(),
        MenuItem(
          label: 'בחר את כל הטקסט',
          onSelected: () =>
              _selectionKey.currentState?.selectableRegion.selectAll(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextBookBloc, TextBookState>(
      builder: (context, state) => MultiSplitView(
        controller: MultiSplitViewController(areas: Area.weights([0.4, 0.6])),
        axis: Axis.horizontal,
        resizable: true,
        dividerBuilder:
            (axis, index, resizable, dragging, highlighted, themeData) =>
                const VerticalDivider(),
        children: [
          ContextMenuRegion(
            contextMenu: _buildContextMenu(state as TextBookLoaded),
            child: SelectionArea(
              key: _selectionKey,
              child: CommentaryList(
                index:
                    0, // we don't need the index here, b/c we listen to the selected index in the commentary list

                fontSize: (state as TextBookLoaded).fontSize,
                openBookCallback: openBookCallback,
                showSplitView: state.showSplitView,
              ),
            ),
          ),
          SimpleBookView(
            data: content,
            textSize: state.fontSize,
            openBookCallback: openBookCallback,
            openLeftPaneTab: openLeftPaneTab,
            showSplitedView: state.showSplitView,
            tab: tab,
          ),
        ],
      ),
    );
  }
}
