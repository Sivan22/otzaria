import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:isar/isar.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/isar_collections/line.dart';
import 'package:otzaria/models/isar_collections/ref.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:otzaria/models/library.dart';
import 'package:pdfrx/pdfrx.dart';

class IsarDataProvider {
  static final IsarDataProvider _singleton = IsarDataProvider();
  static IsarDataProvider get instance => _singleton;

  IsarDataProvider();

  final isar = Isar.open(
    directory: Settings.getValue<String>('key-library-path') ?? 'C:\\אוצריא',
    maxSizeMiB: 100000,
    schemas: [
      RefSchema,
      LineSchema,
    ],
  );
  ValueNotifier<int?> refsNumOfbooksDone = ValueNotifier(null);
  ValueNotifier<int?> refsNumOfbooksTotal = ValueNotifier(null);
  ValueNotifier<int?> linesNumOfbooksDone = ValueNotifier(null);
  ValueNotifier<int?> linesNumOfbooksTotal = ValueNotifier(null);

  Future<void> createRefsFromLibrary(Library library, int startIndex) async {
    isar.write((isar) => isar.refs.clear());
    int i = 0;
    final allBooks =
        library.getAllBooks().whereType<TextBook>().skip(startIndex);
    refsNumOfbooksTotal.value = allBooks.length;
    for (TextBook book in allBooks) {
      try {
        print('Creating refs for ${book.title} (${i++}/${allBooks.length})');
        refsNumOfbooksDone.value = i - 1;
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
        print('Done creating refs for ${book.title} ');
      } catch (e) {
        print(' Failed creating refs for ${book.title} $e');
      }
    }
    final pdfBooks =
        library.getAllBooks().whereType<PdfBook>().skip(startIndex).toList();
    refsNumOfbooksTotal.value = pdfBooks.length;
    for (int i = 0; i < pdfBooks.length; i++) {
      refsNumOfbooksDone.value = i;
      final List<PdfOutlineNode> outlines =
          await PdfDocument.openFile(pdfBooks[i].path)
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
          ref: "${pdfBooks[i].title} ${entry.title}",
          bookTitle: pdfBooks[i].title,
          index: entry.dest?.pageNumber ?? 0,
          pdfBook: true,
          pdfPath: pdfBooks[i].path,
        );
        print('Adding Pdf ref: ${ref.ref}');
        isar.write((isar) => isar.refs.put(ref));
      }
    }
    refsNumOfbooksDone.value = null;
    refsNumOfbooksTotal.value = null;
  }

  List<Ref> getRefsForBook(TextBook book) {
    return isar.refs.where().bookTitleEqualTo(book.title).findAll();
  }

  List<Ref> getAllRefs() {
    return isar.refs.where().findAll();
  }

  Future<List<Ref>> findRefs(String ref) {
    final parts = ref.split(' ');
    return isar.refs
        .where()
        .allOf(
          parts,
          (q, element) => q.refContains(element),
        )
        .findAllAsync();
  }

  Future<List<Ref>> findRefsByRelevance(String ref, {int limit = 10}) async {
    var refs = await findRefs(ref);
    // reduce the number of refs by taking the top N of each book
    refs = await Isolate.run(() {
      List<Ref> takenRefs = [];
      final gruops = refs.groupBy((ref) => ref.bookTitle);
      for (final gruop in gruops.keys) {
        takenRefs += (gruops[gruop]!.take(limit)).toList();
      }
      takenRefs.sort((a, b) {
        final scoreA = ratio(ref, a.ref);
        final scoreB = ratio(ref, b.ref);
        return scoreB.compareTo(scoreA);
      });
      return takenRefs;
    });

    // sort by ratio

    return refs;
  }

  Future<int> getNumberOfBooksWithRefs() async {
    final allRefs = isar.refs.where().findAll();
    final books = allRefs.groupBy((ref) => ref.bookTitle);
    return books.length;
  }

  Future<void> addAllLines(Library library) async {
    final books = library.getAllBooks().whereType<TextBook>().toList();
    linesNumOfbooksTotal.value = books.length;
    linesNumOfbooksDone.value = 0;

    for (TextBook book in books) {
      await addLinesForBook(book);
      linesNumOfbooksDone.value = books.indexOf(book) + 1;
    }
  }

  Future<void> addLinesForBook(TextBook book) async {
    final texts = (await book.text).split('\n');
    final List<Line> lines = [];

    for (int i = 0; i < texts.length; i++) {
      final line = Line(
        id: isar.lines.autoIncrement(),
        text: texts[i],
        bookTitle: book.title,
        topics: book.topics,
        index: i,
      );

      lines.add(line);
    }

    isar.write((isar) => isar.lines.putAll(lines));
  }

  Future<List<Line>> getLinesForBook(TextBook book) async {
    return isar.lines.where().bookTitleEqualTo(book.title).findAll();
  }

  Future<List<Line>> getAllLines() async {
    return isar.lines.where().findAll();
  }

  Future<List<Line>> findLines(String text) async {
    return isar.lines.where().textContains(text).findAllAsync();
  }
}

extension Iterables<E> on Iterable<E> {
  Map<K, List<E>> groupBy<K>(K Function(E) keyFunction) => fold(
      <K, List<E>>{},
      (Map<K, List<E>> map, E element) =>
          map..putIfAbsent(keyFunction(element), () => <E>[]).add(element));
}
