import 'package:flutter/material.dart';
import 'package:otzaria/models/tabs/text_tab.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:otzaria/widgets/filter_list/src/filter_list_dialog.dart';
import 'package:otzaria/widgets/filter_list/src/theme/filter_list_theme.dart';

class CommentatorsListView extends StatefulWidget {
  final TextBookTab tab;

  const CommentatorsListView({Key? key, required this.tab}) : super(key: key);

  @override
  State<CommentatorsListView> createState() => CommentatorsListViewState();
}

class CommentatorsListViewState extends State<CommentatorsListView> {
  String _filterQuery = "";
  Future<List<String>>? commentators;
  List<String> selectedTopics = [];

  Future<void> update() async {
    final List<String> baseList = await widget.tab.availableCommentators;
    final filteredByQuery =
        baseList.where((title) => title.contains(_filterQuery));

    if (selectedTopics.isEmpty) {
      setState(() {
        commentators = Future.value(filteredByQuery.toList());
      });
      return;
    }

    final List<String> filtered = [];
    for (final title in filteredByQuery) {
      for (final topic in selectedTopics) {
        if (await hasTopic(title, topic)) {
          filtered.add(title);
          break;
        }
      }
    }

    setState(() {
      commentators = Future.value(filtered);
    });
  }

  @override
  void initState() {
    super.initState();
    commentators = widget.tab.availableCommentators;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilterListWidget<String>(
          hideSearchField: true,
          controlButtons: const [],
          onApplyButtonClick: (list) {
            setState(() {
              selectedTopics = list ?? [];
            });
            update();
          },
          validateSelectedItem: (list, item) =>
              list != null && list.contains(item),
          onItemSearch: (item, query) => item == query,
          listData: [
            'ראשונים',
            'אחרונים',
            'מחברי זמננו',
            'על ${widget.tab.book.title}'
          ],
          selectedListData: selectedTopics,
          choiceChipLabel: (p0) => p0,
          hideSelectedTextCount: true,
          themeData: FilterListThemeData(
            context,
            wrapAlignment: WrapAlignment.center,
          ),
          choiceChipBuilder: (context, item, isSelected) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 3,
              vertical: 2,
            ),
            child: Chip(
              label: Text(item),
              backgroundColor:
                  isSelected! ? Theme.of(context).colorScheme.secondary : null,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onSecondary
                    : null,
                fontSize: 11,
              ),
              labelPadding: const EdgeInsets.all(0),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder(
              future: commentators,
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
                        hintText: "סינון",
                      ),
                      onChanged: (query) {
                        setState(() {
                          _filterQuery = query;
                        });
                        update();
                      },
                    ),
                    CheckboxListTile(
                      title: const Text("הכל"),
                      value: snapshot.data!.every((test) =>
                          widget.tab.commentatorsToShow.value.contains(test)),
                      onChanged: (value) {
                        setState(() {
                          if (value!) {
                            widget.tab.commentatorsToShow.value
                                .addAll(snapshot.data!);
                          } else {
                            widget.tab.commentatorsToShow.value
                                .removeWhere((e) => snapshot.data!.contains(e));
                          }
                          widget.tab.commentatorsToShow.notifyListeners();
                        });
                      },
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) => CheckboxListTile(
                          title: Text(snapshot.data![index]),
                          value: widget.tab.commentatorsToShow.value
                              .contains(snapshot.data![index]),
                          onChanged: (value) {
                            if (value!) {
                              widget.tab.commentatorsToShow.value
                                  .add(snapshot.data![index]);
                            } else {
                              widget.tab.commentatorsToShow.value.removeWhere(
                                  (s) => s == snapshot.data![index]);
                            }
                            widget.tab.commentatorsToShow.notifyListeners();
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                  ],
                );
              }),
        )
      ],
    );
  }
}
