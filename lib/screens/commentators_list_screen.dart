import 'package:flutter/material.dart';
import 'package:otzaria/models/tabs.dart';

class CommentaryListView extends StatefulWidget {
  final TextBookTab tab;

  const CommentaryListView({Key? key, required this.tab}) : super(key: key);

  @override
  State<CommentaryListView> createState() => CommentaryListViewState();
}

class CommentaryListViewState extends State<CommentaryListView>
    with AutomaticKeepAliveClientMixin<CommentaryListView> {
  bool _selectAll = false;
  String _filterQuery = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
        future: widget.tab.availableCommentators,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
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
                      widget.tab.commentariesToShow.value
                          .addAll(snapshot.data!);
                    } else {
                      widget.tab.commentariesToShow.value.clear();
                    }
                    widget.tab.commentariesToShow.notifyListeners();
                  });
                },
              ),
              Expanded(
                child: Builder(builder: (context) {
                  final filteredCommentaries = snapshot.data!
                      .where((book) =>
                          book.title.toLowerCase().contains(_filterQuery))
                      .toList();
                  return ListView.builder(
                    itemCount: filteredCommentaries.length,
                    itemBuilder: (context, index) => CheckboxListTile(
                      title: Text(filteredCommentaries[index].title),
                      value: widget.tab.commentariesToShow.value
                          .contains(filteredCommentaries[index]),
                      onChanged: (value) {
                        if (value!) {
                          widget.tab.commentariesToShow.value
                              .add(filteredCommentaries[index]);
                        } else {
                          widget.tab.commentariesToShow.value
                              .remove(filteredCommentaries[index]);
                        }
                        widget.tab.commentariesToShow.notifyListeners();
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
