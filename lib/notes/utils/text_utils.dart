import 'package:characters/characters.dart';

/// Utility functions for text processing with RTL and Hebrew support
class TextUtils {
  /// Remove Hebrew nikud (vowel points) from text
  static String removeNikud(String text) {
    // Hebrew nikud Unicode ranges:
    // U+0591-U+05BD, U+05BF, U+05C1-U+05C2, U+05C4-U+05C5, U+05C7
    return text.replaceAll(RegExp(r'[\u0591-\u05BD\u05BF\u05C1-\u05C2\u05C4-\u05C5\u05C7]'), '');
  }

  /// Check if text contains Hebrew characters
  static bool containsHebrew(String text) {
    return text.contains(RegExp(r'[\u0590-\u05FF]'));
  }

  /// Check if text contains Arabic characters
  static bool containsArabic(String text) {
    return text.contains(RegExp(r'[\u0600-\u06FF]'));
  }

  /// Check if text is right-to-left
  static bool isRTL(String text) {
    return containsHebrew(text) || containsArabic(text);
  }

  /// Extract words from text (handles Hebrew and English)
  static List<String> extractWords(String text) {
    // Split on whitespace and punctuation, but preserve Hebrew and English words
    return text
        .split(RegExp(r'[\s\p{P}]+', unicode: true))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  /// Calculate character-based edit distance (simplified Levenshtein)
  static int levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final matrix = List.generate(
      a.length + 1,
      (i) => List.filled(b.length + 1, 0),
    );

    // Initialize first row and column
    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    // Fill the matrix
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,     // deletion
          matrix[i][j - 1] + 1,     // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[a.length][b.length];
  }

  /// Calculate similarity ratio based on Levenshtein distance
  static double calculateSimilarity(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final distance = levenshteinDistance(a, b);
    final maxLength = a.length > b.length ? a.length : b.length;
    
    return 1.0 - (distance / maxLength);
  }

  /// Generate n-grams from text
  static List<String> generateNGrams(String text, int n) {
    if (text.length < n) return [text];
    
    final ngrams = <String>[];
    for (int i = 0; i <= text.length - n; i++) {
      ngrams.add(text.substring(i, i + n));
    }
    return ngrams;
  }

  /// Calculate Jaccard similarity using n-grams
  static double calculateJaccardSimilarity(String a, String b, {int ngramSize = 3}) {
    final ngramsA = generateNGrams(a, ngramSize).toSet();
    final ngramsB = generateNGrams(b, ngramSize).toSet();
    
    if (ngramsA.isEmpty && ngramsB.isEmpty) return 1.0;
    if (ngramsA.isEmpty || ngramsB.isEmpty) return 0.0;
    
    final intersection = ngramsA.intersection(ngramsB);
    final union = ngramsA.union(ngramsB);
    
    return intersection.length / union.length;
  }

  /// Calculate Cosine similarity using n-grams with frequency
  static double calculateCosineSimilarity(String a, String b, {int ngramSize = 3}) {
    Map<String, int> freq(List<String> grams) {
      final m = <String, int>{};
      for (final g in grams) {
        m[g] = (m[g] ?? 0) + 1;
      }
      return m;
    }
    
    final ga = generateNGrams(a, ngramSize);
    final gb = generateNGrams(b, ngramSize);
    final fa = freq(ga);
    final fb = freq(gb);
    final keys = {...fa.keys, ...fb.keys};
    
    if (keys.isEmpty) return 1.0;
    
    double dot = 0, na = 0, nb = 0;
    for (final k in keys) {
      final va = (fa[k] ?? 0).toDouble();
      final vb = (fb[k] ?? 0).toDouble();
      dot += va * vb;
      na += va * va;
      nb += vb * vb;
    }
    
    if (na == 0 || nb == 0) return 0.0;
    return dot / (sqrt(na) * sqrt(nb));
  }

  /// Simple square root implementation
  static double sqrt(double x) {
    if (x < 0) return double.nan;
    if (x == 0) return 0;
    
    double guess = x / 2;
    double prev = 0;
    
    while ((guess - prev).abs() > 0.0001) {
      prev = guess;
      guess = (guess + x / guess) / 2;
    }
    
    return guess;
  }

  /// Slice text by grapheme clusters (safe for RTL and Hebrew with nikud)
  static String sliceByGraphemes(String text, int start, int end) {
    final characters = text.characters;
    final length = characters.length;
    
    // Clamp indices to valid range
    final safeStart = start.clamp(0, length);
    final safeEnd = end.clamp(safeStart, length);
    
    return characters.skip(safeStart).take(safeEnd - safeStart).toString();
  }

  /// Get grapheme-aware length
  static int getGraphemeLength(String text) {
    return text.characters.length;
  }

  /// Convert character index to grapheme index
  static int charIndexToGraphemeIndex(String text, int charIndex) {
    if (charIndex <= 0) return 0;
    
    final characters = text.characters;
    int currentCharIndex = 0;
    int graphemeIndex = 0;
    
    for (final char in characters) {
      if (currentCharIndex >= charIndex) break;
      currentCharIndex += char.length;
      graphemeIndex++;
    }
    
    return graphemeIndex;
  }

  /// Convert grapheme index to character index
  static int graphemeIndexToCharIndex(String text, int graphemeIndex) {
    if (graphemeIndex <= 0) return 0;
    
    final characters = text.characters;
    int charIndex = 0;
    int currentGraphemeIndex = 0;
    
    for (final char in characters) {
      if (currentGraphemeIndex >= graphemeIndex) break;
      charIndex += char.length;
      currentGraphemeIndex++;
    }
    
    return charIndex;
  }

  /// Truncate text to specified length with ellipsis (grapheme-aware)
  static String truncate(String text, int maxLength, {String ellipsis = '...'}) {
    final characters = text.characters;
    if (characters.length <= maxLength) return text;
    
    final ellipsisLength = ellipsis.characters.length;
    final truncateLength = maxLength - ellipsisLength;
    
    return characters.take(truncateLength).toString() + ellipsis;
  }

  /// Clean text for display (remove excessive whitespace, control characters)
  static String cleanForDisplay(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .trim();
  }

  /// Highlight search terms in text (simple implementation)
  static String highlightSearchTerms(String text, String searchTerm) {
    if (searchTerm.isEmpty) return text;
    
    final regex = RegExp(RegExp.escape(searchTerm), caseSensitive: false);
    return text.replaceAllMapped(regex, (match) {
      return '<mark>${match.group(0)}</mark>';
    });
  }
}