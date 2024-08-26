import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/tabs.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:otzaria/screens/full_text_search/full_text_left_pane.dart';
import 'package:provider/provider.dart';
import 'package:search_engine/search_engine.dart';

class MimirFullTextSearch extends StatefulWidget {
  final SearchingTab tab;
  const MimirFullTextSearch({Key? key, required this.tab}) : super(key: key);
  @override
  State<MimirFullTextSearch> createState() => _MimirFullTextSearchState();
}

class _MimirFullTextSearchState extends State<MimirFullTextSearch> {
  Future<List<SearchResult>> results = Future.value([]);
  late TextEditingController queryController;
  ValueNotifier isLeftPaneOpen = ValueNotifier(false);

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
          results = TantivyDataProvider.instance
              .searchTexts('"${queryController.text}"', booksToSearch);
        } else {
          results = TantivyDataProvider.instance
              .searchTexts(queryController.text, booksToSearch);
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
                              if (!snapshot.hasData) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              return ListView.builder(
                                shrinkWrap: true,
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    onTap: () {
                                      if (snapshot.data![index].isPdf) {
                                        context.read<AppModel>().openTab(
                                            PdfBookTab(
                                                PdfBook(
                                                    title: snapshot
                                                        .data![index].title,
                                                    path: snapshot.data![index]
                                                        .filePath),
                                                snapshot.data![index].segment
                                                    .toInt()));
                                      } else {
                                        context.read<AppModel>().openTab(
                                              TextBookTab(
                                                  book: TextBook(
                                                    title: snapshot
                                                        .data![index].title,
                                                  ),
                                                  index: snapshot
                                                      .data![index].segment
                                                      .toInt(),
                                                  searchText:
                                                      queryController.text),
                                            );
                                      }
                                    },
                                    title: snapshot.data![index].isPdf
                                        ? Text(snapshot.data![index].title +
                                            ' עמוד ${snapshot.data![index].segment.toInt() + 1}')
                                        : FutureBuilder(
                                            future: refFromIndex(
                                                snapshot.data![index].segment
                                                    .toInt(),
                                                TextBook(
                                                        title: snapshot
                                                            .data![index].title)
                                                    .tableOfContents),
                                            builder: (context, ref) {
                                              if (!ref.hasData) {
                                                return Text(
                                                    '${snapshot.data![index].title} ...');
                                              }
                                              return Text(
                                                ref.data!,
                                              );
                                            }),
                                    subtitle: Html(
                                        data: highLight(
                                            snapshot.data![index].text,
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
}
