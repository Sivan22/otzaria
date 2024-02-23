import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:otzaria/main_window_view.dart';

class BooksBrowser extends StatefulWidget {
  final void Function(TabWindow tab) openFileCallback;
  final String libraryPath;

  const BooksBrowser(
      {Key? key, required this.openFileCallback, required this.libraryPath})
      : super(key: key);

  @override
  BooksBrowserState createState() => BooksBrowserState();
}

class BooksBrowserState extends State<BooksBrowser> {
  late Directory directory;
  late List<FileSystemEntity> _fileList;
  late int selectedIndex;

  @override
  void initState() {
    super.initState();

    _fileList = Directory(widget.libraryPath).listSync().toList();

    selectedIndex = 0;
  }

  void navigateUp() {
    if (directory.path.split(Platform.pathSeparator).last != "אוצריא") {
      setState(() {
        directory = directory.parent;
        _fileList = directory.listSync().toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('דפדוף בספרייה'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_upward),
          tooltip: 'חזרה לתיקיה הקודמת',
          onPressed: navigateUp,
        ),
      ),
      body: ListView.builder(
        itemCount: _fileList.length,
        itemBuilder: (context, index) {
          FileSystemEntity entity = _fileList[index];
          return ListTile(
            title: Text(entity.path.split(Platform.pathSeparator).last),
            leading: entity is Directory
                ? const Icon(Icons.folder)
                : const Icon(Icons.library_books),
            onTap: () {
              if (entity is Directory) {
                setState(() {
                  //_fileList = Directory(entity.path).list().toList();
                  directory = entity;
                  _fileList = Directory(entity.path).listSync().toList();
                });
              } else if (entity is File) {
                widget.openFileCallback(BookTabWindow(entity.path, 0));
              }
            },
          );
        },
      ),
    );
  }
}
