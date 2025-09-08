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
import 'package:otzaria/library/models/library.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

void openDafYomiBook(BuildContext context, String tractate, String daf) async {
  _openDafYomiBookInCategory(context, tractate, daf, 'תלמוד בבלי');
}

void openDafYomiYerushalmiBook(
    BuildContext context, String tractate, String daf) async {
  _openDafYomiBookInCategory(context, tractate, daf, 'תלמוד ירושלמי');
}

void _openDafYomiBookInCategory(BuildContext context, String tractate,
    String daf, String categoryName) async {
  final libraryBlocState = BlocProvider.of<LibraryBloc>(context).state;
  final library = libraryBlocState.library;

  if (library == null) return;

  // מחפש את הקטגוריה הרלוונטית
  Category? talmudCategory;
  for (var category in library.getAllCategories()) {
    if (category.title == categoryName) {
      talmudCategory = category;
      break;
    }
  }

  if (talmudCategory == null) {
    // נסה לחפש בכל הקטגוריות אם לא נמצאה הקטגוריה הספציפית
    final allBooks = library.getAllBooks();
    Book? book;

    // חיפוש מדויק יותר - גם בשם המלא וגם בחיפוש חלקי
    for (var bookInLibrary in allBooks) {
      if (bookInLibrary.title == tractate ||
          bookInLibrary.title.contains(tractate) ||
          tractate.contains(bookInLibrary.title)) {
        // בדוק אם הספר נמצא בקטגוריה הנכונה על ידי בדיקת הקטגוריה
        if (bookInLibrary.category?.title == categoryName) {
          book = bookInLibrary;
          break;
        }
      }
    }

    if (book == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('לא נמצאה קטגוריה: $categoryName')),
      );
      return;
    } else {
      // נמצא ספר, נמשיך עם הפתיחה
      await _openBook(context, book, daf);
      return;
    }
  }

  // מחפש את הספר בקטגוריה הספציפית
  Book? book;
  final allBooksInCategory = talmudCategory.getAllBooks();

  // חיפוש מדויק יותר
  for (var bookInCategory in allBooksInCategory) {
    if (bookInCategory.title == tractate ||
        bookInCategory.title.contains(tractate) ||
        tractate.contains(bookInCategory.title)) {
      book = bookInCategory;
      break;
    }
  }

  if (book != null) {
    await _openBook(context, book, daf);
  } else {
    // הצג רשימת ספרים זמינים לדיבוג
    final availableBooks =
        allBooksInCategory.map((b) => b.title).take(5).join(', ');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'לא נמצא ספר: $tractate ב$categoryName\nספרים זמינים: $availableBooks...'),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

Future<void> _openBook(BuildContext context, Book book, String daf) async {
  var index = 0;

  if (book is TextBook) {
    final tocEntry = await _findDafInToc(book, 'דף ${daf.trim()}');
    index = tocEntry?.index ?? 0;
    final tab = TextBookTab(
      book: book,
      index: index,
      openLeftPane: (Settings.getValue<bool>('key-pin-sidebar') ?? false) ||
          (Settings.getValue<bool>('key-default-sidebar-open') ?? false),
    );
    BlocProvider.of<TabsBloc>(context).add(AddTab(tab));
  } else if (book is PdfBook) {
    final outline = await getDafYomiOutline(book, 'דף ${daf.trim()}');
    index = outline?.dest?.pageNumber ?? 0;
    final tab = PdfBookTab(
      book: book,
      pageNumber: index,
      openLeftPane: (Settings.getValue<bool>('key-pin-sidebar') ?? false) ||
          (Settings.getValue<bool>('key-default-sidebar-open') ?? false),
    );
    BlocProvider.of<TabsBloc>(context).add(AddTab(tab));
  }

  BlocProvider.of<NavigationBloc>(context)
      .add(const NavigateToScreen(Screen.reading));
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
        pageNumber: outline.dest?.pageNumber ?? 0,
        openLeftPane: (Settings.getValue<bool>('key-pin-sidebar') ?? false) ||
            (Settings.getValue<bool>('key-default-sidebar-open') ?? false),
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
        book: book,
        index: tocEntry.index,
        openLeftPane: (Settings.getValue<bool>('key-pin-sidebar') ?? false) ||
            (Settings.getValue<bool>('key-default-sidebar-open') ?? false),
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
