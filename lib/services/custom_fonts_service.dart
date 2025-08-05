import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter/foundation.dart';

class CustomFont {
  final String id;
  final String displayName;
  final String fileName;
  final String filePath;

  CustomFont({
    required this.id,
    required this.displayName,
    required this.fileName,
    required this.filePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'fileName': fileName,
        'filePath': filePath,
      };

  factory CustomFont.fromJson(Map<String, dynamic> json) => CustomFont(
        id: json['id'],
        displayName: json['displayName'],
        fileName: json['fileName'],
        filePath: json['filePath'],
      );
}

class CustomFontsService {
  static const String _customFontsKey = 'custom-fonts-list';
  static const int _maxCustomFonts = 20; // הגבלת מספר הגופנים האישיים
  static CustomFontsService? _instance;
  static CustomFontsService get instance => _instance ??= CustomFontsService._();
  
  CustomFontsService._();

  List<CustomFont> _loadedFonts = [];
  final Map<String, FontLoader> _fontLoaders = {};
  String? _lastError;

  Future<Directory> get _customFontsDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final fontsDir = Directory('${appDir.path}/otzaria/custom_fonts');
    if (!await fontsDir.exists()) {
      await fontsDir.create(recursive: true);
    }
    return fontsDir;
  }

  Future<List<CustomFont>> getCustomFonts() async {
    if (_loadedFonts.isEmpty) {
      await _loadCustomFonts();
    }
    return List.from(_loadedFonts);
  }

  Future<void> _loadCustomFonts() async {
    try {
      final fontsJson = Settings.getValue<String>(_customFontsKey);
      if (fontsJson != null && fontsJson.isNotEmpty) {
        final List<dynamic> fontsList = json.decode(fontsJson);
        final loadedFonts = <CustomFont>[];
        
        // טעינת הגופנים ל-Flutter עם בדיקת תקינות
        for (final fontJson in fontsList) {
          try {
            final font = CustomFont.fromJson(fontJson);
            
            // בדיקה שהקובץ עדיין קיים
            if (await File(font.filePath).exists()) {
              await _loadFontToFlutter(font);
              loadedFonts.add(font);
            } else {
              if (kDebugMode) {
                print('Font file not found, removing from list: ${font.displayName}');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error loading font: $e');
            }
          }
        }
        
        _loadedFonts = loadedFonts;
        
        // שמירת הרשימה המעודכנת (ללא גופנים שנמחקו)
        if (loadedFonts.length != fontsList.length) {
          await _saveCustomFonts();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading custom fonts: $e');
      }
      _loadedFonts = [];
      // ניסיון לאפס את הרשימה במקרה של שחיתות
      try {
        await Settings.setValue(_customFontsKey, '[]');
      } catch (_) {}
    }
  }

  Future<bool> addCustomFont(String filePath, String displayName) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Font file does not exist');
      }

      // בדיקת תקינות הגופן
      if (!_isValidFontFile(filePath)) {
        throw Exception('Invalid font file format');
      }

      // בדיקת גודל הקובץ (מקסימום 10MB)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Font file is too large (max 10MB)');
      }

      // בדיקה שלא קיים כבר גופן עם אותו שם
      if (_loadedFonts.any((font) => font.displayName == displayName)) {
        throw Exception('Font with this name already exists');
      }

      // בדיקת הגבלת מספר הגופנים
      if (_loadedFonts.length >= _maxCustomFonts) {
        throw Exception('Maximum number of custom fonts reached ($_maxCustomFonts)');
      }

      final fontsDir = await _customFontsDirectory;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
      final newFilePath = '${fontsDir.path}/$fileName';
      
      // העתקת הקובץ
      await file.copy(newFilePath);

      final customFont = CustomFont(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        displayName: displayName,
        fileName: fileName,
        filePath: newFilePath,
      );

      // טעינת הגופן ל-Flutter
      await _loadFontToFlutter(customFont);

      _loadedFonts.add(customFont);
      await _saveCustomFonts();

      if (kDebugMode) {
        print('Successfully added custom font: $displayName');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding custom font: $e');
      }
      rethrow;
    }
  }

  Future<bool> removeCustomFont(String fontId) async {
    try {
      final fontIndex = _loadedFonts.indexWhere((font) => font.id == fontId);
      if (fontIndex == -1) return false;

      final font = _loadedFonts[fontIndex];
      
      // מחיקת הקובץ
      final file = File(font.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // הסרה מהזיכרון
      _loadedFonts.removeAt(fontIndex);
      _fontLoaders.remove(font.id);

      await _saveCustomFonts();
      return true;
    } catch (e) {
      print('Error removing custom font: $e');
      return false;
    }
  }

  Future<void> _loadFontToFlutter(CustomFont font) async {
    try {
      if (_fontLoaders.containsKey(font.id)) return;

      final file = File(font.filePath);
      if (!await file.exists()) {
        throw Exception('Font file not found: ${font.filePath}');
      }

      final fontLoader = FontLoader(font.id);
      final fontData = await file.readAsBytes();
      
      if (fontData.isEmpty) {
        throw Exception('Font file is empty: ${font.filePath}');
      }
      
      fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
      await fontLoader.load();
      
      _fontLoaders[font.id] = fontLoader;
      
      if (kDebugMode) {
        print('Successfully loaded font: ${font.displayName}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading font ${font.displayName}: $e');
      }
      // הסרת הגופן מהרשימה אם הטעינה נכשלה
      _loadedFonts.removeWhere((f) => f.id == font.id);
      rethrow;
    }
  }

  Future<void> _saveCustomFonts() async {
    try {
      final fontsJson = json.encode(_loadedFonts.map((font) => font.toJson()).toList());
      await Settings.setValue(_customFontsKey, fontsJson);
    } catch (e) {
      print('Error saving custom fonts: $e');
    }
  }

  bool _isValidFontFile(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    return ['ttf', 'otf'].contains(extension);
  }

  Future<bool> validateFontFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _lastError = 'קובץ הגופן לא נמצא';
        return false;
      }
      
      if (!_isValidFontFile(filePath)) {
        _lastError = 'פורמט הקובץ לא נתמך. יש להשתמש בקבצי TTF או OTF בלבד';
        return false;
      }
      
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        _lastError = 'הקובץ גדול מדי (מקסימום 10MB)';
        return false;
      }
      
      if (fileSize < 100) {
        _lastError = 'הקובץ קטן מדי או פגום';
        return false;
      }
      
      // בדיקה בסיסית של תוכן הקובץ
      final bytes = await file.readAsBytes();
      
      // בדיקת חתימת TTF/OTF
      if (bytes.length >= 4) {
        final signature = String.fromCharCodes(bytes.take(4));
        final isValidTTF = signature == '\x00\x01\x00\x00' || signature == 'true' || signature == 'typ1';
        final isValidOTF = signature == 'OTTO';
        
        if (!isValidTTF && !isValidOTF) {
          _lastError = 'הקובץ אינו קובץ גופן תקין';
          return false;
        }
      }
      
      _lastError = null;
      return true;
    } catch (e) {
      _lastError = 'שגיאה בבדיקת הקובץ: ${e.toString()}';
      return false;
    }
  }

  String? getLastError() {
    return _lastError;
  }

  Future<void> initializeCustomFonts() async {
    await _loadCustomFonts();
  }

  bool isFontLoaded(String fontId) {
    return _fontLoaders.containsKey(fontId);
  }

  /// ניקוי זיכרון - הסרת גופנים שלא בשימוש
  void cleanup() {
    // כאן ניתן להוסיף לוגיקה לניקוי גופנים שלא בשימוש
    // לעת עתה נשאיר ריק
  }

  /// קבלת מידע על שימוש בזיכרון
  Map<String, dynamic> getMemoryInfo() {
    return {
      'loadedFontsCount': _loadedFonts.length,
      'loadedFontLoadersCount': _fontLoaders.length,
      'maxCustomFonts': _maxCustomFonts,
    };
  }

  Future<bool> renameCustomFont(String fontId, String newName) async {
    try {
      final fontIndex = _loadedFonts.indexWhere((font) => font.id == fontId);
      if (fontIndex == -1) return false;

      // בדיקה שלא קיים כבר גופן עם אותו שם
      if (_loadedFonts.any((font) => font.displayName == newName && font.id != fontId)) {
        throw Exception('Font with this name already exists');
      }

      // עדכון השם
      final oldFont = _loadedFonts[fontIndex];
      final updatedFont = CustomFont(
        id: oldFont.id,
        displayName: newName,
        fileName: oldFont.fileName,
        filePath: oldFont.filePath,
      );

      _loadedFonts[fontIndex] = updatedFont;
      await _saveCustomFonts();

      if (kDebugMode) {
        print('Successfully renamed custom font to: $newName');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error renaming custom font: $e');
      }
      rethrow;
    }
  }
}