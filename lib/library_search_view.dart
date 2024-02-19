import 'package:flutter/material.dart';
import 'package:otzaria/main_window_view.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:search_highlight_text/search_highlight_text.dart';
import 'tree_view_selectable.dart';
import 'library_searcher.dart';

class TextFileSearchScreen extends StatefulWidget {
  final void Function(TabWindow) openBookCallback;
  final  void Function() closeTabCallback;
  final LibrarySearcher searcher;

  const TextFileSearchScreen(
    {super.key,
    required this.openBookCallback, 
    required this.closeTabCallback,
    required this.searcher,}
  );
   
  @override
  TextFileSearchScreenState createState() => TextFileSearchScreenState();
}

class TextFileSearchScreenState extends State<TextFileSearchScreen> with AutomaticKeepAliveClientMixin<TextFileSearchScreen> {
    final showLeftPane = ValueNotifier<bool>(true);

    @override
  void initState() {
    widget.searcher.searchResults.addListener(() {
      setState(() {
      });
    });
    super.initState();
  }

  

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
              ValueListenableBuilder(
                valueListenable: widget.searcher.isSearching,
                 builder: (context,isSearching,child) {
                  return Row(children: [              
                  Expanded(
                    child: TextField(                  
                      controller: widget.searcher.queryController,
                      onSubmitted:(e) =>widget.searcher.search(),
                      decoration: InputDecoration(
                        hintText: "הקלד את הטקסט ולחץ על סמל החיפוש",
                        suffixIcon: isSearching
                            ? Row(children: [
                              Expanded(child: Text(widget.searcher.queryController.text)),
                              IconButton(
                                icon: const Icon(Icons.cancel),
                                onPressed: () {
                                  setState(() {
                                    widget.searcher.queryController.clear();
                                    widget.searcher.searchResults.value = [];
                                    widget.searcher.isSearching.value = false;
                                  });                              
                                }
                              ),
                              const Center(child: CircularProgressIndicator())
                            ],)
                            : IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: () {
                                  widget.searcher.search();
                                },
                                
                              ),
                      ),
                    ),
                  ),
                              ]);
                }
              ),
                
              ValueListenableBuilder<List<BookTextSearchResult>>(
                valueListenable: widget.searcher.searchResults,
               builder: (context, searchResults, child) =>
               searchResults.isEmpty
               ?
               Expanded(
                 child: Column(
                   children: [
                    const Text("רשימת הספרים לחיפוש:"),
              Expanded(
                     child: FileTreeViewScreen(
                        checkedItems: widget.searcher.booksToSearch),
                   )
                   ],
                 ),
               )              
              :
              Expanded(
                child: Column(children:[   
                  widget.searcher.searchStarted != null &&
                   widget.searcher.searchFinished != null
                  ?               
                    Text('${searchResults.length} תוצאות מתוך ${widget.searcher.booksToSearch.length} ספרים בתוך ${DateTimeRange(
                    start: widget.searcher.searchStarted!,
                     end:widget.searcher.searchFinished!).duration.inSeconds} שניות')
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
                        searchText: result.query,
                        style: TextStyle(
                          fontFamily: Settings.getValue<String>('key-font-family'),
                          color: Colors.black,
                          fontSize: 20.0,),
                        textAlign: TextAlign.justify,
                          
                           ),
                        onTap: () {
                          widget.openBookCallback(
                            BookTabWindow(
                              result.path,
                              result.index,
                              searchText: result.query)
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
       @override
  get wantKeepAlive => true;
}

