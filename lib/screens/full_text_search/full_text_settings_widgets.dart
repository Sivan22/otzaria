import 'package:flutter/material.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:otzaria/models/tabs/searching_tab.dart';
import 'package:otzaria/screens/full_text_search/tantivy_search_results.dart';
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
    return ValueListenableBuilder(
        valueListenable: tab.fuzzy,
        builder: (context, aproximateSearch, child) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ToggleSwitch(
              minWidth: 150,
              minHeight: 45,
              inactiveBgColor: Colors.grey,
              inactiveFgColor: Colors.white,
              initialLabelIndex: aproximateSearch ? 1 : 0,
              totalSwitches: 2,
              labels: const ['חיפוש מדוייק', 'חיפוש מקורב'],
              radiusStyle: true,
              onToggle: (index) {
                tab.fuzzy.value = index != 0;
              },
            ),
          );
        });
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
    return SizedBox(
      width: 200,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ValueListenableBuilder(
            valueListenable: tab.distance,
            builder: (context, distance, child) {
              return ValueListenableBuilder(
                  valueListenable: tab.fuzzy,
                  builder: (context, fuzzy, child) {
                    return SpinBox(
                      enabled: !fuzzy,
                      decoration:
                          const InputDecoration(labelText: 'מרווח בין מילים'),
                      min: 0,
                      max: 30,
                      value: distance.toDouble(),
                      onChanged: (value) => tab.distance.value = value.toInt(),
                    );
                  });
            }),
      ),
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
    return ValueListenableBuilder(
        valueListenable: tab.numResults,
        builder: (context, numResults, child) {
          return SizedBox(
            width: 200,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SpinBox(
                value: numResults.toDouble(),
                onChanged: (value) => tab.numResults.value = (value.toInt()),
                min: 10,
                max: 10000,
                decoration: const InputDecoration(labelText: 'מספר תוצאות'),
              ),
            ),
          );
        });
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
    return ValueListenableBuilder(
        valueListenable: widget.tab.sortBy,
        builder: (context, sortBy, child) {
          return SizedBox(
            width: 300,
            child: Center(
              child: DropdownButton<ResultsOrder>(
                  value: sortBy,
                  items: const [
                    DropdownMenuItem(
                      value: ResultsOrder.relevance,
                      child: Text('מיון לפי רלוונטיות'),
                    ),
                    DropdownMenuItem(
                      value: ResultsOrder.catalogue,
                      child: Text('מיון לפי סדר קטלוגי'),
                    ),
                  ],
                  onChanged: (value) {
                    widget.tab.sortBy.value = value!;
                  }),
            ),
          );
        });
  }
}
