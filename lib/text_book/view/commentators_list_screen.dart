// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_event.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:otzaria/widgets/filter_list/src/filter_list_dialog.dart';
import 'package:otzaria/widgets/filter_list/src/theme/filter_list_theme.dart';

class CommentatorsListView extends StatefulWidget {
  const CommentatorsListView({
    Key? key,
  }) : super(key: key);

  @override
  State<CommentatorsListView> createState() => CommentatorsListViewState();
}

class CommentatorsListViewState extends State<CommentatorsListView> {
  TextEditingController searchController = TextEditingController();
  List<String> selectedTopics = [];
  List<String> commentatorsList = [];

  Future<void> update(BuildContext context, TextBookState state) async {
    if (state is! TextBookLoaded) return;
    final List<String> baseList = state.availableCommentators;
    final filteredByQuery =
        baseList.where((title) => title.contains(searchController.text));

    if (selectedTopics.isEmpty) {
      commentatorsList = filteredByQuery.toList();

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

    commentatorsList = filtered;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextBookBloc, TextBookState>(builder: (context, state) {
      if (state is! TextBookLoaded) return const Center();
      if (state.availableCommentators.isEmpty) {
        return const Center(
          child: Text("אין פרשנים"),
        );
      }
      if (commentatorsList.isEmpty) update(context, state);
      return Column(
        children: [
          FilterListWidget<String>(
            hideSearchField: true,
            controlButtons: const [],
            onApplyButtonClick: (list) {
              setState(() {
                selectedTopics = list ?? [];
                update(context, state);
              });
            },
            validateSelectedItem: (list, item) =>
                list != null && list.contains(item),
            onItemSearch: (item, query) => item == query,
            listData: [
              'ראשונים',
              'אחרונים',
              'מחברי זמננו',
              'על ${state.book.title}'
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
            child: Builder(builder: (context) {
              return Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "סינון",
                      suffix: IconButton(
                          onPressed: () {
                            setState(() {
                              searchController.clear();
                              update(context, state);
                            });
                          },
                          icon: Icon(Icons.close)),
                    ),
                    onChanged: (query) {
                      setState(() {
                        update(context, state);
                      });
                    },
                  ),
                  if (commentatorsList.isNotEmpty)
                    CheckboxListTile(
                      title: const Text("הכל"),
                      value: commentatorsList.every(
                          (test) => state.activeCommentators.contains(test)),
                      onChanged: (value) {
                        setState(() {
                          if (value!) {
                            final allCommentators = commentatorsList
                              ..addAll(state.activeCommentators);
                            context
                                .read<TextBookBloc>()
                                .add(UpdateCommentators(allCommentators));
                          } else {
                            context.read<TextBookBloc>().add(UpdateCommentators(
                                state.activeCommentators
                                    .where((element) =>
                                        !commentatorsList.contains(element))
                                    .toList()));
                          }
                        });
                      },
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: commentatorsList.length,
                      itemBuilder: (context, index) => CheckboxListTile(
                        title: Text(commentatorsList[index]),
                        value: state.activeCommentators
                            .contains(commentatorsList[index]),
                        onChanged: (value) {
                          if (value!) {
                            context.read<TextBookBloc>().add(UpdateCommentators(
                                state.activeCommentators +
                                    [commentatorsList[index]]));
                          } else {
                            context.read<TextBookBloc>().add(UpdateCommentators(
                                state.activeCommentators
                                    .where((element) =>
                                        element != commentatorsList[index])
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
