part of 'filter_list_dialog.dart';

typedef ValidateSelectedItem<T> = bool Function(List<T>? list, T item);
typedef OnApplyButtonClick<T> = void Function(List<T>? list);
typedef ChoiceChipBuilder<T> = Widget Function(
    BuildContext context, T? item, bool? isSelected);
// typedef ItemSearchDelegate<T> = List<T> Function(List<T>? list, String query);
typedef SearchPredict<T> = bool Function(T item, String query);
typedef LabelDelegate<T> = String? Function(T?);
typedef ValidateRemoveItem<T> = List<T> Function(List<T>? list, T item);

enum ControlButtonType { All, Reset }

/// The [FilterListWidget] is a widget with some filter utilities and callbacks which helps in single/multiple selection from list of data.
///
/// {@template arguments}
///
/// ### This example shows how to use [FilterListWidget]
///  ``` dart
///  FilterListWidget<String>(
///    listData: ["One","Two","Three", "Four","five", "Six","Seven","Eight","Nine","Ten"],
///    selectedListData: ["One", "Three", "Four", "Eight", "Nine"],
///    hideHeaderText: true,
///    height: MediaQuery.of(context).size.height,
///    // hideHeaderText: true,
///    onApplyButtonClick: (list) {
///      Navigator.pop(context, list);
///    },
///    choiceChipLabel: (item) {
///      /// Used to print text on chip
///      return item;
///    },
///    validateSelectedItem: (list, val) {
///      ///  identify if item is selected or not
///      return list!.contains(val);
///    },
///    onItemSearch: (list, text) {
///      /// When text change in search text field then return list containing that text value
///      ///
///      ///Check if list has value which match's to text
///      if (list!.any((element) =>
///          element.toLowerCase().contains(text.toLowerCase()))) {
///        /// return list which contains matches
///        return list
///            .where((element) =>
///                element.toLowerCase().contains(text.toLowerCase()))
///            .toList();
///      }
///      return [];
///    },
///   )
/// ```
/// {@endtemplate}
class FilterListWidget<T extends Object> extends StatelessWidget {
  const FilterListWidget({
    Key? key,
    this.themeData,
    this.listData,
    required this.validateSelectedItem,
    this.validateRemoveItem,
    required this.choiceChipLabel,
    required this.onItemSearch,
    this.selectedListData,
    this.onApplyButtonClick,
    this.choiceChipBuilder,
    this.headerCloseIcon,
    this.onCloseWidgetPress,
    this.headlineText,
    this.hideSelectedTextCount = false,
    this.hideSearchField = false,
    this.hideCloseIcon = true,
    this.hideHeader = false,
    this.backgroundColor = Colors.white,
    this.enableOnlySingleSelection = false,
    this.maximumSelectionLength,
    this.allButtonText = 'All',
    this.applyButtonText = 'Apply',
    this.resetButtonText = 'Reset',
    this.selectedItemsText = 'selected items',
    this.controlButtons = const [
      ControlButtonType.All,
      ControlButtonType.Reset
    ],
  }) : super(key: key);

  /// Filter theme
  final FilterListThemeData? themeData;

  /// Pass list containing all data which needs to filter
  final List<T>? listData;

  /// The [selectedListData] is used to preselect the choice chips.
  /// It takes list of object and this list should be subset og [listData]
  final List<T>? selectedListData;
  final Color? backgroundColor;

  final String? headlineText;

  final bool hideSelectedTextCount;
  final bool hideSearchField;

  /// if true then it hides close icon.
  final bool hideCloseIcon;

  /// Widget to close the dialog.
  ///
  /// If widget is not provided then default close icon will be used.
  final Widget? headerCloseIcon;

  /// Function to execute on close widget press. To pass user define function and do a different task with this button rather than close. (Example: Add item to the List.)
  ///
  /// Default is `Navigator.pop(context, null)`
  final void Function()? onCloseWidgetPress;

  /// If true then it hide complete header section.
  final bool? hideHeader;

  /// if [enableOnlySingleSelection] is true then it disabled the multiple selection.
  /// and enabled the single selection model.
  ///
  /// Default value is `false`
  final bool enableOnlySingleSelection;

  /// if `maximumSelectionLength` is not null then it will limit the maximum selection length.
  /// `maximumSelectionLength` should be greater than 0. If `maximumSelectionLength` is less than 0 then it will throw an exception.
  /// Only works when `enableOnlySingleSelection` is false.
  /// Default value is [null]
  final int? maximumSelectionLength;

  /// The `onApplyButtonClick` is a callback which return list of all selected items on apply button click.  if no item is selected then it will return empty list.
  final OnApplyButtonClick<T>? onApplyButtonClick;

  /// The `validateSelectedItem` identifies weather a item is selected or not.
  final ValidateSelectedItem<T> validateSelectedItem; /*required*/

  /// The `validateRemoveItem` identifies if a item should be remove or not and returns the list filtered.
  final ValidateRemoveItem<T>? validateRemoveItem;

  /// The `onItemSearch` is delegate which filter the list on the basis of search field text.
  final SearchPredict<T> onItemSearch; /*required*/

  /// The `choiceChipLabel` is callback which required [String] value to display text on choice chip.
  final LabelDelegate<T> choiceChipLabel; /*required*/

  /// The `choiceChipBuilder` is a builder to design custom choice chip.
  final ChoiceChipBuilder? choiceChipBuilder;

  /// Apply Button Label
  final String? applyButtonText;

  /// Reset Button Label
  final String? resetButtonText;

  /// All Button Label
  final String? allButtonText;

  /// Selected items count text
  final String? selectedItemsText;

  /// {@template control_buttons}
  /// control buttons to show on bottom of dialog along with 'Apply' button.
  ///
  /// If `ControlButtonType.All` is passed then it will show 'All' and 'Apply' button.
  ///
  /// If `ControlButtonType.Reset` is passed then it will show 'Reset' and 'Apply' button.
  ///
  /// Default value is `[ControlButton.All, ControlButton.Reset]`
  ///
  /// If `enableOnlySingleSelection` is true then it will hide 'All' button.
  /// {@endtemplate}
  final List<ControlButtonType> controlButtons;

  Widget _body(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.2,
              ),
              child: ChoiceList<T>(
                choiceChipBuilder: choiceChipBuilder,
                choiceChipLabel: choiceChipLabel,
                enableOnlySingleSelection: enableOnlySingleSelection,
                validateSelectedItem: validateSelectedItem,
                validateRemoveItem: validateRemoveItem,
                maximumSelectionLength: maximumSelectionLength,
                onChoiseMade: onApplyButtonClick,
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StateProvider<FilterState<T>>(
      value: FilterState<T>(
        allItems: listData,
        selectedItems: selectedListData,
      ),
      child: FilterListTheme(
        theme: themeData ?? FilterListThemeData.light(context),
        child: Builder(
          builder: (BuildContext innerContext) {
            return _body(context);
          },
        ),
      ),
    );
  }
}
