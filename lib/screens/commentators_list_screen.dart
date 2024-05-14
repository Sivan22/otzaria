import 'package:flutter/material.dart';
import 'package:otzaria/models/tabs.dart';

class CommentatorsListView extends StatefulWidget {
  final TextBookTab tab;

  const CommentatorsListView({Key? key, required this.tab}) : super(key: key);

  @override
  State<CommentatorsListView> createState() => CommentatorsListViewState();
}

class CommentatorsListViewState extends State<CommentatorsListView> {
  bool _selectAll = false;
  String _filterQuery = "";

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: widget.tab.availableCommentators,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text('לא נמצאו פרשנים'));
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
                      widget.tab.commentatorsToShow.value
                          .addAll(snapshot.data!);
                    } else {
                      widget.tab.commentatorsToShow.value.clear();
                    }
                    widget.tab.commentatorsToShow.notifyListeners();
                  });
                },
              ),
              Expanded(
                child: Builder(builder: (context) {
                  final filteredCommentaries = snapshot.data!
                      .where((title) => title.contains(_filterQuery))
                      .toList();
                  return ListView.builder(
                    itemCount: filteredCommentaries.length,
                    itemBuilder: (context, index) => CheckboxListTile(
                      title: Text(filteredCommentaries[index]),
                      value: widget.tab.commentatorsToShow.value
                          .contains(filteredCommentaries[index]),
                      onChanged: (value) {
                        if (value!) {
                          widget.tab.commentatorsToShow.value
                              .add(filteredCommentaries[index]);
                        } else {
                          widget.tab.commentatorsToShow.value.removeWhere(
                              (s) => s == filteredCommentaries[index]);
                        }
                        widget.tab.commentatorsToShow.notifyListeners();
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
}
