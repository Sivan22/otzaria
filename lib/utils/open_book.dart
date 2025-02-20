import 'package:flutter/material.dart';
import 'package:otzaria/bloc/navigation/navigation_bloc.dart';
import 'package:otzaria/bloc/navigation/navigation_event.dart';
import 'package:otzaria/bloc/navigation/navigation_state.dart';
import 'package:otzaria/bloc/tabs/tabs_bloc.dart';
import 'package:otzaria/bloc/tabs/tabs_event.dart';
import 'package:otzaria/models/books.dart';
import "package:flutter_bloc/flutter_bloc.dart";
import 'package:otzaria/models/tabs/pdf_tab.dart';
import 'package:otzaria/models/tabs/text_tab.dart';

void openBook(BuildContext context, Book book, int index, String searchQuery) {
  if (book is TextBook) {
    context.read<TabsBloc>().add(
        AddTab(TextBookTab(book: book, index: index, searchText: searchQuery)));
  } else if (book is PdfBook) {
    context
        .read<TabsBloc>()
        .add(AddTab(PdfBookTab(book, index, searchText: searchQuery)));
  }
  context.read<NavigationBloc>().add(NavigateToScreen(Screen.reading));
}
