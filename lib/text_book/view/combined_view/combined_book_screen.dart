// a widget that takes an html strings array and displays it as a widget
// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_state.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_state.dart';
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
    required this.data,
    required this.openBookCallback,
    required this.textSize,
    required this.showSplitedView,
    required this.tab,
  });

  final List<String> data;
  final Function(OpenedTab) openBookCallback;
  final ValueNotifier<bool> showSplitedView;
  final double textSize;
  final TextBookTab tab;

  @override
  State<CombinedView> createState() => _CombinedViewState();
}

class _CombinedViewState extends State<CombinedView> {
  Widget buildKeyboardListener() {
    return BlocBuilder<TextBookBloc, TextBookState>(
        bloc: context.read<TextBookBloc>(),
        builder: (context, state) {
          if (state is! TextBookLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return ProgressiveScroll(
              maxSpeed: 10000.0,
              curve: 10.0,
              accelerationFactor: 5,
              scrollController: state.scrollOffsetController,
              child: SelectionArea(child: buildOuterList(state)));
        });
  }

  Widget buildOuterList(TextBookLoaded state) {
    return ScrollablePositionedList.builder(
        key: PageStorageKey(widget.tab),
        initialScrollIndex: state.visibleIndices.first,
        itemPositionsListener: state.positionsListener,
        itemScrollController: state.scrollController,
        scrollOffsetController: state.scrollOffsetController,
        itemCount: widget.data.length,
        itemBuilder: (context, index) {
          ExpansibleController controller = ExpansibleController();
          return buildExpansiomTile(controller, index, state);
        });
  }

  ExpansionTile buildExpansiomTile(
      ExpansibleController controller, int index, TextBookLoaded state) {
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
          return Html(
            //remove nikud if needed
            data: state.removeNikud
                ? utils.highLight(
                    utils.removeVolwels('$data\n'), state.searchText)
                : utils.highLight('$data\n', state.searchText),
            style: {
              'body': Style(
                  fontSize: FontSize(widget.textSize),
                  fontFamily: Settings.getValue('key-font-family') ?? 'candara',
                  textAlign: TextAlign.justify),
            },
          );
        }),
        children: [
          widget.showSplitedView.value
              ? const SizedBox.shrink()
              : CommentaryListForCombinedView(
                  index: index,
                  fontSize: widget.textSize,
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
