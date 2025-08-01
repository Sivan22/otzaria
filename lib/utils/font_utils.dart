import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:otzaria/widgets/font_preview_dialog.dart';
import 'package:otzaria/services/custom_fonts_service.dart';

class FontUtils {
  static Future<String?> pickFontFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ttf', 'otf'],
        dialogTitle: 'בחר קובץ גופן',
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single.path!;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> showFontPreviewDialog(
    BuildContext context,
    String fontFilePath,
  ) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => FontPreviewDialog(
        fontFilePath: fontFilePath,
        onConfirm: (displayName) {
          Navigator.of(context).pop(displayName);
        },
        onCancel: () {
          Navigator.of(context).pop(null);
        },
      ),
    );
  }

  static Future<String?> pickAndPreviewFont(BuildContext context) async {
    // בחירת קובץ גופן
    final fontPath = await pickFontFile();
    if (fontPath == null) return null;

    // הצגת תצוגה מקדימה
    final displayName = await showFontPreviewDialog(context, fontPath);
    if (displayName == null) return null;

    return displayName;
  }

  static Map<String, String> getBuiltInFonts() {
    return const {
      'TaameyDavidCLM': 'דוד',
      'FrankRuhlCLM': 'פרנק-רוהל',
      'TaameyAshkenaz': 'טעמי אשכנז',
      'KeterYG': 'כתר',
      'Shofar': 'שופר',
      'NotoSerifHebrew': 'נוטו',
      'Tinos': 'טינוס',
      'NotoRashiHebrew': 'רש"י',
      'Candara': 'קנדרה',
      'roboto': 'רובוטו',
      'Calibri': 'קליברי',
      'Arial': 'אריאל',
    };
  }

  static bool isCustomFont(String fontFamily, List<String> customFontIds) {
    return customFontIds.contains(fontFamily);
  }

  static String getFontFamilyForDisplay(String fontFamily, List<CustomFont> customFonts) {
    // בדיקה אם זה גופן אישי
    final customFont = customFonts.firstWhere(
      (font) => font.id == fontFamily,
      orElse: () => CustomFont(id: '', displayName: '', fileName: '', filePath: ''),
    );
    
    if (customFont.id.isNotEmpty) {
      // זה גופן אישי - החזר את ה-ID שלו (שהוא גם ה-fontFamily ב-Flutter)
      return customFont.id;
    }
    
    // זה גופן מובנה - החזר את השם כמו שהוא
    return fontFamily;
  }

  static String? getFallbackFont(String fontFamily, List<CustomFont> customFonts) {
    // אם הגופן הנוכחי הוא גופן אישי שלא קיים יותר
    if (!getBuiltInFonts().containsKey(fontFamily)) {
      final customFont = customFonts.firstWhere(
        (font) => font.id == fontFamily,
        orElse: () => CustomFont(id: '', displayName: '', fileName: '', filePath: ''),
      );
      
      if (customFont.id.isEmpty) {
        // הגופן לא נמצא - החזר גופן ברירת מחדל
        return 'FrankRuhlCLM';
      }
    }
    
    return null; // הגופן תקין
  }
}