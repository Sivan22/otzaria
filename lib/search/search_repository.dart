import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:search_engine/search_engine.dart';

/// Performs a synchronous search operation across indexed texts.
///
/// [query] The search query string
/// [books] List of book identifiers to search within
/// [limit] Maximum number of results to return
/// [fuzzy] Whether to perform fuzzy matching
///
/// Returns a Future containing a list of search results
///
class SearchRepository {
  Future<List<SearchResult>> searchTexts(
      String query, List<String> facets, int limit,
      {ResultsOrder order = ResultsOrder.relevance,
      bool fuzzy = false,
      int distance = 2}) async {
    SearchEngine index;

    index = await TantivyDataProvider.instance.engine;
    if (!fuzzy) {
      query = distance > 0 ? '*"$query"~$distance' : '"$query"';
    }
    return await index.search(
        query: query, facets: facets, limit: limit, fuzzy: fuzzy, order: order);
  }
}
