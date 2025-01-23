/* this is a representation of the tabs that could be open in the app.
a tab is either a pdf book or a text book, or a full text search window*/

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:otzaria/models/tabs/pdf_tab.dart';
import 'package:otzaria/models/tabs/searching_tab.dart';
import 'package:otzaria/models/tabs/text_tab.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:otzaria/models/links.dart';
import 'package:otzaria/models/books.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

abstract class OpenedTab {
  String title;
  OpenedTab(this.title);

  factory OpenedTab.from(OpenedTab tab) {
    if (tab is TextBookTab) {
      return TextBookTab(
        index: tab.index,
        book: tab.book,
        commentators: tab.commentatorsToShow.value,
      );
    } else if (tab is PdfBookTab) {
      return PdfBookTab(
        tab.book,
        tab.pageNumber,
      );
    }
    return tab;
  }

  factory OpenedTab.fromJson(Map<String, dynamic> json) {
    String type = json['type'];
    if (type == 'TextBookTab') {
      return TextBookTab.fromJson(json);
    } else if (type == 'PdfBookTab') {
      return PdfBookTab.fromJson(json);
    }
    return SearchingTab.fromJson(json);
  }
  Map<String, dynamic> toJson();
}
