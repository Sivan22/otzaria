import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'custom_node.dart';
import 'package:sidebarx/sidebarx.dart';

void main() {
  runApp(FileExplorerApp());
}

class FileExplorerApp extends StatelessWidget {
  const FileExplorerApp({Key? key}) : super(key: key);

  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale("he", "IL"), // OR Locale('ar', 'AE') OR Other RTL locales
      ],
      locale: const Locale(
          "he", "IL"), // OR Locale('ar', 'AE') OR Other RTL locales,
      title: 'אוצריא',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'candara',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 18.0, fontFamily: 'candara'),
        ),
      ),
      home: DirectoryBrowser(directory: Directory('./אוצריא'),openedFiles:[]),
    );
  }
}

class DirectoryBrowser extends StatefulWidget {
  final Directory directory;
  List<File> openedFiles;
  DirectoryBrowser({Key? key, required this.directory,required this.openedFiles}) : super(key: key);

  @override
  _DirectoryBrowserState createState() => _DirectoryBrowserState();
}

class _DirectoryBrowserState extends State<DirectoryBrowser> {
  late Future<List<FileSystemEntity>> _fileList;
  @override
  void initState() {
    super.initState();
    _fileList = widget.directory.list().toList();
  }

openHomePage(){
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => DirectoryBrowser(directory: widget.directory,openedFiles: widget.openedFiles,)),    
  );
}
//open the search page
openSearchPage(){
  Navigator.push(
    context,MaterialPageRoute(builder: (context)=> BookSearchScreen(openedFiles: widget.openedFiles,),)
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('אוצריא'),
      ),
      body:Row(
        children: [
          SidebarX(
            controller: SidebarXController(selectedIndex: 0),
            items:  [
              SidebarXItem(icon: Icons.library_books, label: 'Home',onTap: openHomePage),
              SidebarXItem(icon: Icons.search, label: 'Search', onTap: openSearchPage),
            ],
          ),
           Expanded(
             child: FutureBuilder<List<FileSystemEntity>>(
                     future: _fileList,
                     builder: (context, snapshot) {
                       if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
             
              if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    FileSystemEntity entity = snapshot.data![index];
                    return ListTile(
                      title: Text(entity.path.split('/').last),
                      leading: entity is Directory
                          ? const Icon(Icons.my_library_books)
                          : const Icon(Icons.book),
                      onTap: () {
                        if (entity is Directory) {
                          
                             Navigator.of(context).push(MaterialPageRoute(
                               builder: (context) =>
                                   DirectoryBrowser(directory: entity,openedFiles:widget.openedFiles),
                           ));
                        } else if (entity is File) {
                          widget.openedFiles.insert(0,entity);
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                MarkdownTabView(markdownFiles: widget.openedFiles),
                          ));
                        }
                      },
                    );
                  },
                );
              }
                       }
             
                       return const Center(child: CircularProgressIndicator());
                     },
                   ),
           ),
    ]));
  }
}

class BookSearchScreen extends StatefulWidget {
  List<File> openedFiles;

  BookSearchScreen({Key? key,required this.openedFiles}) : super(key: key);

  @override
  _BookSearchScreenState createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  TextEditingController _searchController = TextEditingController();  
  // get all files from the directory "אוצריא"
  final List<File> books = Directory('./אוצריא').listSync(recursive: true).whereType<File>().toList();
  List<File> _searchResults = [];

  void _searchBooks(String query) {
    final results = books.where((book) {
      final bookName = book.path.split('\\').last.toLowerCase();
       // if all the words seperated by spaces exist in the book name, even not in order, return true

       

      final searchLower = query.toLowerCase();
      return bookName.contains(searchLower);
    }).toList();
    setState(() {
      _searchResults = results;
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _searchBooks(_searchController.text);

    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('חיפוש ספר'),
      ),
      body:  Center(
        child: Padding(
              padding: const EdgeInsets.all(80),
          child: Column(
          children: [TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'הקלד שם ספר: ',
                  suffixIcon: Icon(Icons.search),
                ),
                onChanged: _searchBooks,
              ),
            
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final book = _searchResults[index];
                  return ListTile(
                    title: Text(book.path.split('/').last),
                    onTap: () {
                          widget.openedFiles.insert(0,book);
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                                  MarkdownTabView(markdownFiles: widget.openedFiles),
                      ));
                    },
                  );
                },
              ),
            ),
          ],
        ),
            ),
      ));
  }
}

class MarkdownTabView extends StatefulWidget {
  final List<File> markdownFiles;

  const MarkdownTabView({Key? key, required this.markdownFiles})
      : super(key: key);

  @override
  _MarkdownTabViewState createState() => _MarkdownTabViewState();
}

class _MarkdownTabViewState extends State<MarkdownTabView>
    with SingleTickerProviderStateMixin {

  void closeAllTabs() {
    setState(() {
       widget.markdownFiles.removeAt(widget.markdownFiles.length-1); 
   
          });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: widget.markdownFiles.length,
      child: Scaffold(
            appBar: AppBar(            
              actions: [
                IconButton(icon: Icon(Icons.close), onPressed: closeAllTabs,)
              ],
              bottom: TabBar(
                tabs: widget.markdownFiles
                    .map((file) => Tab(text: file.path.split('/').last))
                    .toList(),
              ),
            ),
            body: TabBarView(       
              children: widget.markdownFiles.map((file) {
                return BookViewer(file: file,
                );
              }).toList(),
            ),
          ),
    );
  }
}

class BookViewer extends StatelessWidget {
  final File file;
  final tocController = TocController();
  Widget buildTocWidget() => TocWidget(controller: tocController);
  Widget buildMarkdown() => MarkdownWidget(
    padding: const EdgeInsets.all(50),
      data: file.readAsStringSync(),
      tocController: tocController,
      markdownGenerator: MarkdownGenerator(
          textGenerator: (node, config, visitor) =>
              CustomTextNode(node.textContent, config, visitor)));

  BookViewer({Key? key, required this.file}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(child: buildTocWidget()),
        appBar: AppBar(
          title: Text('${file.path.split('/').last}'),          
        ),
        body: buildMarkdown(),
            
          
          
        );
  }
}
