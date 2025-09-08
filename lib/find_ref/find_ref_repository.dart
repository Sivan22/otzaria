import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:search_engine/search_engine.dart';

class FindRefRepository {
  final DataRepository dataRepository;

  FindRefRepository({required this.dataRepository});

  Future<List<ReferenceSearchResult>> findRefs(String ref) async {
    // שלב 1: שלוף יותר תוצאות מהרגיל כדי לפצות על אלו שיסוננו
    final rawResults = await TantivyDataProvider.instance
        .searchRefs(replaceParaphrases(removeSectionNames(ref)), 300, false);

    // שלב 2: בצע סינון כפילויות (דה-דופליקציה) חכם
    final unique = _dedupeRefs(rawResults);

    // שלב 3: החזר עד 100 תוצאות ייחודיות
    return unique.length > 100
        ? unique.take(100).toList(growable: false)
        : unique;
  }

  /// מסננת רשימת תוצאות ומשאירה רק את הייחודיות על בסיס מפתח מורכב.
  List<ReferenceSearchResult> _dedupeRefs(List<ReferenceSearchResult> results) {
    final seen = <String>{}; // סט לשמירת מפתחות שכבר נראו
    final out = <ReferenceSearchResult>[];

    for (final r in results) {
      // יצירת מפתח ייחודי חכם שמורכב מ-3 חלקים:

      // 1. טקסט ההפניה לאחר נרמול
      final refKey = _normalize(r.reference);

      // 2. יעד ההפניה (קובץ ספציפי או שם ספר וסוג)
      final file = (r.filePath ?? '').trim().toLowerCase();
      final title = (r.title ?? '').trim().toLowerCase();
      final typ = r.isPdf ? 'pdf' : 'txt';
      final dest = file.isNotEmpty ? file : '$title|$typ';

      // 3. המיקום המדויק בתוך היעד
      final seg = _segNum(r.segment);

      // הרכבת המפתח הסופי
      final key = '$refKey|$dest|$seg';

      // הוסף לרשימת הפלט רק אם המפתח לא נראה בעבר
      if (seen.add(key)) {
        out.add(r);
      }
    }
    return out;
  }

  /// פונקציית עזר לנרמול טקסט: מורידה רווחים, הופכת לאותיות קטנות ומאחדת רווחים.
  String _normalize(String? s) =>
      (s ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// פונקציית עזר להמרת 'segment' למספר שלם (int) בצורה בטוחה.
  int _segNum(dynamic s) {
    if (s is num) return s.round();
    return int.tryParse(s?.toString() ?? '') ?? 0;
  }
}
