import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Service for generating various types of hashes for text anchoring.
class HashGenerator {
  /// Generate SHA-256 hash of normalized text.
  static String generateTextHash(String normalizedText) {
    final bytes = utf8.encode(normalizedText);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate context hashes for before and after text
  static ContextHashes generateContextHashes(String before, String after) {
    return ContextHashes(
      beforeHash: generateTextHash(before),
      afterHash: generateTextHash(after),
      beforeRollingHash: generateRollingHash(before),
      afterRollingHash: generateRollingHash(after),
    );
  }

  /// Generate text hashes for selected content
  static TextHashes generateTextHashes(String normalizedText) {
    return TextHashes(
      textHash: generateTextHash(normalizedText),
      rollingHash: generateRollingHash(normalizedText),
    );
  }

  /// Generate rolling hash for sliding window operations
  static int generateRollingHash(String text) {
    if (text.isEmpty) return 0;
    
    const int base = 31;
    const int mod = 1000000007;
    
    int hash = 0;
    int power = 1;
    
    for (int i = 0; i < text.length; i++) {
      hash = (hash + (text.codeUnitAt(i) * power)) % mod;
      power = (power * base) % mod;
    }
    
    return hash;
  }
}

/// Container for text hashes
class TextHashes {
  final String textHash;
  final int rollingHash;
  
  const TextHashes({
    required this.textHash,
    required this.rollingHash,
  });
}

/// Container for context hashes
class ContextHashes {
  final String beforeHash;
  final String afterHash;
  final int beforeRollingHash;
  final int afterRollingHash;
  
  const ContextHashes({
    required this.beforeHash,
    required this.afterHash,
    required this.beforeRollingHash,
    required this.afterRollingHash,
  });
}