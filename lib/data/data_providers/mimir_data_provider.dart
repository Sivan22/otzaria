import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_mimir/flutter_mimir.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/library.dart';
import 'package:pdfrx/pdfrx.dart';

class MimirDataProvider {
  static final MimirDataProvider _singleton = MimirDataProvider();
  static MimirDataProvider instance = _singleton;

  ValueNotifier<int?> numOfbooksDone = ValueNotifier(null);
  ValueNotifier<int?> numOfbooksTotal = ValueNotifier(null);
  ValueNotifier<bool> isIndexing = ValueNotifier(false);
  late List booksDone;

  MimirDataProvider() {
    booksDone = Settings.getValue<List>(
          'key-books-done',
        ) ??
        [];
  }

  saveBooksDoneToDisk() {
    Settings.setValue('key-books-done', booksDone);
  }

  Future<MimirIndex> textsIndex = () async {
    final instance = await Mimir.getInstanceForPath(
        Settings.getValue('key-library-path') ?? 'C:/אוצריא');
    final textsIndex = instance.getIndex(
      'texts',
    );
    final currSettings = await textsIndex.getSettings();
    await textsIndex.setSettings(currSettings.copyWith(
      // The primary key (PK) is the "ID field" of documents added to mimir.
      // When null, it is automatically inferred for you, but sometimes you may
      // need to specify it manually. See the Important Caveats section for more.
      primaryKey: 'id',
      // Fields in documents that are included in full-text search.
      // Use null, the default, to search all fields
      searchableFields: <String>['text'],
      // Fields in documents that can be queried/filtered by.
      // You probably don't need to change this; it is automatically
      // updated for you.
      filterableFields: <String>['title'],
      // Fields in documents that can be sorted by in searches/queries.
      // You probably don't need to change this; it is automatically
      // updated for you.
      sortableFields: <String>[],
      // The ranking rules of this index, see:
      // https://docs.meilisearch.com/reference/api/settings.html#ranking-rules
      rankingRules: <String>[
        "words",
        "typo",
        "attribute",
        "sort",
        "proximity",
        "exactness",
      ],
      // The stop words of this index, see:
      // https://docs.meilisearch.com/reference/api/settings.html#stop-words
      stopWords: <String>[],
      // A list of synonyms to link words with the same meaning together.
      // Note: in most cases, you probably want to add synonyms both ways, like below:
      synonyms: <Synonyms>[
        Synonyms(
          word: 'שולחן ערוך',
          synonyms: ['שוע', 'שו"ע'],
        ),
        Synonyms(
          word: 'יורה דעה',
          synonyms: ['יו"ד', 'יוד'],
        ),
      ],
      // Whether to enable typo tolerance in searches.
      typosEnabled: true,
      // The minimum size of a word that can have 1 typo.
      // See minWordSizeForTypos.oneTypo here:
      // https://docs.meilisearch.com/reference/api/settings.html#typo-tolerance-object
      minWordSizeForOneTypo: 4,
      // The minimum size of a word that can have 2 typos.
      // See minWordSizeForTypos.twoTypos here:
      // https://docs.meilisearch.com/reference/api/settings.html#typo-tolerance-object
      minWordSizeForTwoTypos: 7,
      // Words that disallow typos. See disableOnWords here:
      // https://docs.meilisearch.com/reference/api/settings.html#typo-tolerance-object
      disallowTyposOnWords: <String>[],
      // Fields that disallow typos. See disableOnAttributes here:
      // https://docs.meilisearch.com/reference/api/settings.html#typo-tolerance-object
      disallowTyposOnFields: <String>[],
    ));
    return textsIndex;
  }();

  Future<List<Map<String, dynamic>>> searchTexts(
      String query, List<String> books) async {
    final index = await textsIndex;
    final List<Filter> filters = [];
    for (var book in books) {
      filters.add(Filter.equal(field: 'title', value: book));
    }
    return index.search(query: query, filter: Filter.or(filters));
  }

  Stream<List<Map<String, dynamic>>> searchTextsStream(
      String query, List<String> books) async* {
    final index = await textsIndex;
    final List<Filter> filters = [];
    if (books.isEmpty) {
      yield* index.searchStream(
        query: query,
      );
      return;
    }
    for (var book in books) {
      filters.add(Filter.equal(field: 'title', value: book));
    }
    yield* index.searchStream(query: query, filter: Filter.or(filters));
  }

  addAllTBooksToMimir(Library library,
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
      print('Adding ${book.title} to Mimir');
      try {
        if (book is TextBook) {
          await addTextsToMimir(book);
        } else if (book is PdfBook) {
          await addPdfTextsToMimir(book);
        }
      } catch (e) {
        print('Error adding ${book.title} to Mimir: $e');
      }
    }

    numOfbooksDone.value = null;
    numOfbooksTotal.value = null;
  }

  addTextsToMimir(TextBook book) async {
    final index = await textsIndex;
    final text = await book.text;
    final title = book.title;
    final author = book.author;
    final topics = book.topics;

    final hash = sha1.convert(utf8.encode(text)).toString();
    if (booksDone.contains(hash)) {
      print('${book.title} already in Mimir');
      numOfbooksDone.value = numOfbooksDone.value! + 1;
      return;
    }

    final texts = text.split('\n');
    final List<Map<String, dynamic>> documents = [];
    for (int i = 0; i < texts.length; i++) {
      if (!isIndexing.value) {
        return;
      }
      documents.add({
        'title': title,
        'author': author,
        'topics': topics,
        'text': texts[i],
        'index': i,
        'id': hash + i.toString(),
        'isPdf': false,
        'pdfPath': null,
      });
    }
    await index.addDocuments(documents);
    booksDone.add(hash);
    saveBooksDoneToDisk();
    print('Added ${book.title} to Mimir');
    numOfbooksDone.value = numOfbooksDone.value! + 1;
  }

  addPdfTextsToMimir(PdfBook book) async {
    final index = await textsIndex;
    final data = await File(book.path).readAsBytes();
    final hash = sha1.convert(data).toString();
    if (booksDone.contains(hash)) {
      print('${book.title} already in Mimir');
      numOfbooksDone.value = numOfbooksDone.value! + 1;
      return;
    }
    final pages = await PdfDocument.openData(data).then((value) => value.pages);
    final title = book.title;
    final author = book.author;
    final topics = book.topics;

    final List<Map<String, dynamic>> documents = [];
    for (int i = 0; i < pages.length; i++) {
      final texts = (await pages[i].loadText()).fullText.split('\n');
      for (int j = 0; j < texts.length; j++) {
        if (!isIndexing.value) {
          return;
        }
        documents.add({
          'title': title,
          'author': author,
          'topics': topics,
          'text': texts[j],
          'index': i,
          'pdfPath': book.path,
          'id': hash + i.toString(),
          'isPdf': true,
        });
      }
    }
    await index.addDocuments(documents);
    booksDone.add(hash);
    saveBooksDoneToDisk();
    print('Added ${book.title} to Mimir');
    numOfbooksDone.value = numOfbooksDone.value! + 1;
  }
}
