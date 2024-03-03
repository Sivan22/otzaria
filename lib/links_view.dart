// a widget that takes an html strings array, finds all the headings, and displays it in a listview. on pressed the scrollcontroller scrolls to the index of the heading.

import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'main_window_view.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';

class LinksViewer extends StatefulWidget {
  final Future<List<Link>> links;
  final Function(TabWindow tab) openTabcallback;
  final ItemPositionsListener itemPositionsListener;

  LinksViewer(
      {super.key,
      required this.links,
      required this.openTabcallback,
      required this.itemPositionsListener});

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
                  widget.openTabcallback(BookTabWindow(
                      snapshot.data![index].path2
                          .replaceAll('..\\..\\refs\\', ''),
                      snapshot.data![index].index2 - 1));
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

class Link {
  final String heRef;
  final int index1;
  final String path2;
  final int index2;
  final String connectionType;

  Link({
    required this.heRef,
    required this.index1,
    required this.path2,
    required this.index2,
    required this.connectionType,
  });

// another constructor for the Link class that takes a json object as a parameter
  Link.fromJson(Map<String, dynamic> json)
      : heRef = json['heRef_2'].toString(),
        index1 = int.parse(json['line_index_1'].toString().split('.').first),
        path2 = json['path_2'].toString(),
        index2 = int.parse(json['line_index_2'].toString().split('.').first),
        connectionType = json['Conection Type'].toString();
}
