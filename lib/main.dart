import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'custom_node.dart';

void main() {
  runApp(FileExplorerApp());
}

class FileExplorerApp extends StatelessWidget {
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
      locale: const Locale("he", "IL"), // OR Locale('ar', 'AE') OR Other RTL locales,
      title: 'אוצריא',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DirectoryBrowser(directory: Directory('./אוצריא')),
    );
  }
}

class DirectoryBrowser extends StatefulWidget {
  final Directory directory;

  const DirectoryBrowser({Key? key, required this.directory}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('אוצריא'),
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
                    title: Text(entity.path.split('/').last),
                    leading: entity is Directory
                        ? Icon(Icons.my_library_books)
                        : Icon(Icons.book),
                    onTap: () {
                      if (entity is Directory) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              DirectoryBrowser(directory: entity),
                        ));
                      } else if (entity is File) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => BookViewer(file: entity),
                        ));
                      }
                    },
                  );
                },
              );
            }
          }

          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class BookViewer extends StatelessWidget {
  final File file;
  final tocController = TocController();
  Widget buildTocWidget() => TocWidget(controller: tocController);
  Widget buildMarkdown() => MarkdownWidget(
      data: file.readAsStringSync(),
      tocController: tocController,
      markdownGenerator: MarkdownGenerator(      
      textGenerator: (node, config, visitor) =>
      CustomTextNode(node.textContent, config, visitor)
      )
      );

  BookViewer({Key? key, required this.file}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('${file.path.split('/').last}'),
        ),
        body: Row(
          children: <Widget>[
            Expanded(child: buildTocWidget()),
            Expanded( flex: 3,child: buildMarkdown(),)
          ],
        ));
  }
}
