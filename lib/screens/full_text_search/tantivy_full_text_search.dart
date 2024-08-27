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

class TantivyFullTextSearch extends StatefulWidget {
  final SearchingTab tab;
  const TantivyFullTextSearch({Key? key, required this.tab}) : super(key: key);
  @override
  State<TantivyFullTextSearch> createState() => _TantivyFullTextSearchState();
}

class _TantivyFullTextSearchState extends State<TantivyFullTextSearch> {
  ValueNotifier isLeftPaneOpen = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    () async {
      widget.tab.booksToSearch.value =
          (await context.read<AppModel>().library).getAllBooks().toSet();
    }();
    widget.tab.aproximateSearch.addListener(() => updateResults());
    widget.tab.booksToSearch.addListener(() => updateResults());
    widget.tab.numResults.addListener(() => updateResults());
    widget.tab.queryController.addListener(() => updateResults());
  }

  @override
  void dispose() {
    widget.tab.aproximateSearch.removeListener(() => updateResults());
    widget.tab.booksToSearch.removeListener(() => updateResults());
    widget.tab.numResults.removeListener(() => updateResults());
    widget.tab.queryController.removeListener(() => updateResults());
    super.dispose();
  }

  void updateResults() {
    setState(() {
      if (widget.tab.queryController.text.isEmpty) {
        widget.tab.results = Future.value([]);
      } else {
        final booksToSearch =
            widget.tab.booksToSearch.value.map<String>((e) => e.title).toList();
        if (!widget.tab.aproximateSearch.value) {
          widget.tab.results = TantivyDataProvider.instance.searchTexts(
              '"${widget.tab.queryController.text.replaceAll('"', '\\"')}"',
              booksToSearch,
              widget.tab.numResults.value);
        } else {
          widget.tab.results = TantivyDataProvider.instance.searchTexts(
              widget.tab.queryController.text,
              booksToSearch,
              widget.tab.numResults.value);
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
                NotificationListener<UserScrollNotification>(
                  onNotification: (scrollNotification) {
                    Future.microtask(() {
                      isLeftPaneOpen.value = false;
                    });
                    return false; // Don't block the notification
                  },
                  child: Expanded(
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
                                padding:
                                    const EdgeInsets.fromLTRB(60, 5, 60, 10),
                                child: TextField(
                                  autofocus: true,
                                  controller: widget.tab.queryController,
                                  onChanged: (e) => updateResults(),
                                  decoration: InputDecoration(
                                    hintText: "חפש כאן..",
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        widget.tab.queryController.clear();
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
                              future: widget.tab.results,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return Center(
                                      child: Text('Error: ${snapshot.error}'));
                                }
                                if (snapshot.data!.isEmpty) {
                                  return const Center(
                                      child: Text('אין תוצאות'));
                                }
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: Text(
                                          '${snapshot.data!.length} תוצאות',
                                        ),
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
                                                context
                                                    .read<AppModel>()
                                                    .openTab(
                                                        PdfBookTab(
                                                            PdfBook(
                                                                title: snapshot
                                                                    .data![
                                                                        index]
                                                                    .title,
                                                                path: snapshot
                                                                    .data![
                                                                        index]
                                                                    .filePath),
                                                            snapshot
                                                                    .data![
                                                                        index]
                                                                    .segment
                                                                    .toInt() +
                                                                1),
                                                        index: snapshot
                                                                .data![index]
                                                                .segment
                                                                .toInt() +
                                                            1);
                                              } else {
                                                context
                                                    .read<AppModel>()
                                                    .openTab(
                                                      TextBookTab(
                                                          book: TextBook(
                                                            title: snapshot
                                                                .data![index]
                                                                .title,
                                                          ),
                                                          index: snapshot
                                                              .data![index]
                                                              .segment
                                                              .toInt(),
                                                          searchText: widget
                                                              .tab
                                                              .queryController
                                                              .text),
                                                    );
                                              }
                                            },
                                            title: snapshot.data![index].isPdf
                                                ? Text(snapshot
                                                        .data![index].title +
                                                    ' עמוד ${snapshot.data![index].segment.toInt() + 1}')
                                                : FutureBuilder(
                                                    future: refFromIndex(
                                                        snapshot.data![index]
                                                            .segment
                                                            .toInt(),
                                                        TextBook(
                                                                title: snapshot
                                                                    .data![
                                                                        index]
                                                                    .title)
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
                                                    widget.tab.queryController
                                                        .text)),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              }),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
    );
  }
}
