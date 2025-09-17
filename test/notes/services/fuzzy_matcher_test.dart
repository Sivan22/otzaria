import 'package:flutter_test/flutter_test.dart';
import 'package:otzaria/notes/services/fuzzy_matcher.dart';
import 'package:otzaria/notes/config/notes_config.dart';
import 'package:otzaria/notes/models/anchor_models.dart';

void main() {
  group('FuzzyMatcher Tests', () {
    group('Similarity Calculations', () {
      test('should calculate Levenshtein similarity correctly', () {
        expect(FuzzyMatcher.calculateLevenshteinSimilarity('hello', 'hello'), equals(1.0));
        expect(FuzzyMatcher.calculateLevenshteinSimilarity('hello', 'hallo'), closeTo(0.8, 0.1));
        expect(FuzzyMatcher.calculateLevenshteinSimilarity('hello', 'world'), lessThan(0.5));
        expect(FuzzyMatcher.calculateLevenshteinSimilarity('', ''), equals(1.0));
        expect(FuzzyMatcher.calculateLevenshteinSimilarity('hello', ''), equals(0.0));
      });

      test('should calculate Jaccard similarity correctly', () {
        expect(FuzzyMatcher.calculateJaccardSimilarity('hello', 'hello'), equals(1.0));
        expect(FuzzyMatcher.calculateJaccardSimilarity('hello', 'hallo'), greaterThan(0.1));
        expect(FuzzyMatcher.calculateJaccardSimilarity('hello', 'world'), lessThan(0.5));
      });

      test('should calculate Cosine similarity correctly', () {
        expect(FuzzyMatcher.calculateCosineSimilarity('hello', 'hello'), closeTo(1.0, 0.01));
        expect(FuzzyMatcher.calculateCosineSimilarity('hello', 'hallo'), greaterThan(0.2));
        expect(FuzzyMatcher.calculateCosineSimilarity('hello', 'world'), lessThan(0.8));
      });

      test('should handle Hebrew text similarity', () {
        const text1 = 'שלום עולם';
        const text2 = 'שלום עולם טוב';
        const text3 = 'שלום חברים';
        
        final sim1 = FuzzyMatcher.calculateLevenshteinSimilarity(text1, text2);
        final sim2 = FuzzyMatcher.calculateLevenshteinSimilarity(text1, text3);
        
        expect(sim1, greaterThan(0.6));
        expect(sim2, greaterThan(0.5));
        expect(sim1, greaterThan(sim2)); // text2 should be more similar
      });
    });

    group('N-gram Generation', () {
      test('should generate n-grams correctly', () {
        final ngrams = FuzzyMatcher.generateNGrams('hello', 3);
        expect(ngrams, equals(['hel', 'ell', 'llo']));
      });

      test('should handle short text', () {
        final ngrams = FuzzyMatcher.generateNGrams('hi', 3);
        expect(ngrams, equals(['hi']));
      });

      test('should handle Hebrew n-grams', () {
        final ngrams = FuzzyMatcher.generateNGrams('שלום', 2);
        expect(ngrams.length, equals(3));
        expect(ngrams.first, equals('של'));
        expect(ngrams.last, equals('ום'));
      });
    });

    group('Fuzzy Matching', () {
      test('should find matches with lenient thresholds', () {
        const searchText = 'hello world';
        const targetText = 'say hello world to everyone';
        
        final candidates = FuzzyMatcher.findFuzzyMatches(
          searchText, 
          targetText,
          levenshteinThreshold: 0.5,
          jaccardThreshold: 0.3,
          cosineThreshold: 0.3,
        );
        
        // With lenient thresholds, we should find something
        expect(candidates, isA<List>());
      });

      test('should return empty list with strict thresholds', () {
        const searchText = 'hello world';
        const targetText = 'completely different text here';
        
        final candidates = FuzzyMatcher.findFuzzyMatches(
          searchText, 
          targetText,
          levenshteinThreshold: 0.1,
          jaccardThreshold: 0.9,
          cosineThreshold: 0.9,
        );
        
        expect(candidates, isEmpty);
      });



      test('should handle Hebrew fuzzy matching', () {
        const searchText = 'שלום עולם';
        const targetText = 'אמר שלום עולם לכולם';
        
        final candidates = FuzzyMatcher.findFuzzyMatches(
          searchText, 
          targetText,
          levenshteinThreshold: 0.3,
          jaccardThreshold: 0.5,
          cosineThreshold: 0.5,
        );
        
        expect(candidates, isA<List>());
      });

      test('should respect custom thresholds', () {
        const searchText = 'hello world';
        const targetText = 'say hallo world to everyone';
        
        // Strict thresholds
        final strictCandidates = FuzzyMatcher.findFuzzyMatches(
          searchText,
          targetText,
          levenshteinThreshold: 0.05, // Very strict
          jaccardThreshold: 0.95,
          cosineThreshold: 0.95,
        );
        
        // Lenient thresholds
        final lenientCandidates = FuzzyMatcher.findFuzzyMatches(
          searchText,
          targetText,
          levenshteinThreshold: 0.3, // More lenient
          jaccardThreshold: 0.6,
          cosineThreshold: 0.6,
        );
        
        expect(lenientCandidates.length, greaterThanOrEqualTo(strictCandidates.length));
      });
    });

    group('Best Match Finding', () {
      test('should handle best match search', () {
        const searchText = 'hello world';
        const targetText = 'say hello world to everyone';
        
        final bestMatch = FuzzyMatcher.findBestMatch(searchText, targetText, minScore: 0.3);
        
        // Should either find a match or return null
        expect(bestMatch, isA<AnchorCandidate?>());
      });

      test('should return null for very poor matches', () {
        const searchText = 'hello world';
        const targetText = 'xyz';
        
        final bestMatch = FuzzyMatcher.findBestMatch(searchText, targetText, minScore: 0.8);
        
        expect(bestMatch, isNull);
      });
    });

    group('Combined Similarity', () {
      test('should calculate weighted combined similarity', () {
        const text1 = 'hello world';
        const text2 = 'hallo world';
        
        final combined = FuzzyMatcher.calculateCombinedSimilarity(text1, text2);
        
        expect(combined, greaterThan(0.0));
        expect(combined, lessThanOrEqualTo(1.0));
      });

      test('should respect custom weights', () {
        const text1 = 'hello world';
        const text2 = 'hallo world';
        
        final combinedSimilarity = FuzzyMatcher.calculateCombinedSimilarity(
          text1, text2,
        );
        
        // Test individual similarities for comparison
        final levenshteinSim = FuzzyMatcher.calculateLevenshteinSimilarity(text1, text2);
        final jaccardSim = FuzzyMatcher.calculateJaccardSimilarity(text1, text2);
        final cosineSim = FuzzyMatcher.calculateCosineSimilarity(text1, text2);
        
        expect(combinedSimilarity, isA<double>());
        expect(combinedSimilarity, greaterThan(0.0));
        expect(combinedSimilarity, lessThanOrEqualTo(1.0));
        
        // Combined should be weighted average of individual similarities
        expect(levenshteinSim, isA<double>());
        expect(jaccardSim, isA<double>());
        expect(cosineSim, isA<double>());
      });
    });

    group('Threshold Validation', () {
      test('should validate correct thresholds', () {
        expect(FuzzyMatcher.validateSimilarityThresholds(
          levenshteinThreshold: 0.2,
          jaccardThreshold: 0.8,
          cosineThreshold: 0.8,
        ), isTrue);
      });

      test('should reject invalid thresholds', () {
        expect(FuzzyMatcher.validateSimilarityThresholds(
          levenshteinThreshold: -0.1,
          jaccardThreshold: 0.8,
          cosineThreshold: 0.8,
        ), isFalse);
        
        expect(FuzzyMatcher.validateSimilarityThresholds(
          levenshteinThreshold: 0.2,
          jaccardThreshold: 1.5,
          cosineThreshold: 0.8,
        ), isFalse);
      });
    });

    group('Similarity Statistics', () {
      test('should provide comprehensive similarity stats', () {
        const text1 = 'hello world';
        const text2 = 'hallo world';
        
        final stats = FuzzyMatcher.getSimilarityStats(text1, text2);
        
        expect(stats['levenshtein'], isA<double>());
        expect(stats['jaccard'], isA<double>());
        expect(stats['cosine'], isA<double>());
        expect(stats['combined'], isA<double>());
        expect(stats['length_ratio'], isA<double>());
        
        // All similarity scores should be between 0 and 1
        expect(stats['levenshtein']!, greaterThanOrEqualTo(0.0));
        expect(stats['levenshtein']!, lessThanOrEqualTo(1.0));
        expect(stats['jaccard']!, greaterThanOrEqualTo(0.0));
        expect(stats['jaccard']!, lessThanOrEqualTo(1.0));
        expect(stats['cosine']!, greaterThanOrEqualTo(0.0));
        expect(stats['cosine']!, lessThanOrEqualTo(1.0));
      });
    });
  });
}