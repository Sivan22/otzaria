import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'links_view.dart';

class CommentaryListView extends StatefulWidget {
  final Future<List<Link>> links;
  final ValueNotifier<List<String>> commentaries;

  const CommentaryListView({
    Key? key,
    required this.links,
    required this.commentaries,
  }) : super(key: key);

  @override
  State<CommentaryListView> createState() => CommentaryListViewState();
}

class CommentaryListViewState extends State<CommentaryListView>
    with AutomaticKeepAliveClientMixin<CommentaryListView> {
  late Future<List<String>> commentariesNames;
  bool _selectAll = false;
  String _filterQuery = "";

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
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          List<String> commentariesNames = snapshot.data!;

          return Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: "סינון מפרשים",
                ),
                onChanged: (query) {
                  setState(() {
                    _filterQuery = query.toLowerCase();
                  });
                },
              ),
              CheckboxListTile(
                title: const Text("כל המפרשים"),
                value: _selectAll,
                onChanged: (value) {
                  setState(() {
                    _selectAll = value!;
                    if (_selectAll) {
                      widget.commentaries.value.addAll(commentariesNames);
                    } else {
                      widget.commentaries.value.clear();
                    }
                    widget.commentaries.notifyListeners();
                  });
                },
              ),
              Expanded(
                child: Builder(builder: (context) {
                  final filteredCommentaries = snapshot.data!
                      .where(
                          (name) => name.toLowerCase().contains(_filterQuery))
                      .toList();
                  return ListView.builder(
                    itemCount: filteredCommentaries.length,
                    itemBuilder: (context, index) => CheckboxListTile(
                      title: Text(filteredCommentaries[index]),
                      value: widget.commentaries.value
                          .contains(filteredCommentaries[index]),
                      onChanged: (value) {
                        if (value!) {
                          widget.commentaries.value
                              .add(filteredCommentaries[index]);
                        } else {
                          widget.commentaries.value
                              .remove(filteredCommentaries[index]);
                        }
                        widget.commentaries.notifyListeners();
                        setState(() {});
                      },
                    ),
                  );
                }),
              ),
            ],
          );
        });
  }

  @override
  bool get wantKeepAlive => true;
}

Future<List<String>> getCommentariesNames(Future<List<Link>> links) async {
  List<Link> finalLinks = (await links)
      .where((link) =>
          link.connectionType == 'commentary' ||
          link.connectionType == 'targum')
      .toList();
  List<String> commentaries =
      finalLinks.map((link) => link.path2.split('\\').last).toList();
  commentaries.sort(
    (a, b) => a.compareTo(b),
  );
  commentaries = commentaries.toSet().toList();
  return commentaries;
}
