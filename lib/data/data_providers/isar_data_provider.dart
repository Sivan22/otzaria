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

/// IsarDataProvider manages all database operations using the Isar database.
///
/// This provider handles:
/// - Storage and retrieval of book references
/// - Management of text lines from books
/// - Search operations across references and lines
/// - Progress tracking for database operations
class IsarDataProvider {
  /// Singleton instance of the IsarDataProvider
  static final IsarDataProvider _singleton = IsarDataProvider();

  /// Provides access to the singleton instance
  static IsarDataProvider get instance => _singleton;

  IsarDataProvider();

  /// Isar database instance configured with the library path from settings
  /// and schemas for Refs and Lines collections
  final isar = Isar.open(
    directory: Settings.getValue<String>('key-library-path') ?? 'C:\\אוצריא',
    maxSizeMiB: null,
    schemas: [
      RefSchema,
      LineSchema,
    ],
  );

  /// Notifies listeners about the number of books processed for references
  ValueNotifier<int?> refsNumOfbooksDone = ValueNotifier(null);

  /// Notifies listeners about the total number of books to process for references
  ValueNotifier<int?> refsNumOfbooksTotal = ValueNotifier(null);

  /// Notifies listeners about the number of books processed for lines
  ValueNotifier<int?> linesNumOfbooksDone = ValueNotifier(null);

  /// Notifies listeners about the total number of books to process for lines
  ValueNotifier<int?> linesNumOfbooksTotal = ValueNotifier(null);

  /// Creates references from a library's books and stores them in the database
  ///
  /// This method processes both text books and PDF books, creating references from their
  /// table of contents and storing them in the Isar database. It tracks progress using
  /// value notifiers.
  ///
  /// Parameters:
  ///   - [library]: The library containing books to process
  ///   - [startIndex]: The index to start processing from
  Future<void> createRefsFromLibrary(Library library, int startIndex) async {
    // Clear existing references before creating new ones
    isar.write((isar) => isar.refs.clear());
    int i = 0;
    final allBooks =
        library.getAllBooks().whereType<TextBook>().skip(startIndex);
    refsNumOfbooksTotal.value = allBooks.length;

    // Process text books
    for (TextBook book in allBooks) {
      try {
        print('Creating refs for ${book.title} (${i++}/${allBooks.length})');
        refsNumOfbooksDone.value = i - 1;
        List<Ref> refs = [];
        final List<TocEntry> toc = await book.tableOfContents;

        // Collect all TOC entries recursively with their full path
        List<TocEntry> alltocs = [];

        void searchToc(List<TocEntry> entries) {
          for (final TocEntry entry in entries) {
            alltocs.add(entry);
            // Append parent text to child entries for full context
            for (final child in entry.children) {
              child.text = '${entry.text},${child.text}';
            }
            searchToc(entry.children);
          }
        }

        searchToc(toc);

        // Create references for each title variant
        for (String title in book.extraTitles ?? [book.title]) {
          for (final TocEntry entry in alltocs) {
            final ref = Ref(
                id: isar.refs.autoIncrement(),
                ref: entry.text
                    .replaceAll(book.title, title)
                    .replaceAll('"', '')
                    .replaceAll("'", '')
                    .replaceAll('״', ''),
                bookTitle: book.title,
                index: entry.index,
                pdfBook: false);
            refs.add(ref);
          }
        }
        isar.write((isar) => isar.refs.putAll(refs));
        print('Done creating refs for ${book.title} ');
      } catch (e) {
        print(' Failed creating refs for ${book.title} $e');
      }
    }

    // Process PDF books
    final pdfBooks =
        library.getAllBooks().whereType<PdfBook>().skip(startIndex).toList();
    refsNumOfbooksTotal.value = pdfBooks.length;

    for (int i = 0; i < pdfBooks.length; i++) {
      refsNumOfbooksDone.value = i;
      // Extract PDF outline (table of contents)
      final List<PdfOutlineNode> outlines =
          await PdfDocument.openFile(pdfBooks[i].path)
              .then((value) => value.loadOutline());

      List<PdfOutlineNode> alloutlines = [];

      void searchOutline(List<PdfOutlineNode> entries) {
        for (final PdfOutlineNode entry in entries) {
          alloutlines.add(entry);
          searchOutline(entry.children);
        }
      }

      searchOutline(outlines);

      // Create references from PDF outline
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

    // Reset progress notifiers
    refsNumOfbooksDone.value = null;
    refsNumOfbooksTotal.value = null;
  }

  /// Retrieves all references for a specific book
  ///
  /// Parameters:
  ///   - [book]: The book whose references should be retrieved
  ///
  /// Returns a list of [Ref] objects associated with the book
  List<Ref> getRefsForBook(TextBook book) {
    return isar.refs.where().bookTitleEqualTo(book.title).findAll();
  }

  /// Retrieves all references from the database
  ///
  /// Returns a list of all [Ref] objects stored in the database
  List<Ref> getAllRefs() {
    return isar.refs.where().findAll();
  }

  /// Searches for references containing all parts of the given reference string
  ///
  /// Parameters:
  ///   - [ref]: The reference string to search for
  ///
  /// Returns a [Future] that completes with matching [Ref] objects
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

  /// Searches for references by relevance to a given reference string
  ///
  /// Uses fuzzy matching to find the most relevant references, processing
  /// matches in a separate isolate for better performance.
  ///
  /// Parameters:
  ///   - [ref]: The reference string to search for
  ///   - [limit]: Maximum number of results per book (defaults to 10)
  ///
  /// Returns a [Future] that completes with a list of [Ref] objects sorted by relevance
  Future<List<Ref>> findRefsByRelevance(String ref, {int limit = 10}) async {
    var refs = await findRefs(ref);

    // Process matches in a separate isolate for better performance
    refs = await Isolate.run(() {
      List<Ref> takenRefs = [];
      final gruops = refs.groupBy((ref) => ref.bookTitle);
      // Take top N matches from each book
      for (final gruop in gruops.keys) {
        takenRefs += (gruops[gruop]!.take(limit)).toList();
      }
      // Sort by fuzzy match ratio
      takenRefs.sort((a, b) {
        final scoreA = ratio(ref, a.ref);
        final scoreB = ratio(ref, b.ref);
        return scoreB.compareTo(scoreA);
      });
      return takenRefs;
    });

    return refs;
  }

  /// Gets the number of unique books that have references in the database
  ///
  /// Returns a [Future] that completes with the count of books with references
  Future<int> getNumberOfBooksWithRefs() async {
    final allRefs = await isar.refs.where().findAllAsync();
    final books = await Isolate.run(() {
      return allRefs.groupBy((ref) => ref.bookTitle);
    });
    return books.length;
  }

  /// Adds all lines from all text books in the library to the database
  ///
  /// Parameters:
  ///   - [library]: The library containing books to process
  Future<void> addAllLines(Library library) async {
    final books = library.getAllBooks().whereType<TextBook>().toList();
    linesNumOfbooksTotal.value = books.length;
    linesNumOfbooksDone.value = 0;

    for (TextBook book in books) {
      print('Adding lines for ${book.title}');
      await addLinesForBook(book);
      linesNumOfbooksDone.value = books.indexOf(book) + 1;
    }
  }

  /// Adds all lines from a specific book to the database
  ///
  /// Parameters:
  ///   - [book]: The book whose lines should be added
  Future<void> addLinesForBook(TextBook book) async {
    final texts = (await book.text).split('\n');
    final List<Line> lines = [];

    // Create Line objects for each line of text
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

  /// Retrieves all lines for a specific book
  ///
  /// Parameters:
  ///   - [book]: The book whose lines should be retrieved
  ///
  /// Returns a [Future] that completes with a list of [Line] objects
  Future<List<Line>> getLinesForBook(TextBook book) async {
    return isar.lines.where().bookTitleEqualTo(book.title).findAll();
  }

  /// Retrieves all lines from the database
  ///
  /// Returns a [Future] that completes with a list of all [Line] objects
  Future<List<Line>> getAllLines() async {
    return isar.lines.where().findAll();
  }

  /// Searches for lines containing the given text
  ///
  /// Parameters:
  ///   - [text]: The text to search for within lines
  ///
  /// Returns a [Future] that completes with matching [Line] objects
  Future<List<Line>> findLines(String text) async {
    return isar.lines.where().textContains(text).findAllAsync();
  }
}

/// Extension on [Iterable] to add grouping functionality
///
/// Provides a [groupBy] method that groups elements by a key function,
/// similar to SQL GROUP BY or LINQ GroupBy.
extension Iterables<E> on Iterable<E> {
  /// Groups elements by a key function
  ///
  /// Parameters:
  ///   - [keyFunction]: Function that extracts the grouping key from an element
  ///
  /// Returns a [Map] where keys are the grouping keys and values are lists of
  /// elements that share that key
  Map<K, List<E>> groupBy<K>(K Function(E) keyFunction) => fold(
      <K, List<E>>{},
      (Map<K, List<E>> map, E element) =>
          map..putIfAbsent(keyFunction(element), () => <E>[]).add(element));
}
