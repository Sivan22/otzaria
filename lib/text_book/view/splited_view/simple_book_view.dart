import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart' as ctx;
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

  /// helper קטן שמחזיר רשימת MenuEntry מקבוצה אחת
  List<ctx.MenuItem<void>> _buildGroup(
    List<String>? group,
    TextBookLoaded st,
  ) {
    if (group == null || group.isEmpty) return const [];

    return group
        .map(
          (title) => ctx.MenuItem<void>(
            label: title,
            onSelected: () {
              final current = List<String>.from(st.activeCommentators);
              current.contains(title)
                  ? current.remove(title)
                  : current.add(title);
              context.read<TextBookBloc>().add(UpdateCommentators(current));
              if (!st.showSplitView) widget.openLeftPaneTab(2);
            },
          ),
        )
        .toList();
  }

  ctx.ContextMenu _buildContextMenu(TextBookLoaded state) {
    // 1. קבלת מידע על גודל המסך
    final screenHeight = MediaQuery.of(context).size.height;
    return ctx.ContextMenu(
      // 2. הגדרת הגובה המקסימלי ל-90% מגובה המסך
      maxHeight: screenHeight * 0.9,
      entries: [
        ctx.MenuItem(label: 'חיפוש', onSelected: () => widget.openLeftPaneTab(1)),
        ctx.MenuItem.submenu(
          label: 'פרשנות',
          items: [
            ctx.MenuItem(
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
            const ctx.MenuDivider(),
            // ראשונים
            ..._buildGroup(state.rishonim, state),
            
            // מוסיפים קו הפרדה רק אם יש גם ראשונים וגם אחרונים
            if(state.rishonim.isNotEmpty && state.acharonim.isNotEmpty)
                const ctx.MenuDivider(),

            // אחרונים
            ..._buildGroup(state.acharonim, state),

            // מוסיפים קו הפרדה רק אם יש גם אחרונים וגם בני זמננו
            if(state.acharonim.isNotEmpty && state.modernCommentators.isNotEmpty)
                const ctx.MenuDivider(),
                
            // מחברי זמננו
            ..._buildGroup(state.modernCommentators, state),
          ],
        ),
        ctx.MenuItem.submenu(
          label: 'קישורים',
          items: LinksViewer.getLinks(state)
              .map(
                (link) => ctx.MenuItem(
                  label: link.heRef,
                  onSelected: () {
                    widget.openBookCallback(
                      TextBookTab(
                        book: TextBook(
                          title: utils.getTitleFromPath(link.path2),
                        ),
                        index: link.index2 - 1,
                        openLeftPane:
                            (Settings.getValue<bool>('key-pin-sidebar') ?? false) ||
                                (Settings.getValue<bool>('key-default-sidebar-open') ??
                                    false),
                      ),
                    );
                  },
                ),
              )
              .toList(),
        ),
        const ctx.MenuDivider(),
        ctx.MenuItem(
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
            child: SelectionArea(
              key: _selectionKey,
              contextMenuBuilder: (_, __) => const SizedBox.shrink(),
              child: ctx.ContextMenuRegion(
                contextMenu: _buildContextMenu(state),
                child: ScrollablePositionedList.builder(
                  key: PageStorageKey(widget.tab),
                  initialScrollIndex: state.visibleIndices.first,
                  itemPositionsListener: state.positionsListener,
                  itemScrollController: state.scrollController,
                  scrollOffsetController: state.scrollOffsetController,
                  itemCount: widget.data.length,
                  itemBuilder: (context, index) {
                    // WORKAROUND: Add an invisible newline character to preserve line breaks
                    // when copying text from the SelectionArea. This addresses a known
                    // issue in Flutter where newlines are stripped when copying from
                    // multiple widgets.
                    // See: https://github.com/flutter/flutter/issues/104548#issuecomment-2051481671
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BlocBuilder<SettingsBloc, SettingsState>(
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
                        ),
                        const Text('\n', style: TextStyle(fontSize: 0, height: 0)),
                      ],
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
