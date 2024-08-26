import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/tabs.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:otzaria/screens/full_text_search/full_text_left_pane.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class TantivyFullTextSearch extends StatefulWidget {
  final SearchingTab tab;
  const TantivyFullTextSearch({Key? key, required this.tab}) : super(key: key);
  @override
  State<TantivyFullTextSearch> createState() => _TantivyFullTextSearchState();
}

class _TantivyFullTextSearchState extends State<TantivyFullTextSearch> {
  late TextEditingController queryController;
  ValueNotifier isLeftPaneOpen = ValueNotifier(false);
  Future<List<Map<String, dynamic>>> results = Future.value([]);

  @override
  void initState() {
    super.initState();
    queryController = widget.tab.queryController;
    widget.tab.aproximateSearch.addListener(() => updateResults());
    widget.tab.booksToSearch.addListener(() => updateResults());
  }

  void updateResults() {
    setState(() {
      if (queryController.text.isEmpty) {
        results = Future.value([]);
      } else {
        final booksToSearch =
            widget.tab.booksToSearch.value.map<String>((e) => e.title).toList();
        if (!widget.tab.aproximateSearch.value) {
          results = search('"${queryController.text}"', booksToSearch);
        } else {
          results = results = search(queryController.text, booksToSearch);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
          valueListenable: isLeftPaneOpen,
          builder: (context, value, child) {
            return Row(
              children: [
                !isLeftPaneOpen.value
                    ? SizedBox.shrink()
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                            child: IconButton(
                              icon: const Icon(Icons.menu),
                              onPressed: () {
                                isLeftPaneOpen.value = !isLeftPaneOpen.value;
                              },
                            ),
                          ),
                          Expanded(child: SizedBox.shrink()),
                        ],
                      ),
                AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: SizedBox(
                      width: isLeftPaneOpen.value ? 350 : 0,
                      child: FullTextLeftPane(tab: widget.tab),
                    )),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          isLeftPaneOpen.value
                              ? SizedBox.shrink()
                              : Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 8, 0),
                                  child: IconButton(
                                    icon: const Icon(Icons.menu),
                                    onPressed: () {
                                      isLeftPaneOpen.value =
                                          !isLeftPaneOpen.value;
                                    },
                                  ),
                                ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(60, 5, 60, 10),
                              child: TextField(
                                autofocus: true,
                                controller: queryController,
                                onChanged: (e) => updateResults(),
                                decoration: InputDecoration(
                                  hintText: "חפש כאן..",
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      queryController.clear();
                                      updateResults();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: FutureBuilder(
                            future: results,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return Center(
                                    child: Text('error: ${snapshot.error}'));
                              }
                              return ListView.builder(
                                shrinkWrap: true,
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    onTap: () {
                                      if (snapshot.data![index]['doc']
                                          ['isPdf']) {
                                        context
                                            .read<AppModel>()
                                            .openTab(
                                                PdfBookTab(
                                                    PdfBook(
                                                        title: snapshot.data![
                                                                index]['doc']
                                                            ['title'],
                                                        path: snapshot
                                                                .data![index]
                                                            ['doc']['pdfPath']),
                                                    snapshot.data![index]['doc']
                                                        ['index']));
                                      } else {
                                        context.read<AppModel>().openTab(
                                              TextBookTab(
                                                  book: TextBook(
                                                    title: snapshot.data![index]
                                                        ['doc']['title'],
                                                  ),
                                                  index: snapshot.data![index]
                                                      ['doc']['index'],
                                                  searchText:
                                                      queryController.text),
                                            );
                                      }
                                    },
                                    title: snapshot.data![index]['doc']
                                                ['isPdf'] ??
                                            false
                                        ? Text(snapshot.data![index]['doc']
                                                ['title'] +
                                            ' עמוד ${snapshot.data![index]['doc']['index'] + 1}')
                                        : FutureBuilder(
                                            future: refFromIndex(
                                                (snapshot.data![index]['doc']
                                                        ['index']) ??
                                                    0,
                                                TextBook(
                                                        title: snapshot.data![
                                                                        index]
                                                                    ['doc']
                                                                ['title'] ??
                                                            '')
                                                    .tableOfContents),
                                            builder: (context, ref) {
                                              if (!ref.hasData) {
                                                return Text(
                                                    '${snapshot.data![index]['doc']['title']} ...');
                                              }
                                              return Text(
                                                ref.data!,
                                              );
                                            }),
                                    subtitle: Html(
                                        data: highLight(
                                            snapshot.data![index]['doc']
                                                ['text'],
                                            queryController.text)),
                                  );
                                },
                              );
                            }),
                      )
                    ],
                  ),
                ),
              ],
            );
          }),
    );
  }

  Future<List<Map<String, dynamic>>> search(
      String query, List<String> books) async {
    final q = 'text:$query title:${books.join(',')}';

    final response =
        await http.get(Uri.parse('http://localhost:3000/api/?q=$query'));
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return (jsonDecode(response.body)['hits'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to search');
    }
  }
}
