import 'main_window_view.dart';
import 'package:flutter/material.dart';
import 'links_view.dart';
import 'dart:io';

class CommetaryListView extends StatefulWidget {
  final Future<List<Link>> links;
  final ValueNotifier<List<String>> commetaries;

  CommetaryListView({required this.links, required this.commetaries});

  @override
  State<CommetaryListView> createState() => CommetaryListViewState();
}

class CommetaryListViewState extends State<CommetaryListView>
    with AutomaticKeepAliveClientMixin<CommetaryListView> {
  late Future<List<String>> commentariesNames;

  @override
  void initState() {
    super.initState();

    commentariesNames = getCommentariesNames(widget.links);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
        future: commentariesNames,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) => CheckboxListTile(
                    title: Text(snapshot.data![index]),
                    value: widget.commetaries.value
                        .contains(snapshot.data![index]),
                    onChanged: (value) {
                      if (value!) {
                        widget.commetaries.value.add(snapshot.data![index]);
                      } else {
                        widget.commetaries.value.remove(snapshot.data![index]);
                      }
                      widget.commetaries.notifyListeners();
                      setState(() {});
                    }));
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        });
  }

  @override
  get wantKeepAlive => true;
}

Future<List<String>> getCommentariesNames(Future<List<Link>> links) async {
  List<Link> finalLinks = (await links)
      .where((link) =>
          link.connectionType == 'commentary' ||
          link.connectionType == 'targum')
      .toList();

  List<String> commentaries = finalLinks
      .map((link) => link.path2.split(Platform.pathSeparator).last)
      .toList();

  commentaries.sort(
    (a, b) => a.compareTo(b),
  );
  commentaries = commentaries.toSet().toList();

  return commentaries;
}
