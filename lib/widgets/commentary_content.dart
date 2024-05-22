import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/tabs.dart';
import 'package:otzaria/models/links.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;

class CommentaryContent extends StatefulWidget {
  const CommentaryContent({
    super.key,
    required this.link,
    required this.fontSize,
    required this.openBookCallback,
    required this.removeNikud,
  });
  final bool removeNikud;
  final Link link;
  final double fontSize;
  final Function(TextBookTab) openBookCallback;

  @override
  State<CommentaryContent> createState() => _CommentaryContentState();
}

class _CommentaryContentState extends State<CommentaryContent> {
  late Future<String> content;

  @override
  void initState() {
    super.initState();
    content = widget.link.content;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        widget.openBookCallback(TextBookTab(
          book: TextBook(title: utils.getTitleFromPath(widget.link.path2)),
          index: widget.link.index2 - 1,
        ));
      },
      child: FutureBuilder(
          future: content,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              String text = snapshot.data!;
              if (widget.removeNikud) {
                text = utils.removeVolwels(text);
              }
              return Html(data: text, style: {
                'body': Style(
                    fontSize: FontSize(widget.fontSize / 1.2),
                    fontFamily:
                        Settings.getValue('key-font-family') ?? 'candara',
                    textAlign: TextAlign.justify),
              });
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          }),
    );
  }
}
