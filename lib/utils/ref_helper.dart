import 'package:isar/isar.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/isar_collections/ref.dart';
import 'package:otzaria/models/library.dart';

Future<void> createRefsFromLibrary(Library library, Isar isar) async {
  for (TextBook book in library.getAllBooks().whereType<TextBook>()) {
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
      print('Adding ref: ${ref.ref}');
      isar.write((isar) => isar.refs.put(ref));
    }
  }
}
