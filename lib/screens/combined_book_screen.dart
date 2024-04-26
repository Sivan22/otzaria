// a widget that takes an html strings array and displays it as a widget
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:otzaria/widgets/commentary_list.dart';
import 'package:otzaria/models/tabs.dart';
import 'package:otzaria/utils/text_manipulation.dart';

class CombinedView extends StatefulWidget {
  final List<String> data;
  final TextBookTab tab;
  final double textSize;
  final Function(OpenedTab) openBookCallback;
  final ValueNotifier<bool> showSplitedView;

  const CombinedView({
    super.key,
    required this.tab,
    required this.data,
    required this.openBookCallback,
    required this.textSize,
    required this.showSplitedView,
  });

  @override
  State<CombinedView> createState() => _CombinedViewState();
}

class _CombinedViewState extends State<CombinedView>
    with AutomaticKeepAliveClientMixin<CombinedView> {
  FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return buildKeyboardListener();
  }

  KeyboardListener buildKeyboardListener() {
    return KeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          if (event.logicalKey.keyLabel == 'Arrow Down') {
            widget.tab.scrollOffsetController.animateScroll(
                offset: 150,
                duration: const Duration(
                    milliseconds: 300)); // Adjust scroll amount as needed
          } else if (event.logicalKey.keyLabel == 'Arrow Up') {
            widget.tab.scrollOffsetController.animateScroll(
                offset: -150,
                duration: const Duration(
                    milliseconds: 300)); // Adjust scroll amount as needed
          }
        },
        child: buildOuterList());
  }

  Widget buildOuterList() {
    return SelectionArea(
      selectionControls: DesktopTextSelectionControls(),
      child: ScrollablePositionedList.builder(
          initialScrollIndex: widget.tab.initalIndex,
          itemPositionsListener: widget.tab.positionsListener,
          itemScrollController: widget.tab.scrollController,
          scrollOffsetController: widget.tab.scrollOffsetController,
          itemCount: widget.data.length,
          itemBuilder: (context, index) {
            ExpansionTileController controller = ExpansionTileController();
            return buildExpansiomTile(controller, index);
          }),
    );
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
        title: Html(
            data: highLight(
                widget.data[index], widget.tab.searchTextController.text),
            style: {
              'body': Style(
                  fontSize: FontSize(widget.textSize),
                  fontFamily: Settings.getValue('key-font-family') ?? 'candara',
                  textAlign: TextAlign.justify),
            }),
        children: [
          //on splited view we don't need the Inner list
          widget.showSplitedView.value
              ? const SizedBox.shrink()
              : CommentaryList(
                  index: index,
                  fontSize: widget.textSize,
                  textBookTab: widget.tab,
                  openBookCallback: widget.openBookCallback,
                  showSplitView: ValueNotifier<bool>(false),
                )
        ]);
  }

  @override
  bool get wantKeepAlive => true;
}
