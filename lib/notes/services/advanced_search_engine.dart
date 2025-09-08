import 'dart:async';
import '../models/note.dart';
import '../services/fuzzy_matcher.dart';
import '../services/notes_telemetry.dart';
import '../utils/text_utils.dart';
import '../config/notes_config.dart';

/// Advanced search engine with multiple search strategies and ranking
class AdvancedSearchEngine {
  static AdvancedSearchEngine? _instance;
  // SearchIndex integration can be added later
  
  AdvancedSearchEngine._();
  
  /// Singleton instance
  static AdvancedSearchEngine get instance {
    _instance ??= AdvancedSearchEngine._();
    return _instance!;
  }

  /// Perform advanced search with multiple strategies
  Future<SearchResults> search(
    String query,
    List<Note> notes, {
    SearchOptions? options,
  }) async {
    final opts = options ?? const SearchOptions();
    final stopwatch = Stopwatch()..start();
    
    try {
      if (query.trim().isEmpty) {
        return SearchResults(
          query: query,
          results: [],
          totalResults: 0,
          searchTime: stopwatch.elapsed,
          strategy: 'empty_query',
        );
      }
      
      // Parse search query
      final parsedQuery = _parseSearchQuery(query);
      
      // Apply filters
      final filteredNotes = _applyFilters(notes, opts);
      
      // Perform search using multiple strategies
      final searchResults = await _performMultiStrategySearch(
        parsedQuery,
        filteredNotes,
        opts,
      );
      
      // Rank and sort results
      final rankedResults = _rankSearchResults(searchResults, parsedQuery, opts);
      
      // Apply pagination
      final paginatedResults = _applyPagination(rankedResults, opts);
      
      final results = SearchResults(
        query: query,
        results: paginatedResults,
        totalResults: rankedResults.length,
        searchTime: stopwatch.elapsed,
        strategy: 'multi_strategy',
        facets: _generateFacets(rankedResults),
        suggestions: _generateSuggestions(query, rankedResults),
      );
      
      // Track search performance
      NotesTelemetry.trackSearchPerformance(
        query,
        results.totalResults,
        stopwatch.elapsed,
      );
      
      return results;
      
    } catch (e) {
      NotesTelemetry.trackPerformanceMetric('search_error', stopwatch.elapsed);
      rethrow;
    }
  }

  /// Parse search query into components
  ParsedSearchQuery _parseSearchQuery(String query) {
    final terms = <String>[];
    final phrases = <String>[];
    final tags = <String>[];
    final excludeTerms = <String>[];
    final filters = <String, String>{};
    
    // Simple query parsing (can be enhanced with proper parser)
    final words = query.split(' ');
    String currentPhrase = '';
    bool inPhrase = false;
    
    for (final word in words) {
      final trimmed = word.trim();
      if (trimmed.isEmpty) continue;
      
      if (trimmed.startsWith('"')) {
        inPhrase = true;
        currentPhrase = trimmed.substring(1);
      } else if (trimmed.endsWith('"') && inPhrase) {
        currentPhrase += ' ${trimmed.substring(0, trimmed.length - 1)}';
        phrases.add(currentPhrase);
        currentPhrase = '';
        inPhrase = false;
      } else if (inPhrase) {
        currentPhrase += ' $trimmed';
      } else if (trimmed.startsWith('#')) {
        tags.add(trimmed.substring(1));
      } else if (trimmed.startsWith('-')) {
        excludeTerms.add(trimmed.substring(1));
      } else if (trimmed.contains(':')) {
        final parts = trimmed.split(':');
        if (parts.length == 2) {
          filters[parts[0]] = parts[1];
        }
      } else {
        terms.add(trimmed);
      }
    }
    
    return ParsedSearchQuery(
      originalQuery: query,
      terms: terms,
      phrases: phrases,
      tags: tags,
      excludeTerms: excludeTerms,
      filters: filters,
    );
  }

  /// Apply search filters
  List<Note> _applyFilters(List<Note> notes, SearchOptions options) {
    var filtered = notes;
    
    // Status filter
    if (options.statusFilter != null) {
      filtered = filtered.where((note) => note.status == options.statusFilter).toList();
    }
    
    // Privacy filter
    if (options.privacyFilter != null) {
      filtered = filtered.where((note) => note.privacy == options.privacyFilter).toList();
    }
    
    // Date range filter
    if (options.dateFrom != null) {
      filtered = filtered.where((note) => note.createdAt.isAfter(options.dateFrom!)).toList();
    }
    if (options.dateTo != null) {
      filtered = filtered.where((note) => note.createdAt.isBefore(options.dateTo!)).toList();
    }
    
    // Book filter
    if (options.bookIds != null && options.bookIds!.isNotEmpty) {
      filtered = filtered.where((note) => options.bookIds!.contains(note.bookId)).toList();
    }
    
    return filtered;
  }

  /// Perform multi-strategy search
  Future<List<SearchResult>> _performMultiStrategySearch(
    ParsedSearchQuery query,
    List<Note> notes,
    SearchOptions options,
  ) async {
    final results = <SearchResult>[];
    
    // Strategy 1: Exact phrase matching
    if (query.phrases.isNotEmpty) {
      final exactResults = await _searchExactPhrases(query.phrases, notes);
      results.addAll(exactResults);
    }
    
    // Strategy 2: Term matching
    if (query.terms.isNotEmpty) {
      final termResults = await _searchTerms(query.terms, notes);
      results.addAll(termResults);
    }
    
    // Strategy 3: Tag matching
    if (query.tags.isNotEmpty) {
      final tagResults = await _searchTags(query.tags, notes);
      results.addAll(tagResults);
    }
    
    // Strategy 4: Fuzzy matching (if enabled and no exact matches)
    if (NotesConfig.fuzzyMatchingEnabled && results.isEmpty) {
      final fuzzyResults = await _searchFuzzy(query.originalQuery, notes);
      results.addAll(fuzzyResults);
    }
    
    // Strategy 5: Semantic search (basic word similarity)
    if (options.enableSemanticSearch && results.length < 5) {
      final semanticResults = await _searchSemantic(query.terms, notes);
      results.addAll(semanticResults);
    }
    
    // Apply exclusions
    return _applyExclusions(results, query.excludeTerms);
  }

  /// Search for exact phrases
  Future<List<SearchResult>> _searchExactPhrases(
    List<String> phrases,
    List<Note> notes,
  ) async {
    final results = <SearchResult>[];
    
    for (final note in notes) {
      double totalScore = 0.0;
      final matches = <SearchMatch>[];
      
      for (final phrase in phrases) {
        final content = '${note.contentMarkdown} ${note.selectedTextNormalized}'.toLowerCase();
        final phraseIndex = content.indexOf(phrase.toLowerCase());
        
        if (phraseIndex != -1) {
          totalScore += 1.0; // Perfect score for exact phrase match
          matches.add(SearchMatch(
            field: phraseIndex < note.contentMarkdown.length ? 'content' : 'selected_text',
            position: phraseIndex,
            length: phrase.length,
            score: 1.0,
          ));
        }
      }
      
      if (matches.isNotEmpty) {
        results.add(SearchResult(
          note: note,
          score: totalScore / phrases.length,
          matches: matches,
          strategy: 'exact_phrase',
        ));
      }
    }
    
    return results;
  }

  /// Search for individual terms
  Future<List<SearchResult>> _searchTerms(
    List<String> terms,
    List<Note> notes,
  ) async {
    final results = <SearchResult>[];
    
    for (final note in notes) {
      double totalScore = 0.0;
      final matches = <SearchMatch>[];
      
      final content = '${note.contentMarkdown} ${note.selectedTextNormalized}'.toLowerCase();
      final words = TextUtils.extractWords(content);
      
      for (final term in terms) {
        final termLower = term.toLowerCase();
        double termScore = 0.0;
        
        // Exact word matches
        final exactMatches = words.where((word) => word.toLowerCase() == termLower).length;
        termScore += exactMatches * 1.0;
        
        // Partial matches
        final partialMatches = words.where((word) => word.toLowerCase().contains(termLower)).length;
        termScore += partialMatches * 0.5;
        
        if (termScore > 0) {
          totalScore += termScore;
          matches.add(SearchMatch(
            field: 'content',
            position: content.indexOf(termLower),
            length: term.length,
            score: termScore,
          ));
        }
      }
      
      if (matches.isNotEmpty) {
        results.add(SearchResult(
          note: note,
          score: totalScore / terms.length,
          matches: matches,
          strategy: 'term_matching',
        ));
      }
    }
    
    return results;
  }

  /// Search by tags
  Future<List<SearchResult>> _searchTags(
    List<String> searchTags,
    List<Note> notes,
  ) async {
    final results = <SearchResult>[];
    
    for (final note in notes) {
      final matchingTags = note.tags.where((tag) => 
          searchTags.any((searchTag) => tag.toLowerCase().contains(searchTag.toLowerCase()))).toList();
      
      if (matchingTags.isNotEmpty) {
        final score = matchingTags.length / searchTags.length;
        results.add(SearchResult(
          note: note,
          score: score,
          matches: [SearchMatch(
            field: 'tags',
            position: 0,
            length: matchingTags.join(', ').length,
            score: score,
          )],
          strategy: 'tag_matching',
        ));
      }
    }
    
    return results;
  }

  /// Fuzzy search
  Future<List<SearchResult>> _searchFuzzy(
    String query,
    List<Note> notes,
  ) async {
    final results = <SearchResult>[];
    
    for (final note in notes) {
      final content = '${note.contentMarkdown} ${note.selectedTextNormalized}';
      final similarity = FuzzyMatcher.calculateCombinedSimilarity(query, content);
      
      if (similarity >= 0.3) { // Threshold for fuzzy matching
        results.add(SearchResult(
          note: note,
          score: similarity,
          matches: [SearchMatch(
            field: 'content',
            position: 0,
            length: content.length,
            score: similarity,
          )],
          strategy: 'fuzzy_matching',
        ));
      }
    }
    
    return results;
  }

  /// Semantic search using word similarity
  Future<List<SearchResult>> _searchSemantic(
    List<String> terms,
    List<Note> notes,
  ) async {
    final results = <SearchResult>[];
    
    for (final note in notes) {
      final noteWords = TextUtils.extractWords('${note.contentMarkdown} ${note.selectedTextNormalized}');
      double semanticScore = 0.0;
      
      for (final term in terms) {
        for (final noteWord in noteWords) {
          final similarity = TextUtils.calculateSimilarity(term, noteWord);
          if (similarity > 0.7) { // Threshold for semantic similarity
            semanticScore += similarity;
          }
        }
      }
      
      if (semanticScore > 0) {
        final normalizedScore = semanticScore / (terms.length * noteWords.length);
        results.add(SearchResult(
          note: note,
          score: normalizedScore,
          matches: [SearchMatch(
            field: 'content',
            position: 0,
            length: 0,
            score: normalizedScore,
          )],
          strategy: 'semantic_matching',
        ));
      }
    }
    
    return results;
  }

  /// Apply exclusions to search results
  List<SearchResult> _applyExclusions(
    List<SearchResult> results,
    List<String> excludeTerms,
  ) {
    if (excludeTerms.isEmpty) return results;
    
    return results.where((result) {
      final content = '${result.note.contentMarkdown} ${result.note.selectedTextNormalized}'.toLowerCase();
      return !excludeTerms.any((term) => content.contains(term.toLowerCase()));
    }).toList();
  }

  /// Rank search results using multiple factors
  List<SearchResult> _rankSearchResults(
    List<SearchResult> results,
    ParsedSearchQuery query,
    SearchOptions options,
  ) {
    // Remove duplicates (same note from different strategies)
    final uniqueResults = <String, SearchResult>{};
    
    for (final result in results) {
      final key = result.note.id;
      final existing = uniqueResults[key];
      
      if (existing == null || result.score > existing.score) {
        uniqueResults[key] = result;
      }
    }
    
    final rankedResults = uniqueResults.values.toList();
    
    // Apply ranking factors
    for (final result in rankedResults) {
      double rankingScore = result.score;
      
      // Boost recent notes
      final age = DateTime.now().difference(result.note.updatedAt).inDays;
      final recencyBoost = (30 - age.clamp(0, 30)) / 30.0 * 0.1;
      rankingScore += recencyBoost;
      
      // Boost notes with more content
      final contentLength = result.note.contentMarkdown.length;
      final contentBoost = (contentLength / 1000.0).clamp(0.0, 0.1);
      rankingScore += contentBoost;
      
      // Boost anchored notes slightly
      if (result.note.status == NoteStatus.anchored) {
        rankingScore += 0.05;
      }
      
      // Update score
      result.score = rankingScore.clamp(0.0, 1.0);
    }
    
    // Sort by score
    rankedResults.sort((a, b) => b.score.compareTo(a.score));
    
    return rankedResults;
  }

  /// Apply pagination to results
  List<SearchResult> _applyPagination(
    List<SearchResult> results,
    SearchOptions options,
  ) {
    final offset = options.offset ?? 0;
    final limit = options.limit ?? 50;
    
    if (offset >= results.length) return [];
    
    final end = (offset + limit).clamp(0, results.length);
    return results.sublist(offset, end);
  }

  /// Generate search facets
  Map<String, Map<String, int>> _generateFacets(List<SearchResult> results) {
    final facets = <String, Map<String, int>>{};
    
    // Status facets
    final statusCounts = <String, int>{};
    for (final result in results) {
      final status = result.note.status.name;
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }
    facets['status'] = statusCounts;
    
    // Tag facets
    final tagCounts = <String, int>{};
    for (final result in results) {
      for (final tag in result.note.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    facets['tags'] = tagCounts;
    
    // Book facets
    final bookCounts = <String, int>{};
    for (final result in results) {
      final bookId = result.note.bookId;
      bookCounts[bookId] = (bookCounts[bookId] ?? 0) + 1;
    }
    facets['books'] = bookCounts;
    
    return facets;
  }

  /// Generate search suggestions
  List<String> _generateSuggestions(String query, List<SearchResult> results) {
    final suggestions = <String>[];
    
    if (results.isEmpty) {
      // Suggest common search terms
      suggestions.addAll(['הערות', 'תגיות', 'טקסט']);
    } else {
      // Suggest related tags
      final allTags = <String>{};
      for (final result in results.take(10)) {
        allTags.addAll(result.note.tags);
      }
      
      suggestions.addAll(allTags.take(5));
    }
    
    return suggestions;
  }
}

/// Parsed search query components
class ParsedSearchQuery {
  final String originalQuery;
  final List<String> terms;
  final List<String> phrases;
  final List<String> tags;
  final List<String> excludeTerms;
  final Map<String, String> filters;

  const ParsedSearchQuery({
    required this.originalQuery,
    required this.terms,
    required this.phrases,
    required this.tags,
    required this.excludeTerms,
    required this.filters,
  });
}

/// Search options
class SearchOptions {
  final NoteStatus? statusFilter;
  final NotePrivacy? privacyFilter;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final List<String>? bookIds;
  final int? offset;
  final int? limit;
  final bool enableSemanticSearch;
  final bool enableFuzzySearch;

  const SearchOptions({
    this.statusFilter,
    this.privacyFilter,
    this.dateFrom,
    this.dateTo,
    this.bookIds,
    this.offset,
    this.limit,
    this.enableSemanticSearch = false,
    this.enableFuzzySearch = true,
  });
}

/// Search result for a single note
class SearchResult {
  final Note note;
  double score;
  final List<SearchMatch> matches;
  final String strategy;

  SearchResult({
    required this.note,
    required this.score,
    required this.matches,
    required this.strategy,
  });
}

/// Individual search match within a note
class SearchMatch {
  final String field;
  final int position;
  final int length;
  final double score;

  const SearchMatch({
    required this.field,
    required this.position,
    required this.length,
    required this.score,
  });
}

/// Complete search results
class SearchResults {
  final String query;
  final List<SearchResult> results;
  final int totalResults;
  final Duration searchTime;
  final String strategy;
  final Map<String, Map<String, int>>? facets;
  final List<String>? suggestions;

  const SearchResults({
    required this.query,
    required this.results,
    required this.totalResults,
    required this.searchTime,
    required this.strategy,
    this.facets,
    this.suggestions,
  });
}