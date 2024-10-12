import 'package:flutter/material.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/isar_collections/ref.dart';
import 'package:otzaria/screens/ref_indexing_screen.dart';
import 'package:provider/provider.dart';

class FindRefScreen extends StatefulWidget {
  const FindRefScreen({super.key});

  @override
  State<FindRefScreen> createState() => _FindRefScreenState();
}

class _FindRefScreenState extends State<FindRefScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Ref>> _refs;

  @override
  void initState() {
    super.initState();
    _refs = findRefs(_searchController.text);
  }

  Future<List<Ref>> findRefs(String ref) async {
    if (ref.length < 3) {
      return [];
    }
    //ref = paraphrase(ref);
    return DataRepository.instance.findRefsByRelevance(
      ref,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                          _searchController.clear();
                          _refs = findRefs(_searchController.text);
                        });
                      },
                    ),
                  ],
                ),
              ),
              controller: _searchController,
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
