// a widget that takes an html strings array, finds all the headings, and displays it in a listview. on pressed the scrollcontroller scrolls to the index of the heading.
import 'dart:isolate';

import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'main_window_view.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

class LinksViewer extends StatefulWidget {
  final String path;
  final Function(TabWindow tab) openTabcallback;
  final ItemPositionsListener itemPositionsListener;

  LinksViewer(
      {super.key,
      required this.path,
      required this.openTabcallback,
      required this.itemPositionsListener});

  @override
  State<LinksViewer> createState() => _LinksViewerState();
}

class _LinksViewerState extends State<LinksViewer>
    with AutomaticKeepAliveClientMixin<LinksViewer> {
  late Future<List<Link>> links;

  @override
  void initState() {
    super.initState();
    links = getLinksFromJson();
    widget.itemPositionsListener.itemPositions.addListener(() {
      links = getLinksFromJson();
      setState(() {});
    });
  }

  Future<List<Link>> getLinksFromJson() async {
    final jsonString = await File(widget.path).readAsString();
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList
        .map((json) => Link.fromJson(json))
        .where((link) =>
            link.index1 ==
            widget.itemPositionsListener.itemPositions.value.first.index)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
        future: links,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(snapshot.data![index].heRef),
                onTap: () {
                  widget.openTabcallback(BookTabWindow(
                      snapshot.data![index].path2.replaceFirst('otzaria\\', ''),
                      snapshot.data![index].index2));
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
  get wantKeepAlive => true;
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
