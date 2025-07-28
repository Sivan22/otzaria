import 'package:search_engine/search_engine.dart';

/// מחלקה שמרכזת את כל הגדרות החיפוש במקום אחד
/// כוללת הגדרות קיימות והגדרות עתידיות לרגקס
class SearchConfiguration {
  // הגדרות חיפוש קיימות
  final int distance;
  final bool fuzzy;
  final ResultsOrder sortBy;
  final int numResults;
  final List<String> currentFacets;

  // הגדרות רגקס עתידיות (מוכנות להרחבה)
  final bool regexEnabled;
  final bool caseSensitive;
  final bool multiline;
  final bool dotAll;
  final bool unicode;

  const SearchConfiguration({
    // ערכי ברירת מחדל קיימים
    this.distance = 2,
    this.fuzzy = false,
    this.sortBy = ResultsOrder.catalogue,
    this.numResults = 100,
    this.currentFacets = const ["/"],

    // ערכי ברירת מחדל לרגקס
    this.regexEnabled = false,
    this.caseSensitive = false,
    this.multiline = false,
    this.dotAll = false,
    this.unicode = true,
  });

  /// יוצר עותק עם שינויים
  SearchConfiguration copyWith({
    int? distance,
    bool? fuzzy,
    ResultsOrder? sortBy,
    int? numResults,
    List<String>? currentFacets,
    bool? regexEnabled,
    bool? caseSensitive,
    bool? multiline,
    bool? dotAll,
    bool? unicode,
  }) {
    return SearchConfiguration(
      distance: distance ?? this.distance,
      fuzzy: fuzzy ?? this.fuzzy,
      sortBy: sortBy ?? this.sortBy,
      numResults: numResults ?? this.numResults,
      currentFacets: currentFacets ?? this.currentFacets,
      regexEnabled: regexEnabled ?? this.regexEnabled,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      multiline: multiline ?? this.multiline,
      dotAll: dotAll ?? this.dotAll,
      unicode: unicode ?? this.unicode,
    );
  }

  /// המרה למפה לשמירה או העברה
  Map<String, dynamic> toMap() {
    return {
      'distance': distance,
      'fuzzy': fuzzy,
      'sortBy': sortBy.index,
      'numResults': numResults,
      'currentFacets': currentFacets,
      'regexEnabled': regexEnabled,
      'caseSensitive': caseSensitive,
      'multiline': multiline,
      'dotAll': dotAll,
      'unicode': unicode,
    };
  }

  /// יצירה ממפה
  factory SearchConfiguration.fromMap(Map<String, dynamic> map) {
    return SearchConfiguration(
      distance: map['distance'] ?? 2,
      fuzzy: map['fuzzy'] ?? false,
      sortBy: ResultsOrder.values[map['sortBy'] ?? 0],
      numResults: map['numResults'] ?? 100,
      currentFacets: List<String>.from(map['currentFacets'] ?? ["/"]),
      regexEnabled: map['regexEnabled'] ?? false,
      caseSensitive: map['caseSensitive'] ?? false,
      multiline: map['multiline'] ?? false,
      dotAll: map['dotAll'] ?? false,
      unicode: map['unicode'] ?? true,
    );
  }

  /// בדיקה אם החיפוש במצב רגקס
  bool get isRegexMode => regexEnabled;

  /// קבלת דגלי רגקס כמחרוזת (לשימוש עתידי)
  String get regexFlags {
    String flags = '';
    if (!caseSensitive) flags += 'i';
    if (multiline) flags += 'm';
    if (dotAll) flags += 's';
    if (unicode) flags += 'u';
    return flags;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchConfiguration &&
        other.distance == distance &&
        other.fuzzy == fuzzy &&
        other.sortBy == sortBy &&
        other.numResults == numResults &&
        other.currentFacets.toString() == currentFacets.toString() &&
        other.regexEnabled == regexEnabled &&
        other.caseSensitive == caseSensitive &&
        other.multiline == multiline &&
        other.dotAll == dotAll &&
        other.unicode == unicode;
  }

  @override
  int get hashCode {
    return Object.hash(
      distance,
      fuzzy,
      sortBy,
      numResults,
      currentFacets,
      regexEnabled,
      caseSensitive,
      multiline,
      dotAll,
      unicode,
    );
  }

  @override
  String toString() {
    return 'SearchConfiguration('
        'distance: $distance, '
        'fuzzy: $fuzzy, '
        'sortBy: $sortBy, '
        'numResults: $numResults, '
        'facets: $currentFacets, '
        'regex: $regexEnabled, '
        'caseSensitive: $caseSensitive, '
        'multiline: $multiline, '
        'dotAll: $dotAll, '
        'unicode: $unicode'
        ')';
  }
}
