import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:otzaria/outline_view.dart';
import 'package:otzaria/settings_screen.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'custom_node.dart';
import 'main.dart';
import 'dart:math';
import 'package:pdfrx/pdfrx.dart';
import 'pdf_page.dart';


class booksTabView extends StatefulWidget {
  const booksTabView({
    Key? key,
  }) : super(key: key);

  @override
  booksTabViewState createState() => booksTabViewState();
}



class booksTabViewState extends State<booksTabView>
    with TickerProviderStateMixin {
  int selectedIndex = 0;
  List<File> openedFiles = [File('אוצריא\\ברוכים הבאים.pdf')];
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: openedFiles.length, vsync: this);
  }

  void enlargeText() {
    setState(() {
      Settings.setValue<double>('key-font-size',
          min(Settings.getValue<double>('key-font-size')! + 3, 50.0));
    });
  }

  void enSmallText() {
    setState(() {
      Settings.setValue<double>('key-font-size',
          max(Settings.getValue<double>('key-font-size')! - 3, 15.0));
    });
  }

  void closelastTab() {
    setState(() {
      if (openedFiles.isNotEmpty) {
        openedFiles.removeAt(tabController.index);
        tabController = TabController(
            length: openedFiles.length,
            vsync: this,
            initialIndex: max(0, tabController.index - 1));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabBar(
          controller: tabController,
          tabs: openedFiles
              .map((file) => Tab(text: file.path.split('\\').last))
              .toList(),
        ),
      
      body: Row(children: [
        NavigationRail(
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.folder),
                label: Text('דפדוף'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.search),
                label: Text('איתור ספר'),
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
                  _openSettingsScreen();
                
                }
              });
            }),
        Expanded(
          child: TabBarView(
              
              controller: tabController,
              children: openedFiles.map((file) {
                if (file.path.endsWith('.pdf')) {

                  return myPdfPage(file: file,closelastTab: closelastTab,);
                } else {
                  return mdBookViewer(closelastTab: closelastTab,
                    file: file,
                  );
                }
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
        tabController = TabController(
            length: openedFiles.length,
            vsync: this,
            initialIndex: openedFiles.length - 1);
      });
    }
  }
  void _openSettingsScreen() async {
  await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => mySettingsScreen(
                )));
                setState(() {
                  
                });
}
}




class mdBookViewer extends StatefulWidget {
  final File file;
  late Future<String> data;
  late void Function() closelastTab;

  mdBookViewer({Key? key, required this.file,  required this.closelastTab  }) : super(key: key) {
    data = file.readAsString();
  }

  @override
  State<mdBookViewer> createState() => _mdBookViewerState();
}

class _mdBookViewerState extends State<mdBookViewer>
    with AutomaticKeepAliveClientMixin<mdBookViewer> {
  final tocController = TocController();
  double textFontSize =Settings.getValue('key-font-size');

  @override
  void initState() {
    super.initState();
  }


 @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(child: TocWidget(controller: tocController)),
      appBar: AppBar(
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
        title: Text('${widget.file.path.split('\\').last}'),
      ),
      body: FutureBuilder(
      future: widget.data.then((value) => value),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.hasData) {
            return           
                MarkdownWidget( 
                  key: PageStorageKey<String>(widget.key.toString())   ,              
                    padding: const EdgeInsets.all(50),
                    data: snapshot.data!,
                    tocController: tocController,
                    config: MarkdownConfig(configs: [
                      PConfig(
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
                      

                    ]),
                    markdownGenerator: MarkdownGenerator(
                        textGenerator: (node, config, visitor) =>
                            CustomTextNode(
                                node.textContent, config, visitor)));
          }
        }
        return const Center(child: CircularProgressIndicator());
      
      })
,
    );
  }

  @override
  bool get wantKeepAlive => true;
}
