import 'dart:async';
import '../models/note.dart';
import '../models/anchor_models.dart';
import '../services/fuzzy_matcher.dart';
import '../services/notes_telemetry.dart';
import '../config/notes_config.dart';
import '../utils/text_utils.dart';

/// Advanced service for managing orphaned notes with smart re-anchoring
class AdvancedOrphanManager {
  static AdvancedOrphanManager? _instance;

  
  AdvancedOrphanManager._();
  
  /// Singleton instance
  static AdvancedOrphanManager get instance {
    _instance ??= AdvancedOrphanManager._();
    return _instance!;
  }

  /// Find potential anchor candidates for an orphan note using multiple strategies
  Future<List<AnchorCandidate>> findCandidatesForOrphan(
    Note orphan,
    CanonicalDocument document,
  ) async {
    final stopwatch = Stopwatch()..start();
    final candidates = <AnchorCandidate>[];
    
    try {
      // Strategy 1: Exact text match (highest priority)
      final exactCandidates = await _findExactMatches(orphan, document);
      candidates.addAll(exactCandidates);
      
      // Strategy 2: Context-based matching
      final contextCandidates = await _findContextMatches(orphan, document);
      candidates.addAll(contextCandidates);
      
      // Strategy 3: Fuzzy matching (if enabled)
      if (NotesConfig.fuzzyMatchingEnabled) {
        final fuzzyCandidates = await _findFuzzyMatches(orphan, document);
        candidates.addAll(fuzzyCandidates);
      }
      
      // Strategy 4: Semantic similarity (advanced)
      final semanticCandidates = await _findSemanticMatches(orphan, document);
      candidates.addAll(semanticCandidates);
      
      // Remove duplicates and sort by score
      final uniqueCandidates = _removeDuplicatesAndSort(candidates);
      
      // Apply confidence scoring
      final scoredCandidates = _applyConfidenceScoring(uniqueCandidates, orphan);
      
      NotesTelemetry.trackPerformanceMetric('orphan_candidate_search', stopwatch.elapsed);
      
      return scoredCandidates.take(10).toList(); // Limit to top 10 candidates
    } catch (e) {
      NotesTelemetry.trackPerformanceMetric('orphan_candidate_search_error', stopwatch.elapsed);
      rethrow;
    }
  }

  /// Find exact text matches
  Future<List<AnchorCandidate>> _findExactMatches(
    Note orphan,
    CanonicalDocument document,
  ) async {
    final candidates = <AnchorCandidate>[];
    final searchText = orphan.selectedTextNormalized;
    
    // Search for exact matches in the document
    int startIndex = 0;
    while (true) {
      final index = document.canonicalText.indexOf(searchText, startIndex);
      if (index == -1) break;
      
      candidates.add(AnchorCandidate(
        index,
        index + searchText.length,
        1.0, // Perfect score for exact match
        'exact',
      ));
      
      startIndex = index + 1;
    }
    
    return candidates;
  }

  /// Find context-based matches
  Future<List<AnchorCandidate>> _findContextMatches(
    Note orphan,
    CanonicalDocument document,
  ) async {
    final candidates = <AnchorCandidate>[];
    final contextBefore = orphan.contextBefore;
    final contextAfter = orphan.contextAfter;
    
    if (contextBefore.isEmpty && contextAfter.isEmpty) {
      return candidates;
    }
    
    // Search for context patterns
    final beforeMatches = _findContextPattern(document.canonicalText, contextBefore);
    final afterMatches = _findContextPattern(document.canonicalText, contextAfter);
    
    // Combine context matches to find potential positions
    for (final beforeMatch in beforeMatches) {
      for (final afterMatch in afterMatches) {
        final distance = afterMatch - beforeMatch;
        if (distance > 0 && distance < AnchoringConstants.maxContextDistance) {
          final score = _calculateContextScore(distance, contextBefore.length, contextAfter.length);
          
          candidates.add(AnchorCandidate(
            beforeMatch + contextBefore.length,
            afterMatch,
            score,
            'context',
          ));
        }
      }
    }
    
    return candidates;
  }

  /// Find fuzzy matches using advanced algorithms
  Future<List<AnchorCandidate>> _findFuzzyMatches(
    Note orphan,
    CanonicalDocument document,
  ) async {
    final searchText = orphan.selectedTextNormalized;
    return FuzzyMatcher.findFuzzyMatches(searchText, document.canonicalText);
  }

  /// Find semantic matches using word similarity
  Future<List<AnchorCandidate>> _findSemanticMatches(
    Note orphan,
    CanonicalDocument document,
  ) async {
    final candidates = <AnchorCandidate>[];
    final searchWords = TextUtils.extractWords(orphan.selectedTextNormalized);
    
    if (searchWords.isEmpty) return candidates;
    
    final documentWords = TextUtils.extractWords(document.canonicalText);
    final windowSize = searchWords.length;
    
    // Sliding window approach for semantic matching
    for (int i = 0; i <= documentWords.length - windowSize; i++) {
      final window = documentWords.sublist(i, i + windowSize);
      final similarity = _calculateSemanticSimilarity(searchWords, window);
      
      if (similarity >= 0.6) { // Threshold for semantic similarity
        final startPos = _findWordPosition(document.canonicalText, documentWords, i);
        final endPos = _findWordPosition(document.canonicalText, documentWords, i + windowSize - 1);
        
        if (startPos != -1 && endPos != -1) {
          candidates.add(AnchorCandidate(
            startPos,
            endPos,
            similarity,
            'semantic',
          ));
        }
      }
    }
    
    return candidates;
  }

  /// Find positions of context patterns
  List<int> _findContextPattern(String text, String pattern) {
    final positions = <int>[];
    if (pattern.isEmpty) return positions;
    
    int startIndex = 0;
    while (true) {
      final index = text.indexOf(pattern, startIndex);
      if (index == -1) break;
      
      positions.add(index);
      startIndex = index + 1;
    }
    
    return positions;
  }

  /// Calculate context-based score
  double _calculateContextScore(int distance, int beforeLength, int afterLength) {
    // Prefer shorter distances and longer context
    final distanceScore = 1.0 - (distance / AnchoringConstants.maxContextDistance);
    final contextScore = (beforeLength + afterLength) / 100.0; // Normalize context length
    
    return (distanceScore * 0.7 + contextScore.clamp(0.0, 1.0) * 0.3);
  }

  /// Calculate semantic similarity between word lists
  double _calculateSemanticSimilarity(List<String> words1, List<String> words2) {
    if (words1.isEmpty || words2.isEmpty) return 0.0;
    
    final set1 = words1.map((w) => w.toLowerCase()).toSet();
    final set2 = words2.map((w) => w.toLowerCase()).toSet();
    
    final intersection = set1.intersection(set2);
    final union = set1.union(set2);
    
    return intersection.length / union.length; // Jaccard similarity
  }

  /// Find position of a word in text
  int _findWordPosition(String text, List<String> words, int wordIndex) {
    if (wordIndex >= words.length) return -1;
    
    // Find position of target word
    int currentPos = 0;
    
    for (int i = 0; i <= wordIndex; i++) {
      final index = text.indexOf(words[i], currentPos);
      if (index == -1) return -1;
      
      if (i == wordIndex) return index;
      currentPos = index + words[i].length;
    }
    
    return -1;
  }

  /// Remove duplicate candidates and sort by score
  List<AnchorCandidate> _removeDuplicatesAndSort(List<AnchorCandidate> candidates) {
    final uniqueMap = <String, AnchorCandidate>{};
    
    for (final candidate in candidates) {
      final key = '${candidate.start}-${candidate.end}';
      final existing = uniqueMap[key];
      
      if (existing == null || candidate.score > existing.score) {
        uniqueMap[key] = candidate;
      }
    }
    
    final uniqueCandidates = uniqueMap.values.toList();
    uniqueCandidates.sort((a, b) => b.score.compareTo(a.score));
    
    return uniqueCandidates;
  }

  /// Apply confidence scoring based on multiple factors
  List<AnchorCandidate> _applyConfidenceScoring(
    List<AnchorCandidate> candidates,
    Note orphan,
  ) {
    return candidates.map((candidate) {
      double confidence = candidate.score;
      
      // Boost confidence for exact matches
      if (candidate.strategy == 'exact') {
        confidence = (confidence * 1.2).clamp(0.0, 1.0);
      }
      
      // Reduce confidence for very short or very long matches
      final length = candidate.end - candidate.start;
      final originalLength = orphan.selectedTextNormalized.length;
      final lengthRatio = length / originalLength;
      
      if (lengthRatio < 0.5 || lengthRatio > 2.0) {
        confidence *= 0.8;
      }
      
      // Boost confidence for matches with similar length
      if (lengthRatio >= 0.8 && lengthRatio <= 1.2) {
        confidence = (confidence * 1.1).clamp(0.0, 1.0);
      }
      
      return AnchorCandidate(
        candidate.start,
        candidate.end,
        confidence,
        candidate.strategy,
      );
    }).toList();
  }

  /// Auto-reanchor orphans with high confidence scores
  Future<List<AutoReanchorResult>> autoReanchorOrphans(
    List<Note> orphans,
    CanonicalDocument document, {
    double confidenceThreshold = 0.9,
  }) async {
    final results = <AutoReanchorResult>[];
    final stopwatch = Stopwatch()..start();
    
    for (final orphan in orphans) {
      try {
        final candidates = await findCandidatesForOrphan(orphan, document);
        
        if (candidates.isNotEmpty && candidates.first.score >= confidenceThreshold) {
          final bestCandidate = candidates.first;
          
          results.add(AutoReanchorResult(
            orphan: orphan,
            candidate: bestCandidate,
            success: true,
          ));
        } else {
          results.add(AutoReanchorResult(
            orphan: orphan,
            candidate: null,
            success: false,
            reason: candidates.isEmpty 
                ? 'No candidates found'
                : 'Low confidence (${(candidates.first.score * 100).toStringAsFixed(1)}%)',
          ));
        }
      } catch (e) {
        results.add(AutoReanchorResult(
          orphan: orphan,
          candidate: null,
          success: false,
          reason: 'Error: $e',
        ));
      }
    }
    
    final successCount = results.where((r) => r.success).length;
    NotesTelemetry.trackBatchReanchoring(
      'auto_reanchor_${DateTime.now().millisecondsSinceEpoch}',
      orphans.length,
      successCount,
      stopwatch.elapsed,
    );
    
    return results;
  }

  /// Get orphan statistics and recommendations
  OrphanAnalysis analyzeOrphans(List<Note> orphans) {
    final byAge = <String, int>{};
    final byLength = <String, int>{};
    final byTags = <String, int>{};
    
    final now = DateTime.now();
    
    for (final orphan in orphans) {
      // Age analysis
      final age = now.difference(orphan.createdAt).inDays;
      final ageGroup = age < 7 ? 'recent' : age < 30 ? 'medium' : 'old';
      byAge[ageGroup] = (byAge[ageGroup] ?? 0) + 1;
      
      // Length analysis
      final length = orphan.selectedTextNormalized.length;
      final lengthGroup = length < 20 ? 'short' : length < 100 ? 'medium' : 'long';
      byLength[lengthGroup] = (byLength[lengthGroup] ?? 0) + 1;
      
      // Tags analysis
      for (final tag in orphan.tags) {
        byTags[tag] = (byTags[tag] ?? 0) + 1;
      }
    }
    
    return OrphanAnalysis(
      totalOrphans: orphans.length,
      byAge: byAge,
      byLength: byLength,
      byTags: byTags,
      recommendations: _generateRecommendations(orphans),
    );
  }

  /// Generate recommendations for orphan management
  List<String> _generateRecommendations(List<Note> orphans) {
    final recommendations = <String>[];
    
    if (orphans.isEmpty) {
      recommendations.add('אין הערות יתומות - מצוין!');
      return recommendations;
    }
    
    final oldOrphans = orphans.where((o) => 
        DateTime.now().difference(o.createdAt).inDays > 30).length;
    
    if (oldOrphans > 0) {
      recommendations.add('יש $oldOrphans הערות יתומות ישנות - שקול למחוק אותן');
    }
    
    final shortOrphans = orphans.where((o) => 
        o.selectedTextNormalized.length < 10).length;
    
    if (shortOrphans > orphans.length * 0.3) {
      recommendations.add('הרבה הערות יתומות קצרות - ייתכן שהטקסט השתנה משמעותית');
    }
    
    if (orphans.length > 20) {
      recommendations.add('מספר גבוה של הערות יתומות - שקול להריץ עיגון אוטומטי');
    }
    
    return recommendations;
  }
}

/// Result of auto re-anchoring operation
class AutoReanchorResult {
  final Note orphan;
  final AnchorCandidate? candidate;
  final bool success;
  final String? reason;

  const AutoReanchorResult({
    required this.orphan,
    required this.candidate,
    required this.success,
    this.reason,
  });
}

/// Analysis of orphan notes
class OrphanAnalysis {
  final int totalOrphans;
  final Map<String, int> byAge;
  final Map<String, int> byLength;
  final Map<String, int> byTags;
  final List<String> recommendations;

  const OrphanAnalysis({
    required this.totalOrphans,
    required this.byAge,
    required this.byLength,
    required this.byTags,
    required this.recommendations,
  });
}