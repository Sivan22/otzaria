import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'dart:math';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:search_highlight_text/search_highlight_text.dart';
import "package:flutter_html/flutter_html.dart";
import 'toc_viewer.dart';
import 'package:html/parser.dart';




class MarkdownSearchView extends StatefulWidget {
final String data;
ItemScrollController scrollControler;
ValueNotifier searchQuery;
  
   MarkdownSearchView({
    Key? key,required this.data, required this.scrollControler,required this.searchQuery
  }) : super(key: key);

  @override
  _MarkdownSearchViewState createState() => _MarkdownSearchViewState();
}

class _MarkdownSearchViewState extends State<MarkdownSearchView> with AutomaticKeepAliveClientMixin<MarkdownSearchView> {
  final focusNode = FocusNode();
  final searchTextController = TextEditingController();
  late final MarkdownSearcher markdownTextSearcher;
    List<TextSearchResult> searchResults = [];
    late ItemScrollController scrollControler; 

  @override
  void initState() {
    super.initState();
     markdownTextSearcher = MarkdownSearcher(widget.data);
    markdownTextSearcher.addListener(_searchResultUpdated);
    searchTextController.addListener(_searchTextUpdated);
   scrollControler = widget.scrollControler;
  }

  @override
  void dispose() {
    focusNode.dispose();
    searchTextController.dispose();
    searchTextController.removeListener(_searchTextUpdated);
    markdownTextSearcher.removeListener(_searchResultUpdated);
    super.dispose();
  }

  void _searchTextUpdated() {
    markdownTextSearcher.startTextSearch(searchTextController.text);
    widget.searchQuery.value = searchTextController.text;

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
    return Column(
      children: <Widget>[
        TextField(
          focusNode: focusNode,
          controller: searchTextController,
          decoration: InputDecoration(
            hintText: 'חפש כאן..',
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    searchTextController.clear();
                    focusNode.requestFocus();
                  },
                ),
              ],
            ),
  
          ),
        ),
        
           Expanded(
             child: SizedBox.fromSize(
              size: Size.fromHeight(300),
               child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  if (searchResults!.length > 0){
                  final result = searchResults[index];
                  return Expanded(
                    child: ListTile(
                      subtitle: SearchHighlightText(
                        result.snippet,
                        searchText: result.query),
                       onTap: () {                         
                           widget.scrollControler.scrollTo( 
                            index: result.index,
                        duration: Duration(milliseconds: 250),
                         curve: Curves.ease,
                                 );
                                }
                ));
                }
                }
                    )
                 ))]);}
                   bool get wantKeepAlive => true;
                }

class MarkdownSearcher {
  final String _markdownData;
  final List<TextSearchResult> searchResults = [];
  int searchSession = 0;
  bool isSearching = false;
  double searchProgress = 0.0;

  MarkdownSearcher(this._markdownData);

  void startTextSearch(String query) {
    if (query.isEmpty) {
      searchResults.clear();
      isSearching = false;
      searchProgress = 0.0;
      searchSession++;
      //notifyListeners();
      
      return;
    }

    isSearching = true;
    searchProgress = 0.0; // Reset progress for new search

    // Perform search asynchronously to avoid blocking the main thread
    Future(() {
      searchResults.clear();
      var matches = _findAllMatches(_markdownData, query);
      searchResults.addAll(matches);

      // Update search session and mark search as complete
      searchSession++;
      isSearching = false;
      searchProgress = 1.0;
      notifyListeners();
      
    });
  }

  List<TextSearchResult> _findAllMatches(String data, String query) {
    List<String> sections = removeVolwels(stripHtmlIfNeeded(data)).split('\n');
    List<TextSearchResult> results = [];
    String address = '';
    for (int section_index =0;section_index<sections.length;section_index++){

      int index = sections[section_index].indexOf(query);
      if (index>=0){ // if there is a match
      results.add(TextSearchResult(
        snippet: sections[section_index].substring(max(0,index-40), min(sections[section_index].length-1, index + query.length + 40)),
        index: section_index,
        query: query
 
      ));};

    } {   
    return results;
  }
  }
   final List<VoidCallback> _listeners = [];

  void notifyListeners() {   
    for (final listener in _listeners) {
      listener();
    }
  }
 void addListener(VoidCallback listener) {
   _listeners.add(listener);
 }

 void removeListener(VoidCallback listener) {
   _listeners.remove(listener);
 }
 
}

class TextSearchResult {
  final String snippet;
  final int index;
  final String query;


  TextSearchResult({
    required this.snippet,
    required this.index,
    required this.query,
    

  });
  
}

 String stripHtmlIfNeeded(String text) {
  return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
}
 String removeVolwels(String s) {        
   return s.replaceAll(RegExp(r'[\u0591-\u05C7]'), '');
 }