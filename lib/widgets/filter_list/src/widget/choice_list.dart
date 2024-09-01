import 'package:otzaria/widgets/filter_list/src/filter_list_dialog.dart';
import 'package:otzaria/widgets/filter_list/src/theme/filter_list_theme.dart';

import '../state/filter_state.dart';
import '../state/provider.dart';
import 'choice_chip_widget.dart';
import 'package:flutter/material.dart';

class ChoiceList<T> extends StatelessWidget {
  const ChoiceList({
    Key? key,
    required this.validateSelectedItem,
    this.choiceChipBuilder,
    this.choiceChipLabel,
    this.enableOnlySingleSelection = false,
    this.validateRemoveItem,
    this.maximumSelectionLength,
    this.onChoiseMade,
  }) : super(key: key);
  final ValidateSelectedItem<T> validateSelectedItem;
  final OnApplyButtonClick<T>? onChoiseMade;
  final ChoiceChipBuilder? choiceChipBuilder;
  final LabelDelegate<T>? choiceChipLabel;
  final bool enableOnlySingleSelection;
  final ValidateRemoveItem<T>? validateRemoveItem;
  final int? maximumSelectionLength;

  List<Widget> _buildChoiceList(BuildContext context) {
    final state = StateProvider.of<FilterState<T>>(context);
    final items = state.items;
    final selectedListData = state.selectedItems;
    if (items == null || items.isEmpty) {
      return const <Widget>[];
    }
    final List<Widget> choices = [];
    for (final item in items) {
      final selected = validateSelectedItem(selectedListData, item);

      // Check if maximum selection length reached
      final maxSelectionReached = maximumSelectionLength != null &&
          state.selectedItems != null &&
          state.selectedItems!.length >= maximumSelectionLength!;
      choices.add(
        ChoiceChipWidget(
          choiceChipBuilder: choiceChipBuilder,
          disabled: maxSelectionReached,
          item: item,
          onSelected: (value) {
            if (enableOnlySingleSelection) {
              state.clearSelectedList();
              state.addSelectedItem(item);
            } else {
              if (selected) {
                if (validateRemoveItem != null) {
                  final shouldDelete =
                      validateRemoveItem!(selectedListData, item);
                  state.selectedItems = shouldDelete;
                } else {
                  state.removeSelectedItem(item);
                }
              } else {
                // Add maximum selection length check
                if (maxSelectionReached && !selected) {
                  return;
                }
                state.addSelectedItem(item);
              }
              final selectedItems = FilterState.of<T>(context).selectedItems;
              if (onChoiseMade != null) {
                onChoiseMade!.call(selectedItems);
              }
            }
          },
          selected: selected,
          text: choiceChipLabel!(item),
        ),
      );
    }
    choices.add(
      SizedBox(
        height: 1,
        width: MediaQuery.of(context).size.width,
      ),
    );
    return choices;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FilterListTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: SingleChildScrollView(
        child: ChangeNotifierProvider<FilterState<T>>(
          builder: (
            BuildContext context,
            FilterState<T> state,
            Widget? child,
          ) {
            return Wrap(
              alignment: theme.wrapAlignment,
              crossAxisAlignment: theme.wrapCrossAxisAlignment,
              runSpacing: theme.wrapSpacing,
              children: _buildChoiceList(context),
            );
          },
        ),
      ),
    );
  }
}
