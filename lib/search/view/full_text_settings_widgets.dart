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

class SearchTermsDisplay extends StatelessWidget {
  const SearchTermsDisplay({
    super.key,
    required this.tab,
  });

  final SearchingTab tab;

  String _getDisplayText(String originalQuery) {
    // כרגע נציג את הטקסט המקורי
    // בעתיד נוסיף כאן לוגיקה להצגת החלופות
    // למשל: "מאימתי או מתי ו קורין או קוראין"
    return originalQuery;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        final displayText = _getDisplayText(state.searchQuery);

        // חישוב רוחב מותאם לטקסט המלא (כולל חלופות)
        final textLength = displayText.length;
        const minWidth = 120.0; // רוחב מינימלי
        const maxWidth = 400.0; // רוחב מקסימלי מוגדל לחלופות
        final calculatedWidth =
            (textLength * 8.0 + 60).clamp(minWidth, maxWidth);

        return Container(
          height: 52, // גובה קבוע כמו שאר הווידג'טים
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: minWidth,
                maxWidth: calculatedWidth,
              ),
              child: TextField(
                readOnly: true,
                controller: TextEditingController(text: displayText),
                textAlign: TextAlign.center, // ממרכז את הטקסט
                decoration: const InputDecoration(
                  labelText: 'מילות החיפוש',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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
