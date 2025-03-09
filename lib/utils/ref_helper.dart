import 'package:isar/isar.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/isar_collections/ref.dart';
import 'package:otzaria/library/models/library.dart';
import 'package:pdfrx/pdfrx.dart';

Future<void> createRefsFromLibrary(
    Library library, Isar isar, int startIndex) async {
  final allBooks = library.getAllBooks().whereType<TextBook>().skip(startIndex);
  for (TextBook book in allBooks) {
    List<Ref> refs = [];
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
          ref: entry.text
              .replaceAll('"', '')
              .replaceAll("'", '')
              .replaceAll('״', ''),
          bookTitle: book.title,
          index: entry.index,
          pdfBook: false);
      refs.add(ref);
    }
    isar.write((isar) => isar.refs.putAll(refs));
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
          pdfBook: true);
      isar.write((isar) => isar.refs.put(ref));
    }
  }
}

Future<String> refFromIndex(
    int index, Future<List<TocEntry>> tableOfContents) async {
  List<TocEntry> toc = await tableOfContents;
  List<String> texts = [];

  void searchToc(List<TocEntry> entries, int index) {
    for (final TocEntry entry in entries) {
      if (entry.index > index) {
        return;
      }
      if (entry.level > texts.length) {
        texts.add(entry.text);
      } else {
        texts[entry.level - 1] = entry.text;
        texts = texts.getRange(0, entry.level).toList();
      }

      searchToc(entry.children, index);
    }
  }

  searchToc(toc, index);

  texts = texts.map((e) => e.trim()).toList();
  return texts.join(', ');
}
