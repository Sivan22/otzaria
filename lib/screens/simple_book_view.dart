// a widget that takes an html strings array and displays it as a widget
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/models/tabs.dart';
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
  final ValueNotifier<bool> showSplitedView;
  final TextBookTab tab;
  final double textSize;

  @override
  State<SimpleBookView> createState() => _SimpleBookViewState();
}

class _SimpleBookViewState extends State<SimpleBookView> {
  FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
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
        child: SelectionArea(
          key: PageStorageKey(widget.tab),
          selectionControls: DesktopTextSelectionControls(),
          child: ScrollablePositionedList.builder(
              initialScrollIndex: widget.tab.index,
              itemPositionsListener: widget.tab.positionsListener,
              itemScrollController: widget.tab.scrollController,
              scrollOffsetController: widget.tab.scrollOffsetController,
              itemCount: widget.data.length,
              itemBuilder: (context, index) {
                return ValueListenableBuilder(
                  valueListenable: widget.tab.removeNikud,
                  builder: (context, removeNikud, child) => InkWell(
                    onTap: () => widget.tab.selectedIndex.value = index,
                    child: Html(
                        //remove nikud if needed
                        data: removeNikud
                            ? highLight(removeVolwels(widget.data[index]),
                                widget.tab.searchTextController.text)
                            : highLight(widget.data[index],
                                widget.tab.searchTextController.text),
                        style: {
                          'body': Style(
                              fontSize: FontSize(widget.textSize),
                              fontFamily:
                                  Settings.getValue('key-font-family') ??
                                      'candara',
                              textAlign: TextAlign.justify),
                        }),
                  ),
                );
              }),
        ));
  }
}
