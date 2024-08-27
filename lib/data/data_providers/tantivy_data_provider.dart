import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:search_engine/search_engine.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/library.dart';
import 'package:pdfrx/pdfrx.dart';

class TantivyDataProvider {
  static final TantivyDataProvider _singleton = TantivyDataProvider();
  static TantivyDataProvider instance = _singleton;

  ValueNotifier<int?> numOfbooksDone = ValueNotifier(null);
  ValueNotifier<int?> numOfbooksTotal = ValueNotifier(null);
  ValueNotifier<bool> isIndexing = ValueNotifier(false);
  late List booksDone;

  TantivyDataProvider() {
    booksDone = Settings.getValue<List>(
          'key-books-done',
        ) ??
        [];
  }

  saveBooksDoneToDisk() {
    Settings.setValue('key-books-done', booksDone);
  }

  final engine = SearchEngine.newInstance(
      path: (Settings.getValue('key-library-path') ?? 'C:/אוצריא') +
          Platform.pathSeparator +
          'index');

  Future<List<SearchResult>> searchTexts(
      String query, List<String> books, int limit) async {
    final index = await engine;
    return await index.search(query: query, books: books, limit: limit);
  }

  Stream<List<SearchResult>> searchTextsStream(
      String query, List<String> books, int limit) async* {
    final index = await engine;
    yield* index.searchStream(query: query, books: books, limit: limit);
  }

  addAllTBooksToTantivy(Library library,
      {int start = 0, int end = 100000}) async {
    isIndexing.value = true;
    var allBooks = library.getAllBooks();
    allBooks = allBooks.getRange(start, min(end, allBooks.length)).toList();

    numOfbooksTotal.value = allBooks.length;
    numOfbooksDone.value = 0;

    for (Book book in allBooks) {
      if (!isIndexing.value) {
        return;
      }
      print('Adding ${book.title} to index');
      try {
        if (book is TextBook) {
          await addTextsToTantivy(book);
        } else if (book is PdfBook) {
          await addPdfTextsToMimir(book);
        }
      } catch (e) {
        print('Error adding ${book.title} to index: $e');
      }
    }

    numOfbooksDone.value = null;
    numOfbooksTotal.value = null;
  }

  addTextsToTantivy(TextBook book) async {
    final index = await engine;
    final text = await book.text;
    final title = book.title;

    final hash = sha1.convert(utf8.encode(text)).toString();
    if (booksDone.contains(hash)) {
      print('${book.title} already in index');
      numOfbooksDone.value = numOfbooksDone.value! + 1;
      return;
    }

    final texts = text.split('\n');
    for (int i = 0; i < texts.length; i++) {
      if (!isIndexing.value) {
        return;
      }
      index.addDocument(
          id: BigInt.from(hashCode + i),
          title: title,
          text: texts[i],
          segment: BigInt.from(i),
          isPdf: false,
          filePath: '');
    }
    await index.commit();
    booksDone.add(hash);
    saveBooksDoneToDisk();
    print('Added ${book.title} to index');
    numOfbooksDone.value = numOfbooksDone.value! + 1;
  }

  addPdfTextsToMimir(PdfBook book) async {
    final index = await engine;
    final data = await File(book.path).readAsBytes();
    final hash = sha1.convert(data).toString();
    if (booksDone.contains(hash)) {
      print('${book.title} already in index');
      numOfbooksDone.value = numOfbooksDone.value! + 1;
      return;
    }
    final pages = await PdfDocument.openData(data).then((value) => value.pages);
    final title = book.title;
    for (int i = 0; i < pages.length; i++) {
      final texts = (await pages[i].loadText()).fullText.split('\n');
      for (int j = 0; j < texts.length; j++) {
        if (!isIndexing.value) {
          return;
        }
        index.addDocument(
            id: BigInt.from(hashCode + i + j),
            title: title,
            text: texts[j],
            segment: BigInt.from(i),
            isPdf: true,
            filePath: book.path);
      }
    }
    await index.commit();
    booksDone.add(hash);
    saveBooksDoneToDisk();
    print('Added ${book.title} to index');
    numOfbooksDone.value = numOfbooksDone.value! + 1;
  }
}
