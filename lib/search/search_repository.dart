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
    
    print('🔍 SearchRepository: מתחיל חיפוש');
    print('🔍 Query: "$query"');
    print('🔍 Facets: $facets');
    print('🔍 Fuzzy: $fuzzy, Distance: $distance');
    
    // המרת החיפוש הפשוט לפורמט החדש - ללא רגקס אמיתי!
    List<String> regexTerms;
    if (!fuzzy) {
      // חיפוש מדוייק - ננסה בלי מירכאות תחילה
      regexTerms = [query];
    } else {
      // חיפוש מקורב - נשתמש במילים בודדות
      regexTerms = query.trim().split(RegExp(r'\s+'));
    }
    
    print('🔍 RegexTerms: $regexTerms');
    print('🔍 Slop: $distance, MaxExpansions: ${fuzzy ? 50 : 0}');
    
    try {
      final results = await index.search(
          regexTerms: regexTerms, 
          facets: facets, 
          limit: limit, 
          slop: distance, 
          maxExpansions: fuzzy ? 50 : 0, 
          order: order);
      
      print('🔍 תוצאות: נמצאו ${results.length} תוצאות');
      return results;
    } catch (e) {
      print('❌ שגיאה בחיפוש: $e');
      rethrow;
    }
  }
}
