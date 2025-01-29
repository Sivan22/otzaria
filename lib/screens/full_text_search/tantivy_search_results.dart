import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/tabs/pdf_tab.dart';
import 'package:otzaria/models/tabs/searching_tab.dart';
import 'package:otzaria/models/tabs/text_tab.dart';
import 'package:provider/provider.dart';
import 'package:search_engine/search_engine.dart';

class TantivySearchResults extends StatefulWidget {
  final SearchingTab tab;
  const TantivySearchResults({Key? key, required this.tab}) : super(key: key);

  @override
  State<TantivySearchResults> createState() => _TantivySearchResultsState();
}

class _TantivySearchResultsState extends State<TantivySearchResults> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: widget.tab.results,
        builder: (context, results, child) {
          if (widget.tab.queryController.text.isEmpty) {
            return const Center(child: Text("לא בוצע חיפוש"));
          }
          return FutureBuilder(
              future: results,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.data!.isEmpty) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('אין תוצאות'),
                  ));
                }
                return Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: FutureBuilder(
                              future: widget.tab.totalResultsNum,
                              builder: (context, totalResults) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return Center(
                                      child: Text('Error: ${snapshot.error}'));
                                }
                                return Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${snapshot.data!.length} תוצאות מתוך ${totalResults.data}',
                                      ),
                                    ),
                                  ],
                                );
                              }),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              onTap: () {
                                if (snapshot.data![index].isPdf) {
                                  context.read<AppModel>().openTab(
                                      PdfBookTab(
                                          searchText:
                                              widget.tab.queryController.text,
                                          PdfBook(
                                              title:
                                                  snapshot.data![index].title,
                                              path: snapshot
                                                  .data![index].filePath),
                                          snapshot.data![index].segment
                                                  .toInt() +
                                              1),
                                      index: snapshot.data![index].segment
                                              .toInt() +
                                          1);
                                } else {
                                  context.read<AppModel>().openTab(
                                        TextBookTab(
                                            book: TextBook(
                                              title:
                                                  snapshot.data![index].title,
                                            ),
                                            index: snapshot.data![index].segment
                                                .toInt(),
                                            searchText: widget
                                                .tab.queryController.text),
                                      );
                                }
                              },
                              title: Text(
                                  '[תוצאה ${index + 1}] ${snapshot.data![index].reference}'),
                              subtitle: Html(
                                  data: snapshot.data![index].text,
                                  style: {
                                    'body': Style(
                                        fontSize: FontSize(
                                          context
                                              .read<AppModel>()
                                              .fontSize
                                              .value,
                                        ),
                                        fontFamily: context
                                            .read<AppModel>()
                                            .fontFamily
                                            .value,
                                        textAlign: TextAlign.justify),
                                  }),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              });
        });
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
    return ValueListenableBuilder(
        valueListenable: widget.tab.sortBy,
        builder: (context, sortBy, child) {
          return SizedBox(
            width: 300,
            child: Center(
              child: DropdownButton<ResultsOrder>(
                  value: sortBy,
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
                    widget.tab.sortBy.value = value!;
                  }),
            ),
          );
        });
  }
}
