import 'package:flutter/material.dart';
import 'package:otzaria/data/data_providers/mimir_data_provider.dart';
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
                          valueListenable: tab.aproximateSearch,
                          builder: (context, aproximateSearch, child) {
                            return Switch(
                                value: aproximateSearch,
                                onChanged: (value) =>
                                    tab.aproximateSearch.value = value);
                          }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: ElevatedButton(
                onPressed: () async {
                  final result = showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                            content: const Text(
                                'האם ברצונך ליצור אינדקס חיפוש? הדבר יאפס את האינדקס הקיים ועלול לקחת זמן ארוך מאד.'),
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
                    context.read<AppModel>().addAllTextsToMimir();
                  }
                },
                child: const Text(
                  'יצירת אינדקס',
                ),
              ),
            ),
          ),
          ValueListenableBuilder(
              valueListenable: MimirDataProvider.instance.numOfbooksDone,
              builder: (context, valueDone, child) {
                if (valueDone == null) {
                  return const SizedBox.shrink();
                }
                return ValueListenableBuilder(
                    valueListenable: MimirDataProvider.instance.numOfbooksTotal,
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
                              value: valueDone / valueTotal,
                            ),
                            Text(' $valueTotal / $valueDone'),
                          ],
                        ),
                      );
                    });
              }),
        ],
      ),
    );
  }
}
