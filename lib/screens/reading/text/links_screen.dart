// a widget that takes an html strings array, finds all the headings, and displays it in a listview. on pressed the scrollcontroller scrolls to the index of the heading.

import 'package:otzaria/models/books.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:otzaria/models/tabs.dart';
import 'package:otzaria/models/links.dart';

class LinksViewer extends StatefulWidget {
  final Future<List<Link>> links;
  final Function(OpenedTab tab) openTabcallback;
  final ItemPositionsListener itemPositionsListener;
  final void Function() closeLeftPanelCallback;

  const LinksViewer({
    super.key,
    required this.links,
    required this.openTabcallback,
    required this.itemPositionsListener,
    required this.closeLeftPanelCallback,
  });

  @override
  State<LinksViewer> createState() => _LinksViewerState();
}

class _LinksViewerState extends State<LinksViewer>
    with AutomaticKeepAliveClientMixin<LinksViewer> {
  late Future<List<Link>> visibleLinks;

  @override
  void initState() {
    super.initState();
    visibleLinks = getLinks();

    widget.itemPositionsListener.itemPositions.addListener(() {
      visibleLinks = getLinks();
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<List<Link>> getLinks() async {
    List<Link> visibleLinks = (await widget.links)
        .where((link) =>
            link.index1 ==
                widget.itemPositionsListener.itemPositions.value.first.index +
                    2 &&
            link.connectionType != "commentary")
        .toList();

    visibleLinks.sort((a, b) => a.path2
        .split(Platform.pathSeparator)
        .last
        .compareTo(b.path2.split(Platform.pathSeparator).last));

    return visibleLinks;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
        future: visibleLinks,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(
                  snapshot.data![index].heRef,
                ),
                onTap: () {
                  widget.openTabcallback(
                    TextBookTab(
                        book: TextBook(
                          title: utils
                              .getTitleFromPath(snapshot.data![index].path2),
                        ),
                        index: snapshot.data![index].index2 - 1),
                  );
                  widget.closeLeftPanelCallback();
                },
              ),
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        });
  }

  @override
  get wantKeepAlive => false;
}
