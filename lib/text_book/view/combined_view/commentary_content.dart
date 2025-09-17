import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/links.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_state.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;

class CommentaryContent extends StatefulWidget {
  const CommentaryContent({
    super.key,
    required this.link,
    required this.fontSize,
    required this.openBookCallback,
    required this.removeNikud,
    this.searchQuery = '',
    this.currentSearchIndex = 0,
    this.onSearchResultsCountChanged,
  });
  final bool removeNikud;
  final Link link;
  final double fontSize;
  final Function(TextBookTab) openBookCallback;
  final String searchQuery;
  final int currentSearchIndex;
  final Function(int)? onSearchResultsCountChanged;

  @override
  State<CommentaryContent> createState() => _CommentaryContentState();
}

class _CommentaryContentState extends State<CommentaryContent> {
  late Future<String> content;

  @override
  void initState() {
    super.initState();
    content = widget.link.content;
  }

  int _countSearchMatches(String text, String searchQuery) {
    if (searchQuery.isEmpty) return 0;

    final RegExp regex = RegExp(
      RegExp.escape(searchQuery),
      caseSensitive: false,
    );

    return regex.allMatches(text).length;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        widget.openBookCallback(TextBookTab(
          book: TextBook(title: utils.getTitleFromPath(widget.link.path2)),
          index: widget.link.index2 - 1,
          openLeftPane: (Settings.getValue<bool>('key-pin-sidebar') ?? false) ||
              (Settings.getValue<bool>('key-default-sidebar-open') ?? false),
        ));
      },
      child: FutureBuilder(
          future: content,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              String text = snapshot.data!;
              if (widget.removeNikud) {
                text = utils.removeVolwels(text);
              }

              // ספירת תוצאות החיפוש ועדכון הרכיב האב
              if (widget.searchQuery.isNotEmpty) {
                final searchCount =
                    _countSearchMatches(text, widget.searchQuery);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onSearchResultsCountChanged?.call(searchCount);
                });
              }

              text = utils.highLight(text, widget.searchQuery,
                  currentIndex: widget.currentSearchIndex);

              // החלת עיצוב הסוגריים העגולים
              text = utils.formatTextWithParentheses(text);

              return BlocBuilder<SettingsBloc, SettingsState>(
                builder: (context, settingsState) {
                  return DefaultTextStyle.merge(
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: widget.fontSize / 1.2,
                      fontFamily: settingsState.fontFamily,
                    ),
                    child: HtmlWidget(text),
                  );
                },
              );
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          }),
    );
  }
}
