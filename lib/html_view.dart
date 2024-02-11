// a widget that takes an html strings array and displays it as a widget
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_html/flutter_html.dart';

class HtmlView extends StatefulWidget {
  final List<String> data;
  final double textSize;
  final ItemScrollController scrollController;
  final String searchQuery;
  const HtmlView({super.key, required this.data, required this.scrollController,required this.searchQuery, required this.textSize});

  @override
  State<HtmlView> createState() => _HtmlViewState();
}

class _HtmlViewState extends State<HtmlView> with AutomaticKeepAliveClientMixin<HtmlView> {
  @override
  Widget build(BuildContext context) {
  return ScrollablePositionedList.builder(
  itemCount: widget.data.length,
  itemBuilder: (context, index) => SelectionArea(
    child: Html(data: Highlight(widget.data[index], widget.searchQuery), 
    style: {'body': Style(fontSize: FontSize(widget.textSize),
    fontFamily: Settings.getValue('key-font-family'))}),
  ),
  itemScrollController: widget.scrollController,
);
  }

    bool get wantKeepAlive => true;
}

// function to highlight a search query in html text 
String Highlight(String data, String searchQuery) {
  if(searchQuery.isNotEmpty){
    return data.replaceAll(searchQuery, '<font color=red>$searchQuery</font>');
  }
  return data;
}