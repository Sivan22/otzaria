class TextSearchResult {
  final String snippet;
  final int index;
  final String query;
  final String address;

  TextSearchResult({
    required this.snippet,
    required this.index,
    required this.query,
    required this.address,
  });
}

class BookTextSearchResult extends TextSearchResult {
  final String path;
  BookTextSearchResult(
      {required this.path,
      required String snippet,
      required int index,
      required String query,
      required String address})
      : super(snippet: snippet, index: index, query: query, address: address);
}
