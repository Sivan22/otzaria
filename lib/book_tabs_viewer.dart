import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:otzaria/settings_screen.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'main.dart';
import 'dart:math';
import 'pdf_page.dart';
import 'markdown_view.dart';
import 'package:flutter/widgets.dart';
import 'search.dart';

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
  late List<File> openedFiles=[];
  Map<File, ItemScrollController> itemScrollControllers= {};  
  // offset controlers
  Map<File, ScrollOffsetController>  scrollOffsetControllers= {};

  late TabController tabController;



  @override
  void initState() {
    super.initState();    
    File firstFile = File('אוצריא\\ברוכים הבאים.pdf');
    openedFiles.add(firstFile);
    itemScrollControllers[firstFile] = ItemScrollController();
    scrollOffsetControllers[firstFile] = ScrollOffsetController();
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
        
        scrollOffsetControllers.remove(openedFiles[tabController.index]);
        itemScrollControllers.remove(openedFiles[tabController.index]);
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
          isScrollable: true,
          tabAlignment: TabAlignment.center,      
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
                icon: Icon(Icons.library_books),
                label: Text('איתור ספר'),
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
                    _openSearchScreen();                  
                  case 3:
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
                  return mdBookViewer(
                    closelastTab: closelastTab, 
                    file: file,
                    scrollController: itemScrollControllers[file]!,
                    initalIndex: 0,                  );
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
        itemScrollControllers[selectedFile] = ItemScrollController();
        scrollOffsetControllers[selectedFile] = ScrollOffsetController();
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

void _openSearchScreen() async {
  BookTextSearchResult? result;
  result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TextFileSearchScreen()),
      );
    
    if (result != null) {
      ItemScrollController controller = ItemScrollController();
      File file = File(result.path);
      Future _scrollAfterBuild() async {
  await Future.delayed(Duration(milliseconds: 1)); // Optional delay
  itemScrollControllers[file]!.scrollTo(
    index:result!.index,
    duration: Duration(milliseconds: 250),
    curve: Curves.ease,
  );}
      setState(() {        
        openedFiles.add(file);
        itemScrollControllers[file] = controller;
        tabController = TabController(
            length: openedFiles.length,
            vsync: this,
            initialIndex: openedFiles.length - 1);
            
      }); 
       _scrollAfterBuild();
 
}

}
          }



  








