import 'dart:async';
import 'package:otzaria/utils/isolate_manager.dart';
import 'package:otzaria/indexing/services/indexing_isolate_service.dart';
import 'package:search_engine/search_engine.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'dart:io';

/// הודעות חיפוש
abstract class SearchMessage {}

class TextSearchMessage extends SearchMessage {
  final String query;
  final List<String> facets;
  final int limit;
  final SearchOptions options;
  final String indexPath;
  
  TextSearchMessage({
    required this.query,
    required this.facets,
    required this.limit,
    required this.options,
    required this.indexPath,
  });
}

class CountSearchMessage extends SearchMessage {
  final String query;
  final List<String> facets;
  final SearchOptions options;
  final String indexPath;
  
  CountSearchMessage({
    required this.query,
    required this.facets,
    required this.options,
    required this.indexPath,
  });
}

class BuildRegexMessage extends SearchMessage {
  final List<String> words;
  final Map<int, List<String>>? alternativeWords;
  final Map<String, Map<String, bool>>? searchOptions;
  
  BuildRegexMessage({
    required this.words,
    this.alternativeWords,
    this.searchOptions,
  });
}

/// אפשרויות חיפוש
class SearchOptions {
  final bool fuzzy;
  final int distance;
  final Map<String, String>? customSpacing;
  final Map<int, List<String>>? alternativeWords;
  final Map<String, Map<String, bool>>? searchOptions;
  final ResultsOrder order;
  
  SearchOptions({
    this.fuzzy = false,
    this.distance = 2,
    this.customSpacing,
    this.alternativeWords,
    this.searchOptions,
    this.order = ResultsOrder.relevance,
  });
}

/// תוצאות חיפוש
class SearchResultWrapper {
  final List<SearchResult> results;
  final int totalCount;
  final String? error;
  
  SearchResultWrapper({
    required this.results,
    required this.totalCount,
    this.error,
  });
}

class SearchCountResult {
  final int count;
  final String? error;
  
  SearchCountResult({
    required this.count,
    this.error,
  });
}

class RegexBuildResult {
  final List<String> regexTerms;
  final int slop;
  final int maxExpansions;
  
  RegexBuildResult({
    required this.regexTerms,
    required this.slop,
    required this.maxExpansions,
  });
}

/// שירות חיפוש ב-Isolate
class SearchIsolateService {
  static IsolateHandler? _searchIsolate;
  static ReadOnlySearchEngine? _readOnlyEngine;
  
  /// אתחול שירות החיפוש
  static Future<void> initialize() async {
    if (_searchIsolate == null) {
      _searchIsolate = await IsolateManager.getOrCreate(
        'search',
        _searchIsolateEntry,
      );
      
      // אתחול מנוע חיפוש לקריאה בלבד
      final indexPath = '${Settings.getValue('key-library-path') ?? 'C:/אוצריא'}${Platform.pathSeparator}index';
      _readOnlyEngine = ReadOnlySearchEngine(indexPath: indexPath);
    }
  }
  
  /// חיפוש טקסט
  static Future<SearchResultWrapper> searchTexts(
    String query,
    List<String> facets,
    int limit,
    SearchOptions options,
  ) async {
    await initialize();
    
    final indexPath = '${Settings.getValue('key-library-path') ?? 'C:/אוצריא'}${Platform.pathSeparator}index';
    
    return await _searchIsolate!.compute<SearchResultWrapper>(
      TextSearchMessage(
        query: query,
        facets: facets,
        limit: limit,
        options: options,
        indexPath: indexPath,
      ),
    );
  }
  
  /// ספירת תוצאות
  static Future<SearchCountResult> countResults(
    String query,
    List<String> facets,
    SearchOptions options,
  ) async {
    await initialize();
    
    final indexPath = '${Settings.getValue('key-library-path') ?? 'C:/אוצריא'}${Platform.pathSeparator}index';
    
    return await _searchIsolate!.compute<SearchCountResult>(
      CountSearchMessage(
        query: query,
        facets: facets,
        options: options,
        indexPath: indexPath,
      ),
    );
  }
  
  /// בניית ביטויים רגולריים מורכבים
  static Future<RegexBuildResult> buildRegex(
    List<String> words,
    Map<int, List<String>>? alternativeWords,
    Map<String, Map<String, bool>>? searchOptions,
  ) async {
    await initialize();
    
    return await _searchIsolate!.compute<RegexBuildResult>(
      BuildRegexMessage(
        words: words,
        alternativeWords: alternativeWords,
        searchOptions: searchOptions,
      ),
    );
  }
  
  /// שחרור משאבים
  static Future<void> dispose() async {
    if (_searchIsolate != null) {
      await IsolateManager.kill('search');
      _searchIsolate = null;
    }
    _readOnlyEngine = null;
  }
}

/// נקודת כניסה ל-Isolate של חיפוש
void _searchIsolateEntry(IsolateContext context) {
  SearchEngine? searchEngine;
  String? currentIndexPath;
  
  // פונקציה לקבלת או יצירת מנוע חיפוש
  Future<SearchEngine> _getEngine(String indexPath) async {
    if (searchEngine == null || currentIndexPath != indexPath) {
      searchEngine = SearchEngine(path: indexPath);
      currentIndexPath = indexPath;
    }
    return searchEngine!;
  }
  
  // האזנה להודעות
  context.messages.listen((message) async {
    try {
      if (message is TextSearchMessage) {
        // ביצוע חיפוש
        final engine = await _getEngine(message.indexPath);
        
        // בניית פרמטרי החיפוש
        final regexData = _buildSearchParams(
          message.query,
          message.options,
        );
        
        // ביצוע החיפוש
        final results = await engine.search(
          regexTerms: regexData.regexTerms,
          facets: message.facets,
          limit: message.limit,
          slop: regexData.slop,
          maxExpansions: regexData.maxExpansions,
          order: message.options.order,
        );
        
        context.send(SearchResultWrapper(
          results: results,
          totalCount: results.length,
        ));
        
      } else if (message is CountSearchMessage) {
        // ספירת תוצאות
        final engine = await _getEngine(message.indexPath);
        
        // בניית פרמטרי החיפוש
        final regexData = _buildSearchParams(
          message.query,
          message.options,
        );
        
        // ביצוע הספירה
        final count = await engine.count(
          regexTerms: regexData.regexTerms,
          facets: message.facets,
          slop: regexData.slop,
          maxExpansions: regexData.maxExpansions,
        );
        
        context.send(SearchCountResult(count: count));
        
      } else if (message is BuildRegexMessage) {
        // בניית רגקס
        final result = _buildAdvancedRegex(
          message.words,
          message.alternativeWords,
          message.searchOptions,
        );
        
        context.send(result);
      }
    } catch (e) {
      // שליחת שגיאה
      if (message is TextSearchMessage) {
        context.send(SearchResultWrapper(
          results: [],
          totalCount: 0,
          error: e.toString(),
        ));
      } else if (message is CountSearchMessage) {
        context.send(SearchCountResult(
          count: 0,
          error: e.toString(),
        ));
      }
    }
  });
}

/// בניית פרמטרי חיפוש
RegexBuildResult _buildSearchParams(String query, SearchOptions options) {
  final words = query.trim().split(RegExp(r'\s+'));
  
  final hasCustomSpacing = options.customSpacing != null && options.customSpacing!.isNotEmpty;
  final hasAlternativeWords = options.alternativeWords != null && options.alternativeWords!.isNotEmpty;
  final hasSearchOptions = options.searchOptions != null && options.searchOptions!.isNotEmpty;
  
  List<String> regexTerms;
  int effectiveSlop;
  
  if (hasAlternativeWords || hasSearchOptions) {
    // בניית query מתקדם
    final result = _buildAdvancedRegex(words, options.alternativeWords, options.searchOptions);
    regexTerms = result.regexTerms;
    effectiveSlop = hasCustomSpacing 
        ? _getMaxCustomSpacing(options.customSpacing!, words.length)
        : (options.fuzzy ? options.distance : 0);
  } else if (options.fuzzy) {
    regexTerms = words;
    effectiveSlop = options.distance;
  } else if (words.length == 1) {
    regexTerms = [query];
    effectiveSlop = 0;
  } else if (hasCustomSpacing) {
    regexTerms = words;
    effectiveSlop = _getMaxCustomSpacing(options.customSpacing!, words.length);
  } else {
    regexTerms = words;
    effectiveSlop = options.distance;
  }
  
  final maxExpansions = _calculateMaxExpansions(
    options.fuzzy,
    regexTerms.length,
    searchOptions: options.searchOptions,
    words: words,
  );
  
  return RegexBuildResult(
    regexTerms: regexTerms,
    slop: effectiveSlop,
    maxExpansions: maxExpansions,
  );
}

/// בניית רגקס מתקדם
RegexBuildResult _buildAdvancedRegex(
  List<String> words,
  Map<int, List<String>>? alternativeWords,
  Map<String, Map<String, bool>>? searchOptions,
) {
  List<String> regexTerms = [];
  
  for (int i = 0; i < words.length; i++) {
    final word = words[i];
    final wordKey = '${word}_$i';
    
    // קבלת אפשרויות החיפוש למילה
    final wordOptions = searchOptions?[wordKey] ?? {};
    final hasPrefix = wordOptions['קידומות'] == true;
    final hasSuffix = wordOptions['סיומות'] == true;
    final hasGrammaticalPrefixes = wordOptions['קידומות דקדוקיות'] == true;
    final hasGrammaticalSuffixes = wordOptions['סיומות דקדוקיות'] == true;
    final hasFullPartialSpelling = wordOptions['כתיב מלא/חסר'] == true;
    final hasPartialWord = wordOptions['חלק ממילה'] == true;
    
    // קבלת מילים חילופיות
    final alternatives = alternativeWords?[i];
    
    // בניית רשימת כל האפשרויות
    final allOptions = [word];
    if (alternatives != null && alternatives.isNotEmpty) {
      allOptions.addAll(alternatives);
    }
    
    // סינון אפשרויות ריקות
    final validOptions = allOptions.where((w) => w.trim().isNotEmpty).toList();
    
    if (validOptions.isNotEmpty) {
      final allVariations = <String>{};
      
      for (final option in validOptions) {
        String pattern = option;
        
        // החלת אפשרויות חיפוש
        if (hasFullPartialSpelling) {
          pattern = _createSpellingPattern(pattern);
        }
        
        if (hasGrammaticalPrefixes && hasGrammaticalSuffixes) {
          pattern = _createFullMorphologicalPattern(pattern);
        } else if (hasGrammaticalPrefixes) {
          pattern = _createPrefixPattern(pattern);
        } else if (hasGrammaticalSuffixes) {
          pattern = _createSuffixPattern(pattern);
        } else if (hasPrefix) {
          pattern = '.*${RegExp.escape(pattern)}';
        } else if (hasSuffix) {
          pattern = '${RegExp.escape(pattern)}.*';
        } else if (hasPartialWord) {
          pattern = '.*${RegExp.escape(pattern)}.*';
        } else {
          pattern = RegExp.escape(pattern);
        }
        
        allVariations.add(pattern);
      }
      
      // הגבלת מספר הוריאציות
      final limitedVariations = allVariations.length > 20
          ? allVariations.take(20).toList()
          : allVariations.toList();
      
      final finalPattern = limitedVariations.length == 1
          ? limitedVariations.first
          : '(${limitedVariations.join('|')})';
      
      regexTerms.add(finalPattern);
    } else {
      regexTerms.add(word);
    }
  }
  
  return RegexBuildResult(
    regexTerms: regexTerms,
    slop: 0,
    maxExpansions: 100,
  );
}

/// חישוב מרווח מקסימלי
int _getMaxCustomSpacing(Map<String, String> customSpacing, int wordCount) {
  int maxSpacing = 0;
  
  for (int i = 0; i < wordCount - 1; i++) {
    final spacingKey = '$i-${i + 1}';
    final customSpacingValue = customSpacing[spacingKey];
    
    if (customSpacingValue != null && customSpacingValue.isNotEmpty) {
      final spacingNum = int.tryParse(customSpacingValue) ?? 0;
      maxSpacing = maxSpacing > spacingNum ? maxSpacing : spacingNum;
    }
  }
  
  return maxSpacing;
}

/// חישוב maxExpansions
int _calculateMaxExpansions(
  bool fuzzy,
  int termCount, {
  Map<String, Map<String, bool>>? searchOptions,
  List<String>? words,
}) {
  bool hasSuffixOrPrefix = false;
  int shortestWordLength = 10;
  
  if (searchOptions != null && words != null) {
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final wordKey = '${word}_$i';
      final wordOptions = searchOptions[wordKey] ?? {};
      
      if (wordOptions['סיומות'] == true ||
          wordOptions['קידומות'] == true ||
          wordOptions['קידומות דקדוקיות'] == true ||
          wordOptions['סיומות דקדוקיות'] == true ||
          wordOptions['חלק ממילה'] == true) {
        hasSuffixOrPrefix = true;
        if (word.length < shortestWordLength) {
          shortestWordLength = word.length;
        }
      }
    }
  }
  
  if (fuzzy) {
    return 50;
  } else if (hasSuffixOrPrefix) {
    if (shortestWordLength <= 1) {
      return 2000;
    } else if (shortestWordLength <= 2) {
      return 3000;
    } else if (shortestWordLength <= 3) {
      return 4000;
    } else {
      return 5000;
    }
  } else if (termCount > 1) {
    return 100;
  } else {
    return 10;
  }
}

// פונקציות עזר ליצירת דפוסי רגקס
String _createSpellingPattern(String word) {
  // יצירת וריאציות כתיב מלא/חסר
  return word.replaceAll('י', '[י]?')
             .replaceAll('ו', '[ו]?')
             .replaceAll("'", "['\"]*");
}

String _createPrefixPattern(String word) {
  return r'(ו|מ|כ|ב|ש|ל|ה|ד)?(כ|ב|ש|ל|ה|ד)?(ה)?' + RegExp.escape(word);
}

String _createSuffixPattern(String word) {
  return RegExp.escape(word) + r'(ות|ים|יה|יו|יך|ינו|יכם|יכן|יהם|יהן|י|ך|ו|ה|נו|כם|כן|ם|ן)?';
}

String _createFullMorphologicalPattern(String word) {
  return r'(ו|מ|כ|ב|ש|ל|ה|ד)?(כ|ב|ש|ל|ה|ד)?(ה)?' + 
         RegExp.escape(word) + 
         r'(ות|ים|יה|יו|יך|ינו|יכם|יכן|יהם|יהן|י|ך|ו|ה|נו|כם|כן|ם|ן)?';
}
