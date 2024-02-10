import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'dart:math';




class MarkdownSearchView extends StatefulWidget {
final String data;
ScrollController scrollControler;
  
   MarkdownSearchView({
    Key? key,required this.data, required this.scrollControler,
  }) : super(key: key);

  @override
  _MarkdownSearchViewState createState() => _MarkdownSearchViewState();
}

class _MarkdownSearchViewState extends State<MarkdownSearchView> {
  final focusNode = FocusNode();
  final searchTextController = TextEditingController();
  late final MarkdownSearcher markdownTextSearcher;
    List<TextSearchResult> searchResults = [];
    late ScrollController scrollControler; 

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
        Text('...זהירות כאן בונים'),CircularProgressIndicator(),
        TextField(
          focusNode: focusNode,
          controller: searchTextController,
          decoration: InputDecoration(
            hintText: 'חפש כאן..',
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_upward),
                  onPressed: () {
                    // Insert logic to navigate to the previous search result
                  },
                ),
                IconButton(
                  icon: Icon(Icons.arrow_downward),
                  onPressed: () {
                    // Insert logic to navigate to the next search result
                  },
                ),
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
                      title: Text(result.snippet),
                      // onTap: () {
                      //   final position = result.index/200;
                      //     widget.scrollControler.animateTo( position,
                      //  duration: Duration(milliseconds: 500),
                      //    curve: Curves.ease,
                              //   );
                              //  }
                ));
                }
                }
                    )
                 ))]);}
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
    List<TextSearchResult> results = [];
    int index = data.indexOf(query);
    while (index != -1) {
      results.add(TextSearchResult(
        snippet: data.substring(max(0,index-30), min(data.length-1, index + query.length + 30)),
        index: index,
      ));
      index = data.indexOf(query, index + query.length);
    }
    return results;
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

  TextSearchResult({
    required this.snippet,
    required this.index,
  });
}
