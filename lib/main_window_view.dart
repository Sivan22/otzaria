import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:otzaria/settings_screen.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:math';
import 'pdf_page.dart';
import 'text_book_view.dart';
import 'search.dart';
import 'books_browser.dart';
import 'book_search_view.dart';

class MainWindowView extends StatefulWidget {
  const MainWindowView({
    Key? key,
  }) : super(key: key);

  @override
  MainWindowViewState createState() => MainWindowViewState();
}

class MainWindowViewState extends State<MainWindowView>
    with TickerProviderStateMixin {
  
  int selectedIndex = 0;
  late List<String> tabs=[];
  Map<File, ItemScrollController> itemScrollControllers= {};
  late TabController tabController = TabController(length: tabs.length, vsync: this,initialIndex: max(0,tabs.length-1));
  final  showBooksBrowser = ValueNotifier<bool>(false);
   final  showBookSearch = ValueNotifier<bool>(false);



  @override
  void initState() {
    super.initState();    
  }


  void addTab(String path,{int index =0}) {
  
             setState(() {
      tabs.insert(0,path);
      tabController = TabController(length: tabs.length, vsync: this,);
       }
      );
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

  void closeTab() {
    setState(() {
      if (tabs.isNotEmpty) {
        itemScrollControllers.remove(tabs[tabController.index]);
        tabs.removeAt(tabController.index);
        tabController = TabController(
            length: tabs.length,
            vsync: this,
            initialIndex: max(0, tabController.index - 1));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
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
                  showBookSearch.value = false;     
                  showBooksBrowser.value = !showBooksBrowser.value;
                  case 1:
                  showBooksBrowser.value = false;
                  showBookSearch.value = ! showBookSearch.value;                  
                  case 2:
                  showBookSearch.value = false;
                  showBooksBrowser.value = false; 
                    _openSearchScreen();                  
                  case 3:
                    _openSettingsScreen();
                
                }
              });
            }),
             AnimatedSize(
              
            duration: const Duration(milliseconds: 300),
            child: ValueListenableBuilder(
              valueListenable: showBooksBrowser,
              builder: (context, showBooksBrowser, child) => SizedBox(
                width: showBooksBrowser ? 300 : 0,
                child: child!,
              ),
              child: BooksBrowser(
                openFileCallback: addTab),
            ),
            ),
            AnimatedSize(
              
            duration: const Duration(milliseconds: 300),
            child: ValueListenableBuilder(
              valueListenable: showBookSearch,
              builder: (context, showBookSearch, child) => SizedBox(
                width: showBookSearch ? 300 : 0,
                child: child!,
              ),
              child: BookSearchScreen(
                openFileCallback: addTab),
            ),
            ),

    Expanded(
      child:
      GestureDetector(
      
        onTap: () {
          showBooksBrowser.value = false;
          showBookSearch.value = false;
          },

        child: Scaffold(
          appBar: TabBar(
              controller: tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.center,      
              tabs: tabs.map((e)=>
                e.isEmpty
                ?
                 Tab(text: "חיפוש")
              :
               Tab(text:e.split('\\').last)
              ).toList(),),
 
        
          body: Row(children: [          
            Expanded(
              child: TabBarView(
                 controller: tabController,
                
                  children:
                 tabs.map((path) {
                  if(path.isEmpty){
                    return TextFileSearchScreen(addTab,closeTab);

                  }
                    else if (path.endsWith('.pdf')) {           
                    return myPdfPage(file: File(path),closelastTab: closeTab,);
                   } else {
                     File file = File(path);
                    itemScrollControllers[file] = ItemScrollController();
                     return TextBookViewer(
                       closelastTab: closeTab, 
                       file: file,
                     scrollController: itemScrollControllers[file]!,
                       initalIndex: 0,                  );
                  }
               }).toList()
                  ),
            ),
          ]),
        ),
      ),
    )]);
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

  addTab('');

}
          }

class TabWindow {
  final String title;

  TabWindow(
    this.title
  );
}

class BookTabWindow extends TabWindow {
final String path;
int scrollIndex;
final ItemScrollController scrollController = ItemScrollController();

  BookTabWindow(
    super.title,
     this.path,
     this.scrollIndex
  );
}

class SearchingTabWindow extends TabWindow {
  List<String> booksToSearch= [];
  String searchQuery='';
  List<BookTextSearchResult> searchResults=[];  
  final ItemScrollController scrollController = ItemScrollController();
  SearchingTabWindow(
    super.title,
  );
}
