import 'package:flutter_mimir/flutter_mimir.dart';

class MimirDataProvider {
  static final MimirDataProvider _singleton = MimirDataProvider();
  static MimirDataProvider instance = _singleton;

  Future<MimirIndex> textsIndex = () async {
    final instance = await Mimir.defaultInstance;
    final textsIndex = instance.getIndex('texts');
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

  Future<List<Map<String, dynamic>>> searchTexts(String query) async {
    final index = await textsIndex;
    return index.search(query: query);
  }

  Stream<List<Map<String, dynamic>>> searchTextsStream(String query) async* {
    final index = await textsIndex;
    yield* index.searchStream(query: query);
  }
}
