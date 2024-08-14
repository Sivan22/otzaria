import 'package:isar/isar.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/isar_collections/ref.dart';
import 'package:otzaria/models/library.dart';
import 'package:pdfrx/pdfrx.dart';

Future<void> createRefsFromLibrary(Library library, Isar isar) async {
  int i = 0;
  final allBooks = library.getAllBooks().whereType<TextBook>();
  for (TextBook book in allBooks) {
    i = 1;
    print('Creating refs for ${book.title} (${i++}/${allBooks.length})');
    final List<TocEntry> toc = await book.tableOfContents;
    //get all TocEntries recursively
    List<TocEntry> alltocs = [];

    void searchToc(List<TocEntry> entries) {
      for (final TocEntry entry in entries) {
        alltocs.add(entry);
        for (final child in entry.children) {
          child.text = '${entry.text},${child.text}';
        }
        searchToc(entry.children);
      }
    }

    searchToc(toc);
    for (final TocEntry entry in alltocs) {
      final ref = Ref(
        id: isar.refs.autoIncrement(),
        ref: entry.text.replaceAll('\n', ''),
        bookTitle: book.title,
        index: entry.index,
      );

      isar.write((isar) => isar.refs.put(ref));
    }
  }

  for (PdfBook book in library.getAllBooks().whereType<PdfBook>()) {
    final List<PdfOutlineNode> outlines = await PdfDocument.openFile(book.path)
        .then((value) => value.loadOutline());

    //get all TocEntries recursively
    List<PdfOutlineNode> alloutlines = [];

    void searchOutline(List<PdfOutlineNode> entries) {
      for (final PdfOutlineNode entry in entries) {
        alloutlines.add(entry);
        searchOutline(entry.children);
      }
    }

    searchOutline(outlines);

    for (final PdfOutlineNode entry in alloutlines) {
      final ref = Ref(
        id: isar.refs.autoIncrement(),
        ref: entry.title.replaceAll('\n', ''),
        bookTitle: book.title,
        index: entry.dest?.pageNumber ?? 0,
      );
      print('Adding Pdf ref: ${ref.ref}');
      isar.write((isar) => isar.refs.put(ref));
    }
  }
}
