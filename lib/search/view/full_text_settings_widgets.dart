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
          width: 200,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SpinBox(
              value: state.numResults.toDouble(),
              onChanged: (value) => context
                  .read<SearchBloc>()
                  .add(UpdateNumResults(value.toInt())),
              min: 10,
              max: 10000,
              decoration: const InputDecoration(labelText: 'מספר תוצאות'),
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
          width: 300,
          child: Center(
            child: DropdownButton<ResultsOrder>(
                value: state.sortBy,
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
                  if (value != null) {
                    context.read<SearchBloc>().add(UpdateSortOrder(value));
                  }
                }),
          ),
        );
      },
    );
  }
}
