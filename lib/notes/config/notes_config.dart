/// Configuration constants for the notes anchoring system.
/// 
/// This class contains all the tuned parameters that control the behavior
/// of the anchoring algorithms. These values have been carefully chosen
/// based on testing with Hebrew texts and should not be modified without
/// extensive testing.
/// 
/// ## Parameter Categories
/// 
/// ### Context Windows
/// - Control how much surrounding text is used for anchoring
/// - Larger windows = more context but slower processing
/// - Smaller windows = faster but less reliable anchoring
/// 
/// ### Similarity Thresholds
/// - Determine when text is "similar enough" to anchor
/// - Higher thresholds = stricter matching, fewer false positives
/// - Lower thresholds = more lenient matching, more false positives
/// 
/// ### Performance Limits
/// - Ensure the system remains responsive under load
/// - Prevent runaway operations that could freeze the UI
/// - Balance accuracy with speed requirements
/// 
/// ## Tuning Guidelines
/// 
/// These parameters were optimized for:
/// - Hebrew text with nikud and RTL formatting
/// - Books with 10,000-100,000 characters
/// - 100-1000 notes per book
/// - 98% accuracy target after 5% text changes
/// 
/// **Warning**: Changing these values may significantly impact accuracy
/// and performance. Always test thoroughly with representative data.
class AnchoringConstants {
  /// Context window size (characters before and after selected text).
  /// 
  /// This determines how much surrounding text is captured and used for
  /// context-based anchoring. A larger window provides more context but
  /// increases processing time and memory usage.
  /// 
  /// **Value**: 40 characters (optimized for Hebrew text)
  /// **Range**: 20-100 characters recommended
  static const int contextWindowSize = 40;
  
  /// Maximum distance between prefix and suffix for context matching.
  /// 
  /// When searching for context matches, this limits how far apart the
  /// before and after context can be. Prevents matching unrelated text
  /// that happens to have similar context fragments.
  /// 
  /// **Value**: 300 characters (allows for moderate text insertions)
  /// **Range**: 200-500 characters recommended
  static const int maxContextDistance = 300;
  
  /// Levenshtein distance threshold for fuzzy matching.
  /// 
  /// Maximum allowed edit distance as a fraction of the original text length.
  /// Lower values require closer matches, higher values are more permissive.
  /// 
  /// **Value**: 0.18 (18% of original length)
  /// **Example**: 50-char text allows up to 9 character changes
  static const double levenshteinThreshold = 0.18;
  
  /// Jaccard similarity threshold for n-gram matching.
  /// 
  /// Minimum required overlap between n-gram sets. Higher values require
  /// more similar text structure, lower values allow more variation.
  /// 
  /// **Value**: 0.82 (82% n-gram overlap required)
  /// **Range**: 0.7-0.9 recommended for Hebrew text
  static const double jaccardThreshold = 0.82;
  
  /// Cosine similarity threshold for semantic matching.
  /// 
  /// Minimum required cosine similarity between n-gram frequency vectors.
  /// Captures semantic similarity even when word order changes.
  /// 
  /// **Value**: 0.82 (82% vector similarity required)
  /// **Range**: 0.7-0.9 recommended for semantic matching
  static const double cosineThreshold = 0.82;
  
  /// N-gram size for fuzzy matching algorithms.
  /// 
  /// Size of character sequences used for Jaccard and Cosine similarity.
  /// Smaller values are more sensitive to character changes, larger values
  /// focus on word-level patterns.
  /// 
  /// **Value**: 3 characters (optimal for Hebrew with nikud)
  /// **Range**: 2-4 characters recommended
  static const int ngramSize = 3;
  
  /// Weight for Levenshtein similarity in composite scoring.
  /// 
  /// Controls the influence of character-level edit distance in the
  /// final similarity score. Higher weight emphasizes exact character matching.
  static const double levenshteinWeight = 0.4;
  
  /// Weight for Jaccard similarity in composite scoring.
  /// 
  /// Controls the influence of n-gram overlap in the final similarity score.
  /// Higher weight emphasizes structural text similarity.
  static const double jaccardWeight = 0.3;
  
  /// Weight for Cosine similarity in composite scoring.
  /// 
  /// Controls the influence of semantic similarity in the final score.
  /// Higher weight emphasizes meaning preservation over exact structure.
  static const double cosineWeight = 0.3;
  
  /// Maximum time allowed for re-anchoring a single note (milliseconds).
  /// 
  /// Prevents runaway operations that could freeze the UI. If re-anchoring
  /// takes longer than this, the operation is terminated and the note is
  /// marked as orphan.
  /// 
  /// **Value**: 50ms (maintains 60fps UI responsiveness)
  static const int maxReanchoringTimeMs = 50;
  
  /// Maximum delay allowed for page load operations (milliseconds).
  /// 
  /// Ensures UI remains responsive during note loading. Operations that
  /// exceed this limit are moved to background processing.
  /// 
  /// **Value**: 16ms (60fps frame budget)
  static const int maxPageLoadDelayMs = 16;
  
  /// Window size for rolling hash calculations.
  /// 
  /// Size of the sliding window used for polynomial rolling hash.
  /// Larger windows provide more unique hashes but increase computation.
  /// 
  /// **Value**: 20 characters (balanced uniqueness vs. performance)
  static const int rollingHashWindowSize = 20;
  
  /// Minimum score difference to trigger orphan manager.
  /// 
  /// When multiple candidates have scores within this difference, the
  /// situation is considered ambiguous and requires manual resolution
  /// through the orphan manager.
  /// 
  /// **Value**: 0.03 (3% score difference)
  /// **Example**: Scores 0.85 and 0.87 would trigger orphan manager
  static const double candidateScoreDifference = 0.03;
}

/// Database configuration constants
class DatabaseConfig {
  static const String databaseName = 'notes.db';
  static const int databaseVersion = 1;
  static const String notesTable = 'notes';
  static const String canonicalDocsTable = 'canonical_documents';
  static const String notesFtsTable = 'notes_fts';
  
  /// Cache settings
  static const int maxCacheSize = 10000;
  static const Duration cacheExpiry = Duration(hours: 1);
}

/// Feature flags for the notes system
class NotesConfig {
  static const bool enabled = true;                    // Kill switch
  static const bool highlightEnabled = true;           // Emergency disable highlights
  static const bool fuzzyMatchingEnabled = false;      // V2 feature
  static const bool encryptionEnabled = false;         // V2 feature
  static const bool importExportEnabled = false;       // V2 feature
  static const int maxNotesPerBook = 5000;            // Resource limit
  static const int maxNoteSize = 32768;               // 32KB limit
  static const int reanchoringTimeoutMs = 50;         // Performance limit
  static const int maxReanchoringBatchSize = 200;     // Optimal batch limit
  static const bool telemetryEnabled = true;          // Performance telemetry
  static const int busyTimeoutMs = 5000;             // SQLite busy timeout
}

/// Environment-specific settings
class NotesEnvironment {
  static const bool debugMode = bool.fromEnvironment('dart.vm.product') == false;
  static const bool telemetryEnabled = !debugMode;
  static const bool performanceLogging = debugMode;
  static const String databasePath = debugMode ? 'notes_debug.db' : 'notes.db';
}

/// Text normalization configuration
class NormalizationConfig {
  /// Current normalization version
  static const String version = 'v1';
  
  /// Whether to remove nikud (vowel points)
  final bool removeNikud;
  
  /// Quote normalization style
  final String quoteStyle;
  
  /// Unicode normalization form
  final String unicodeForm;

  const NormalizationConfig({
    this.removeNikud = false,
    this.quoteStyle = 'ascii',
    this.unicodeForm = 'NFKC',
  });

  /// Creates a configuration string for storage
  String toConfigString() {
    return 'norm=$version;nikud=${removeNikud ? 'remove' : 'keep'};quotes=$quoteStyle;unicode=$unicodeForm';
  }

  /// Parses a configuration string
  factory NormalizationConfig.fromConfigString(String config) {
    final parts = config.split(';');
    final map = <String, String>{};
    
    for (final part in parts) {
      final keyValue = part.split('=');
      if (keyValue.length == 2) {
        map[keyValue[0]] = keyValue[1];
      }
    }
    
    return NormalizationConfig(
      removeNikud: map['nikud'] == 'remove',
      quoteStyle: map['quotes'] ?? 'ascii',
      unicodeForm: map['unicode'] ?? 'NFKC',
    );
  }

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'removeNikud': removeNikud,
      'quoteStyle': quoteStyle,
      'unicodeForm': unicodeForm,
    };
  }

  /// Create from map
  factory NormalizationConfig.fromMap(Map<String, dynamic> map) {
    return NormalizationConfig(
      removeNikud: map['removeNikud'] ?? false,
      quoteStyle: map['quoteStyle'] ?? 'ascii',
      unicodeForm: map['unicodeForm'] ?? 'NFKC',
    );
  }

  @override
  String toString() => toConfigString();
}