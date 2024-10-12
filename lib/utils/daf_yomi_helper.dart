import 'package:flutter/material.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/books.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

void openDafYomiBook(BuildContext context, String tractate, String daf) async {
  final appModel = Provider.of<AppModel>(context, listen: false);
  final book = await appModel.findBookByTitle(tractate);
  var index = 0;
  if (book != null) {
    if (book is TextBook) {
      final tocEntry = await _findDafInToc(book, daf);
      index = tocEntry?.index ?? 0;
    } else if (book is PdfBook) {
      final outline = await getDafYomiOutline(book, daf);
      index = outline?.dest?.pageNumber ?? 0;
    }
    appModel.openBook(book, index, openLeftPane: true);
  }
}

Future<TocEntry?> _findDafInToc(TextBook book, String daf) async {
  final toc = await book.tableOfContents;
  TocEntry? findDafInEntries(List<TocEntry> entries) {
    for (var entry in entries) {
      String ref = entry.text;
      if (ref.contains('דף ${daf.trim()}')) {
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
      if (ref.contains('דף ${daf.trim()}')) {
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
  final appModel = Provider.of<AppModel>(context, listen: false);
  final book = await appModel.findBookByTitle(bookname);

  if (book != null && book is PdfBook) {
    final outline = await getDafYomiOutline(book, ref);
    appModel.openBook(book, outline?.dest?.pageNumber ?? 0, openLeftPane: true);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('הספר אינו קיים'),
      ),
    );
  }
}
