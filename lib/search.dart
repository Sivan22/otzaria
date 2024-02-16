import 'package:flutter/material.dart';
import 'dart:io';
import 'text_book_search_view.dart';
import 'dart:math';
import 'package:search_highlight_text/search_highlight_text.dart';
import 'tree_view_selectable.dart';

class TextFileSearchScreen extends StatefulWidget {
  void Function(String book,{int index}) openBookCallback;
  void Function() closeTabCallback;

  TextFileSearchScreen(
    this.openBookCallback, 
    this.closeTabCallback,   
  );
   


  _TextFileSearchScreenState createState() => _TextFileSearchScreenState();
}

class _TextFileSearchScreenState extends State<TextFileSearchScreen> with AutomaticKeepAliveClientMixin<TextFileSearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  bool _isSearching = false;
  String _searchError = "";
  ValueNotifier<List<BookTextSearchResult>> _searchResults = ValueNotifier([]);
  List<String> checkedItems= [];
  final showLeftPane = ValueNotifier<bool>(true);
  late DateTime searchStarted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        leading:IconButton(
          icon: const Icon(Icons.menu),
          tooltip: "רשימת ספרים לחיפוש",
          onPressed: () {
            showLeftPane.value = !showLeftPane.value;
          }),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'סגור חיפוש',
            onPressed: widget.closeTabCallback,
          ),
        ],
      ),
      body: Row(
        children: [AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: ValueListenableBuilder(
            valueListenable: showLeftPane,
            builder: (context, showLeftPane, child) => SizedBox(
              width: showLeftPane ? 500 : 0,
              child:  Padding(
              padding: const EdgeInsets.fromLTRB(1, 0, 4, 0),
          child: Row(
            children:[Expanded(
              child: Column(
                children: [
                  Text('רשימת ספרים לחיפוש:'),
                  Divider(),
                  Expanded(child: FileTreeViewScreen(checkedItems: checkedItems)),
                ],
              ),
            ),          
          VerticalDivider(),]
          ),
          ),

          ),
          ),),
      
          Expanded(
          child: Column(
            children: [
              Row(children: [
              
              Expanded(
                child: TextField(                  
                  controller: _queryController,
                  onSubmitted:(e) =>_search(),
                  decoration: InputDecoration(
                    hintText: "הקלד את הטקסט ולחץ על סמל החיפוש",
                    suffixIcon: _isSearching
                        ? Row(children: [
                          Expanded(child: Text(_queryController.text)),
                          IconButton(
                            icon: Icon(Icons.cancel),
                            onPressed: () {
                              setState(() {
                                _queryController.clear();
                                _isSearching = false;
                              });
                              
                            }
                          ),
                          Center(child: CircularProgressIndicator())
                        ],)
                        : IconButton(
                            icon: Icon(Icons.search),
                            onPressed: () {
                              _search();
                            },
                            
                          ),
                  ),
                ),
              ),],),
                
              ValueListenableBuilder<List<BookTextSearchResult>>(
                valueListenable: _searchResults,
               builder: (context, results, child) =>
               checkedItems.isEmpty
               ? 
               const Center(child: Text('לא נבחרו ספרים, יש לבחור ספרים לחיפוש בתפריט הצד'))
               :
              results.isNotEmpty
              ?
              Expanded(
                child: Column(children:[
                   Text('${results.length} תוצאות תוך ${DateTimeRange(
                    start: searchStarted,end: DateTime.now()).duration.inSeconds} שניות'),
                Expanded(
                    child: ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                    final result = results[index];
                     return ListTile(
                      title: Text(result.address,
                      style:const TextStyle(fontWeight: FontWeight.bold ),) ,
                      subtitle: SearchHighlightText(
                        result.snippet,
                        searchText: result.query),
                        onTap: () {
                          widget.openBookCallback(result.path,index:result.index);
                          }
                    );
                    }
                    ),
                    ),
                    ],
                    ),
              )
                  :const SizedBox.shrink()
            )]
          ),
                  ),
       
        
      ]),
     ) ;
  }

  void _search() async {
    setState(() {
      showLeftPane.value = false;
      _isSearching = true;
      _searchError = "";
      _searchResults.value = [];
      searchStarted = DateTime.now();
          });

    // Hardcoded directory path
          for (final entry in checkedItems) {
        if (FileSystemEntity.isFileSync(entry) && ! entry.endsWith('.pdf')) {
          final file = File(entry);
          int section_index = 0;
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
            int index = section.indexOf(_queryController.text);
            if (index>0){              
         _searchResults.value.add(BookTextSearchResult(
          path: entry,
        snippet: section.substring(max(0,index-40),
         min(section.length-1, index + _queryController.text.length + 40)),
        index: section_index,
        query: _queryController.text,
        address: removeVolwels(stripHtmlIfNeeded(address.join('')))));
       
            if (mounted) {
              setState(() {
      });
            }
            }
            section_index++;
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
