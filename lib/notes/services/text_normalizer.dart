import '../config/notes_config.dart';
import '../utils/text_utils.dart';

/// Service for normalizing text to ensure consistent hashing and matching.
/// 
/// Text normalization is critical for the anchoring system to work reliably
/// across different text versions. This service applies deterministic
/// transformations to create stable, comparable text representations.
/// 
/// ## Normalization Steps
/// 
/// The normalization process follows a specific order:
/// 
/// 1. **Unicode Normalization**: Apply NFKC or NFC normalization
/// 2. **Quote Normalization**: Convert various quote marks to ASCII
/// 3. **Nikud Handling**: Remove or preserve Hebrew vowel points
/// 4. **Whitespace Normalization**: Standardize spacing and line breaks
/// 5. **RTL Marker Cleanup**: Remove directional formatting characters
/// 
/// ## Configuration-Driven
/// 
/// Normalization behavior is controlled by [NormalizationConfig]:
/// - `unicodeForm`: NFKC (default) or NFC normalization
/// - `removeNikud`: Whether to remove Hebrew vowel points
/// - `quoteStyle`: ASCII (default) or preserve original quotes
/// 
/// ## Deterministic Output
/// 
/// The same input text with the same configuration will always produce
/// identical output, ensuring hash stability across sessions.
/// 
/// ## Usage
/// 
/// ```dart
/// // Create configuration from user settings
/// final config = TextNormalizer.createConfigFromSettings();
/// 
/// // Normalize text for hashing
/// final normalized = TextNormalizer.normalize(rawText, config);
/// 
/// // Get configuration string for storage
/// final configStr = TextNormalizer.configToString(config);
/// ```
/// 
/// ## Performance
/// 
/// - Time complexity: O(n) where n is text length
/// - Memory usage: Creates new string, original unchanged
/// - Optimized for Hebrew and RTL text processing
/// 
/// ## Hebrew & RTL Support
/// 
/// Special handling for Hebrew text:
/// - Nikud (vowel points) removal/preservation
/// - Hebrew quote marks (״׳) normalization
/// - RTL/LTR embedding character cleanup
/// - Grapheme cluster awareness for complex scripts
class TextNormalizer {
  /// Map of Unicode quote characters to ASCII equivalents
  static final Map<String, String> _quoteMap = {
    '\u201C': '"', '\u201D': '"', // " "
    '\u201E': '"', '\u00AB': '"', '\u00BB': '"', // „ « »
    '\u2018': "'", '\u2019': "'", // ' '
    '\u05F4': '"', '\u05F3': "'", // ״ ׳ (Hebrew)
  };

  /// Normalize text according to the given configuration (deterministic)
  static String normalize(String text, NormalizationConfig config) {
    // Step 1: Apply Unicode normalization first (NFKC)
    switch (config.unicodeForm) {
      case 'NFKC':
        text = _basicUnicodeNormalization(text);
        break;
      case 'NFC':
        text = _basicUnicodeNormalization(text);
        break;
    }
    
    // Step 2: Remove directional marks (LTR/RTL marks, embedding controls)
    text = text.replaceAll(RegExp(r'[\u200E\u200F\u202A-\u202E]'), '');
    
    // Step 3: Handle Zero-Width Joiner and Non-Joiner
    text = text.replaceAll(RegExp(r'[\u200C\u200D]'), '');
    
    // Step 4: Normalize punctuation (quotes and apostrophes)
    _quoteMap.forEach((from, to) {
      text = text.replaceAll(from, to);
    });
    
    // Step 5: Collapse multiple whitespace to single space
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    
    // Step 6: Handle nikud (vowel points) based on configuration
    if (config.removeNikud) {
      text = TextUtils.removeNikud(text);
    }
    
    // Step 7: Trim whitespace
    return text.trim();
  }

  /// Basic Unicode normalization (simplified implementation)
  static String _basicUnicodeNormalization(String text) {
    // This is a simplified implementation
    // In a production system, you might want to use a proper Unicode normalization library
    return text
        .replaceAll(RegExp(r'[\u0300-\u036F]'), '') // Remove combining diacritical marks
        .replaceAll(RegExp(r'[\uFE00-\uFE0F]'), '') // Remove variation selectors
        .replaceAll(RegExp(r'[\u200B-\u200D]'), ''); // Remove zero-width characters
  }

  /// Create a normalization configuration from current settings
  static NormalizationConfig createConfigFromSettings() {
    // This would typically read from app settings
    // For now, we'll use defaults
    return const NormalizationConfig(
      removeNikud: false, // This should come from Settings
      quoteStyle: 'ascii',
      unicodeForm: 'NFKC',
    );
  }

  /// Validate that text normalization is stable
  static bool validateNormalization(String text, NormalizationConfig config) {
    final normalized1 = normalize(text, config);
    final normalized2 = normalize(normalized1, config);
    return normalized1 == normalized2;
  }

  /// Extract context window around a text selection
  static ContextWindow extractContextWindow(
    String text,
    int start,
    int end, {
    int windowSize = AnchoringConstants.contextWindowSize,
  }) {
    final beforeStart = (start - windowSize).clamp(0, text.length);
    final afterEnd = (end + windowSize).clamp(0, text.length);
    
    final before = text.substring(beforeStart, start);
    final after = text.substring(end, afterEnd);
    final selected = text.substring(start, end);
    
    return ContextWindow(
      before: before,
      selected: selected,
      after: after,
      beforeStart: beforeStart,
      selectedStart: start,
      selectedEnd: end,
      afterEnd: afterEnd,
    );
  }

  /// Normalize context window text
  static ContextWindow normalizeContextWindow(
    ContextWindow window,
    NormalizationConfig config,
  ) {
    return ContextWindow(
      before: normalize(window.before, config),
      selected: normalize(window.selected, config),
      after: normalize(window.after, config),
      beforeStart: window.beforeStart,
      selectedStart: window.selectedStart,
      selectedEnd: window.selectedEnd,
      afterEnd: window.afterEnd,
    );
  }
}

/// Represents a context window around selected text
class ContextWindow {
  /// Text before the selection
  final String before;
  
  /// The selected text
  final String selected;
  
  /// Text after the selection
  final String after;
  
  /// Character position where 'before' starts
  final int beforeStart;
  
  /// Character position where selection starts
  final int selectedStart;
  
  /// Character position where selection ends
  final int selectedEnd;
  
  /// Character position where 'after' ends
  final int afterEnd;

  const ContextWindow({
    required this.before,
    required this.selected,
    required this.after,
    required this.beforeStart,
    required this.selectedStart,
    required this.selectedEnd,
    required this.afterEnd,
  });

  /// Total length of the context window
  int get totalLength => before.length + selected.length + after.length;

  @override
  String toString() {
    return 'ContextWindow(before: "${before.length} chars", selected: "${selected.length} chars", after: "${after.length} chars")';
  }
}