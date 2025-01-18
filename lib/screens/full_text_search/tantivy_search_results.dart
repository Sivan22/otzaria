import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/tabs.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:provider/provider.dart';

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
                  return const Center(child: Text('אין תוצאות'));
                }
                return Scaffold(
                  body: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: Text(
                              '${snapshot.data!.length} תוצאות',
                            ),
                          ),
                        ),
                        ListView.builder(
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
                              title: snapshot.data![index].isPdf
                                  ? Text(snapshot.data![index].title +
                                      ' עמוד ${snapshot.data![index].segment.toInt() + 1}')
                                  : FutureBuilder(
                                      future: refFromIndex(
                                          snapshot.data![index].segment.toInt(),
                                          TextBook(
                                                  title: snapshot
                                                      .data![index].title)
                                              .tableOfContents),
                                      builder: (context, ref) {
                                        if (!ref.hasData) {
                                          return Text(
                                              '[תוצאה ${index + 1}] ${snapshot.data![index].title} ...');
                                        }
                                        return Text(
                                          '[תוצאה ${index + 1}] ${ref.data!}',
                                        );
                                      }),
                              subtitle: Html(
                                  data: snapshot.data![index].text,
                                  style: {
                                    'body': Style(
                                        fontSize: FontSize(
                                          context
                                              .watch<AppModel>()
                                              .fontSize
                                              .value,
                                        ),
                                        fontFamily: context
                                            .watch<AppModel>()
                                            .fontFamily
                                            .value,
                                        textAlign: TextAlign.justify),
                                  }),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              });
        });
  }
}
