import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:otzaria/models/books.dart';
import 'package:otzaria/search/bloc/search_bloc.dart';
import 'package:otzaria/search/bloc/search_state.dart';
import 'package:otzaria/search/view/full_text_settings_widgets.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_state.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_event.dart';
import 'package:otzaria/tabs/models/pdf_tab.dart';
import 'package:otzaria/tabs/models/searching_tab.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;

class TantivySearchResults extends StatefulWidget {
  final SearchingTab tab;
  const TantivySearchResults({
    Key? key,
    required this.tab,
  }) : super(key: key);

  @override
  State<TantivySearchResults> createState() => _TantivySearchResultsState();
}

class _TantivySearchResultsState extends State<TantivySearchResults> {
  // פונקציה לחישוב כמה תווים יכולים להיכנס בשורה אחת
  int _calculateCharsPerLine(double availableWidth, TextStyle textStyle) {
    final textPainter = TextPainter(
      text: TextSpan(text: 'א' * 100, style: textStyle), // טקסט לדוגמה
      textDirection: TextDirection.rtl,
    );
    textPainter.layout(maxWidth: availableWidth);

    // חישוב כמה תווים נכנסים בשורה אחת
    final singleCharWidth = textPainter.width / 100;
    final charsPerLine = (availableWidth / singleCharWidth).floor();

    textPainter.dispose();
    return charsPerLine;
  }

  // פונקציה חכמה ליצירת קטע טקסט עם הדגשות - מבטיחה שכל ההתאמות יופיעו!
  List<InlineSpan> createSnippetSpans(
    String fullHtml,
    String query,
    TextStyle defaultStyle,
    TextStyle highlightStyle,
    double availableWidth,
  ) {
    // 1. קבלת הטקסט הנקי מה-HTML
    final plainText =
        html_parser.parse(fullHtml).documentElement?.text.trim() ?? '';

    // 2. חילוץ מילות החיפוש
    final searchTerms = query
        .trim()
        .replaceAll(RegExp(r'[~"*\(\)]'), ' ')
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();

    if (searchTerms.isEmpty || plainText.isEmpty) {
      return [TextSpan(text: plainText, style: defaultStyle)];
    }

    // 3. מציאת כל ההתאמות של כל המילים בטקסט המקורי - זה הכי חשוב!
    final List<Match> allMatches = [];
    for (final term in searchTerms) {
      final regex = RegExp(RegExp.escape(term), caseSensitive: false);
      allMatches.addAll(regex.allMatches(plainText));
    }

    if (allMatches.isEmpty) {
      return [
        TextSpan(
            text: plainText.substring(0, min(200, plainText.length)),
            style: defaultStyle)
      ];
    }

    // 4. מיון ההתאמות וקביעת הגבולות המוחלטים
    allMatches.sort((a, b) => a.start.compareTo(b.start));
    final int absoluteFirstMatch = allMatches.first.start;
    final int absoluteLastMatch = allMatches.last.end;
    final int totalMatchesSpan = absoluteLastMatch - absoluteFirstMatch;

    // 5. קביעת הקטע - עקרון ברזל: כל ההתאמות חייבות להיכלל!
    int snippetStart;
    int snippetEnd;

    // חישוב אורך הטקסט הנדרש לשלוש שורות בהתבסס על רוחב המסך בפועל
    final charsPerLine = _calculateCharsPerLine(availableWidth, defaultStyle);
    final targetLength = (charsPerLine * 3).clamp(120, 400); // הקטנתי את הטווח

    // תמיד מתחילים מהגבולות המוחלטים של ההתאמות
    snippetStart = absoluteFirstMatch;
    snippetEnd = absoluteLastMatch;

    // לוגיקה מתוקנת: אם יש מילה אחת או מילים קרובות, נוסיף הקשר מוגבל
    if (totalMatchesSpan < 50) {
      // אם המילים קרובות מאוד (כולל מילה אחת)
      // נוסיף הקשר מוגבל - מקסימום 60 תווים מכל צד
      const limitedPadding = 60;
      snippetStart =
          (absoluteFirstMatch - limitedPadding).clamp(0, plainText.length);
      snippetEnd =
          (absoluteLastMatch + limitedPadding).clamp(0, plainText.length);
    } else if (totalMatchesSpan < targetLength) {
      // אם ההתאמות קצרות מהיעד, נוסיף הקשר עד שנגיע ל-3 שורות
      int remainingSpace = targetLength - totalMatchesSpan;
      int paddingBefore = remainingSpace ~/ 2;
      int paddingAfter = remainingSpace - paddingBefore;

      snippetStart =
          (absoluteFirstMatch - paddingBefore).clamp(0, plainText.length);
      snippetEnd =
          (absoluteLastMatch + paddingAfter).clamp(0, plainText.length);
    } else {
      // אם ההתאמות ארוכות, נוסיף רק מעט הקשר
      const minPadding = 30;
      snippetStart =
          (absoluteFirstMatch - minPadding).clamp(0, plainText.length);
      snippetEnd = (absoluteLastMatch + minPadding).clamp(0, plainText.length);
    }

    // התאמה לגבולות מילים - אבל לא על חשבון ההתאמות!
    // וידוא שלא חותכים מילה בהתחלה
    if (snippetStart > 0 && snippetStart < absoluteFirstMatch) {
      // מחפשים רווח לפני הנקודה הנוכחית
      int? spaceIndex = plainText.lastIndexOf(' ', snippetStart);
      if (spaceIndex != -1 && spaceIndex >= snippetStart - 50) {
        snippetStart = spaceIndex + 1;
      } else {
        // אם לא מצאנו רווח קרוב, נתחיל מתחילת המילה
        while (snippetStart > 0 && plainText[snippetStart - 1] != ' ') {
          snippetStart--;
        }
      }
    }

    // וידוא שלא חותכים מילה בסוף
    if (snippetEnd < plainText.length && snippetEnd > absoluteLastMatch) {
      // מחפשים רווח אחרי הנקודה הנוכחית
      int? spaceIndex = plainText.indexOf(' ', snippetEnd);
      if (spaceIndex != -1 && spaceIndex <= snippetEnd + 50) {
        snippetEnd = spaceIndex;
      } else {
        // אם לא מצאנו רווח קרוב, נסיים בסוף המילה
        while (snippetEnd < plainText.length && plainText[snippetEnd] != ' ') {
          snippetEnd++;
        }
      }
    }

    // וידוא אחרון שלא חתכנו את ההתאמות
    if (snippetStart > absoluteFirstMatch) {
      snippetStart = absoluteFirstMatch;
    }
    if (snippetEnd < absoluteLastMatch) {
      snippetEnd = absoluteLastMatch;
    }

    final snippetText = plainText.substring(snippetStart, snippetEnd);

    // 6. בדיקה נוספת - ספירת ההתאמות בקטע הסופי
    int finalMatchCount = 0;
    for (final term in searchTerms) {
      final regex = RegExp(RegExp.escape(term), caseSensitive: false);
      finalMatchCount += regex.allMatches(snippetText).length;
    }

    // אם יש פחות התאמות בקטע הסופי, זה אומר שמשהו השתבש
    if (finalMatchCount < allMatches.length) {
      // במקרה כזה, נחזור לטקסט המלא או לקטע גדול יותר
      snippetStart = (absoluteFirstMatch - 100).clamp(0, plainText.length);
      snippetEnd = (absoluteLastMatch + 100).clamp(0, plainText.length);
      final expandedSnippet = plainText.substring(snippetStart, snippetEnd);

      // בדיקה אחרונה
      int expandedMatchCount = 0;
      for (final term in searchTerms) {
        final regex = RegExp(RegExp.escape(term), caseSensitive: false);
        expandedMatchCount += regex.allMatches(expandedSnippet).length;
      }

      if (expandedMatchCount >= allMatches.length) {
        return _buildTextSpans(
            expandedSnippet, searchTerms, defaultStyle, highlightStyle);
      }
    }

    return _buildTextSpans(
        snippetText, searchTerms, defaultStyle, highlightStyle);
  }

  // פונקציה עזר לבניית ה-TextSpans
  List<InlineSpan> _buildTextSpans(
    String text,
    List<String> searchTerms,
    TextStyle defaultStyle,
    TextStyle highlightStyle,
  ) {
    final List<InlineSpan> spans = [];
    int currentPosition = 0;

    final highlightRegex = RegExp(
      searchTerms.map(RegExp.escape).join('|'),
      caseSensitive: false,
    );

    for (final match in highlightRegex.allMatches(text)) {
      // טקסט רגיל לפני ההדגשה
      if (match.start > currentPosition) {
        spans.add(TextSpan(
          text: text.substring(currentPosition, match.start),
          style: defaultStyle,
        ));
      }
      // הטקסט המודגש
      spans.add(TextSpan(
        text: match.group(0),
        style: highlightStyle,
      ));
      currentPosition = match.end;
    }

    // טקסט רגיל אחרי ההדגשה האחרונה
    if (currentPosition < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentPosition),
        style: defaultStyle,
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constrains) {
      return BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.searchQuery.isEmpty) {
            return const Center(child: Text("לא בוצע חיפוש"));
          }
          if (state.results.isEmpty) {
            return const Center(
                child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('אין תוצאות'),
            ));
          }

          return Column(
            children: [
              // פס עליון עם הבקרות - גובה קבוע
              Container(
                height: 60, // גובה קבוע
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  children: [
                    const Spacer(), // דוחף הכל לצד ימין
                    // ספירת התוצאות במלבן
                    Container(
                      height: 52, // אותו גובה כמו הבקרות האחרות
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        child: Center(
                          child: Text(
                            '${state.results.length} תוצאות מתוך ${state.totalResults}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                    if (constrains.maxWidth > 450)
                      OrderOfResults(widget: widget),
                    if (constrains.maxWidth > 450)
                      NumOfResults(tab: widget.tab),
                  ],
                ),
              ),
              // פס מפריד מתחת לשורת הבקרות
              Container(
                height: 1,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.results.length,
                  itemBuilder: (context, index) {
                    final result = state.results[index];
                    return BlocBuilder<SettingsBloc, SettingsState>(
                      builder: (context, settingsState) {
                        String titleText =
                            '[תוצאה ${index + 1}] ${result.reference}';
                        String rawHtml = result.text;
                        if (settingsState.replaceHolyNames) {
                          titleText = utils.replaceHolyNames(titleText);
                          rawHtml = utils.replaceHolyNames(rawHtml);
                        }

                        // חישוב רוחב זמין לטקסט (מינוס אייקון ו-padding)
                        final availableWidth = constrains.maxWidth -
                            (result.isPdf
                                ? 56.0
                                : 16.0) - // רוחב האייקון או padding
                            32.0; // padding נוסף של ListTile

                        // Create the snippet using the new robust function
                        final snippetSpans = createSnippetSpans(
                          rawHtml,
                          state.searchQuery,
                          TextStyle(
                            fontSize: settingsState.fontSize,
                            fontFamily: settingsState.fontFamily,
                          ),
                          TextStyle(
                            fontSize: settingsState.fontSize,
                            fontFamily: settingsState.fontFamily,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                          availableWidth,
                        );

                        return ListTile(
                          leading: result.isPdf
                              ? const Icon(Icons.picture_as_pdf)
                              : null,
                          onTap: () {
                            if (result.isPdf) {
                              context.read<TabsBloc>().add(AddTab(
                                    PdfBookTab(
                                      book: PdfBook(
                                          title: result.title,
                                          path: result.filePath),
                                      pageNumber: result.segment.toInt() + 1,
                                      searchText:
                                          widget.tab.queryController.text,
                                      openLeftPane: (Settings.getValue<bool>(
                                                  'key-pin-sidebar') ??
                                              false) ||
                                          (Settings.getValue<bool>(
                                                  'key-default-sidebar-open') ??
                                              false),
                                    ),
                                  ));
                            } else {
                              context.read<TabsBloc>().add(AddTab(
                                    TextBookTab(
                                        book: TextBook(
                                          title: result.title,
                                        ),
                                        index: result.segment.toInt(),
                                        searchText:
                                            widget.tab.queryController.text,
                                        openLeftPane: (Settings.getValue<bool>(
                                                    'key-pin-sidebar') ??
                                                false) ||
                                            (Settings.getValue<bool>(
                                                    'key-default-sidebar-open') ??
                                                false)),
                                  ));
                            }
                          },
                          title: Text(titleText),
                          subtitle: Text.rich(
                            TextSpan(children: snippetSpans),
                            maxLines: null, // אין הגבלה על מספר השורות!
                            textAlign: TextAlign.justify,
                            textDirection: TextDirection.rtl,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    });
  }
}
