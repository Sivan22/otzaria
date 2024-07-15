import 'dart:io';
import 'package:otzaria/models/text_book_searcher.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:search_highlight_text/search_highlight_text.dart';
import 'package:otzaria/models/search_results.dart';

class TextBookSearchView extends StatefulWidget {
  final String data;
  final ItemScrollController scrollControler;
  final TextEditingController searchTextController;
  final FocusNode focusNode;
  final void Function() closeLeftPaneCallback;

  const TextBookSearchView(
      {Key? key,
      required this.data,
      required this.scrollControler,
      required this.searchTextController,
      required this.focusNode,
      required this.closeLeftPaneCallback})
      : super(key: key);

  @override
  TextBookSearchViewState createState() => TextBookSearchViewState();
}

class TextBookSearchViewState extends State<TextBookSearchView>
    with AutomaticKeepAliveClientMixin<TextBookSearchView> {
  late final TextBookSearcher markdownTextSearcher;
  List<TextSearchResult> searchResults = [];
  late ItemScrollController scrollControler;

  @override
  void initState() {
    super.initState();
    markdownTextSearcher = TextBookSearcher(widget.data);
    markdownTextSearcher.addListener(_searchResultUpdated);
    widget.searchTextController.addListener(_searchTextUpdated);
    scrollControler = widget.scrollControler;
    if (!Platform.isAndroid) {
      widget.focusNode.requestFocus();
    }
  }

  void _searchTextUpdated() {
    markdownTextSearcher.startTextSearch(widget.searchTextController.text);
  }

  void _searchResultUpdated() {
    if (mounted) {
      setState(() {
        searchResults = markdownTextSearcher.searchResults;
        // Trigger a rebuild to display the search results.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(children: <Widget>[
      TextField(
        focusNode: widget.focusNode,
        controller: widget.searchTextController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'חפש כאן..',
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  widget.searchTextController.clear();
                  widget.focusNode.requestFocus();
                },
              ),
            ],
          ),
        ),
      ),
      SizedBox.fromSize(
          size: const Size.fromHeight(400),
          child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                if (searchResults.isNotEmpty) {
                  final result = searchResults[index];
                  return ListTile(
                      title: Text(
                        result.address,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: SearchHighlightText(result.snippet,
                          searchText: result.query),
                      onTap: () {
                        widget.scrollControler.scrollTo(
                          index: result.index,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.ease,
                        );
                        if (Platform.isAndroid) {
                          widget.closeLeftPaneCallback();
                        }
                      });
                } else {
                  return const SizedBox.shrink();
                }
              }))
    ]);
  }

  @override
  bool get wantKeepAlive => true;
}
