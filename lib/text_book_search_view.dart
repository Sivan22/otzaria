import 'package:flutter/material.dart';
import 'dart:math';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:search_highlight_text/search_highlight_text.dart';



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
  late final textBookSearcher markdownTextSearcher;
    List<TextSearchResult> searchResults = [];
    late ItemScrollController scrollControler; 

  @override
  void initState() {
    super.initState();
     markdownTextSearcher = textBookSearcher(widget.data);
    markdownTextSearcher.addListener(_searchResultUpdated);
    searchTextController.addListener(_searchTextUpdated);
    searchTextController.text = widget.searchQuery.value;
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
    widget.searchQuery.value = searchTextController.text;
    markdownTextSearcher.startTextSearch(widget.searchQuery.value);
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
                    focusNode.requestFocus();
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
                if (searchResults.isNotEmpty){
                final result = searchResults[index];
                return ListTile(
                  title: Text(result.address,
                  style:const TextStyle(fontWeight: FontWeight.bold ),) ,
                  subtitle: SearchHighlightText(
                    result.snippet,
                    searchText: result.query),
                   onTap: () {                         
                       widget.scrollControler.scrollTo( 
                        index: result.index,
                    duration: const Duration(milliseconds: 250),
                     curve: Curves.ease,
                             );
                            }
                                );
              }
              }
                  )
               )]);}
               @override
                bool get wantKeepAlive => true;
                }

class textBookSearcher {
  final String _markdownData;
  final List<TextSearchResult> searchResults = [];
  int searchSession = 0;
  bool isSearching = false;
  double searchProgress = 0.0;

  textBookSearcher(this._markdownData);

  void startTextSearch(String query) {
    if (query.isEmpty) {
      searchResults.clear();
      isSearching = false;
      searchProgress = 0.0;
      searchSession++;
      notifyListeners();      
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
    List<String> sections = data.split('\n');
    List<TextSearchResult> results = [];
    List<String> address = [];
    for (int section_index =0;section_index<sections.length;section_index++){
    // get the address from html content
      if (sections[section_index].startsWith('<h'))
      {
        if (address.isNotEmpty && address.any((element) => element.substring(0,4) == sections[section_index].substring(0,4)))
            {address.removeRange(address.indexWhere((element) => element.substring(0,4) == sections[section_index].substring(0,4)),address.length);}
      address.add(sections[section_index]);
      
      }
      // get results from clean text
      String section = removeVolwels(stripHtmlIfNeeded(sections[section_index]));
        
      int index = section.indexOf(query);
      if (index>=0){ // if there is a match
      results.add(TextSearchResult(
        snippet: section.substring(max(0,index-40),
         min(section.length-1, index + query.length + 40)),
        index: section_index,
        query: query,
        address: removeVolwels(stripHtmlIfNeeded(address.join('')))
 
      ));
      }
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
  final String query;
  final String address;

  TextSearchResult({
    required this.snippet,
    required this.index,
    required this.query,  
    required this. address,
  });
  }

 String stripHtmlIfNeeded(String text) {
  return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
}
 String removeVolwels(String s) {        
   return s.replaceAll(RegExp(r'[\u0591-\u05C7]'), '');
 }