import 'package:flutter/material.dart';
import 'dart:io';
import 'md_search_view.dart';
import 'dart:math';
import 'package:search_highlight_text/search_highlight_text.dart';
import 'tree_view_selectable.dart';

class TextFileSearchScreen extends StatefulWidget {
   


  _TextFileSearchScreenState createState() => _TextFileSearchScreenState();
}

class _TextFileSearchScreenState extends State<TextFileSearchScreen> with AutomaticKeepAliveClientMixin<TextFileSearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  bool _isSearching = false;
  String _searchError = "";
  ValueNotifier<List<BookTextSearchResult>> _searchResults = ValueNotifier([]);
  List<String> checkedItems= [];
  final showLeftPane = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Row( children:  <Widget>[
          
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("חיפוש בכל המאגר"),
        ),
        const Padding(
          padding:  EdgeInsets.symmetric(horizontal: 16),
          child: Text ('לעת עתה החיפוש ללא אינדקס, מומלץ לחפש במספר קטן של ספרים בלבד)',
          style: TextStyle(color: Colors.grey, fontSize: 12),),
          
        )
        
        
      ]
      ),
      leading: Row( children:  <Widget>[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: IconButton(onPressed: () => Navigator.pop(context)
          , icon: const  Icon(Icons.arrow_back,),
          ),),
        ]),),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: ValueListenableBuilder(
              valueListenable: showLeftPane,
              builder: (context, showLeftPane, child) => SizedBox(
                width: showLeftPane ? 300 : 0,
                child:  Padding(
                padding: const EdgeInsets.fromLTRB(1, 0, 4, 0),
            child: FileTreeViewScreen(checkedItems: checkedItems),
            ),
            ),
            ),
            ),

            Expanded(
            child: Column(
              children: [
                Row(children: [
                  SizedBox.fromSize(
                    size: const Size(60.0, 60.0),
                    child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: IconButton(
                                icon: const Icon(Icons.menu),
                                tooltip: "רשימת הספרים לחיפוש",
                                onPressed: () {
                                  showLeftPane.value = !showLeftPane.value;
                                }),
                            ),
                  ),
                
                Expanded(
                  child: TextField(                  
                    controller: _queryController,
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
                ?Expanded(
                    child: ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                    final result = results[index];
                     return ListTile(
                      title: Text(result.address + " " + result.index.toString(),
                      style:const TextStyle(fontWeight: FontWeight.bold ),) ,
                      subtitle: SearchHighlightText(
                        result.snippet,
                        searchText: result.query),
                        onTap: () {
                        Navigator.pop(context, result);}
                    );}))
                    :const SizedBox.shrink()
              )]
            ),
          ),
         
          
        ]),
      ),
     ) ;
  }

  void _search() async {
    setState(() {
      _isSearching = true;
      _searchError = "";
      _searchResults.value = [];
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
