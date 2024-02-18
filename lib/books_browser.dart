import 'package:flutter/material.dart';
import 'dart:io';

import 'package:otzaria/main_window_view.dart';

class BooksBrowser extends StatefulWidget {
  
  void Function(TabWindow tab) openFileCallback;
   
    BooksBrowser({
    Key? key,
    required this.openFileCallback
  }) : super(key: key);

  @override
  BooksBrowserState createState() => BooksBrowserState();
}

class BooksBrowserState extends State<BooksBrowser> {
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

}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('דפדוף בספרייה'),
        leading:
        
         IconButton(
              icon: const Icon(Icons.arrow_upward),
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
                         widget.openFileCallback(
                          BookTabWindow(
                            entity.path,
                            0
                          )
                         );
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
