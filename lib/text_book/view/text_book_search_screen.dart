import 'dart:io';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_event.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/text_book/models/text_book_searcher.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:search_highlight_text/search_highlight_text.dart';
import 'package:otzaria/text_book/models/search_results.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TextBookSearchView extends StatefulWidget {
  final String data;
  final ItemScrollController scrollControler;
  final FocusNode focusNode;
  final void Function() closeLeftPaneCallback;

  const TextBookSearchView(
      {Key? key,
      required this.data,
      required this.scrollControler,
      required this.focusNode,
      required this.closeLeftPaneCallback})
      : super(key: key);

  @override
  TextBookSearchViewState createState() => TextBookSearchViewState();
}

class TextBookSearchViewState extends State<TextBookSearchView>
    with AutomaticKeepAliveClientMixin<TextBookSearchView> {
  TextEditingController searchTextController = TextEditingController();
  late final TextBookSearcher markdownTextSearcher;
  List<TextSearchResult> searchResults = [];
  late ItemScrollController scrollControler;

  @override
  void initState() {
    super.initState();
    markdownTextSearcher = TextBookSearcher(widget.data);
    markdownTextSearcher.addListener(_searchResultUpdated);
    searchTextController.text =
        (context.read<TextBookBloc>().state as TextBookLoaded).searchText;
    scrollControler = widget.scrollControler;
    if (!Platform.isAndroid) {
      widget.focusNode.requestFocus();
    }
  }

  void _searchTextUpdated() {
    markdownTextSearcher.startTextSearch(searchTextController.text);
  }

  void _searchResultUpdated() {
    if (mounted) {
      setState(() {
        searchResults = markdownTextSearcher.searchResults;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(children: <Widget>[
      TextField(
        onChanged: (e) {
          context.read<TextBookBloc>().add(UpdateSearchText(e));
          _searchTextUpdated();
        },
        controller: searchTextController,
        decoration: InputDecoration(
          hintText: 'חפש כאן..',
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  searchTextController.clear();
                  widget.focusNode.requestFocus();
                },
              ),
            ],
          ),
        ),
      ),
      Expanded(
        child: ListView.builder(
            shrinkWrap: true,
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
            }),
      )
    ]);
  }

  @override
  bool get wantKeepAlive => true;
}
