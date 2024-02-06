import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import  'dart:io';
import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'custom_node.dart';
import 'main.dart';
import 'dart:math';

class MarkdownTabView extends StatefulWidget {
  

   const MarkdownTabView({Key? key,})
      : super(key: key);

  @override
  MarkdownTabViewState createState() => MarkdownTabViewState();
}

class MarkdownTabViewState extends State<MarkdownTabView> with TickerProviderStateMixin{
  int selectedIndex = 0;
  List<File> openedFiles = [];
  late TabController tabController;
    

  @override
  void initState() {
    super.initState(); 
     tabController = TabController(length: openedFiles.length, vsync:this);
     
  }

  
  void enlargeText() {
    setState(() {
      Settings.setValue<double>( 'key-font-size',min(Settings.getValue<double>('key-font-size')!+3,50.0));
      
    });

  }

    void enSmallText() {
    setState(() {
      Settings.setValue<double>( 'key-font-size',max(Settings.getValue<double>('key-font-size')!-3,15.0));
      
    });

  }

  void closelastTab() {
    setState(() {
      if (openedFiles.isNotEmpty) {
        openedFiles.removeAt(tabController.index);
        
        tabController = TabController(length: openedFiles.length, vsync:this,initialIndex: max(0,tabController.index-1));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
          appBar: AppBar(
            title: const Center(child: Text('אוצריא')),
            actions: [
              
              IconButton(
                icon: const Icon(
                  Icons.font_download_outlined,
                  
                ),
                tooltip: 'הגדל טקסט',
                onPressed: enlargeText,
              ),
                           IconButton(
                icon: const Icon(
                  Icons.font_download_off_outlined,
                  
                ),
                tooltip: 'הקטן טקסט',
                onPressed: enSmallText,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'סגור ספר פתוח',
                onPressed: closelastTab,
              ),
            ],
            bottom: TabBar(
              controller: tabController,
              tabs: openedFiles
                  .map((file) => Tab(text: file.path.split('\\').last))
                  .toList(),
            ),
          ),
          body: Row(children: [
            NavigationRail(
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.library_books),
                    label: Text('ספריה'),                    
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.search),
                    label: Text('חיפוש'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings),
                    label: Text('הגדרות'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (int index) {
                  setState(() {
                    selectedIndex = index;
                    switch (index) {
                      case 0:
                        _openSelectedFile('browser');
                      case 1:
                        _openSelectedFile('search');
                      case 2:
                        Navigator.pushNamed(context, '/settings');
                    }
                  });
                }),
            Expanded(
              child: TabBarView(
                  controller: tabController,
                  children: openedFiles.map((file) {
                return BookViewer(                  
                  file: file,
                );
              }).toList()),
            ),
          ]),
        );
  }

  void _openSelectedFile(String how) async {
    File? selectedFile;

    if (how == 'browser') {
      selectedFile = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => DirectoryBrowser(
                  directory: Directory('./אוצריא'),
                )),
      );
    } else if (how == 'search') {
      selectedFile = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BookSearchScreen()),
      );
    }
    if (selectedFile != null) {
      setState(() {
     openedFiles.add(selectedFile!);        
     tabController = TabController(length: openedFiles.length, vsync:this,initialIndex: openedFiles.length-1);
      });
    }
  }
}


class BookViewer extends StatefulWidget {
  final File file;
  late Future<String> data;

  BookViewer({Key? key, required this.file}) : super(key: key) {
    data = file.readAsString();
  }

  @override
  State<BookViewer> createState() => _BookViewerState();
}

class _BookViewerState extends State<BookViewer>  with AutomaticKeepAliveClientMixin<BookViewer> {
  //use value notifier

  ValueNotifier textFontSize = ValueNotifier(Settings.getValue('key-font-size'));


@override
  void initState() {  
    super.initState();
  }
  final tocController = TocController();

  Widget buildTocWidget() => TocWidget(controller: tocController);

  Widget buildMarkdown() => FutureBuilder(
      future: widget.data.then((value) => value),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.hasData) {
            return ValueListenableBuilder(
              key:  PageStorageKey<String>(widget.key.toString()),
              valueListenable: textFontSize,
              builder: (context, value, child) => 
              MarkdownWidget(
                padding: const EdgeInsets.all(50),
                data: snapshot.data!,
                tocController: tocController,
                config: MarkdownConfig(configs: [
                  PConfig(
                      textStyle: TextStyle(
                          fontSize: Settings.getValue('key-font-size'),
                          fontFamily: Settings.getValue('key-font-family'),

                          )),
                  H1Config(
                    style: TextStyle(
                          fontSize: Settings.getValue('key-font-size')+10,
                          fontFamily: Settings.getValue('key-font-family'),
                          fontWeight: FontWeight.bold,

                          )),
                  H2Config(
                    style: TextStyle(
                          fontSize: Settings.getValue('key-font-size')+5,
                          fontFamily: Settings.getValue('key-font-family'),
                          fontWeight: FontWeight.bold,

                          )),
                  H3Config(
                    style: TextStyle(
                          fontSize: Settings.getValue('key-font-size')+5,
                          fontFamily: Settings.getValue('key-font-family'),
                          fontWeight: FontWeight.bold,
                          )

                  ),
                    H4Config(
                    style: TextStyle(
                          fontSize: Settings.getValue('key-font-size'),
                          fontFamily: Settings.getValue('key-font-family'),
                          fontWeight: FontWeight.bold,

                          ),
                  ),
                    H5Config(
                    style: TextStyle(
                          fontSize: Settings.getValue('key-font-size')-5,
                          fontFamily: Settings.getValue('key-font-family'),
                          fontWeight: FontWeight.bold,

                          ),
                        ),
              ]),
                markdownGenerator: MarkdownGenerator(
                    textGenerator: (node, config, visitor) =>
                        CustomTextNode(node.textContent, config, visitor))));
          }
        }
        return const Center(child: CircularProgressIndicator(         
        ));
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(child: buildTocWidget()),
      appBar: AppBar(
        actions: [],
        title: Text('${widget.file.path.split('\\').last}'),
      ),
      body: buildMarkdown(),
    );
  }
    @override
  bool get wantKeepAlive => true;
}
