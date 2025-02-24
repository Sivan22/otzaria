// a widget that takes an html strings array and displays it as a widget
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_state.dart';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/text_book/view/combined_view/commentary_list_for_combined_view.dart';
import 'package:otzaria/widgets/progressive_scrolling.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;

class CombinedView extends StatefulWidget {
  const CombinedView({
    super.key,
    required this.tab,
    required this.data,
    required this.openBookCallback,
    required this.textSize,
    required this.showSplitedView,
  });

  final List<String> data;
  final Function(OpenedTab) openBookCallback;
  final ValueNotifier<bool> showSplitedView;
  final TextBookTab tab;
  final double textSize;

  @override
  State<CombinedView> createState() => _CombinedViewState();
}

class _CombinedViewState extends State<CombinedView> {
  Widget buildKeyboardListener() {
    return BlocBuilder<TextBookBloc, TextBookState>(builder: (context, state) {
      return ProgressiveScroll(
          maxSpeed: 10000.0,
          curve: 10.0,
          accelerationFactor: 5,
          scrollController: state.scrollOffsetController,
          child: SelectionArea(child: buildOuterList(state)));
    });
  }

  Widget buildOuterList(TextBookState state) {
    return ScrollablePositionedList.builder(
        initialScrollIndex: widget.tab.index,
        itemPositionsListener: state.positionsListener,
        itemScrollController: state.scrollController,
        scrollOffsetController: state.scrollOffsetController,
        itemCount: widget.data.length,
        itemBuilder: (context, index) {
          ExpansionTileController controller = ExpansionTileController();
          return buildExpansiomTile(controller, index);
        });
  }

  ExpansionTile buildExpansiomTile(
      ExpansionTileController controller, int index) {
    return ExpansionTile(
        shape: const Border(),
        //maintainState: true,
        controller: controller,
        key: PageStorageKey(widget.data[index]),
        iconColor: Colors.transparent,
        tilePadding: const EdgeInsets.all(0.0),
        collapsedIconColor: Colors.transparent,
        title: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, settingsState) {
          String data = widget.data[index];
          if (!settingsState.showTeamim) {
            data = utils.removeTeamim(data);
          }

          if (settingsState.replaceHolyNames) {
            data = utils.replaceHolyNames(data);
          }
          return BlocBuilder<TextBookBloc, TextBookState>(
            builder: (context, state) => Html(
              //remove nikud if needed
              data: state.removeNikud
                  ? utils.highLight(
                      utils.removeVolwels('$data\n'), state.searchText)
                  : utils.highLight('$data\n', state.searchText),
              style: {
                'body': Style(
                    fontSize: FontSize(widget.textSize),
                    fontFamily:
                        Settings.getValue('key-font-family') ?? 'candara',
                    textAlign: TextAlign.justify),
              },
            ),
          );
        }),
        children: [
          widget.showSplitedView.value
              ? const SizedBox.shrink()
              : CommentaryListForCombinedView(
                  index: index,
                  fontSize: widget.textSize,
                  textBookTab: widget.tab,
                  openBookCallback: widget.openBookCallback,
                  showSplitView: false,
                )
        ]);
  }

  @override
  Widget build(BuildContext context) {
    return buildKeyboardListener();
  }
}
