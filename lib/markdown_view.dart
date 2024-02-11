import 'package:flutter/material.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:otzaria/md_search_view.dart';
import 'dart:io';
import 'package:otzaria/toc_viewer.dart';
import 'dart:math';
import 'html_view.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';



class mdBookViewer extends StatefulWidget {
  final File file;
  late Future<String> data;
  late void Function() closelastTab;
  late ItemScrollController scrollController;

  mdBookViewer({Key? key, required this.file,  required this.closelastTab,  }) : super(key: key) {
    data = file.readAsString();
    scrollController = ItemScrollController();

  }

  @override
  State<mdBookViewer> createState() => _mdBookViewerState();
}

class _mdBookViewerState extends State<mdBookViewer>
    with AutomaticKeepAliveClientMixin<mdBookViewer> {
  double textFontSize =Settings.getValue('key-font-size');
    final showLeftPane = ValueNotifier<bool>(false);    
  ValueNotifier<String> searchQuery = ValueNotifier<String>('');
    

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading:IconButton(
          icon: const Icon(Icons.menu),
          tooltip: "ניווט וחיפוש",
          onPressed: () {
            showLeftPane.value = !showLeftPane.value;
          }),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.zoom_in,
            ),
            tooltip: 'הגדל טקסט',
            onPressed: ()=>setState(() {
              textFontSize =min(50.0, textFontSize + 3);
            })
          ),
          IconButton(
            icon: const Icon(
              Icons.zoom_out,
            ),
            tooltip: 'הקטן טקסט',
            onPressed:()=>setState(() {
              textFontSize =max(15.0, textFontSize - 3);
            }) ,
          ),
          // button to scroll all the way up
          IconButton(
            icon: const Icon(Icons.first_page),
            tooltip: 'תחילת הספר',
            onPressed: () {
              widget.scrollController.scrollTo(index: 0, duration: const Duration(milliseconds: 300));
                                 }
          // button to scroll all the way down
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            tooltip: 'סוף הספר',
            onPressed: () async{  
              widget.scrollController.scrollTo(index: await widget.data.then((value) => value.length), duration: const Duration(milliseconds: 300));
              
              }
          )
          ,
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'סגור ספר פתוח',
            onPressed: widget.closelastTab,
          ),
        ],
      ),
      body: Row(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: ValueListenableBuilder(
              valueListenable: showLeftPane,
              builder: (context, showLeftPane, child) => SizedBox(
                width: showLeftPane ? 300 : 0,
                child: child!,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(1, 0, 4, 0),
                child: DefaultTabController(
                  length: 2,
                    
                    child: Column(
                       
                      children: [
                        const TabBar(tabs: [
                          Tab(text: 'ניווט'),
                          Tab(text: 'חיפוש'),

                        ]),
                        
                          Expanded(
                            child: TabBarView(
                              children: [   
                              
                               
                                Row(
                                  children: [FutureBuilder(
                                    future: widget.data.then((value) => value),
                                    builder: (context, snapshot) =>
                                     snapshot.connectionState == ConnectionState.done ?
                                          Expanded(
                                            child:TocViewer(
                                                data: snapshot.data!,
                                                scrollController: widget.scrollController, )
                                         ): const CircularProgressIndicator()
                                                    
                                    
                                  )],
                                )
                                ,
                            
                                FutureBuilder(
                                  future: widget.data.then((value) => value),
                                  builder: (context, snapshot)=>                          
                                                              
                                  snapshot.connectionState == ConnectionState.done ?
                                      MarkdownSearchView(
                                      data: snapshot.data!,
                                      scrollControler: widget.scrollController,
                                      searchQuery:searchQuery 
                                      ):
                                                            
                                        const CircularProgressIndicator()
                                                
                                                            
                                    
                                   ),]
                                   
                              
                                                
                            ),
                          )
                          
                          ,]
                          ),
                  ),
                        ),
                        ),
                        ),
                        
                          Expanded(
                            child: FutureBuilder(
                                  future: widget.data.then((value) => value),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.done) {
                                      if (snapshot.hasError) {
                                        return Center(child: Text('Error: ${snapshot.error}'));
                                      }
                            
                                      if (snapshot.hasData) {
                                        return    
                                        ValueListenableBuilder(valueListenable:  searchQuery, 
                                        builder: (context, searchQuery, child) =>       
                                             HtmlView(
                                              key: PageStorageKey(snapshot.data!),
                                                   data: snapshot.data!.split('\n'),
                                                   scrollController: widget.scrollController,
                                                   searchQuery: searchQuery,
                                                   textSize: textFontSize
                                                  ));
                                                }}
                                                return Center(child: CircularProgressIndicator());
                                  }
                          ),
                          ),]));
                                              
                                      }



  bool get wantKeepAlive => true;
}


