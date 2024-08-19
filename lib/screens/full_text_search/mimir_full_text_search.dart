import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_mimir/flutter_mimir.dart';
import 'package:otzaria/data/data_providers/mimir_data_provider.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/tabs.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:otzaria/screens/full_text_search/full_text_left_pane.dart';
import 'package:provider/provider.dart';

class MimirFullTextSearch extends StatefulWidget {
  final SearchingTab tab;
  const MimirFullTextSearch({Key? key, required this.tab}) : super(key: key);
  @override
  State<MimirFullTextSearch> createState() => _MimirFullTextSearchState();
}

class _MimirFullTextSearchState extends State<MimirFullTextSearch> {
  Stream<List<MimirDocument>> results = Stream.value([]);
  List<String> booksToSearch = [];
  late TextEditingController queryController;
  ValueNotifier isLeftPaneOpen = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    queryController = widget.tab.queryController;
    widget.tab.aproximateSearch.addListener(() => updateResults());
  }

  void updateResults() {
    setState(() {
      if (queryController.text.isEmpty) {
        results = Stream.value([]);
      } else {
        if (!widget.tab.aproximateSearch.value) {
          results = MimirDataProvider.instance
              .searchTextsStream('"${queryController.text}"', booksToSearch);
        } else {
          results = MimirDataProvider.instance
              .searchTextsStream(queryController.text, booksToSearch);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            isLeftPaneOpen.value = !isLeftPaneOpen.value;
          },
        ),
      ),
      body: Row(
        children: [
          ValueListenableBuilder(
              valueListenable: isLeftPaneOpen,
              builder: (context, value, child) {
                return AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: SizedBox(
                      width: isLeftPaneOpen.value ? 350 : 0,
                      child: FullTextLeftPane(tab: widget.tab),
                    ));
              }),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(60, 30, 60, 10),
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
                Expanded(
                  child: StreamBuilder(
                      stream: results,
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
                                context.read<AppModel>().openTab(
                                      TextBookTab(
                                          book: TextBook(
                                            title: snapshot.data![index]
                                                ['title'],
                                          ),
                                          index: snapshot.data![index]['index'],
                                          searchText: queryController.text),
                                    );
                              },
                              title: FutureBuilder(
                                  future: refFromIndex(
                                      snapshot.data![index]['index'],
                                      TextBook(
                                              title: snapshot.data![index]
                                                  ['title'])
                                          .tableOfContents),
                                  builder: (context, ref) {
                                    if (!ref.hasData) {
                                      return Text(
                                          '${snapshot.data![index]['title']} ...');
                                    }
                                    return Text(
                                      ref.data!,
                                    );
                                  }),
                              subtitle: Html(
                                  data: highLight(snapshot.data![index]['text'],
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
      ),
    );
  }
}
