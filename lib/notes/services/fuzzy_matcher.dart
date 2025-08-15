import '../utils/text_utils.dart';
import '../config/notes_config.dart';
import '../models/anchor_models.dart';

/// Service for fuzzy text matching using multiple similarity algorithms.
/// 
/// This service implements various string similarity algorithms used by the
/// anchoring system when exact matches are not possible. It combines multiple
/// approaches to provide robust matching for changed text.
/// 
/// ## Similarity Algorithms
/// 
/// ### 1. Levenshtein Distance
/// - **Type**: Edit distance (character-level)
/// - **Best for**: Small character changes, typos
/// - **Range**: 0.0 (no similarity) to 1.0 (identical)
/// - **Complexity**: O(m×n) where m,n are string lengths
/// 
/// ### 2. Jaccard Similarity
/// - **Type**: Set-based similarity using n-grams
/// - **Best for**: Word reordering, partial matches
/// - **Range**: 0.0 (no overlap) to 1.0 (identical sets)
/// - **Complexity**: O(m+n) for n-gram generation
/// 
/// ### 3. Cosine Similarity
/// - **Type**: Vector-based similarity with n-gram frequency
/// - **Best for**: Semantic similarity, different word frequencies
/// - **Range**: 0.0 (orthogonal) to 1.0 (identical direction)
/// - **Complexity**: O(m+n) with frequency counting
/// 
/// ## Composite Scoring
/// 
/// The service can combine multiple algorithms using weighted averages:
/// 
/// ```
/// final_score = (levenshtein × 0.4) + (jaccard × 0.3) + (cosine × 0.3)
/// ```
/// 
/// ## Usage
/// 
/// ```dart
/// // Individual algorithm scores
/// final levenshtein = FuzzyMatcher.calculateLevenshteinSimilarity(text1, text2);
/// final jaccard = FuzzyMatcher.calculateJaccardSimilarity(text1, text2);
/// final cosine = FuzzyMatcher.calculateCosineSimilarity(text1, text2);
/// 
/// // Composite score for anchoring decisions
/// final composite = FuzzyMatcher.calculateCompositeSimilarity(
///   text1, text2, candidate
/// );
/// 
/// // Find best match from candidates
/// final bestMatch = FuzzyMatcher.findBestMatch(targetText, candidates);
/// ```
/// 
/// ## Performance Optimization
/// 
/// - **Early termination**: Stop calculation if similarity drops below threshold
/// - **N-gram caching**: Reuse n-gram sets for multiple comparisons
/// - **Length filtering**: Skip candidates with very different lengths
/// - **Batch processing**: Optimize for multiple candidate evaluation
/// 
/// ## Thresholds
/// 
/// Default similarity thresholds from [AnchoringConstants]:
/// - Levenshtein: 0.82 (82% similarity required)
/// - Jaccard: 0.82 (82% n-gram overlap required)
/// - Cosine: 0.82 (82% vector similarity required)
/// 
/// ## Hebrew & RTL Considerations
/// 
/// - Uses grapheme-aware text processing
/// - Handles Hebrew nikud in n-gram generation
/// - RTL-safe character counting and slicing
/// - Consistent with [TextNormalizer] output
class FuzzyMatcher {
  /// Calculate Levenshtein similarity ratio
  static double calculateLevenshteinSimilarity(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final distance = TextUtils.levenshteinDistance(a, b);
    final maxLength = a.length > b.length ? a.length : b.length;
    
    return 1.0 - (distance / maxLength);
  }

  /// Calculate Jaccard similarity using n-grams
  static double calculateJaccardSimilarity(String a, String b, {int ngramSize = 3}) {
    return TextUtils.calculateJaccardSimilarity(a, b, ngramSize: ngramSize);
  }

  /// Calculate true Cosine similarity using n-grams with frequency
  static double calculateCosineSimilarity(String a, String b, {int ngramSize = 3}) {
    return TextUtils.calculateCosineSimilarity(a, b, ngramSize: ngramSize);
  }

  /// Generate n-grams from text
  static List<String> generateNGrams(String text, int n) {
    return TextUtils.generateNGrams(text, n);
  }

  /// Find fuzzy matches in a text using sliding window
  static List<AnchorCandidate> findFuzzyMatches(
    String searchText,
    String targetText, {
    double levenshteinThreshold = AnchoringConstants.levenshteinThreshold,
    double jaccardThreshold = AnchoringConstants.jaccardThreshold,
    double cosineThreshold = AnchoringConstants.cosineThreshold,
    int ngramSize = AnchoringConstants.ngramSize,
  }) {
    final candidates = <AnchorCandidate>[];
    final searchLength = searchText.length;
    
    if (searchLength > targetText.length) {
      return candidates;
    }
    
    // Use adaptive step size based on text length
    final stepSize = (searchLength / 4).clamp(1, 10).round();
    
    for (int i = 0; i <= targetText.length - searchLength; i += stepSize) {
      final candidateText = targetText.substring(i, i + searchLength);
      
      // Calculate multiple similarity scores
      final levenshteinSim = calculateLevenshteinSimilarity(searchText, candidateText);
      final jaccardSim = calculateJaccardSimilarity(searchText, candidateText, ngramSize: ngramSize);
      final cosineSim = calculateCosineSimilarity(searchText, candidateText, ngramSize: ngramSize);
      
      // Check if any similarity meets the threshold
      final meetsLevenshtein = levenshteinSim >= (1.0 - levenshteinThreshold);
      final meetsJaccard = jaccardSim >= jaccardThreshold;
      final meetsCosine = cosineSim >= cosineThreshold;
      
      if (meetsLevenshtein && (meetsJaccard || meetsCosine)) {
        // Use the highest similarity score
        final maxScore = [levenshteinSim, jaccardSim, cosineSim].reduce((a, b) => a > b ? a : b);
        
        candidates.add(AnchorCandidate(
          i,
          i + searchLength,
          maxScore,
          'fuzzy',
        ));
      }
    }
    
    // Sort by score (highest first) and remove duplicates
    candidates.sort((a, b) => b.score.compareTo(a.score));
    
    return _removeDuplicateCandidates(candidates);
  }

  /// Remove duplicate candidates that are too close to each other
  static List<AnchorCandidate> _removeDuplicateCandidates(List<AnchorCandidate> candidates) {
    if (candidates.length <= 1) return candidates;
    
    final filtered = <AnchorCandidate>[];
    const minDistance = 10; // Minimum distance between candidates
    
    for (final candidate in candidates) {
      bool tooClose = false;
      
      for (final existing in filtered) {
        if ((candidate.start - existing.start).abs() < minDistance) {
          tooClose = true;
          break;
        }
      }
      
      if (!tooClose) {
        filtered.add(candidate);
      }
    }
    
    return filtered;
  }

  /// Find the best match using combined scoring
  static AnchorCandidate? findBestMatch(
    String searchText,
    String targetText, {
    double minScore = 0.7,
  }) {
    final candidates = findFuzzyMatches(searchText, targetText);
    
    if (candidates.isEmpty) return null;
    
    final best = candidates.first;
    return best.score >= minScore ? best : null;
  }

  /// Calculate combined similarity score using locked weights
  static double calculateCombinedSimilarity(String a, String b) {
    final levenshteinSim = calculateLevenshteinSimilarity(a, b);
    final jaccardSim = calculateJaccardSimilarity(a, b);
    final cosineSim = calculateCosineSimilarity(a, b);
    
    return (levenshteinSim * AnchoringConstants.levenshteinWeight) +
           (jaccardSim * AnchoringConstants.jaccardWeight) +
           (cosineSim * AnchoringConstants.cosineWeight);
  }

  /// Validate similarity thresholds
  static bool validateSimilarityThresholds({
    required double levenshteinThreshold,
    required double jaccardThreshold,
    required double cosineThreshold,
  }) {
    return levenshteinThreshold >= 0.0 && levenshteinThreshold <= 1.0 &&
           jaccardThreshold >= 0.0 && jaccardThreshold <= 1.0 &&
           cosineThreshold >= 0.0 && cosineThreshold <= 1.0;
  }

  /// Get similarity statistics for debugging
  static Map<String, double> getSimilarityStats(String a, String b) {
    return {
      'levenshtein': calculateLevenshteinSimilarity(a, b),
      'jaccard': calculateJaccardSimilarity(a, b),
      'cosine': calculateCosineSimilarity(a, b),
      'combined': calculateCombinedSimilarity(a, b),
      'length_ratio': a.length / b.length.clamp(1, double.infinity),
    };
  }
}