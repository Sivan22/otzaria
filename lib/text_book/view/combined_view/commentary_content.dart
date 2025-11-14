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
import 'package:otzaria/i18n/translations.g.dart';

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

  @override
  void didUpdateWidget(CommentaryContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // עדכון תוכן הפירוש כאשר הקישור משתנה
    // בודקים אם הקישור השתנה על ידי השוואת המאפיינים המזהים שלו
    if (oldWidget.link.path2 != widget.link.path2 ||
        oldWidget.link.index2 != widget.link.index2 ||
        oldWidget.link.heRef != widget.link.heRef) {
      content = widget.link.content;
    }
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
                  // החלפת שמות קדושים אם נדרש
                  String displayText = text;
                  if (settingsState.replaceHolyNames) {
                    displayText = utils.replaceHolyNames(displayText);
                  }

                  return HtmlWidget(
                    '<div style="text-align: justify; direction: rtl;">$displayText</div>',
                    textStyle: TextStyle(
                      fontSize: widget.fontSize / 1.2,
                      fontFamily: settingsState.commentatorsFontFamily,
                    ),
                  );
                },
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(context.t.textBook.errorLoadingCommentator(error: snapshot.error.toString())),
              );
            }
            return _buildSkeletonLoading(context);
          }),
    );
  }

  /// בניית skeleton loading לתוכן פרשנות - שלוש שורות
  Widget _buildSkeletonLoading(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _SkeletonLine(width: 0.95, height: 14, color: baseColor),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _SkeletonLine(width: 0.92, height: 14, color: baseColor),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _SkeletonLine(width: 0.88, height: 14, color: baseColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget של שורה סטטית לשלד טעינה
class _SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _SkeletonLine({
    required this.width,
    required this.color,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: MediaQuery.of(context).size.width * width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
