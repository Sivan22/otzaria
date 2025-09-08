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
  List<String> _torahShebichtav = [];
  List<String> _chazal = [];
  List<String> _rishonim = [];
  List<String> _acharonim = [];
  List<String> _modern = [];
  List<String> _ungrouped = [];
  static const String _torahShebichtavTitle = '__TITLE_TORAH_SHEBICHTAV__';
  static const String _chazalTitle = '__TITLE_CHAZAL__';
  static const String _rishonimTitle = '__TITLE_RISHONIM__';
  static const String _acharonimTitle = '__TITLE_ACHARONim__';
  static const String _modernTitle = '__TITLE_MODERN__';
  static const String _ungroupedTitle = '__TITLE_UNGROUPED__';
  static const String _torahShebichtavButton = '__BUTTON_TORAH_SHEBICHTAV__';
  static const String _chazalButton = '__BUTTON_CHAZAL__';
  static const String _rishonimButton = '__BUTTON_RISHONIM__';
  static const String _acharonimButton = '__BUTTON_ACHARONIM__';
  static const String _modernButton = '__BUTTON_MODERN__';
  static const String _ungroupedButton = '__BUTTON_UNGROUPED__';

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

  Future<void> _update(BuildContext context, TextBookLoaded state) async {
    // סינון הקבוצות הידועות
    final torahShebichtav = await filterGroup(state.torahShebichtav);
    final chazal = await filterGroup(state.chazal);
    final rishonim = await filterGroup(state.rishonim);
    final acharonim = await filterGroup(state.acharonim);
    final modern = await filterGroup(state.modernCommentators);

    final Set<String> alreadyListed = {
      ...torahShebichtav,
      ...chazal,
      ...rishonim,
      ...acharonim,
      ...modern,
    };
    final ungroupedRaw = state.availableCommentators
        .where((c) => !alreadyListed.contains(c))
        .toList();
    final ungrouped = await filterGroup(ungroupedRaw);

    _torahShebichtav = torahShebichtav;
    _chazal = chazal;
    _rishonim = rishonim;
    _acharonim = acharonim;
    _modern = modern;
    _ungrouped = ungrouped;

    // בניית הרשימה עם כותרות לפני כל קבוצה קיימת
    final List<String> merged = [];

    if (torahShebichtav.isNotEmpty) {
      merged.add(_torahShebichtavTitle); // הוסף כותרת תורה שבכתב
      merged.add(_torahShebichtavButton);
      merged.addAll(torahShebichtav);
    }
    if (chazal.isNotEmpty) {
      merged.add(_chazalTitle); // הוסף כותרת חזל
      merged.add(_chazalButton);
      merged.addAll(chazal);
    }
    if (rishonim.isNotEmpty) {
      merged.add(_rishonimTitle); // הוסף כותרת ראשונים
      merged.add(_rishonimButton);
      merged.addAll(rishonim);
    }
    if (acharonim.isNotEmpty) {
      merged.add(_acharonimTitle); // הוסף כותרת אחרונים
      merged.add(_acharonimButton);
      merged.addAll(acharonim);
    }
    if (modern.isNotEmpty) {
      merged.add(_modernTitle); // הוסף כותרת מחברי זמננו
      merged.add(_modernButton);
      merged.addAll(modern);
    }
    if (ungrouped.isNotEmpty) {
      merged.add(_ungroupedTitle); // הוסף כותרת לשאר
      merged.add(_ungroupedButton);
      merged.addAll(ungrouped);
    }
    if (mounted) {
      setState(() => commentatorsList = merged);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextBookBloc, TextBookState>(builder: (context, state) {
      if (state is! TextBookLoaded) return const Center();
      if (state.availableCommentators.isEmpty) {
        return const Center(
          child: Text("אין מפרשים"),
        );
      }
      if (commentatorsList.isEmpty) _update(context, state);
      return Column(
        children: [
          FilterListWidget<String>(
            hideSearchField: true,
            controlButtons: const [],
            onApplyButtonClick: (list) {
              selectedTopics = list ?? [];
              _update(context, state as TextBookLoaded);
            },
            validateSelectedItem: (list, item) =>
                list != null && list.contains(item),
            onItemSearch: (item, query) => item == query,
            listData: [
              'תורה שבכתב',
              'חז"ל',
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
            child: Column(
              children: [
                // --- שדה החיפוש ---
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "סינון",
                    suffix: IconButton(
                        onPressed: () {
                          searchController.clear();
                          _update(context, state);
                        },
                        icon: const Icon(Icons.close)),
                  ),
                  onChanged: (_) => _update(context, state),
                ),

                // --- כפתור הכל ---
                if (commentatorsList.isNotEmpty)
                  CheckboxListTile(
                    title:
                        const Text('הצג את כל המפרשים'), // שמרתי את השינוי שלך
                    value: commentatorsList
                        .where((e) =>
                            !e.startsWith('__TITLE_') &&
                            !e.startsWith('__BUTTON_'))
                        .every(state.activeCommentators.contains),
                    onChanged: (checked) {
                      final items = commentatorsList
                          .where((e) =>
                              !e.startsWith('__TITLE_') &&
                              !e.startsWith('__BUTTON_'))
                          .toList();
                      if (checked ?? false) {
                        context.read<TextBookBloc>().add(UpdateCommentators(
                            {...state.activeCommentators, ...items}.toList()));
                      } else {
                        context.read<TextBookBloc>().add(UpdateCommentators(
                            state.activeCommentators
                                .where((e) => !items.contains(e))
                                .toList()));
                      }
                    },
                  ),

                // --- רשימת הפרשנים ---
                Expanded(
                  child: ListView.builder(
                    itemCount: commentatorsList.length,
                    itemBuilder: (context, index) {
                      final item = commentatorsList[index];

                      // בדוק אם הפריט הוא כפתור הצגת קבוצה
                      if (item == _torahShebichtavButton) {
                        final allActive = _torahShebichtav
                            .every(state.activeCommentators.contains);
                        return CheckboxListTile(
                          title: const Text('הצג את כל התורה שבכתב'),
                          value: allActive,
                          onChanged: (checked) {
                            final current =
                                List<String>.from(state.activeCommentators);
                            if (checked ?? false) {
                              for (final t in _torahShebichtav) {
                                if (!current.contains(t)) current.add(t);
                              }
                            } else {
                              current.removeWhere(_torahShebichtav.contains);
                            }
                            context
                                .read<TextBookBloc>()
                                .add(UpdateCommentators(current));
                          },
                        );
                      }
                      if (item == _chazalButton) {
                        final allActive =
                            _chazal.every(state.activeCommentators.contains);
                        return CheckboxListTile(
                          title: const Text('הצג את כל חז"ל'),
                          value: allActive,
                          onChanged: (checked) {
                            final current =
                                List<String>.from(state.activeCommentators);
                            if (checked ?? false) {
                              for (final t in _chazal) {
                                if (!current.contains(t)) current.add(t);
                              }
                            } else {
                              current.removeWhere(_chazal.contains);
                            }
                            context
                                .read<TextBookBloc>()
                                .add(UpdateCommentators(current));
                          },
                        );
                      }
                      if (item == _rishonimButton) {
                        final allActive =
                            _rishonim.every(state.activeCommentators.contains);
                        return CheckboxListTile(
                          title: const Text('הצג את כל הראשונים'),
                          value: allActive,
                          onChanged: (checked) {
                            final current =
                                List<String>.from(state.activeCommentators);
                            if (checked ?? false) {
                              for (final t in _rishonim) {
                                if (!current.contains(t)) current.add(t);
                              }
                            } else {
                              current.removeWhere(_rishonim.contains);
                            }
                            context
                                .read<TextBookBloc>()
                                .add(UpdateCommentators(current));
                          },
                        );
                      }
                      if (item == _acharonimButton) {
                        final allActive =
                            _acharonim.every(state.activeCommentators.contains);
                        return CheckboxListTile(
                          title: const Text('הצג את כל האחרונים'),
                          value: allActive,
                          onChanged: (checked) {
                            final current =
                                List<String>.from(state.activeCommentators);
                            if (checked ?? false) {
                              for (final t in _acharonim) {
                                if (!current.contains(t)) current.add(t);
                              }
                            } else {
                              current.removeWhere(_acharonim.contains);
                            }
                            context
                                .read<TextBookBloc>()
                                .add(UpdateCommentators(current));
                          },
                        );
                      }
                      if (item == _modernButton) {
                        final allActive =
                            _modern.every(state.activeCommentators.contains);
                        return CheckboxListTile(
                          title: const Text('הצג את כל מחברי זמננו'),
                          value: allActive,
                          onChanged: (checked) {
                            final current =
                                List<String>.from(state.activeCommentators);
                            if (checked ?? false) {
                              for (final t in _modern) {
                                if (!current.contains(t)) current.add(t);
                              }
                            } else {
                              current.removeWhere(_modern.contains);
                            }
                            context
                                .read<TextBookBloc>()
                                .add(UpdateCommentators(current));
                          },
                        );
                      }
                      if (item == _ungroupedButton) {
                        final allActive =
                            _ungrouped.every(state.activeCommentators.contains);
                        return CheckboxListTile(
                          title: const Text('הצג את כל שאר המפרשים'),
                          value: allActive,
                          onChanged: (checked) {
                            final current =
                                List<String>.from(state.activeCommentators);
                            if (checked ?? false) {
                              for (final t in _ungrouped) {
                                if (!current.contains(t)) current.add(t);
                              }
                            } else {
                              current.removeWhere(_ungrouped.contains);
                            }
                            context
                                .read<TextBookBloc>()
                                .add(UpdateCommentators(current));
                          },
                        );
                      }

                      // בדוק אם הפריט הוא כותרת
                      if (item.startsWith('__TITLE_')) {
                        String titleText = '';
                        switch (item) {
                          case _torahShebichtavTitle:
                            titleText = 'תורה שבכתב';
                            break;
                          case _chazalTitle:
                            titleText = 'חז"ל';
                            break;
                          case _rishonimTitle:
                            titleText = 'ראשונים';
                            break;
                          case _acharonimTitle:
                            titleText = 'אחרונים';
                            break;
                          case _modernTitle:
                            titleText = 'מחברי זמננו';
                            break;
                          case _ungroupedTitle:
                            titleText = 'שאר מפרשים';
                            break;
                        }

                        // ווידג'ט הכותרת
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 16.0),
                          child: Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  titleText,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.8),
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                        );
                      }

                      // אם זה לא כותרת, הצג CheckboxListTile רגיל
                      return CheckboxListTile(
                        title: Text(item),
                        value: state.activeCommentators.contains(item),
                        onChanged: (checked) {
                          if (checked ?? false) {
                            context.read<TextBookBloc>().add(
                                  UpdateCommentators(
                                      [...state.activeCommentators, item]),
                                );
                          } else {
                            context.read<TextBookBloc>().add(
                                  UpdateCommentators(state.activeCommentators
                                      .where((e) => e != item)
                                      .toList()),
                                );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      );
    });
  }
}
