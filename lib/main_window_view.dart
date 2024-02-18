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
  late List<TabWindow> tabs=[
    BookTabWindow(
       'אוצריא\\ברוכים הבאים.pdf',
       0
    )
  ];
  late TabController tabController = TabController(
    length: tabs.length, 
    vsync: this,
    initialIndex: max(0,tabs.length-1));
  final  showBooksBrowser = ValueNotifier<bool>(false);
  final  showBookSearch = ValueNotifier<bool>(false);
  final focusNode = FocusNode();

  void addTab(TabWindow tab) {  
             setState(() {
      int newIndex = tabController.length == 0?  0: tabController.index+1;
      tabs.insert(newIndex,tab);
      tabController = TabController(length: 
      tabs.length,
       vsync: this);
      tabController.index =newIndex;
    });
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
      SizedBox.fromSize(
        size: const Size.fromWidth(100),
        child: NavigationRail(
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
      ),
      AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: ValueListenableBuilder(
            valueListenable: showBooksBrowser,
            builder: (context, showBooksBrowser, child) =>
            SizedBox(
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
              e is SearchingTabWindow
              ?
              Tab(text:'${e.title}:  ${e._searchController.text}')
              :
               Tab(text:e.title)).toList(),),
 
        
          body: Row(children: [          
            Expanded(
              child: TabBarView(
                 controller: tabController,
                
                  children:
                 tabs.map((tab) {
                  if(tab is BookTabWindow){
                      if (tab.path.endsWith('.pdf')){

                          return myPdfPage(file: File(tab.path),closelastTab: closeTab,);
                    }
                      else{
                          return TextBookViewer(
                       closelastTab: closeTab, 
                       file: File(tab.path),
                     scrollController: tab.scrollController,
                       initalIndex: tab.scrollIndex,                  );
                    }}
                    if (tab is SearchingTabWindow){
                    return TextFileSearchScreen(
                      addTab,
                    closeTab,
                    tab.searchResults,
                    tab._searchController,
                    tab.booksToSearch,
                    tab.searchStarted,
                    tab.searchFinished
                    );
                    }
                    return SizedBox.shrink();
                  }
              ).toList()
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

  addTab(
    SearchingTabWindow(
      'חיפוש'
    )
  );

}
          }

class TabWindow {
   String title;

  TabWindow(
    this.title
  );
}

class BookTabWindow extends TabWindow {
final String path;
int scrollIndex;
ItemScrollController scrollController = ItemScrollController();

  BookTabWindow(
     this.path,
     this.scrollIndex
  ):super(path.split('\\').last);
  }

class SearchingTabWindow extends TabWindow {
  List<String> booksToSearch= [];
  TextEditingController _searchController = TextEditingController();
  ValueNotifier<List<BookTextSearchResult>> searchResults= ValueNotifier([]);  
  final ItemScrollController scrollController = ItemScrollController();
  DateTime? searchStarted;
  DateTime? searchFinished;
  
  SearchingTabWindow(
    super.title,
  );
}
