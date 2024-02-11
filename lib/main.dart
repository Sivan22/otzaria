import  'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'book_tabs_viewer.dart';
import 'settings_screen.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'cache_provider.dart';

void  main(){
   Settings.init(cacheProvider: HiveCache());
  //Settings.clearCache();
  runApp(const FileExplorerApp());
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
      routes: {
        '/search': (context) => BookSearchScreen(),
        '/browser': (context) => const DirectoryBrowser(),
        '/settings': (context) => mySettingsScreen(),
      },
      home:  const booksTabView(),
    );
  }
}



class DirectoryBrowser extends StatefulWidget {
   
   const DirectoryBrowser({
    Key? key,
  }) : super(key: key);

  @override
  DirectoryBrowserState createState() => DirectoryBrowserState();
}

class DirectoryBrowserState extends State<DirectoryBrowser> {
  late Directory directory;
  late Future<List<FileSystemEntity>> _fileList;
  late int selectedIndex;

  @override
  void initState() {
    super.initState();    
    directory = Directory('./אוצריא');
    _fileList = directory.list().toList();
    selectedIndex = 0;
  }

void navigateUp() {
  final parentDirectory = directory.parent;
  if (parentDirectory.path != "." ) {
    setState(() {
      directory = parentDirectory;
      _fileList = Directory(parentDirectory.path).list().toList();
    }); 
  }
     else {
      Navigator.pop(context);
     }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('דפדוף בספרייה'),
        leading:
        
         IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'חזרה לתיקיה הקודמת',
              onPressed: navigateUp,
            ),
        
      ),
      body: FutureBuilder<List<FileSystemEntity>>(
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
                    title: Text(entity.path.split('\\').last),
                    leading: entity is Directory
                        ? const Icon(Icons.folder)
                        : const Icon(Icons.library_books),
                    onTap: () {
                      if (entity is Directory) {
                        setState(() {
                          //_fileList = Directory(entity.path).list().toList();
                          directory = entity;
                          _fileList = Directory(entity.path).list().toList();
                        });
                      } else if (entity is File) {
                        Navigator.pop(context, entity);
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
    );
  }
}

class BookSearchScreen extends StatefulWidget {
  BookSearchScreen({
    Key? key,
  }) : super(key: key);

  @override
  _BookSearchScreenState createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  TextEditingController _searchController = TextEditingController();
  // get all files from the directory "אוצריא"
  final List<File> books = Directory('אוצריא')
      .listSync(recursive: true)
      .whereType<File>()
      .toList();
  List<File> _searchResults = [];

  void _searchBooks(String query) {
    final results = books.where((book) {
      final bookName = book.path.split('\\').last.toLowerCase();
      bool result = true;
      for (final word in query.split(' ')) {
        result = result && bookName.contains(word.toLowerCase());
      }// if all the words seperated by spaces exist in the book name, even not in order, return true
 
      return result;
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(80),
            child: Column(
              children: [
                TextField(
                  autofocus: true,
                  controller: _searchController,
                  decoration: const InputDecoration(
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
                          title: Text(book.path.split('\\').last),
                          onTap: () {
                            Navigator.of(context).pop(book);
                          });
                    },
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
