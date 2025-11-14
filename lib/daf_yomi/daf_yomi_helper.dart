import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/library/bloc/library_bloc.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/library/models/library.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:otzaria/utils/open_book.dart';
import 'package:otzaria/core/scaffold_messenger.dart';
import 'package:otzaria/i18n/translations.g.dart';

// Generic tree search for outlines
typedef EntryTextGetter<T> = String Function(T entry);
typedef ChildrenGetter<T> = Future<List<T>> Function(T entry);

Future<T?> findEntryInTree<T>(Future<List<T>> rootEntries, String daf,
    EntryTextGetter<T> getText, ChildrenGetter<T> getChildren) async {
  final entries = await rootEntries;
  for (var entry in entries) {
    String ref = getText(entry);
    if (ref.contains(daf)) {
      return entry;
    }
    T? result =
        await findEntryInTree(getChildren(entry), daf, getText, getChildren);
    if (result != null) return result;
  }
  return null;
}

void openDafYomiBook(BuildContext context, String tractate, String daf,
    {String categoryName = 'תלמוד בבלי'}) async {
  _openDafYomiBookInCategory(context, tractate, daf, categoryName);
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
      UiSnack.showError('לא נמצאה קטגוריה: $categoryName',
          backgroundColor: Theme.of(context).colorScheme.error);
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
    UiSnack.showError(
        'לא נמצא ספר: $tractate ב$categoryName\nספרים זמינים: $availableBooks...',
        backgroundColor: Theme.of(context).colorScheme.error);
  }
}

Future<void> _openBook(BuildContext context, Book book, String daf) async {
  final index = await findReference(book, 'דף ${daf.trim()}') ?? 0;
  if (!context.mounted) return;
  openBook(context, book, index, '', ignoreHistory: true);
}

Future<int?> findReference(Book book, String ref) async {
  if (book is TextBook) {
    final tocEntry = await _findDafInToc(book, ref);
    return tocEntry?.index;
  } else if (book is PdfBook) {
    final outline = await getDafYomiOutline(book, ref);
    return outline?.dest?.pageNumber;
  }
  return null;
}

Future<TocEntry?> _findDafInToc(TextBook book, String daf) async {
  final toc = await book.tableOfContents;
  return await findEntryInTree(
    Future.value(toc),
    daf,
    (entry) => entry.text,
    (entry) => Future.value(entry.children),
  );
}

Future<PdfOutlineNode?> getDafYomiOutline(PdfBook book, String daf) async {
  final outlines = await PdfDocument.openFile(book.path)
      .then((value) => value.loadOutline());
  return await findEntryInTree(
    Future.value(outlines),
    daf,
    (entry) => entry.title,
    (entry) => Future.value(entry.children),
  );
}

openPdfBookFromRef(String bookname, String ref, BuildContext context) async {
  await _openBookFromRefHelper(bookname, ref, context, PdfBook);
}

openTextBookFromRef(String bookname, String ref, BuildContext context) async {
  await _openBookFromRefHelper(bookname, ref, context, TextBook);
}

Future<void> _openBookFromRefHelper(
    String bookname, String ref, BuildContext context, Type bookType) async {
  final libraryBlocState = BlocProvider.of<LibraryBloc>(context).state;
  final book = libraryBlocState.library?.findBookByTitle(bookname, bookType);

  if (book != null) {
    final index = await findReference(book, ref);
    if (!context.mounted) return;
    if (index != null) {
      openBook(context, book, index, '', ignoreHistory: true);
    } else {
      UiSnack.showError(context.t.messages.sectionNotFound);
    }
  } else {
    UiSnack.showError(context.t.messages.bookNotFound);
  }
}
