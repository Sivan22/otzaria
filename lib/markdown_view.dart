import 'package:flutter/material.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:otzaria/md_search_view.dart';
import 'dart:io';
import 'package:markdown_widget/markdown_widget.dart';
import 'custom_node.dart';
import 'dart:math';
import 'package:scroll_to_index/scroll_to_index.dart';





class mdBookViewer extends StatefulWidget {
  final File file;
  late Future<String> data;
  late void Function() closelastTab;
   AutoScrollController scrollController;

  mdBookViewer({Key? key, required this.file,  required this.closelastTab, required this.scrollController }) : super(key: key) {
    data = file.readAsString();
  }

  @override
  State<mdBookViewer> createState() => _mdBookViewerState();
}

class _mdBookViewerState extends State<mdBookViewer>
    with AutomaticKeepAliveClientMixin<mdBookViewer> {
  final tocController = TocController();
  double textFontSize =Settings.getValue('key-font-size');
    final showLeftPane = ValueNotifier<bool>(false);
    

  @override
  void initState() {
    super.initState();
  }


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
  
                               Container(
                                key: PageStorageKey(widget.file.path),
                                child: TocWidget(controller: tocController)
                                ),

                                FutureBuilder(
                                  future: widget.data.then((value) => value),
                                  builder: (context, snapshot)=>                          
  
                                  snapshot.connectionState == ConnectionState.done ?
                                      Expanded(
                                        child: MarkdownSearchView(
                                        data: snapshot.data!,
                                        scrollControler: widget.scrollController, ),
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
                                            Scrollbar(
                                              child: Container(
                                                padding: const EdgeInsets.all(50),                                              
                                                 child:  MarkdownWidget( 
                                                      //key: PageStorageKey<String>(widget.file.toString()),  
                                                        data: snapshot.data!,
                                                        tocController: tocController,  
                                                        config: MyMarkdownConfig(),
                                                        markdownGenerator: MarkdownGenerator(
                                                          textGenerator: (node, config, visitor) =>
                                                                    CustomTextNode( node.textContent, config, visitor))),
                                                 
                                                ),
                                            );  
                                  }}
                                  return const Expanded(child:Center(child: CircularProgressIndicator()));
                                  
                                  }
  )
                                              )]));
                                              
                                      }

 MarkdownConfig MyMarkdownConfig() {
   return MarkdownConfig(configs: [ PConfig(
                                                                            textStyle: TextStyle(
                                                                          fontSize: textFontSize,
                                                                          fontFamily: Settings.getValue('key-font-family'),                    
                                                    ),
                                                    
                                                    ),
                                                    H1Config(
                                                                            style: TextStyle(
                                                                          fontSize: textFontSize + 10,
                                                                          fontFamily: Settings.getValue('key-font-family'),
                                                                          fontWeight: FontWeight.bold,
                                                    )),
                                                    H2Config(
                                                                            style: TextStyle(
                                                                          fontSize: textFontSize + 5,
                                                                          fontFamily: Settings.getValue('key-font-family'),
                                                                          fontWeight: FontWeight.bold,
                                                    )),
                                                    H3Config(
                                                                            style: TextStyle(
                                                                          fontSize:textFontSize + 5,
                                                                          fontFamily: Settings.getValue('key-font-family'),
                                                                          fontWeight: FontWeight.bold,
                                                    )),
                                                    H4Config(
                                                                          style: TextStyle(
                                                                            fontSize: textFontSize,
                                                                            fontFamily: Settings.getValue('key-font-family'),
                                                                            fontWeight: FontWeight.bold,
                                                                          ),
                                                    ),
                                                    H5Config(
                                                                          style: TextStyle(
                                                                            fontSize: textFontSize - 5,
                                                                            fontFamily: Settings.getValue('key-font-family'),
                                                                            fontWeight: FontWeight.bold,
                                                                          ),
                                                    ),
                                                    
                                              
                                                  ]);
 }
                                      
                                    
                                    
 

  @override
  bool get wantKeepAlive => true;
}


class myMarkdownWidget extends MarkdownWidget{

  ScrollController scrollController;
  myMarkdownWidget(key, data, tocController, this.scrollController) : super(key: key, data: data, tocController: tocController);

}

class _MyMarkdownWidgetState extends State<myMarkdownWidget> {
late ScrollController scrollController;
  @override
  void initState() {
    super.initState();
    scrollController = widget.scrollController; 
    
  }

  @override
  Widget build(BuildContext context) {
    return myMarkdownWidget(widget.key, widget.data, widget.tocController, widget.scrollController);
  }
}