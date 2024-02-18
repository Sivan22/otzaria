import 'package:flutter/material.dart';
import 'package:otzaria/main_window_view.dart';
import 'dart:io';
import 'text_book_search_view.dart';
import 'dart:math';
import 'package:search_highlight_text/search_highlight_text.dart';
import 'tree_view_selectable.dart';

class TextFileSearchScreen extends StatefulWidget {
  void Function(TabWindow) openBookCallback;
  void Function() closeTabCallback;  
  ValueNotifier<List<BookTextSearchResult>> searchResults;
  final TextEditingController queryController;  
  List<String> booksToSearch= [];
  DateTime? searchStarted;
  DateTime? searchFinished;

  TextFileSearchScreen(
    this.openBookCallback, 
    this.closeTabCallback,
    this.searchResults,   
    this.queryController,
    this.booksToSearch,
    this.searchStarted,
    this.searchFinished
  );
   
  _TextFileSearchScreenState createState() => _TextFileSearchScreenState();
}

class _TextFileSearchScreenState extends State<TextFileSearchScreen> with AutomaticKeepAliveClientMixin<TextFileSearchScreen> {
  
  bool _isSearching = false;
  final showLeftPane = ValueNotifier<bool>(true);

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(       
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'סגור חיפוש',
            onPressed: widget.closeTabCallback,
          ),
        ],
      ),
      body: Column(
            children: [
              Row(children: [              
              Expanded(
                child: TextField(                  
                  controller: widget.queryController,
                  onSubmitted:(e) =>_search(),
                  decoration: InputDecoration(
                    hintText: "הקלד את הטקסט ולחץ על סמל החיפוש",
                    suffixIcon: _isSearching
                        ? Row(children: [
                          Expanded(child: Text(widget.queryController.text)),
                          IconButton(
                            icon: Icon(Icons.cancel),
                            onPressed: () {
                              setState(() {
                                widget.queryController.clear();
                                widget.searchResults.value = [];
                                _isSearching = false;
                              });                              
                            }
                          ),
                          const Center(child: CircularProgressIndicator())
                        ],)
                        : IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              _search();
                            },
                            
                          ),
                  ),
                ),
              ),
            ]),
                
              ValueListenableBuilder<List<BookTextSearchResult>>(
                valueListenable: widget.searchResults,
               builder: (context, searchResults, child) =>
               searchResults.isEmpty
               ?
               Expanded(
                 child: Column(
                   children: [
                    Text("רשימת הספרים לחיפוש:"),
              Expanded(
                     child: FileTreeViewScreen(
                        checkedItems: widget.booksToSearch),
                   )
                   ],
                 ),
               )              
              :
              Expanded(
                child: Column(children:[   
                  widget.searchStarted != null && widget.searchFinished != null
                  ?               
                    Text('${searchResults.length} תוצאות תוך ${DateTimeRange(
                    start: widget.searchStarted!,
                     end:widget.searchFinished!).duration.inSeconds} שניות')
                  :
                  const SizedBox.shrink(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                    final result = searchResults[index];
                     return ListTile(
                      title: Text(result.address,
                      style:const TextStyle(fontWeight: FontWeight.bold ),) ,
                      subtitle: SearchHighlightText(
                        result.snippet,
                        searchText: result.query),
                        onTap: () {
                          widget.openBookCallback(
                            BookTabWindow(
                              result.path,
                              result.index,)
                          );}
                    );
                  }
                ),
              ),
            ],),
          )
        )]
      ),
    );     
  }

  void _search() async {
    setState(() {
      showLeftPane.value = false;
      _isSearching = true;
      widget.searchResults.value = [];
      widget.searchStarted = DateTime.now();
          });


          for (final entry in widget.booksToSearch) {
        if (FileSystemEntity.isFileSync(entry) && ! entry.endsWith('.pdf')) {
          final file = File(entry);
          int sectionIndex = 0;
          final contents = await file.readAsString();
          List<String> address = [];
 
          for (String line in contents.split('\n')) {
            
      // get the address from html content
      if (line.startsWith('<h'))
      {
        if (address.isNotEmpty && address.any((element) => 
        element.substring(0,4) == line.substring(0,4)))
            {address.removeRange(address.indexWhere((element) =>
             element.substring(0,4) == line.substring(0,4)),address.length);}
      address.add(line);
      }
            // get results from clean text
            String section = removeVolwels(stripHtmlIfNeeded(line));
            int index = section.indexOf(widget.queryController.text);
            if (index>0){              
              widget.searchResults.value.add(BookTextSearchResult(
          path: entry,
        snippet: section.substring(max(0,index-40),
         min(section.length-1, index + widget.queryController.text.length + 40)),
        index: sectionIndex,
        query: widget.queryController.text,
        address: removeVolwels(stripHtmlIfNeeded(address.join('')))));
      
      widget.searchFinished = DateTime.now();

            if (mounted) {
              setState(() {
      });
            }
            }
            sectionIndex++;
          }
          }
          
        }
        if (mounted){
        setState(() {
          _isSearching = false;
        });}
      }
       @override
  get wantKeepAlive => true;
    } 

    class BookTextSearchResult extends TextSearchResult {
      final String path;
      BookTextSearchResult({
        required this.path,
        required String snippet,
        required int index,
        required String query,
        required String address
      }) : super(snippet: snippet, index: index, query: query, address: address);

    }
