import 'package:flutter/material.dart';
import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/tabs.dart';
import 'package:provider/provider.dart';

class FullTextSettingsScreen extends StatelessWidget {
  const FullTextSettingsScreen({
    Key? key,
    required this.tab,
  }) : super(key: key);
  final SearchingTab tab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(child: Text('חיפוש מקורב')),
                    ValueListenableBuilder(
                        valueListenable: tab.fuzzy,
                        builder: (context, aproximateSearch, child) {
                          return Switch(
                              value: aproximateSearch,
                              onChanged: (value) => tab.fuzzy.value = value);
                        }),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(child: Text('מרווח בין מילות החיפוש')),
                    ValueListenableBuilder(
                        valueListenable: tab.distance,
                        builder: (context, distance, child) {
                          return Slider(
                            min: 0,
                            max: 6,
                            value: distance.toDouble(),
                            onChanged: (value) =>
                                tab.distance.value = value.toInt(),
                          );
                        }),
                  ],
                ),
              ),
              Center(
                child: Text(' מספר תוצאות להצגה'),
              ),
              ValueListenableBuilder(
                  valueListenable: tab.numResults,
                  builder: (context, numResults, child) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Slider(
                        value: numResults.toDouble(),
                        onChanged: (value) =>
                            tab.numResults.value = (value.toInt()),
                        label: tab.numResults.value.toString(),
                        min: 10,
                        max: 10000,
                        divisions: 9990,
                      ),
                    );
                  }),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: ValueListenableBuilder(
                      valueListenable: TantivyDataProvider.instance.isIndexing,
                      builder: (context, isIndexing, child) {
                        if (isIndexing) {
                          return const SizedBox.shrink();
                        }
                        return ElevatedButton(
                          onPressed: () async {
                            final result = showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                      content: const Text(
                                          'עדכון האינדקס עלול לקחת זמן ומשאבים רבים. להמשיך?'),
                                      actions: <Widget>[
                                        TextButton(
                                          child: const Text('ביטול'),
                                          onPressed: () {
                                            Navigator.pop(context, false);
                                          },
                                        ),
                                        TextButton(
                                          child: const Text('אישור'),
                                          onPressed: () {
                                            Navigator.pop(context, true);
                                          },
                                        ),
                                      ],
                                    ));
                            if (await result == true) {
                              context.read<AppModel>().addAllTextsToTantivy();
                            }
                          },
                          child: const Text(
                            'עדכון אינדקס',
                          ),
                        );
                      }),
                ),
              ),
              ValueListenableBuilder(
                  valueListenable: TantivyDataProvider.instance.isIndexing,
                  builder: (context, isIndexing, child) {
                    if (!isIndexing) {
                      return const SizedBox.shrink();
                    }
                    return ValueListenableBuilder(
                      valueListenable:
                          TantivyDataProvider.instance.numOfbooksDone,
                      builder: (context, numOfbooksDone, child) => Column(
                        children: [
                          ValueListenableBuilder(
                              valueListenable:
                                  TantivyDataProvider.instance.numOfbooksTotal,
                              builder: (context, valueTotal, child) {
                                if (valueTotal == null) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 50),
                                  child: Column(
                                    children: [
                                      LinearProgressIndicator(
                                        borderRadius: BorderRadius.circular(20),
                                        value: numOfbooksDone! / valueTotal,
                                      ),
                                      Text(' $valueTotal / $numOfbooksDone'),
                                    ],
                                  ),
                                );
                              }),
                          isIndexing
                              ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ElevatedButton(
                                      onPressed: () => TantivyDataProvider
                                          .instance.isIndexing.value = false,
                                      child: Text('עצור')),
                                )
                              : SizedBox.shrink()
                        ],
                      ),
                    );
                  }),
            ],
          ),
        )
      ],
    ));
  }
}
