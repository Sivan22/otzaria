class SearchTerm {
  final String word;
  final List<String> alternatives;
  
  SearchTerm({
    required this.word,
    this.alternatives = const [],
  });
  
  SearchTerm copyWith({
    String? word,
    List<String>? alternatives,
  }) {
    return SearchTerm(
      word: word ?? this.word,
      alternatives: alternatives ?? this.alternatives,
    );
  }
  
  SearchTerm addAlternative(String alternative) {
    return copyWith(
      alternatives: [...alternatives, alternative],
    );
  }
  
  SearchTerm removeAlternative(int index) {
    final newAlternatives = List<String>.from(alternatives);
    if (index >= 0 && index < newAlternatives.length) {
      newAlternatives.removeAt(index);
    }
    return copyWith(alternatives: newAlternatives);
  }
  
  String get displayText {
    if (alternatives.isEmpty) {
      return word;
    }
    return '$word או ${alternatives.join(' או ')}';
  }
}

class SearchQuery {
  final List<SearchTerm> terms;
  
  SearchQuery({this.terms = const []});
  
  SearchQuery copyWith({List<SearchTerm>? terms}) {
    return SearchQuery(terms: terms ?? this.terms);
  }
  
  SearchQuery updateTerm(int index, SearchTerm term) {
    final newTerms = List<SearchTerm>.from(terms);
    if (index >= 0 && index < newTerms.length) {
      newTerms[index] = term;
    }
    return copyWith(terms: newTerms);
  }
  
  String get displayText {
    if (terms.isEmpty) return '';
    return terms.map((term) => term.displayText).join(' ו ');
  }
  
  String get originalQuery {
    return terms.map((term) => term.word).join(' ');
  }
  
  static SearchQuery fromString(String query) {
    if (query.trim().isEmpty) {
      return SearchQuery();
    }
    
    final words = query.trim().split(RegExp(r'\s+'));
    final terms = words.map((word) => SearchTerm(word: word)).toList();
    return SearchQuery(terms: terms);
  }
}