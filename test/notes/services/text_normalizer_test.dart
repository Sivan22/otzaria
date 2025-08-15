import 'package:flutter_test/flutter_test.dart';
import 'package:otzaria/notes/services/text_normalizer.dart';
import 'package:otzaria/notes/config/notes_config.dart';

void main() {
  group('TextNormalizer Tests', () {
    late NormalizationConfig config;

    setUp(() {
      config = const NormalizationConfig(
        removeNikud: false,
        quoteStyle: 'ascii',
        unicodeForm: 'NFKC',
      );
    });

    group('Basic Normalization', () {
      test('should normalize multiple spaces to single space', () {
        const input = 'שלום    עולם';
        final result = TextNormalizer.normalize(input, config);
        expect(result, equals('שלום עולם'));
      });

      test('should trim whitespace from beginning and end', () {
        const input = '  שלום עולם  ';
        final result = TextNormalizer.normalize(input, config);
        expect(result, equals('שלום עולם'));
      });

      test('should handle empty string', () {
        const input = '';
        final result = TextNormalizer.normalize(input, config);
        expect(result, equals(''));
      });

      test('should handle whitespace-only string', () {
        const input = '   \t\n  ';
        final result = TextNormalizer.normalize(input, config);
        expect(result, equals(''));
      });
    });

    group('Quote Normalization', () {
      test('should normalize smart quotes to ASCII', () {
        const input = '"שלום" ו\'עולם\'';
        final result = TextNormalizer.normalize(input, config);
        expect(result, equals('"שלום" ו\'עולם\''));
      });

      test('should normalize Hebrew quotes', () {
        const input = '״שלום״ ו׳עולם׳';
        final result = TextNormalizer.normalize(input, config);
        expect(result, equals('"שלום" ו\'עולם\''));
      });

      test('should handle mixed quote types', () {
        const input = '«שלום» "עולם" \'טוב\'';
        final result = TextNormalizer.normalize(input, config);
        expect(result, equals('"שלום" "עולם" \'טוב\''));
      });
    });

    group('Directional Marks', () {
      test('should remove LTR and RTL marks', () {
        const input = 'שלום\u200Eעולם\u200F';
        final result = TextNormalizer.normalize(input, config);
        expect(result, equals('שלוםעולם'));
      });

      test('should remove embedding controls', () {
        const input = 'שלום\u202Aעולם\u202C';
        final result = TextNormalizer.normalize(input, config);
        expect(result, equals('שלוםעולם'));
      });

      test('should remove zero-width joiners', () {
        const input = 'שלום\u200Cעולם\u200D';
        final result = TextNormalizer.normalize(input, config);
        expect(result, equals('שלוםעולם'));
      });
    });

    group('Nikud Handling', () {
      test('should preserve nikud when configured', () {
        const input = 'שָׁלוֹם עוֹלָם';
        final configWithNikud = NormalizationConfig(
          removeNikud: false,
          quoteStyle: 'ascii',
          unicodeForm: 'NFKC',
        );
        final result = TextNormalizer.normalize(input, configWithNikud);
        expect(result, contains('שָׁלוֹם'));
        expect(result, contains('עוֹלָם'));
      });

      test('should remove nikud when configured', () {
        const input = 'שָׁלוֹם עוֹלָם';
        final configWithoutNikud = NormalizationConfig(
          removeNikud: true,
          quoteStyle: 'ascii',
          unicodeForm: 'NFKC',
        );
        final result = TextNormalizer.normalize(input, configWithoutNikud);
        expect(result, equals('שלום עולם'));
      });
    });

    group('Normalization Stability', () {
      test('should be idempotent', () {
        const input = '  "שָׁלוֹם    עוֹלָם"  \u200E';
        final result1 = TextNormalizer.normalize(input, config);
        final result2 = TextNormalizer.normalize(result1, config);
        expect(result1, equals(result2));
      });

      test('should validate normalization stability', () {
        const input = '  "שלום    עולם"  ';
        final isStable = TextNormalizer.validateNormalization(input, config);
        expect(isStable, isTrue);
      });
    });

    group('Context Window Extraction', () {
      test('should extract context window correctly', () {
        const text = 'זה טקסט לדוגמה עם הרבה מילים בתוכו';
        final window = TextNormalizer.extractContextWindow(text, 10, 15);
        
        expect(window.selected, equals('וגמה '));
        expect(window.before, equals('זה טקסט לד'));
        expect(window.after, equals('עם הרבה מילים בתוכו'));
        expect(window.selectedStart, equals(10));
        expect(window.selectedEnd, equals(15));
      });

      test('should handle context window at text boundaries', () {
        const text = 'קצר';
        final window = TextNormalizer.extractContextWindow(text, 0, 2);
        
        expect(window.selected, equals('קצ'));
        expect(window.before, equals(''));
        expect(window.after, equals('ר'));
      });

      test('should respect window size limits', () {
        final text = 'א' * 200; // 200 characters
        final window = TextNormalizer.extractContextWindow(text, 100, 110, windowSize: 20);
        
        expect(window.before.length, equals(20));
        expect(window.after.length, equals(20));
        expect(window.selected.length, equals(10));
      });
    });

    group('Context Window Normalization', () {
      test('should normalize all parts of context window', () {
        final window = ContextWindow(
          before: '  "לפני"  ',
          selected: '  "נבחר"  ',
          after: '  "אחרי"  ',
          beforeStart: 0,
          selectedStart: 10,
          selectedEnd: 20,
          afterEnd: 30,
        );
        
        final normalized = TextNormalizer.normalizeContextWindow(window, config);
        
        expect(normalized.before, equals('"לפני"'));
        expect(normalized.selected, equals('"נבחר"'));
        expect(normalized.after, equals('"אחרי"'));
      });
    });

    group('Configuration', () {
      test('should create config from settings', () {
        final config = TextNormalizer.createConfigFromSettings();
        expect(config.quoteStyle, equals('ascii'));
        expect(config.unicodeForm, equals('NFKC'));
      });
    });
  });

  group('ContextWindow Tests', () {
    test('should calculate total length correctly', () {
      final window = ContextWindow(
        before: 'לפני',
        selected: 'נבחר',
        after: 'אחרי',
        beforeStart: 0,
        selectedStart: 4,
        selectedEnd: 8,
        afterEnd: 12,
      );
      
      expect(window.totalLength, equals(12)); // 4 + 4 + 4
    });

    test('should provide meaningful toString', () {
      final window = ContextWindow(
        before: 'לפני',
        selected: 'נבחר',
        after: 'אחרי',
        beforeStart: 0,
        selectedStart: 4,
        selectedEnd: 8,
        afterEnd: 12,
      );
      
      final string = window.toString();
      expect(string, contains('4 chars'));
    });
  });
}