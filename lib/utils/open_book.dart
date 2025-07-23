import 'package:flutter/material.dart';
import 'package:otzaria/history/bloc/history_bloc.dart';
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

void openBook(BuildContext context, Book book, int index, String searchQuery) {
  final historyState = context.read<HistoryBloc>().state;
  final lastOpened = historyState.history
      .firstWhereOrNull((b) => b.book.title == book.title);
  
  final int initialIndex = lastOpened?.index ?? index;
  final List<String>? initialCommentators = lastOpened?.commentatorsToShow;

  final bool shouldOpenLeftPane =
      (Settings.getValue<bool>('key-pin-sidebar') ?? false) ||
      (Settings.getValue<bool>('key-default-sidebar-open') ?? false);

  if (book is TextBook) {
    context.read<TabsBloc>().add(AddTab(TextBookTab(
          book: book,
          index: initialIndex,
          searchText: searchQuery,
          commentators: initialCommentators,
          openLeftPane: shouldOpenLeftPane,
        )));
  } else if (book is PdfBook) {
    context.read<TabsBloc>().add(AddTab(PdfBookTab(
          book: book,
          pageNumber: initialIndex,
          openLeftPane: shouldOpenLeftPane,
        )));
  }

  context.read<NavigationBloc>().add(const NavigateToScreen(Screen.reading));
}
