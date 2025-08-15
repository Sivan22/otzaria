import 'package:flutter_test/flutter_test.dart';
import 'package:otzaria/notes/services/hash_generator.dart';

void main() {
  group('HashGenerator Tests', () {
    group('Text Hash Generation', () {
      test('should generate consistent SHA-256 hashes', () {
        const text = 'שלום עולם';
        final hash1 = HashGenerator.generateTextHash(text);
        final hash2 = HashGenerator.generateTextHash(text);
        
        expect(hash1, equals(hash2));
        expect(hash1.length, equals(64)); // SHA-256 produces 64 character hex string
      });

      test('should generate different hashes for different texts', () {
        const text1 = 'שלום עולם';
        const text2 = 'שלום עולם טוב';
        
        final hash1 = HashGenerator.generateTextHash(text1);
        final hash2 = HashGenerator.generateTextHash(text2);
        
        expect(hash1, isNot(equals(hash2)));
      });

      test('should handle empty string', () {
        const text = '';
        final hash = HashGenerator.generateTextHash(text);
        
        expect(hash, isNotEmpty);
        expect(hash.length, equals(64));
      });

      test('should be case sensitive', () {
        const text1 = 'Hello World';
        const text2 = 'hello world';
        
        final hash1 = HashGenerator.generateTextHash(text1);
        final hash2 = HashGenerator.generateTextHash(text2);
        
        expect(hash1, isNot(equals(hash2)));
      });
    });

    group('Rolling Hash Generation', () {
      test('should generate consistent rolling hashes', () {
        const text = 'שלום עולם';
        final hash1 = HashGenerator.generateRollingHash(text);
        final hash2 = HashGenerator.generateRollingHash(text);
        
        expect(hash1, equals(hash2));
      });

      test('should generate different hashes for different texts', () {
        const text1 = 'שלום עולם';
        const text2 = 'שלום עולם טוב';
        
        final hash1 = HashGenerator.generateRollingHash(text1);
        final hash2 = HashGenerator.generateRollingHash(text2);
        
        expect(hash1, isNot(equals(hash2)));
      });

      test('should handle empty string', () {
        const text = '';
        final hash = HashGenerator.generateRollingHash(text);
        
        expect(hash, equals(0));
      });

      test('should be order sensitive', () {
        const text1 = 'ab';
        const text2 = 'ba';
        
        final hash1 = HashGenerator.generateRollingHash(text1);
        final hash2 = HashGenerator.generateRollingHash(text2);
        
        expect(hash1, isNot(equals(hash2)));
      });
    });

    group('Combined Hash Generation', () {
      test('should generate text hashes with all components', () {
        const text = 'שלום עולם';
        final hashes = HashGenerator.generateTextHashes(text);
        
        expect(hashes.textHash, isNotEmpty);
        expect(hashes.textHash.length, equals(64));
        expect(hashes.rollingHash, isA<int>());
        expect(hashes.length, equals(text.length));
      });

      test('should generate context hashes', () {
        const before = 'לפני';
        const after = 'אחרי';
        
        final hashes = HashGenerator.generateContextHashes(before, after);
        
        expect(hashes.beforeHash, isNotEmpty);
        expect(hashes.afterHash, isNotEmpty);
        expect(hashes.beforeHash.length, equals(64));
        expect(hashes.afterHash.length, equals(64));
        expect(hashes.beforeRollingHash, isA<int>());
        expect(hashes.afterRollingHash, isA<int>());
      });
    });
  });

  group('RollingHashWindow Tests', () {
    test('should initialize with text correctly', () {
      final window = RollingHashWindow(5);
      window.init('hello');
      
      expect(window.isFull, isTrue);
      expect(window.currentWindow, equals('hello'));
      expect(window.currentHash, isA<int>());
    });

    test('should slide window correctly', () {
      final window = RollingHashWindow(3);
      window.init('abc');
      
      final initialHash = window.currentHash;
      expect(window.currentWindow, equals('abc'));
      
      // Slide to 'bcd'
      final newHash = window.slide('a'.codeUnitAt(0), 'd'.codeUnitAt(0));
      expect(window.currentWindow, equals('bcd'));
      expect(newHash, isNot(equals(initialHash)));
      expect(window.currentHash, equals(newHash));
    });

    test('should handle partial window initialization', () {
      final window = RollingHashWindow(5);
      window.init('hi');
      
      expect(window.isFull, isFalse);
      expect(window.currentWindow, equals('hi'));
    });

    test('should maintain consistent hash for same content', () {
      final window1 = RollingHashWindow(4);
      final window2 = RollingHashWindow(4);
      
      window1.init('test');
      window2.init('test');
      
      expect(window1.currentHash, equals(window2.currentHash));
    });

    test('should handle sliding with partial window', () {
      final window = RollingHashWindow(5);
      window.init('hi');
      
      expect(window.isFull, isFalse);
      
      // Add more characters
      window.slide(0, 'a'.codeUnitAt(0)); // Should add 'a'
      expect(window.currentWindow, equals('hia'));
      expect(window.isFull, isFalse);
    });
  });

  group('DocumentHasher Tests', () {
    test('should generate document version hash', () {
      const document = 'זהו מסמך לדוגמה עם הרבה טקסט';
      final version = DocumentHasher.generateDocumentVersion(document);
      
      expect(version, isNotEmpty);
      expect(version.length, equals(64));
    });

    test('should generate consistent document versions', () {
      const document = 'זהו מסמך לדוגמה';
      final version1 = DocumentHasher.generateDocumentVersion(document);
      final version2 = DocumentHasher.generateDocumentVersion(document);
      
      expect(version1, equals(version2));
    });

    test('should generate different versions for different documents', () {
      const doc1 = 'מסמך ראשון';
      const doc2 = 'מסמך שני';
      
      final version1 = DocumentHasher.generateDocumentVersion(doc1);
      final version2 = DocumentHasher.generateDocumentVersion(doc2);
      
      expect(version1, isNot(equals(version2)));
    });

    test('should generate section hash with index', () {
      const section = 'זהו קטע במסמך';
      const index = 5;
      
      final hash = DocumentHasher.generateSectionHash(section, index);
      
      expect(hash, isNotEmpty);
      expect(hash.length, equals(64));
    });

    test('should generate different section hashes for different indexes', () {
      const section = 'אותו קטע';
      
      final hash1 = DocumentHasher.generateSectionHash(section, 1);
      final hash2 = DocumentHasher.generateSectionHash(section, 2);
      
      expect(hash1, isNot(equals(hash2)));
    });

    test('should generate incremental hash', () {
      const previousHash = 'abc123';
      const newContent = 'תוכן חדש';
      
      final incrementalHash = DocumentHasher.generateIncrementalHash(previousHash, newContent);
      
      expect(incrementalHash, isNotEmpty);
      expect(incrementalHash.length, equals(64));
      expect(incrementalHash, isNot(equals(previousHash)));
    });
  });

  group('Hash Container Tests', () {
    test('TextHashes should provide meaningful toString', () {
      final hashes = TextHashes(
        textHash: 'abcdef1234567890' * 4, // 64 chars
        rollingHash: 12345,
        length: 10,
      );
      
      final string = hashes.toString();
      expect(string, contains('abcdef12'));
      expect(string, contains('12345'));
      expect(string, contains('10'));
    });

    test('ContextHashes should provide meaningful toString', () {
      final hashes = ContextHashes(
        beforeHash: 'before12' + '0' * 56,
        afterHash: 'after123' + '0' * 56,
        beforeRollingHash: 111,
        afterRollingHash: 222,
      );
      
      final string = hashes.toString();
      expect(string, contains('before12'));
      expect(string, contains('after123'));
    });
  });
}