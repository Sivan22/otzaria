import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:otzaria/model/books.dart';
import 'dart:isolate';
import 'dart:io';
import 'package:otzaria/model/links.dart';

class CommentaryContent extends StatefulWidget {
  const CommentaryContent({
    super.key,
    required this.smallindex,
    required this.thisLinks,
    required this.fontSize,
    required this.openBookCallback,
  });
  final List<Link> thisLinks;
  final int smallindex;
  final double fontSize;
  final Function(TextBookTab) openBookCallback;

  @override
  State<CommentaryContent> createState() => _CommentaryContentState();
}

class _CommentaryContentState extends State<CommentaryContent>
    with AutomaticKeepAliveClientMixin<CommentaryContent> {
  late Future<String> content;

  @override
  void initState() {
    content = getContent(
        Settings.getValue<String>('key-library-path') ?? './',
        widget.thisLinks[widget.smallindex].path2,
        widget.thisLinks[widget.smallindex].index2);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
        future: content,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return GestureDetector(
              onDoubleTap: () {
                String path =
                    (Settings.getValue<String>('key-library-path') ?? './') +
                        Platform.pathSeparator +
                        widget.thisLinks[widget.smallindex].path2
                            .replaceAll('\\', Platform.pathSeparator);
                widget.openBookCallback(TextBookTab(
                  path,
                  widget.thisLinks[widget.smallindex].index2 - 1,
                ));
              },
              child: Html(data: snapshot.data, style: {
                'body': Style(
                    fontSize: FontSize(widget.fontSize / 1.2),
                    fontFamily:
                        Settings.getValue('key-font-family') ?? 'candara',
                    textAlign: TextAlign.justify),
              }),
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        });
  }

  @override
  bool get wantKeepAlive => true;
}

Future<String> getContent(
    String libraryRootPath, String path, int index) async {
  path = libraryRootPath +
      Platform.pathSeparator +
      path.replaceAll('\\', Platform.pathSeparator);
  return Isolate.run(() async {
    List<String> lines = await File(path).readAsLines();
    String line = lines[index - 1];
    return line;
  });
}
