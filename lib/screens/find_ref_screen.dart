import 'package:flutter/material.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/isar_collections/ref.dart';
import 'package:otzaria/screens/ref_indexing_screen.dart';
import 'package:provider/provider.dart';
import 'package:otzaria/data/data_providers/isar_data_provider.dart';

class FindRefScreen extends StatefulWidget {
  const FindRefScreen({super.key});

  @override
  State<FindRefScreen> createState() => _FindRefScreenState();
}

class _FindRefScreenState extends State<FindRefScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late Future<List<Ref>> _refs;
  late AppModel appModel;

  @override
  void initState() {
    super.initState();
    appModel = Provider.of<AppModel>(context, listen: false);
    _refs = findRefs(appModel.findReferenceController.text);
    _checkIndexStatus();
  }

  Future<void> _checkIndexStatus() async {
    final booksWithRefs =
        await DataRepository.instance.getNumberOfBooksWithRefs();
    if (booksWithRefs == 0) {
      appModel.createRefsFromLibrary(0);
    }
  }

  Future<List<Ref>> findRefs(String ref) async {
    if (ref.length < 3) {
      return [];
    }
    return DataRepository.instance.findRefsByRelevance(
      ref,
    );
  }

  Widget _buildIndexingWarning() {
    return ValueListenableBuilder(
      valueListenable: IsarDataProvider.instance.refsNumOfbooksDone,
      builder: (context, valueDone, child) {
        if (valueDone == null) return const SizedBox.shrink();

        return ValueListenableBuilder(
          valueListenable: IsarDataProvider.instance.refsNumOfbooksTotal,
          builder: (context, valueTotal, child) {
            if (valueTotal == null || valueDone >= valueTotal) {
              return const SizedBox.shrink();
            }

            return Container(
              padding: const EdgeInsets.all(8.0),
              margin: const EdgeInsets.only(bottom: 8.0),
              decoration: BoxDecoration(
                color: Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'אינדקס המקורות בתהליך בנייה. תוצאות החיפוש עלולות להיות חלקיות.',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      drawer: const Drawer(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.zero)),
          semanticLabel: 'הגדרות אינדקס',
          child: RefIndexingScreen()),
      appBar: AppBar(
        title: const Center(child: Text('איתור מקורות')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildIndexingWarning(),
            TextField(
              autofocus: true,
              focusNode: context.read<AppModel>().findReferenceFocusNode,
              decoration: InputDecoration(
                hintText:
                    'הקלד מקור מדוייק, לדוגמה: בראשית פרק א או שוע אוח יב   ',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          appModel.findReferenceController.clear();
                          _refs =
                              findRefs(appModel.findReferenceController.text);
                        });
                      },
                    ),
                  ],
                ),
              ),
              controller: appModel.findReferenceController,
              onChanged: (ref) {
                setState(() {
                  _refs = findRefs(ref);
                });
              },
            ),
            Expanded(
              child: FutureBuilder<List<Ref>>(
                future: _refs,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (snapshot.data!.isEmpty &&
                      appModel.findReferenceController.text.length >= 3) {
                    return const Center(
                      child: Text(
                        'אין תוצאות',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                            title: Text(snapshot.data![index].ref),
                            onTap: () {
                              final appModel =
                                  Provider.of<AppModel>(context, listen: false);
                              if (snapshot.data![index].pdfBook) {
                                appModel.openBook(
                                    PdfBook(
                                        title: snapshot.data![index].bookTitle,
                                        path: snapshot.data![index].pdfPath!),
                                    snapshot.data![index].index);
                              } else {
                                appModel.openBook(
                                    TextBook(
                                      title: snapshot.data![index].bookTitle,
                                    ),
                                    snapshot.data![index].index);
                              }
                            });
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
