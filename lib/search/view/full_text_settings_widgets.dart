import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:otzaria/search/bloc/search_bloc.dart';
import 'package:otzaria/search/bloc/search_event.dart';
import 'package:otzaria/search/bloc/search_state.dart';
import 'package:otzaria/tabs/models/searching_tab.dart';
import 'package:otzaria/search/view/tantivy_search_results.dart';
import 'package:search_engine/search_engine.dart';
import 'package:toggle_switch/toggle_switch.dart';

class FuzzyToggle extends StatelessWidget {
  const FuzzyToggle({
    super.key,
    required this.tab,
  });

  final SearchingTab tab;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ToggleSwitch(
            minWidth: 150,
            minHeight: 45,
            inactiveBgColor: Colors.grey,
            inactiveFgColor: Colors.white,
            initialLabelIndex: state.fuzzy ? 1 : 0,
            totalSwitches: 2,
            labels: const ['חיפוש מדוייק', 'חיפוש מקורב'],
            radiusStyle: true,
            onToggle: (index) {
              context.read<SearchBloc>().add(ToggleFuzzy());
            },
          ),
        );
      },
    );
  }
}

class FuzzyDistance extends StatelessWidget {
  const FuzzyDistance({
    super.key,
    required this.tab,
  });

  final SearchingTab tab;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        return SizedBox(
          width: 200,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SpinBox(
              enabled: !state.fuzzy,
              decoration: const InputDecoration(labelText: 'מרווח בין מילים'),
              min: 0,
              max: 30,
              value: state.distance.toDouble(),
              onChanged: (value) =>
                  context.read<SearchBloc>().add(UpdateDistance(value.toInt())),
            ),
          ),
        );
      },
    );
  }
}

class NumOfResults extends StatelessWidget {
  const NumOfResults({
    super.key,
    required this.tab,
  });

  final SearchingTab tab;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        return SizedBox(
          width: 160,
          height: 52, // גובה קבוע
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: SpinBox(
              value: state.numResults.toDouble(),
              onChanged: (value) => context
                  .read<SearchBloc>()
                  .add(UpdateNumResults(value.toInt())),
              min: 10,
              max: 10000,
              decoration: const InputDecoration(
                labelText: 'מספר תוצאות',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SearchTermsDisplay extends StatefulWidget {
  const SearchTermsDisplay({
    super.key,
    required this.tab,
  });

  final SearchingTab tab;

  @override
  State<SearchTermsDisplay> createState() => _SearchTermsDisplayState();
}

class _SearchTermsDisplayState extends State<SearchTermsDisplay> {
  @override
  void initState() {
    super.initState();
    // מאזין לשינויים בקונטרולר
    widget.tab.queryController.addListener(_onTextChanged);
    // מאזין לשינויים באפשרויות החיפוש
    _listenToSearchOptions();
  }

  void _listenToSearchOptions() {
    // מאזין לשינויים באפשרויות החיפוש
    widget.tab.searchOptionsChanged.addListener(_onSearchOptionsChanged);
    // מאזין לשינויים במילים החילופיות
    widget.tab.alternativeWordsChanged.addListener(_onAlternativeWordsChanged);
  }

  void _onSearchOptionsChanged() {
    // עדכון התצוגה כשמשתמש משנה אפשרויות
    setState(() {
      // זה יגרום לעדכון של התצוגה
    });
  }

  void _onAlternativeWordsChanged() {
    // עדכון התצוגה כשמשתמש משנה מילים חילופיות
    setState(() {
      // זה יגרום לעדכון של התצוגה
    });
  }

  double _calculateFormattedTextWidth(String text, BuildContext context) {
    if (text.trim().isEmpty) return 0;

    // יצירת TextSpan עם הטקסט המעוצב
    final spans = _buildFormattedTextSpans(text, context);

    // שימוש ב-TextPainter למדידת הרוחב האמיתי
    final textPainter = TextPainter(
      text: TextSpan(children: spans),
      textDirection: TextDirection.rtl,
    );

    textPainter.layout();
    return textPainter.width;
  }

  List<TextSpan> _buildFormattedTextSpans(String text, BuildContext context) {
    if (text.trim().isEmpty) return [const TextSpan(text: '')];

    final words = text.trim().split(RegExp(r'\s+'));
    final List<TextSpan> spans = [];

    // מיפוי אפשרויות לקיצורים
    const Map<String, String> optionAbbreviations = {
      'קידומות': 'ק',
      'סיומות': 'ס',
      'קידומות דקדוקיות': 'קד',
      'סיומות דקדוקיות': 'סד',
      'כתיב מלא/חסר': 'מח',
      'שורש': 'ש',
    };

    // אפשרויות שמופיעות אחרי המילה (סיומות)
    const Set<String> suffixOptions = {
      'סיומות',
      'סיומות דקדוקיות',
    };

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final wordKey = '${word}_$i';

      // בדיקה אם יש אפשרויות למילה הזו
      final wordOptions = widget.tab.searchOptions[wordKey];
      final selectedOptions = wordOptions?.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList() ??
          [];

      // בדיקה אם יש מילים חילופיות למילה הזו
      final alternativeWords = widget.tab.alternativeWords[i] ?? [];

      // הפרדה בין קידומות לסיומות
      final prefixes = selectedOptions
          .where((opt) => !suffixOptions.contains(opt))
          .map((opt) => optionAbbreviations[opt] ?? opt)
          .toList();

      final suffixes = selectedOptions
          .where((opt) => suffixOptions.contains(opt))
          .map((opt) => optionAbbreviations[opt] ?? opt)
          .toList();

      // הוספת קידומות לפני המילה
      if (prefixes.isNotEmpty) {
        spans.add(
          TextSpan(
            text: '(${prefixes.join(',')})',
            style: TextStyle(
              fontSize: 10, // גופן קטן יותר לקיצורים
              fontWeight: FontWeight.normal,
              color: Theme.of(context).primaryColor,
            ),
          ),
        );
        spans.add(const TextSpan(text: ' '));
      }

      // הוספת המילה המודגשת
      spans.add(
        TextSpan(
          text: word,
          style: const TextStyle(
            fontSize: 16, // גופן גדול יותר למילים
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      );

      // הוספת מילים חילופיות אם יש
      if (alternativeWords.isNotEmpty) {
        for (final altWord in alternativeWords) {
          // הוספת "או" בצבע הסיומות
          spans.add(const TextSpan(text: ' '));
          spans.add(
            TextSpan(
              text: 'או',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).primaryColor,
              ),
            ),
          );
          spans.add(const TextSpan(text: ' '));

          // הוספת המילה החילופית המודגשת
          spans.add(
            TextSpan(
              text: altWord,
              style: const TextStyle(
                fontSize: 16, // גופן גדול יותר למילים
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          );
        }
      }

      // הוספת סיומות אחרי המילה (והמילים החילופיות)
      if (suffixes.isNotEmpty) {
        spans.add(const TextSpan(text: ' '));
        spans.add(
          TextSpan(
            text: '(${suffixes.join(',')})',
            style: TextStyle(
              fontSize: 10, // גופן קטן יותר לקיצורים
              fontWeight: FontWeight.normal,
              color: Theme.of(context).primaryColor,
            ),
          ),
        );
      }

      // הוספת + בין המילים (לא אחרי המילה האחרונה)
      if (i < words.length - 1) {
        spans.add(
          const TextSpan(
            text: ' + ',
            style: TextStyle(
              fontSize: 16, // גופן גדול יותר ל-+
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        );
      }
    }

    return spans;
  }

  @override
  void dispose() {
    widget.tab.queryController.removeListener(_onTextChanged);
    widget.tab.searchOptionsChanged.removeListener(_onSearchOptionsChanged);
    widget.tab.alternativeWordsChanged
        .removeListener(_onAlternativeWordsChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      // עדכון התצוגה כשהטקסט משתנה
    });
  }

  String _getDisplayText(String originalQuery) {
    // כרגע נציג את הטקסט המקורי
    // בעתיד נוסיף לוגיקה להצגת החלופות
    // למשל: "מאימתי או מתי ו קורין או קוראין"
    return originalQuery;
  }

  Widget _buildFormattedText(String text, BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    final spans = _buildFormattedTextSpans(text, context);
    return RichText(
      text: TextSpan(children: spans),
      textAlign: TextAlign.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        // נציג את הטקסט הנוכחי מהקונטרולר במקום מה-state
        final displayText = _getDisplayText(widget.tab.queryController.text);

        return LayoutBuilder(
          builder: (context, constraints) {
            // חישוב רוחב דינמי בהתבסס על אורך הטקסט המעוצב
            const minWidth = 120.0; // רוחב מינימלי גדול יותר
            final maxWidth = constraints.maxWidth; // כל הרוחב הזמין

            // חישוב רוחב בהתבסס על הרוחב האמיתי של הטקסט המעוצב
            final formattedTextWidth =
                _calculateFormattedTextWidth(displayText, context);
            final calculatedWidth = formattedTextWidth == 0
                ? minWidth
                : (formattedTextWidth + 40)
                    .clamp(minWidth, maxWidth); // מרווח מותאם לגופן הגדול

            return Align(
              alignment: Alignment.center, // ממורכז תמיד
              child: SizedBox(
                width: calculatedWidth,
                height: 52, // גובה קבוע כמו שאר הבקרות
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'מילות החיפוש',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 8.0), // padding מותאם
                    ),
                    child: displayText.isEmpty
                        ? const SizedBox.shrink()
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Center(
                              child: _buildFormattedText(displayText, context),
                            ),
                          ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class AdvancedSearchToggle extends StatelessWidget {
  const AdvancedSearchToggle({
    super.key,
    required this.tab,
    required this.onChanged,
  });

  final SearchingTab tab;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100, // רוחב צר יותר
      height: 52, // גובה קבוע כמו שאר הבקרות
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'חיפוש מתקדם',
            labelStyle: TextStyle(fontSize: 13), // גופן קטן יותר
            border: OutlineInputBorder(),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          ),
          child: Center(
            child: Checkbox(
              value: tab.isAdvancedSearchEnabled,
              onChanged: (value) => onChanged(value ?? true),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ),
    );
  }
}

class OrderOfResults extends StatelessWidget {
  const OrderOfResults({
    super.key,
    required this.widget,
  });

  final TantivySearchResults widget;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        return SizedBox(
          width: 175, // רוחב גדול יותר לטקסט הארוך
          height: 52, // גובה קבוע כמו NumOfResults
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: DropdownButtonFormField<ResultsOrder>(
              value: state.sortBy,
              decoration: const InputDecoration(
                labelText: 'מיון',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              ),
              items: const [
                DropdownMenuItem(
                  value: ResultsOrder.relevance,
                  child: Text('לפי רלוונטיות'),
                ),
                DropdownMenuItem(
                  value: ResultsOrder.catalogue,
                  child: Text('לפי סדר קטלוגי'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  context.read<SearchBloc>().add(UpdateSortOrder(value));
                }
              },
            ),
          ),
        );
      },
    );
  }
}
