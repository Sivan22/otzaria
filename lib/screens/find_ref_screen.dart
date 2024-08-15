import 'package:flutter/material.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/isar_collections/ref.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:provider/provider.dart';

class FindRefScreen extends StatefulWidget {
  const FindRefScreen({super.key});

  @override
  State<FindRefScreen> createState() => _FindRefScreenState();
}

class _FindRefScreenState extends State<FindRefScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Ref>> _refs;

  @override
  void initState() {
    super.initState();
    _refs = findRefs(_searchController.text);
  }

  Future<List<Ref>> findRefs(String ref) async {
    if (ref.isEmpty) {
      return [];
    }
    ref = paraphrase(ref);
    return DataRepository.instance.findRefsByRelevance(ref);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('איתור מקור מדוייק')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                  hintText:
                      'הקלד מקור מדוייק, לדוגמה: בראשית פרק א או שוע אוח יב   '),
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
                            Provider.of<AppModel>(context, listen: false)
                                .openBook(
                                    TextBook(
                                      title: snapshot.data![index].bookTitle,
                                    ),
                                    snapshot.data![index].index);
                          },
                        );
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
