import '../models/anchor_models.dart';
import '../config/notes_config.dart';

/// Fast search index for canonical documents with O(1) hash lookups.
/// 
/// This service creates and manages high-performance indexes for canonical
/// documents, enabling fast lookups during the anchoring process. It uses
/// hash-based indexes to achieve O(1) average lookup time.
/// 
/// ## Index Types
/// 
/// ### 1. Text Hash Index
/// - **Key**: SHA-256 hash of normalized text chunks
/// - **Value**: Set of character positions where the text appears
/// - **Use**: Exact text matching (primary anchoring strategy)
/// 
/// ### 2. Context Hash Index
/// - **Key**: SHA-256 hash of context windows (before/after text)
/// - **Value**: Set of character positions for context centers
/// - **Use**: Context-based matching when text changes slightly
/// 
/// ### 3. Rolling Hash Index
/// - **Key**: Polynomial rolling hash of sliding windows
/// - **Value**: Set of character positions for window starts
/// - **Use**: Fast sliding window operations and fuzzy matching
/// 
/// ## Performance Characteristics
/// 
/// - **Build time**: O(n) where n is document length
/// - **Lookup time**: O(1) average, O(k) worst case (k = collision count)
/// - **Memory usage**: ~2-3x document size for all indexes
/// - **Update time**: O(1) for incremental updates
/// 
/// ## Usage
/// 
/// ```dart
/// final index = SearchIndex();
/// 
/// // Build indexes from canonical document
/// index.buildIndex(canonicalDocument);
/// 
/// // Fast lookups during anchoring
/// final positions = index.findByTextHash(textHash);
/// final contextPositions = index.findByContextHash(contextHash);
/// final rollingPositions = index.findByRollingHash(rollingHash);
/// 
/// // Check if indexes are ready
/// if (index.isBuilt) {
///   // Perform searches
/// }
/// ```
/// 
/// ## Index Building Strategy
/// 
/// The index building process:
/// 
/// 1. **Text Hash Index**: Slide window of various sizes, hash each chunk
/// 2. **Context Index**: Extract context windows around each position
/// 3. **Rolling Hash Index**: Use sliding window with polynomial hash
/// 
/// ## Memory Management
/// 
/// - Indexes use `Set<int>` for position storage (efficient for duplicates)
/// - Hash collisions are handled gracefully with multiple positions
/// - Indexes can be cleared and rebuilt as needed
/// - No persistent storage - rebuilt from canonical documents
/// 
/// ## Thread Safety
/// 
/// - Index building is not thread-safe (single-threaded operation)
/// - Lookups are thread-safe after building is complete
/// - Use separate instances for concurrent operations
class SearchIndex {
  final Map<String, Set<int>> _textHashIndex = {};
  final Map<String, Set<int>> _contextIndex = {};
  final Map<int, Set<int>> _rollingHashIndex = {};
  
  bool _isBuilt = false;

  /// Build indexes from a canonical document
  void buildIndex(CanonicalDocument document) {
    _textHashIndex.clear();
    _contextIndex.clear();
    _rollingHashIndex.clear();
    
    _buildTextHashIndex(document);
    _buildContextIndex(document);
    _buildRollingHashIndex(document);
    
    _isBuilt = true;
  }

  /// Build text hash index from document
  void _buildTextHashIndex(CanonicalDocument document) {
    for (final entry in document.textHashIndex.entries) {
      final hash = entry.key;
      final positions = entry.value;
      
      _textHashIndex[hash] = positions.toSet();
    }
  }

  /// Build context index from document
  void _buildContextIndex(CanonicalDocument document) {
    for (final entry in document.contextHashIndex.entries) {
      final hash = entry.key;
      final positions = entry.value;
      
      _contextIndex[hash] = positions.toSet();
    }
  }

  /// Build rolling hash index from document
  void _buildRollingHashIndex(CanonicalDocument document) {
    for (final entry in document.rollingHashIndex.entries) {
      final hash = entry.key;
      final positions = entry.value;
      
      _rollingHashIndex[hash] = positions.toSet();
    }
  }

  /// Find positions by text hash
  List<int> findByTextHash(String hash) {
    _ensureBuilt();
    return (_textHashIndex[hash] ?? const {}).toList();
  }

  /// Find positions by context hash (before and after)
  List<int> findByContextHash(String beforeHash, String afterHash) {
    _ensureBuilt();
    
    final beforePositions = _contextIndex[beforeHash] ?? const <int>{};
    final afterPositions = _contextIndex[afterHash] ?? const <int>{};
    
    return beforePositions.intersection(afterPositions).toList();
  }

  /// Find positions by single context hash
  List<int> findBySingleContextHash(String contextHash) {
    _ensureBuilt();
    return (_contextIndex[contextHash] ?? const {}).toList();
  }

  /// Find positions by rolling hash
  List<int> findByRollingHash(int hash) {
    _ensureBuilt();
    return (_rollingHashIndex[hash] ?? const {}).toList();
  }

  /// Find positions where before and after contexts are within distance
  List<int> findByContextProximity(
    String beforeHash,
    String afterHash, {
    int maxDistance = AnchoringConstants.maxContextDistance,
  }) {
    _ensureBuilt();
    
    final beforePositions = _contextIndex[beforeHash] ?? const <int>{};
    final afterPositions = _contextIndex[afterHash] ?? const <int>{};
    
    final matches = <int>[];
    
    for (final beforePos in beforePositions) {
      for (final afterPos in afterPositions) {
        final distance = (afterPos - beforePos).abs();
        if (distance <= maxDistance) {
          // Use the position that's more likely to be the actual match
          final matchPos = beforePos < afterPos ? beforePos : afterPos;
          if (!matches.contains(matchPos)) {
            matches.add(matchPos);
          }
        }
      }
    }
    
    return matches..sort();
  }

  /// Get all unique text hashes in the index
  Set<String> getAllTextHashes() {
    _ensureBuilt();
    return _textHashIndex.keys.toSet();
  }

  /// Get all unique context hashes in the index
  Set<String> getAllContextHashes() {
    _ensureBuilt();
    return _contextIndex.keys.toSet();
  }

  /// Get all unique rolling hashes in the index
  Set<int> getAllRollingHashes() {
    _ensureBuilt();
    return _rollingHashIndex.keys.toSet();
  }

  /// Get statistics about the index
  Map<String, int> getIndexStats() {
    return {
      'text_hash_entries': _textHashIndex.length,
      'context_hash_entries': _contextIndex.length,
      'rolling_hash_entries': _rollingHashIndex.length,
      'total_text_positions': _textHashIndex.values
          .fold(0, (sum, positions) => sum + positions.length),
      'total_context_positions': _contextIndex.values
          .fold(0, (sum, positions) => sum + positions.length),
      'total_rolling_positions': _rollingHashIndex.values
          .fold(0, (sum, positions) => sum + positions.length),
    };
  }

  /// Check if the index has been built
  bool get isBuilt => _isBuilt;

  /// Clear all indexes
  void clear() {
    _textHashIndex.clear();
    _contextIndex.clear();
    _rollingHashIndex.clear();
    _isBuilt = false;
  }

  /// Ensure the index has been built before use
  void _ensureBuilt() {
    if (!_isBuilt) {
      throw StateError('SearchIndex must be built before use. Call buildIndex() first.');
    }
  }

  /// Merge results from multiple hash lookups
  List<int> mergeResults(List<List<int>> resultSets, {bool requireAll = false}) {
    if (resultSets.isEmpty) return [];
    if (resultSets.length == 1) return resultSets.first;
    
    if (requireAll) {
      // Intersection - position must appear in all result sets
      Set<int> intersection = resultSets.first.toSet();
      for (int i = 1; i < resultSets.length; i++) {
        intersection = intersection.intersection(resultSets[i].toSet());
      }
      return intersection.toList()..sort();
    } else {
      // Union - position appears in any result set
      final union = <int>{};
      for (final results in resultSets) {
        union.addAll(results);
      }
      return union.toList()..sort();
    }
  }

  /// Find the best matches by combining multiple search strategies
  List<SearchMatch> findBestMatches(
    String textHash,
    String beforeHash,
    String afterHash,
    int rollingHash,
  ) {
    _ensureBuilt();
    
    final matches = <SearchMatch>[];
    
    // Exact text hash matches (highest priority)
    final exactMatches = findByTextHash(textHash);
    for (final pos in exactMatches) {
      matches.add(SearchMatch(
        position: pos,
        score: 1.0,
        strategy: 'exact_text',
      ));
    }
    
    // Context proximity matches (medium priority)
    final contextMatches = findByContextProximity(beforeHash, afterHash);
    for (final pos in contextMatches) {
      // Avoid duplicates from exact matches
      if (!exactMatches.contains(pos)) {
        matches.add(SearchMatch(
          position: pos,
          score: 0.8,
          strategy: 'context_proximity',
        ));
      }
    }
    
    // Rolling hash matches (lower priority)
    final rollingMatches = findByRollingHash(rollingHash);
    for (final pos in rollingMatches) {
      // Avoid duplicates
      if (!exactMatches.contains(pos) && !contextMatches.contains(pos)) {
        matches.add(SearchMatch(
          position: pos,
          score: 0.6,
          strategy: 'rolling_hash',
        ));
      }
    }
    
    // Sort by score (highest first) then by position
    matches.sort((a, b) {
      final scoreComparison = b.score.compareTo(a.score);
      return scoreComparison != 0 ? scoreComparison : a.position.compareTo(b.position);
    });
    
    return matches;
  }
}

/// Represents a search match with position and confidence score
class SearchMatch {
  final int position;
  final double score;
  final String strategy;

  const SearchMatch({
    required this.position,
    required this.score,
    required this.strategy,
  });

  @override
  String toString() {
    return 'SearchMatch(pos: $position, score: ${score.toStringAsFixed(2)}, strategy: $strategy)';
  }
}