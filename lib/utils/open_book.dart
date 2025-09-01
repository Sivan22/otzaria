import 'package:flutter/material.dart';
import 'package:otzaria/history/bloc/history_bloc.dart';
import 'package:otzaria/history/bloc/history_event.dart';
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
import 'package:collection/collection.dart';

void openBook(BuildContext context, Book book, int index, String searchQuery,
    {bool ignoreHistory = false}) {
  print('DEBUG: פתיחת ספר - ${book.title}, אינדקס: $index');

  // שמירת המצב הנוכחי לפני פתיחת ספר חדש כדי למנוע בלבול במיקום
  final tabsState = context.read<TabsBloc>().state;
  if (tabsState.hasOpenTabs) {
    print('DEBUG: שמירת מצב הטאב הנוכחי לפני פתיחת ספר חדש');
    context
        .read<HistoryBloc>()
        .add(CaptureStateForHistory(tabsState.currentTab!));
  }

  final historyState = context.read<HistoryBloc>().state;
  final lastOpened = ignoreHistory
      ? null
      : historyState.history
          .firstWhereOrNull((b) => b.book.title == book.title);

  // אם ignoreHistory=true או האינדקס שהועבר הוא מחושב ממעבר בין תצוגות, השתמש בו תמיד
  // רק אם האינדקס הוא 0 (ברירת מחדל) ולא ignoreHistory, השתמש בהיסטוריה
  final int initialIndex =
      (ignoreHistory || index != 0) ? index : (lastOpened?.index ?? 0);
  final List<String>? initialCommentators = lastOpened?.commentatorsToShow;

  print(
      'DEBUG: אינדקס סופי לטאב: $initialIndex (מועבר: $index, מהיסטוריה: ${lastOpened?.index})');

  final bool shouldOpenLeftPane =
      (Settings.getValue<bool>('key-pin-sidebar') ?? false) ||
          (Settings.getValue<bool>('key-default-sidebar-open') ?? false);

  if (book is TextBook) {
    print('DEBUG: יצירת טאב טקסט עם אינדקס: $initialIndex');
    context.read<TabsBloc>().add(AddTab(TextBookTab(
          book: book,
          index: initialIndex,
          searchText: searchQuery,
          commentators: initialCommentators,
          openLeftPane: shouldOpenLeftPane,
        )));
  } else if (book is PdfBook) {
    print('DEBUG: יצירת טאב PDF עם דף: $initialIndex');
    context.read<TabsBloc>().add(AddTab(PdfBookTab(
          book: book,
          pageNumber: initialIndex,
          openLeftPane: shouldOpenLeftPane,
        )));
  }

  context.read<NavigationBloc>().add(const NavigateToScreen(Screen.reading));
}
