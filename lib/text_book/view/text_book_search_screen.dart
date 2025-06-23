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

class _GroupedResultItem {
  final String? header;
  final TextSearchResult? result;
  const _GroupedResultItem.header(this.header) : result = null;
  const _GroupedResultItem.result(this.result) : header = null;
  bool get isHeader => header != null;
}

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
    widget.focusNode.requestFocus();
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
        onSubmitted: (_) {
          widget.focusNode.requestFocus();
        },
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        controller: searchTextController,
        focusNode: widget.focusNode,
        autofocus: true,
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
      // START --- Added Code for Result Count
      if (searchResults.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'נמצאו ${searchResults.length} תוצאות',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey[700],
              ),
            ),
          ),
        ),
      // END --- Added Code for Result Count
      Expanded(
        child: Builder(builder: (context) {
          final List<_GroupedResultItem> items = [];
          String? lastAddress;
          for (final r in searchResults) {
            if (lastAddress != r.address) {
              items.add(_GroupedResultItem.header(r.address));
              lastAddress = r.address;
            }
            items.add(_GroupedResultItem.result(r));
          }

          if (items.isEmpty && searchTextController.text.isNotEmpty) {
            return const Center(child: Text('אין תוצאות'));
          }

          return ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              if (item.isHeader) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Text(
                    item.header!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                );
              } else {
                final result = item.result!;
                return ListTile(
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
              }
            },
          );
        }),
      )
    ]);
  }

  @override
  bool get wantKeepAlive => true;
}
