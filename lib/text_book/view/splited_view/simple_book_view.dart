// a widget that takes an html strings array and displays it as a widget
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_state.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_event.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/widgets/progressive_scrolling.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;
import 'package:otzaria/text_book/view/links_screen.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/models/books.dart';

class SimpleBookView extends StatefulWidget {
  SimpleBookView({
    super.key,
    required this.data,
    required this.openBookCallback,
    required this.openLeftPaneTab,
    required this.textSize,
    required this.showSplitedView,
    required this.tab,
  });

  final List<String> data;
  final Function(OpenedTab) openBookCallback;
  final void Function(int) openLeftPaneTab;
  final bool showSplitedView;
  final double textSize;
  final TextBookTab tab;

  @override
  State<SimpleBookView> createState() => _SimpleBookViewState();
}

class _SimpleBookViewState extends State<SimpleBookView> {
  final GlobalKey<SelectionAreaState> _selectionKey =
      GlobalKey<SelectionAreaState>();

  ContextMenu _buildContextMenu(TextBookLoaded state) {
    return ContextMenu(
      entries: [
        MenuItem(label: 'חיפוש', onSelected: () => widget.openLeftPaneTab(1)),
        MenuItem.submenu(
          label: 'פרשנות',
          items: [
            MenuItem(
              label: 'הצג את כל המפרשים',
              onSelected: () => widget.openLeftPaneTab(2),
            ),
            const MenuDivider(),
            ...state.availableCommentators.map(
              (title) => MenuItem(
                label: title,
                onSelected: () {
                  widget.openBookCallback(
                    TextBookTab(
                      book: TextBook(title: title),
                      index: state.selectedIndex ?? state.visibleIndices.first,
                      openLeftPane:
                          Settings.getValue<bool>('key-default-sidebar-open') ??
                              false,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        MenuItem.submenu(
          label: 'קישורים',
          items: LinksViewer.getLinks(state)
              .map(
                (link) => MenuItem(
                  label: link.heRef,
                  onSelected: () {
                    widget.openBookCallback(
                      TextBookTab(
                        book: TextBook(
                          title: utils.getTitleFromPath(link.path2),
                        ),
                        index: link.index2 - 1,
                        openLeftPane: Settings.getValue<bool>(
                              'key-default-sidebar-open',
                            ) ??
                            false,
                      ),
                    );
                  },
                ),
              )
              .toList(),
        ),
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
      builder: (context, state) {
        if (state is! TextBookLoaded) return const Center();
        return ProgressiveScroll(
          scrollController: state.scrollOffsetController,
          maxSpeed: 10000.0,
          curve: 10.0,
          accelerationFactor: 5,
          child: ContextMenuRegion(
            contextMenu: _buildContextMenu(state),
            child: SelectionArea(
              key: _selectionKey,
              child: ScrollablePositionedList.builder(
                key: PageStorageKey(widget.tab),
                initialScrollIndex: state.visibleIndices.first,
                itemPositionsListener: state.positionsListener,
                itemScrollController: state.scrollController,
                scrollOffsetController: state.scrollOffsetController,
                itemCount: widget.data.length,
                itemBuilder: (context, index) {
                  return BlocBuilder<SettingsBloc, SettingsState>(
                    builder: (context, settingsState) {
                      String data = widget.data[index];
                      if (!settingsState.showTeamim) {
                        data = utils.removeTeamim(data);
                      }

                      if (settingsState.replaceHolyNames) {
                        data = utils.replaceHolyNames(data);
                      }
                      return InkWell(
                        onTap: () => context.read<TextBookBloc>().add(
                              UpdateSelectedIndex(index),
                            ),
                        child: Html(
                          // remove nikud if needed
                          data: state.removeNikud
                              ? utils.highLight(
                                  utils.removeVolwels('$data\n'),
                                  state.searchText,
                                )
                              : utils.highLight('$data\n', state.searchText),
                          style: {
                            'body': Style(
                              fontSize: FontSize(widget.textSize),
                              fontFamily: settingsState.fontFamily,
                              textAlign: TextAlign.justify,
                            ),
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
