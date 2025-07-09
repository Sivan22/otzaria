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
  static const String _separator = '__sep__';

  // 1. הפונקציה filterGroup חזרה להיות פונקציה רגילה בקלאס
  //    ותוקן בה המיקום של ה-return
  Future<List<String>> filterGroup(List<String> group) async {
    final filteredByQuery =
        group.where((title) => title.contains(searchController.text));
        
    if (selectedTopics.isEmpty) {
      return filteredByQuery.toList();
    }

    final List<String> filtered = [];
    for (final title in filteredByQuery) {
      for (final topic in selectedTopics) {
        if (await hasTopic(title, topic)) {
          filtered.add(title);
          break; // יציאה מהלולאה הפנימית ומעבר לכותרת הבאה
        }
      }
    }
    // ה-return נמצא כאן, אחרי שהלולאה סיימה לעבור על כל האיברים
    return filtered;
  }

  // 2. הפונקציה update מכילה את כל הלוגיקה הא-סינכרונית
  //    ובסופה היא קוראת ל-setState כדי לעדכן את ה-UI
  Future<void> update(BuildContext context, TextBookState state) async {
    if (state is! TextBookLoaded) return;

    // קריאות א-סינכרוניות לסינון הרשימות
    final rishonim = await filterGroup(state.rishonim);
    final acharonim = await filterGroup(state.acharonim);
    final modern = await filterGroup(state.modernCommentators);

    // עדכון המצב (state) של הווידג'ט רק אחרי שכל המידע מוכן
    setState(() {
      commentatorsList = [
        ...rishonim,
        if (rishonim.isNotEmpty && acharonim.isNotEmpty) _separator,
        ...acharonim,
        if (acharonim.isNotEmpty && modern.isNotEmpty) _separator,
        ...modern,
      ];
    });
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
              // 3. אין צורך ב-setState כאן, כי update כבר עושה את זה
              selectedTopics = list ?? [];
              update(context, state);
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
                            searchController.clear();
                            update(context, state);
                          },
                          icon: Icon(Icons.close)),
                    ),
                    onChanged: (query) {
                      // 4. אין צורך ב-setState כאן
                      update(context, state);
                    },
                  ),
                  if (commentatorsList.isNotEmpty)
                    CheckboxListTile(
                      title: const Text("הכל"),
                      value: commentatorsList
                          .where((e) => e != _separator)
                          .every((test) =>
                              state.activeCommentators.contains(test)),
                      onChanged: (value) {
                        setState(() { // כאן צריך setState כי זה משפיע ישירות על ה-Bloc
                          final items =
                              commentatorsList.where((e) => e != _separator).toList();
                          if (value!) {
                            final allCommentators = [
                              ...items,
                              ...state.activeCommentators
                            ];
                            context
                                .read<TextBookBloc>()
                                .add(UpdateCommentators(allCommentators.toSet().toList())); // toSet().toList() למניעת כפילויות
                          } else {
                            context.read<TextBookBloc>().add(UpdateCommentators(
                                state.activeCommentators
                                    .where((element) => !items.contains(element))
                                    .toList()));
                          }
                        });
                      },
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: commentatorsList.length,
                      itemBuilder: (context, index) {
                        final item = commentatorsList[index];
                        if (item == _separator) return const Divider();
                        return CheckboxListTile(
                          title: Text(item),
                          value: state.activeCommentators.contains(item),
                          onChanged: (value) {
                            if (value!) {
                              context
                                  .read<TextBookBloc>()
                                  .add(UpdateCommentators(state.activeCommentators + [item]));
                            } else {
                              context.read<TextBookBloc>().add(UpdateCommentators(
                                  state.activeCommentators
                                      .where((element) => element != item)
                                      .toList()));
                            }
                          },
                        );
                      },
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