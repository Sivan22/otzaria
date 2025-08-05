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
import 'package:otzaria/utils/font_utils.dart';
import 'package:otzaria/widgets/current_font_provider.dart';

class SimpleBookView extends StatefulWidget {
  SimpleBookView({
    super.key,
    required this.data,
    required this.openBookCallback,
    required this.openLeftPaneTab,
    required this.textSize,
    required this.showSplitedView,
    required this.tab,
    this.customFontFamily,
  });

  final List<String> data;
  final Function(OpenedTab) openBookCallback;
  final void Function(int) openLeftPaneTab;
  final bool showSplitedView;
  final double textSize;
  final TextBookTab tab;
  final String? customFontFamily;

  @override
  State<SimpleBookView> createState() => _SimpleBookViewState();
}

class _SimpleBookViewState extends State<SimpleBookView> {
  final GlobalKey<SelectionAreaState> _selectionKey =
      GlobalKey<SelectionAreaState>();

  String _getEffectiveFontFamily(BuildContext context, SettingsState settingsState) {
    // בדיקה אם יש גופן נוכחי מה-Provider
    final fontProvider = CurrentFontProvider.of(context);
    final currentFont = fontProvider?.currentFont ?? widget.customFontFamily;
    
    if (currentFont != null) {
      final fallbackFont = FontUtils.getFallbackFont(
        currentFont,
        settingsState.customFonts,
      );
      
      if (fallbackFont != null) {
        return fallbackFont;
      }
      
      return FontUtils.getFontFamilyForDisplay(
        currentFont,
        settingsState.customFonts,
      );
    }
    
    // fallback לגופן הגלובלי
    return FontUtils.getFontFamilyForDisplay(
      settingsState.fontFamily,
      settingsState.customFonts,
    );
  }

  /// helper קטן שמחזיר רשימת MenuEntry מקבוצה אחת, כולל כפתור הצג/הסתר הכל
  List<ctx.MenuItem<void>> _buildGroup(
    String groupName,
    List<String>? group,
    TextBookLoaded st,
  ) {
    if (group == null || group.isEmpty) return const [];

    final bool groupActive =
        group.every((title) => st.activeCommentators.contains(title));

    return [
      ctx.MenuItem<void>(
        label: 'הצג את כל ${groupName}',
        icon: groupActive ? Icons.check : null,
        onSelected: () {
          final current = List<String>.from(st.activeCommentators);
          if (groupActive) {
            current.removeWhere(group.contains);
          } else {
            for (final title in group) {
              if (!current.contains(title)) current.add(title);
            }
          }
          context.read<TextBookBloc>().add(UpdateCommentators(current));
        },
      ),
      ...group.map((title) {
        final bool isActive = st.activeCommentators.contains(title);
        return ctx.MenuItem<void>(
          label: title,
          icon: isActive ? Icons.check : null,
          onSelected: () {
            final current = List<String>.from(st.activeCommentators);
            current.contains(title)
                ? current.remove(title)
                : current.add(title);
            context.read<TextBookBloc>().add(UpdateCommentators(current));
          },
        );
      }),
    ];
  }

  ctx.ContextMenu _buildContextMenu(TextBookLoaded state) {
    // 1. קבלת מידע על גודל המסך
    final screenHeight = MediaQuery.of(context).size.height;

    // 2. זיהוי פרשנים שכבר שויכו לקבוצה
    final Set<String> alreadyListed = {
      ...state.rishonim,
      ...state.acharonim,
      ...state.modernCommentators,
    };

    // 3. יצירת רשימה של פרשנים שלא שויכו לאף קבוצה
    final List<String> ungrouped = state.availableCommentators
        .where((c) => !alreadyListed.contains(c))
        .toList();

    return ctx.ContextMenu(
      // 4. הגדרת הגובה המקסימלי ל-90% מגובה המסך
      maxHeight: screenHeight * 0.9,
      entries: [
        ctx.MenuItem(
            label: 'חיפוש', onSelected: () => widget.openLeftPaneTab(1)),
        ctx.MenuItem.submenu(
          label: 'פרשנות',
          items: [
            ctx.MenuItem(
              label: 'הצג את כל המפרשים',
              icon: state.activeCommentators
                      .toSet()
                      .containsAll(state.availableCommentators)
                  ? Icons.check
                  : null,
              onSelected: () {
                final allActive = state.activeCommentators
                    .toSet()
                    .containsAll(state.availableCommentators);
                context.read<TextBookBloc>().add(
                      UpdateCommentators(
                        allActive
                            ? <String>[]
                            : List<String>.from(state.availableCommentators),
                      ),
                    );
              },
            ),
            const ctx.MenuDivider(),
            // ראשונים
            ..._buildGroup('ראשונים', state.rishonim, state),

            // מוסיפים קו הפרדה רק אם יש גם ראשונים וגם אחרונים
            if (state.rishonim.isNotEmpty && state.acharonim.isNotEmpty)
              const ctx.MenuDivider(),

            // אחרונים
            ..._buildGroup('אחרונים', state.acharonim, state),

            // מוסיפים קו הפרדה רק אם יש גם אחרונים וגם בני זמננו
            if (state.acharonim.isNotEmpty &&
                state.modernCommentators.isNotEmpty)
              const ctx.MenuDivider(),

            // מחברי זמננו
            ..._buildGroup('מחברי זמננו', state.modernCommentators, state),

            // הוסף קו הפרדה רק אם יש קבוצות אחרות וגם פרשנים לא-משויכים
            if ((state.rishonim.isNotEmpty ||
                    state.acharonim.isNotEmpty ||
                    state.modernCommentators.isNotEmpty) &&
                ungrouped.isNotEmpty)
              const ctx.MenuDivider(),

            // הוסף את רשימת הפרשנים הלא משויכים
            ..._buildGroup('שאר מפרשים', ungrouped, state),
          ],
        ),
        ctx.MenuItem.submenu(
          label: 'קישורים',
          enabled: LinksViewer.getLinks(state).isNotEmpty, // <--- חדש
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
                            (Settings.getValue<bool>('key-pin-sidebar') ??
                                    false) ||
                                (Settings.getValue<bool>(
                                        'key-default-sidebar-open') ??
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
                              fontFamily: _getEffectiveFontFamily(context, settingsState),
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
