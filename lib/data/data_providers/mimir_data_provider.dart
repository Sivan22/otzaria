import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_mimir/flutter_mimir.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/library.dart';

class MimirDataProvider {
  static final MimirDataProvider _singleton = MimirDataProvider();
  static MimirDataProvider instance = _singleton;

  ValueNotifier<int?> numOfbooksDone = ValueNotifier(null);
  ValueNotifier<int?> numOfbooksTotal = ValueNotifier(null);

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
      rankingRules: <String>[],
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
      typosEnabled: false,
      // The minimum size of a word that can have 1 typo.
      // See minWordSizeForTypos.oneTypo here:
      // https://docs.meilisearch.com/reference/api/settings.html#typo-tolerance-object
      minWordSizeForOneTypo: 5,
      // The minimum size of a word that can have 2 typos.
      // See minWordSizeForTypos.twoTypos here:
      // https://docs.meilisearch.com/reference/api/settings.html#typo-tolerance-object
      minWordSizeForTwoTypos: 9,
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

  addAllTextsToMimir(Library library, {int start = 0, int end = 100000}) async {
    var allBooks = library.getAllBooks().whereType<TextBook>().toList();
    allBooks = allBooks.getRange(start, min(end, allBooks.length)).toList();
    numOfbooksTotal.value = allBooks.length;
    numOfbooksDone.value = 0;

    for (TextBook book in allBooks) {
      print('Adding ${book.title} to Mimir');
      await addTextsToMimir(
        book,
      );
      numOfbooksDone.value = numOfbooksDone.value! + 1;
    }
  }

  addTextsToMimir(TextBook book) async {
    final index = await textsIndex;
    final text = await book.text;
    final title = book.title;
    final author = book.author;
    final topics = book.topics;

    final texts = text.split('\n');
    final List<Map<String, dynamic>> documents = [];
    for (int i = 0; i < texts.length; i++) {
      documents.add({
        'title': title,
        'author': author,
        'topics': topics,
        'text': texts[i],
        'index': i,
        'id': DateTime.now().millisecondsSinceEpoch + Random().nextInt(1000000),
      });
    }
    await index.addDocuments(documents);
    print('Added ${book.title} to Mimir');
  }
}
