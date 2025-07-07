// a widget that takes an html strings array and displays it as a widget
// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_state.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_state.dart';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/text_book/view/combined_view/commentary_list_for_combined_view.dart';
import 'package:otzaria/text_book/view/links_screen.dart';
import 'package:otzaria/widgets/progressive_scrolling.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;
import 'package:otzaria/text_book/bloc/text_book_event.dart';


class CombinedView extends StatefulWidget {
  CombinedView({
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
  final ValueNotifier<bool> showSplitedView;
  final double textSize;
  final TextBookTab tab;

  @override
  State<CombinedView> createState() => _CombinedViewState();
}

class _CombinedViewState extends State<CombinedView> {
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
              onSelected: () {
                // 1. מפעילים את כל המפרשים הזמינים
                context.read<TextBookBloc>().add(
                      UpdateCommentators(
                        List<String>.from(state.availableCommentators),
                      ),
                    );

                // 2. פותחים את סרגל הצד אם צריך
                if (!state.showSplitView) {
                  widget.openLeftPaneTab(2);
                }
              },
            ),
            const MenuDivider(),
            ...state.availableCommentators.map(
              (title) => MenuItem(
                label: title,
                onSelected: () {
                 // 1. בונים רשימה מעודכנת של פרשנים פעילים
                 final List<String> current =
                     List<String>.from(state.activeCommentators);
                 current.contains(title) ? current.remove(title) : current.add(title);
          
                 // 2. שולחים את האירוע ל-Bloc
                 context.read<TextBookBloc>().add(UpdateCommentators(current));
          
                 // 3. במצב שאינו Split-View – פותחים את סרגל הצד בכרטיסיית “פרשנות”
                 if (!state.showSplitView) widget.openLeftPaneTab(2);
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

  Widget buildKeyboardListener() {
    return BlocBuilder<TextBookBloc, TextBookState>(
      bloc: context.read<TextBookBloc>(),
      builder: (context, state) {
        if (state is! TextBookLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        return ProgressiveScroll(
          maxSpeed: 10000.0,
          curve: 10.0,
          accelerationFactor: 5,
          scrollController: state.scrollOffsetController,
          child: ContextMenuRegion(
            contextMenu: _buildContextMenu(state),
            child: SelectionArea(
              key: _selectionKey,
              contextMenuBuilder: (_, __) => const SizedBox.shrink(),
              child: ContextMenuRegion( // <-- ה-Region היחיד, במיקום הנכון
                contextMenu: _buildContextMenu(state),
                child: buildOuterList(state),
              ),
          ),
          ),
        );
      },
    );
  }

  Widget buildOuterList(TextBookLoaded state) {
    return ScrollablePositionedList.builder(
      key: PageStorageKey(widget.tab),
      initialScrollIndex: state.visibleIndices.first,
      itemPositionsListener: state.positionsListener,
      itemScrollController: state.scrollController,
      scrollOffsetController: state.scrollOffsetController,
      itemCount: widget.data.length,
      itemBuilder: (context, index) {
        ExpansibleController controller = ExpansibleController();
        return buildExpansiomTile(controller, index, state);
      },
    );
  }

  ExpansionTile buildExpansiomTile(
    ExpansibleController controller,
    int index,
    TextBookLoaded state,
  ) {
    return ExpansionTile(
      shape: const Border(),
      //maintainState: true,
      controller: controller,
      key: PageStorageKey(widget.data[index]),
      iconColor: Colors.transparent,
      tilePadding: const EdgeInsets.all(0.0),
      collapsedIconColor: Colors.transparent,
      title: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          String data = widget.data[index];
          if (!settingsState.showTeamim) {
            data = utils.removeTeamim(data);
          }

          if (settingsState.replaceHolyNames) {
            data = utils.replaceHolyNames(data);
          }
          return Html(
            //remove nikud if needed
            data: state.removeNikud
                ? utils.highLight(
                    utils.removeVolwels('$data\n'),
                    state.searchText,
                  )
                : utils.highLight('$data\n', state.searchText),
            style: {
              'body': Style(
                fontSize: FontSize(widget.textSize),
                fontFamily: Settings.getValue('key-font-family') ?? 'candara',
                textAlign: TextAlign.justify,
              ),
            },
          );
        },
      ),
      children: [
        widget.showSplitedView.value
            ? const SizedBox.shrink()
            : CommentaryListForCombinedView(
                index: index,
                fontSize: widget.textSize,
                openBookCallback: widget.openBookCallback,
                showSplitView: false,
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildKeyboardListener();
  }
}
