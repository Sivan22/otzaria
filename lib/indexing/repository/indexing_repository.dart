import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/library/models/library.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:otzaria/utils/ref_helper.dart';

class IndexingRepository {
  final TantivyDataProvider _tantivyDataProvider;

  IndexingRepository(this._tantivyDataProvider);

  /// Indexes all books in the provided library.
  ///
  /// [library] The library containing books to index
  /// [onProgress] Callback function to report progress
  Future<void> indexAllBooks(
    Library library,
    void Function(int processed, int total) onProgress,
  ) async {
    _tantivyDataProvider.isIndexing.value = true;
    final allBooks = library.getAllBooks();
    final totalBooks = allBooks.length;
    int processedBooks = 0;

    for (Book book in allBooks) {
      // Check if indexing was cancelled
      if (!_tantivyDataProvider.isIndexing.value) {
        return;
      }

      try {
        // Check if this book has already been indexed
        if (book is TextBook) {
          if (!_tantivyDataProvider.booksDone
              .contains("${book.title}textBook")) {
            final bookText = await book.text;
            final bookTextHash = await Isolate.run(() {
              // Don't access book.text in isolate - just do the hash calculation
              return sha1.convert(utf8.encode(bookText)).toString();
            });
            if (_tantivyDataProvider.booksDone.contains(bookTextHash)) {
              _tantivyDataProvider.booksDone.add("${book.title}textBook");
            } else {
              await _indexTextBook(book.title, book.topics, bookText);
              _tantivyDataProvider.booksDone.add("${book.title}textBook");
            }
          }
        } else if (book is PdfBook) {
          if (!_tantivyDataProvider.booksDone
              .contains("${book.title}pdfBook")) {
            final bookPath = book.path;
            final pdfFileHash = await Isolate.run(() async {
              // Don't access book.path in isolate - just do the hash calculation
              final fileBytes = await File(bookPath).readAsBytes();
              return sha1.convert(fileBytes).toString();
            });
            if (_tantivyDataProvider.booksDone.contains(pdfFileHash)) {
              _tantivyDataProvider.booksDone.add("${book.title}pdfBook");
            } else {
              await _indexPdfBook(book);
              _tantivyDataProvider.booksDone.add("${book.title}pdfBook");
            }
          }
        }

        processedBooks++;
        // Report progress
        onProgress(processedBooks, totalBooks);
      } catch (e) {
        debugPrint('Error adding ${book.title} to index: $e');
        processedBooks++;
      }
    }

    // Reset indexing flag after completion
    _tantivyDataProvider.isIndexing.value = false;
  }

  /// Indexes a text-based book by processing its content and adding it to the search index and reference index.
  Future<void> _indexTextBook(
      String title, String bookTopics, String text) async {
    final index = await _tantivyDataProvider.engine;
    final refIndex = _tantivyDataProvider.refEngine;
    final topics = "/${bookTopics.replaceAll(', ', '/')}";

    final texts = text.split('\n');
    List<String> reference = [];

    // Index each line separately
    for (int i = 0; i < texts.length; i++) {
      if (!_tantivyDataProvider.isIndexing.value) {
        return;
      }

      String line = texts[i];
      // get the reference from the headers
      if (line.startsWith('<h')) {
        if (reference.isNotEmpty &&
            reference.any(
                (element) => element.substring(0, 4) == line.substring(0, 4))) {
          reference.removeRange(
              reference.indexWhere(
                  (element) => element.substring(0, 4) == line.substring(0, 4)),
              reference.length);
        }
        reference.add(line);

        // Index the header as a reference
        String refText = stripHtmlIfNeeded(reference.join(" "));
        final shortref = replaceParaphrases(removeSectionNames(refText));

        refIndex.addDocument(
            id: BigInt.from(DateTime.now().microsecondsSinceEpoch),
            title: title,
            reference: refText,
            shortRef: shortref,
            segment: BigInt.from(i),
            isPdf: false,
            filePath: '');
      } else {
        line = stripHtmlIfNeeded(line);
        line = removeVolwels(line);

        // Add to search index
        index.addDocument(
            id: BigInt.from(DateTime.now().microsecondsSinceEpoch),
            title: title,
            reference: stripHtmlIfNeeded(reference.join(', ')),
            topics: '$topics/$title',
            text: line,
            segment: BigInt.from(i),
            isPdf: false,
            filePath: '');
      }
    }

    await index.commit();
    await refIndex.commit();
    saveIndexedBooks();
  }

  /// Indexes a PDF book by extracting and processing text from each page.
  Future<void> _indexPdfBook(PdfBook book) async {
    final index = await _tantivyDataProvider.engine;

    // Extract text from each page
    final document = await PdfDocument.openFile(book.path);
    final pages = document.pages;
    final outline = await document.loadOutline();
    final title = book.title;
    final topics = "/${book.topics.replaceAll(', ', '/')}";

    // Process each page
    for (int i = 0; i < pages.length; i++) {
      final pageText = (await pages[i].loadText()).fullText;
      final texts = pageText.split('\n');
      // Index each line from the page
      for (int j = 0; j < texts.length; j++) {
        if (!_tantivyDataProvider.isIndexing.value) {
          return;
        }
        final bookmark = await refFromPageNumber(i + 1, outline, title);
        final ref = bookmark.isNotEmpty
            ? '$title, $bookmark, עמוד ${i + 1}'
            : '$title, עמוד ${i + 1}';
        index.addDocument(
            id: BigInt.from(DateTime.now().microsecondsSinceEpoch),
            title: title,
            reference: ref,
            topics: '$topics/$title',
            text: texts[j],
            segment: BigInt.from(i),
            isPdf: true,
            filePath: book.path);
      }
    }

    await index.commit();
    saveIndexedBooks();
  }

  /// Cancels the ongoing indexing process.
  void cancelIndexing() {
    _tantivyDataProvider.isIndexing.value = false;
  }

  /// Persists the list of indexed books to disk.
  void saveIndexedBooks() {
    _tantivyDataProvider.saveBooksDoneToDisk();
  }

  /// Clears the index and resets the list of indexed books.
  Future<void> clearIndex() async {
    _tantivyDataProvider.clear();
  }

  /// Gets the list of books that have already been indexed.
  List<String> getIndexedBooks() {
    return List<String>.from(_tantivyDataProvider.booksDone);
  }

  /// Checks if indexing is currently in progress.
  bool isIndexing() {
    return _tantivyDataProvider.isIndexing.value;
  }
}
