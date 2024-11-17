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
  bool _needsIndexing = false;
  late AppModel appModel;

  @override
  void initState() {
    super.initState();
    appModel = Provider.of<AppModel>(context, listen: false);
    _refs = findRefs(_searchController.text);
    _checkIndexStatus();
  }

  Future<void> _checkIndexStatus() async {
    final booksWithRefs =
        await DataRepository.instance.getNumberOfBooksWithRefs();
    final totalBooks = (await appModel.library).getAllBooks().length;

    // If there's a difference of more than 5 books or if there are no refs at all
    if (booksWithRefs == 0 || (totalBooks - booksWithRefs) > 5) {
      setState(() {
        _needsIndexing = true;
      });
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

  Widget _buildIndexingMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'האינדקס ריק או לא מעודכן. יש לעדכן את האינדקס כדי לחפש מקורות.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final result = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  content: const Text(
                    'האם ברצונך ליצור אינדקס מקורות? הדבר יאפס את האינדקס הקיים ועלול לקחת זמן ארוך מאד.',
                  ),
                  actions: <Widget>[
                    ElevatedButton(
                      child: const Text('ביטול'),
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                    ),
                    ElevatedButton(
                      child: const Text('אישור'),
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                    ),
                  ],
                ),
              );
              if (result == true) {
                appModel.createRefsFromLibrary(0);
                setState(() {
                  _needsIndexing = false;
                });
              }
            },
            child: const Text('יצירת אינדקס מקורות'),
          ),
        ],
      ),
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
              child: _needsIndexing
                  ? _buildIndexingMessage()
                  : FutureBuilder<List<Ref>>(
                      future: _refs,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (snapshot.data!.isEmpty &&
                            _searchController.text.length >= 3) {
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
                                    final appModel = Provider.of<AppModel>(
                                        context,
                                        listen: false);
                                    if (snapshot.data![index].pdfBook) {
                                      appModel.openBook(
                                          PdfBook(
                                              title: snapshot
                                                  .data![index].bookTitle,
                                              path: snapshot
                                                  .data![index].pdfPath!),
                                          snapshot.data![index].index);
                                    } else {
                                      appModel.openBook(
                                          TextBook(
                                            title:
                                                snapshot.data![index].bookTitle,
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
