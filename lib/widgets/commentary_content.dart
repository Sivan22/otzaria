import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:otzaria/model/books.dart';
import 'package:otzaria/model/tabs.dart';
import 'package:otzaria/model/links.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;
import 'dart:isolate';

class CommentaryContent extends StatefulWidget {
  const CommentaryContent({
    super.key,
    required this.link,
    required this.fontSize,
    required this.openBookCallback,
  });
  final Link link;
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
    super.initState();
    content = widget.link.content;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onDoubleTap: () {
        widget.openBookCallback(TextBookTab(
          book: TextBook(title: utils.getTitleFromPath(widget.link.path2)),
          widget.link.index2 - 1,
        ));
      },
      child: FutureBuilder(
          future: content,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Html(data: snapshot.data, style: {
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

  @override
  bool get wantKeepAlive => true;
}