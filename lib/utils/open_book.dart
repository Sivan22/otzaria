import 'package:flutter/material.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_event.dart';
import 'package:otzaria/navigation/bloc/navigation_state.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_event.dart';
import 'package:otzaria/models/books.dart';
import "package:flutter_bloc/flutter_bloc.dart";
import 'package:otzaria/tabs/models/pdf_tab.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

void openBook(BuildContext context, Book book, int index, String searchQuery) {
  // שלב 1: חישוב הערך הבוליאני ושמירתו במשתנה נפרד
  // זה הופך את הקוד לקריא יותר ומונע את השגיאה
  final bool shouldOpenLeftPane =
      (Settings.getValue<bool>('key-pin-sidebar') ?? false) ||
      (Settings.getValue<bool>('key-default-sidebar-open') ?? false);

  // שלב 2: שימוש במשתנה החדש בשני המקרים
  if (book is TextBook) {
    context.read<TabsBloc>().add(AddTab(TextBookTab(
          book: book,
          index: index,
          searchText: searchQuery,
          openLeftPane: shouldOpenLeftPane, // שימוש במשתנה הפשוט
        )));
  } else if (book is PdfBook) {
    context.read<TabsBloc>().add(AddTab(PdfBookTab(
          book: book,
          pageNumber: index,
          openLeftPane: shouldOpenLeftPane, // שימוש באותו משתנה פשוט
        )));
  }

  context.read<NavigationBloc>().add(const NavigateToScreen(Screen.reading));
}
