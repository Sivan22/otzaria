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
  int? _hoveredWordIndex;

  @override
  void initState() {
    super.initState();
    // מאזין לשינויים בקונטרולר
    widget.tab.queryController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.tab.queryController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      // עדכון התצוגה כשהטקסט משתנה
    });
  }

  String _getDisplayText(String originalQuery) {
    // כרגע נציג את הטקסט המקורי
    // בעתיד נוסיף כאן לוגיקה להצגת החלופות
    // למשל: "מאימתי או מתי ו קורין או קוראין"
    return originalQuery;
  }

  List<String> _getWords(String text) {
    // פיצול הטקסט למילים
    return text.trim().split(RegExp(r'\s+'));
  }

  Widget _buildSpacingButton(
      {required VoidCallback onPressed, required bool isLeft}) {
    return SizedBox(
      width: 20,
      height: 20,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 12,
        onPressed: onPressed,
        icon: Icon(
          isLeft ? Icons.keyboard_arrow_left : Icons.keyboard_arrow_right,
          color: Colors.blue,
        ),
        style: IconButton.styleFrom(
          backgroundColor: Colors.blue.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildWordWithSpacing(String word, int index, int totalWords) {
    final isFirst = index == 0;
    final isLast = index == totalWords - 1;
    final isHovered = _hoveredWordIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredWordIndex = index),
      onExit: (_) => setState(() => _hoveredWordIndex = null),
      child: Container(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // כפתור שמאלי (רק למילים שאינן ראשונות או כשמרחפים)
            if (!isFirst && isHovered)
              _buildSpacingButton(
                onPressed: () {
                  // כאן נוסיף לוגיקה להוספת מרווח
                  print('Add spacing before word: $word');
                },
                isLeft: true,
              ),

            // המילה עצמה
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: isHovered
                  ? BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              child: Text(
                word,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // כפתור ימני (רק למילים שאינן אחרונות או כשמרחפים)
            if (!isLast && isHovered)
              _buildSpacingButton(
                onPressed: () {
                  // כאן נוסיף לוגיקה להוספת מרווח
                  print('Add spacing after word: $word');
                },
                isLeft: false,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        // נציג את הטקסט הנוכחי מהקונטרולר במקום מה-state
        final displayText = _getDisplayText(widget.tab.queryController.text);

        return Container(
          height: 52, // גובה קבוע כמו שאר הווידג'טים
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // חישוב רוחב דינמי בהתבסס על אורך הטקסט
              final textLength = displayText.length;
              const minWidth = 120.0; // רוחב מינימלי גדול יותר
              final maxWidth = constraints.maxWidth; // כל הרוחב הזמין

              // חישוב רוחב בהתבסס על אורך הטקסט
              final calculatedWidth = textLength == 0
                  ? minWidth
                  : (textLength * 8.0 + 40).clamp(minWidth, maxWidth);

              return Align(
                alignment: Alignment.center, // ממורכז תמיד
                child: SizedBox(
                  width: calculatedWidth,
                  child: Scrollbar(
                    thumbVisibility:
                        displayText.isNotEmpty, // מציג פס גלילה רק כשיש טקסט
                    child: TextField(
                      readOnly: true,
                      controller: TextEditingController(text: displayText),
                      textAlign: TextAlign.center, // ממרכז את הטקסט
                      maxLines: 1, // שורה אחת בלבד
                      scrollPadding: EdgeInsets.zero, // מאפשר גלילה חלקה
                      decoration: const InputDecoration(
                        labelText: 'מילות החיפוש',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 8.0),
                      ),
                      style: const TextStyle(
                        fontSize: 13, // גופן קצת יותר קטן
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
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
