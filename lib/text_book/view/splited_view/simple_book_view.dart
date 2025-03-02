// a widget that takes an html strings array and displays it as a widget
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_state.dart';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_event.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/widgets/progressive_scrolling.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/utils/text_manipulation.dart';

class SimpleBookView extends StatefulWidget {
  const SimpleBookView({
    super.key,
    required this.tab,
    required this.data,
    required this.openBookCallback,
    required this.textSize,
    required this.showSplitedView,
  });

  final List<String> data;
  final Function(OpenedTab) openBookCallback;
  final bool showSplitedView;
  final TextBookTab tab;
  final double textSize;

  @override
  State<SimpleBookView> createState() => _SimpleBookViewState();
}

class _SimpleBookViewState extends State<SimpleBookView> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextBookBloc, TextBookState>(builder: (context, state) {
      return ProgressiveScroll(
          scrollController: state.scrollOffsetController,
          maxSpeed: 10000.0,
          curve: 10.0,
          accelerationFactor: 5,
          child: SelectionArea(
              key: PageStorageKey(widget.tab),
              child: ScrollablePositionedList.builder(
                  initialScrollIndex: state.visibleIndices?.first ?? 0,
                  itemPositionsListener: state.positionsListener,
                  itemScrollController: state.scrollController,
                  scrollOffsetController: state.scrollOffsetController,
                  itemCount: widget.data.length,
                  itemBuilder: (context, index) {
                    return BlocBuilder<SettingsBloc, SettingsState>(
                        builder: (context, settingsState) {
                      String data = widget.data[index];
                      if (!settingsState.showTeamim) {
                        data = removeTeamim(data);
                      }

                      if (settingsState.replaceHolyNames) {
                        data = replaceHolyNames(data);
                      }
                      return BlocBuilder<TextBookBloc, TextBookState>(
                        builder: (context, state) => InkWell(
                          onTap: () => context
                              .read<TextBookBloc>()
                              .add(UpdateSelectedIndex(index)),
                          child: Html(
                              //remove nikud if needed
                              data: state.removeNikud
                                  ? highLight(
                                      removeVolwels('${widget.data[index]}\n'),
                                      state.searchText)
                                  : highLight('${widget.data[index]}\n',
                                      state.searchText),
                              style: {
                                'body': Style(
                                    fontSize: FontSize(widget.textSize),
                                    fontFamily: settingsState.fontFamily,
                                    textAlign: TextAlign.justify),
                              }),
                        ),
                      );
                    });
                  })));
    });
  }
}
