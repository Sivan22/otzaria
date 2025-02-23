import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_event.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
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

  Future<void> update(TextBookState state) async {
    final List<String> baseList = state.availableCommentators ?? [];
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
  Widget build(BuildContext context) {
    return BlocBuilder<TextBookBloc, TextBookState>(builder: (context, state) {
      return Column(
        children: [
          FilterListWidget<String>(
            hideSearchField: true,
            controlButtons: const [],
            onApplyButtonClick: (list) {
              setState(() {
                selectedTopics = list ?? [];
              });
              update(state);
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
                backgroundColor: isSelected!
                    ? Theme.of(context).colorScheme.secondary
                    : null,
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
                          update(state);
                        },
                      ),
                      CheckboxListTile(
                        title: const Text("הכל"),
                        value: snapshot.data!.every(
                            (test) => state.activeCommentators.contains(test)),
                        onChanged: (value) {
                          setState(() {
                            if (value!) {
                              context
                                  .read<TextBookBloc>()
                                  .add(UpdateCommentators(snapshot.data!));
                            } else {
                              context.read<TextBookBloc>().add(
                                  UpdateCommentators(state.activeCommentators
                                      .where((element) =>
                                          !snapshot.data!.contains(element))
                                      .toList()));
                            }
                          });
                        },
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) => CheckboxListTile(
                            title: Text(snapshot.data![index]),
                            value: state.activeCommentators
                                .contains(snapshot.data![index]),
                            onChanged: (value) {
                              if (value!) {
                                state.activeCommentators
                                    .add(snapshot.data![index]);
                              } else {
                                context.read<TextBookBloc>().add(
                                    UpdateCommentators(state.activeCommentators
                                        .where((element) =>
                                            element != snapshot.data![index])
                                        .toList()));
                              }
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
    });
  }
}
