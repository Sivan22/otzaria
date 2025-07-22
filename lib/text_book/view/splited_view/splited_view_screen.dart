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

class SplitedViewScreen extends StatefulWidget {
  const SplitedViewScreen({
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

  @override
  State<SplitedViewScreen> createState() => _SplitedViewScreenState();
}

class _SplitedViewScreenState extends State<SplitedViewScreen> {
  late final MultiSplitViewController _controller;
  static final GlobalKey<SelectionAreaState> _selectionKey =
      GlobalKey<SelectionAreaState>();

  bool _paneOpen = true;

  @override
  void initState() {
    super.initState();
    _controller = MultiSplitViewController(areas: _openAreas());
  }

  List<Area> _openAreas() => [
        Area(weight: 0.4, minimalSize: 200),
        Area(weight: 0.6, minimalSize: 200),
      ];

  List<Area> _closedAreas() => [
        Area(weight: 0, minimalSize: 0),
        Area(weight: 1, minimalSize: 200),
      ];

  void _updateAreas() {
    _controller.areas = _paneOpen ? _openAreas() : _closedAreas();
  }

  void _togglePane() {
    setState(() {
      _paneOpen = !_paneOpen;
      _updateAreas();
    });
  }

  void _openPane() {
    if (!_paneOpen) {
      setState(() {
        _paneOpen = true;
        _updateAreas();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ContextMenu _buildContextMenu(TextBookLoaded state) {
    return ContextMenu(
      entries: [
        MenuItem(
            label: 'חיפוש',
            onSelected: () => widget.openLeftPaneTab(1)),
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
    return BlocConsumer<TextBookBloc, TextBookState>(
      listenWhen: (previous, current) {
        return previous is TextBookLoaded &&
            current is TextBookLoaded &&
            previous.activeCommentators != current.activeCommentators;
      },
      listener: (context, state) {
        if (state is TextBookLoaded) {
          _openPane();
        }
      },
      buildWhen: (previous, current) {
        if (previous is TextBookLoaded && current is TextBookLoaded) {
          return previous.fontSize != current.fontSize ||
              previous.showSplitView != current.showSplitView ||
              previous.activeCommentators != current.activeCommentators;
        }
        return true;
      },
      builder: (context, state) {
        if (state is! TextBookLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        return Stack(
          children: [
            MultiSplitView(
              controller: _controller,
              axis: Axis.horizontal,
              resizable: true,
              dividerBuilder:
                  (axis, index, resizable, dragging, highlighted, themeData) {
                final color = dragging
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor;
                return MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: Container(
                    width: 8,
                    alignment: Alignment.center,
                    child: Container(
                      width: 1.5,
                      color: color,
                    ),
                  ),
                );
              },
              children: [
                ContextMenuRegion(
                  contextMenu: _buildContextMenu(state),
                  child: SelectionArea(
                    key: _selectionKey,
                    child: _paneOpen
                        ? CommentaryList(
                            index: 0,
                            fontSize: state.fontSize,
                            openBookCallback: widget.openBookCallback,
                            showSplitView: state.showSplitView,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                SimpleBookView(
                  data: widget.content,
                  textSize: state.fontSize,
                  openBookCallback: widget.openBookCallback,
                  openLeftPaneTab: widget.openLeftPaneTab,
                  showSplitedView: state.showSplitView,
                  tab: widget.tab,
                ),
              ],
            ),
            Positioned(
              left: 0,
              top: 0,
              child: IconButton(
                iconSize: 16,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                icon: Icon(_paneOpen ? Icons.close : Icons.drag_handle),
                onPressed: _togglePane,
              ),
            )
          ],
        );
      },
    );
  }
}
