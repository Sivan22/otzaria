import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/library/bloc/library_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_event.dart';
import 'package:otzaria/navigation/bloc/navigation_state.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_event.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/tabs/models/pdf_tab.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:pdfrx/pdfrx.dart';

void openDafYomiBook(BuildContext context, String tractate, String daf) async {
  final libraryBlocState = BlocProvider.of<LibraryBloc>(context).state;
  final book = libraryBlocState.library?.findBookByTitle(tractate, null);
  var index = 0;
  if (book != null) {
    if (book is TextBook) {
      final tocEntry = await _findDafInToc(book, 'דף ${daf.trim()}');
      index = tocEntry?.index ?? 0;
      final tab = TextBookTab(book: book, index: index, openLeftPane: true);
      BlocProvider.of<TabsBloc>(context).add(AddTab(tab));
    } else if (book is PdfBook) {
      final outline = await getDafYomiOutline(book, 'דף ${daf.trim()}');
      index = outline?.dest?.pageNumber ?? 0;
      final tab = PdfBookTab(
        book: book,
        initialPage: index,
      );
      BlocProvider.of<TabsBloc>(context).add(AddTab(tab));
    }
    BlocProvider.of<NavigationBloc>(context)
        .add(NavigateToScreen(Screen.reading));
  }
}

Future<TocEntry?> _findDafInToc(TextBook book, String daf) async {
  final toc = await book.tableOfContents;
  TocEntry? findDafInEntries(List<TocEntry> entries) {
    for (var entry in entries) {
      String ref = entry.text;
      if (ref.contains(daf)) {
        return entry;
      }
      // Recursively search in children
      TocEntry? result = findDafInEntries(entry.children);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  return findDafInEntries(toc);
}

Future<PdfOutlineNode?> getDafYomiOutline(PdfBook book, String daf) async {
  final outlines = await PdfDocument.openFile(book.path)
      .then((value) => value.loadOutline());
  PdfOutlineNode? findDafInEntries(List<PdfOutlineNode> entries) {
    for (var entry in entries) {
      String ref = entry.title;
      if (daf.contains(ref)) {
        return entry;
      }
      // Recursively search in children
      PdfOutlineNode? result = findDafInEntries(entry.children);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  return findDafInEntries(outlines);
}

openPdfBookFromRef(String bookname, String ref, BuildContext context) async {
  final libraryBlocState = BlocProvider.of<LibraryBloc>(context).state;
  final book =
      libraryBlocState.library?.findBookByTitle(bookname, PdfBook) as PdfBook?;

  if (book != null) {
    final outline = await getDafYomiOutline(book, ref);
    if (outline != null) {
      final tab = PdfBookTab(
        book: book,
        initialPage: outline.dest?.pageNumber ?? 0,
      );
      BlocProvider.of<TabsBloc>(context).add(AddTab(tab));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Section not found'),
        ),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('הספר אינו קיים'),
      ),
    );
  }
}

openTextBookFromRef(String bookname, String ref, BuildContext context) async {
  final libraryBlocState = BlocProvider.of<LibraryBloc>(context).state;
  final book = libraryBlocState.library?.findBookByTitle(bookname, TextBook)
      as TextBook?;

  if (book != null) {
    final tocEntry = await _findDafInToc(book, ref);
    if (tocEntry != null) {
      final tab = TextBookTab(
          book: book, index: tocEntry.index ?? 0, openLeftPane: true);
      BlocProvider.of<TabsBloc>(context).add(AddTab(tab));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Section not found'),
        ),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('הספר אינו קיים'),
      ),
    );
  }
}
