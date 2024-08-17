import 'package:flutter/material.dart';
import 'package:otzaria/data/data_providers/isar_data_provider.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:provider/provider.dart';

class RefIndexingScreen extends StatefulWidget {
  const RefIndexingScreen({Key? key}) : super(key: key);

  @override
  State<RefIndexingScreen> createState() => _RefIndexingScreenState();
}

class _RefIndexingScreenState extends State<RefIndexingScreen> {
  late AppModel appModel;

  @override
  void initState() {
    appModel = Provider.of<AppModel>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('אינדקס מקורות')),
      ),
      body: Center(
        child: Column(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: TextButton(
                  onPressed: () async {
                    final result = showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                              content: const Text(
                                  'האם ברצונך ליצור אינדקס מקורות? הדבר יאפס את האינדקס הקיים ועלול לקחת זמן ארוך מאד.'),
                              actions: <Widget>[
                                ElevatedButton(
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
                      appModel.createRefsFromLibrary(0);
                    }
                  },
                  child: const Text(
                    'יצירת אינדקס מקורות',
                  ),
                ),
              ),
            ),
            ValueListenableBuilder(
                valueListenable: IsarDataProvider.instance.refsNumOfbooksDone,
                builder: (context, valueDone, child) {
                  if (valueDone == null) {
                    return const SizedBox.shrink();
                  }
                  return ValueListenableBuilder(
                      valueListenable:
                          IsarDataProvider.instance.refsNumOfbooksTotal,
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
      ),
    );
  }
}
