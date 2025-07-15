import 'dart:io';

import 'package:otzaria/data/data_providers/file_system_data_provider.dart';

String stripHtmlIfNeeded(String text) {
  return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '');
}

String truncate(String text, int length) {
  return text.length > length ? '${text.substring(0, length)}...' : text;
}

String removeVolwels(String s) {
  s = s.replaceAll('־', ' ').replaceAll(' ׀', '');
  return s.replaceAll(RegExp(r'[\u0591-\u05C7]'), '');
}

String highLight(String data, String searchQuery) {
  if (searchQuery.isNotEmpty) {
    return data.replaceAll(searchQuery, '<font color=red>$searchQuery</font>');
  }
  return data;
}

String getTitleFromPath(String path) {
  path = path
      .replaceAll('/', Platform.pathSeparator)
      .replaceAll('\\', Platform.pathSeparator);
  return path.split(Platform.pathSeparator).last.split('.').first;
}

Future<bool> hasTopic(String title, String topic) async {
  final titleToPath = await FileSystemData.instance.titleToPath;
  return titleToPath[title]?.contains(topic) ?? false;
}


// Matches the Tetragrammaton with any Hebrew diacritics or cantillation marks.
final RegExp _holyNameRegex = RegExp(
  r"י([\p{Mn}]*)ה([\p{Mn}]*)ו([\p{Mn}]*)ה([\p{Mn}]*)",
  unicode: true,
);

String replaceHolyNames(String s) {
  return s.replaceAllMapped(
    _holyNameRegex,
    (match) => 'י${match[1]}ק${match[2]}ו${match[3]}ק${match[4]}',
  );
}

String removeTeamim(String s) => s
    .replaceAll('־', ' ')
    .replaceAll(' ׀', '')
    .replaceAll('ֽ', '')
    .replaceAll('׀', '')
    .replaceAll(RegExp(r'[\u0591-\u05AF]'), '');

String removeSectionNames(String s) => s
    .replaceAll('פרק ', '')
    .replaceAll('פסוק ', '')
    .replaceAll('פסקה ', '')
    .replaceAll('סעיף ', '')
    .replaceAll('סימן ', '')
    .replaceAll('הלכה ', '')
    .replaceAll('מאמר ', '')
    .replaceAll('קטן  ', '')
    .replaceAll('משנה  ', '')
    .replaceAll('"', '')
    .replaceAll("'", '')
    .replaceAll(',', '')
    .replaceAll(':', ' ב')
    .replaceAll('.', ' א');

String replaceParaphrases(String s) {
  s = s
      .replaceAll(' שוע', ' שולחן ערוך')
      .replaceAll(' בב', ' בבא בתרא')
      .replaceAll(' בק', ' בבא קמא')
      .replaceAll('אוח', 'אורח חיים')
      .replaceAll(' יוד', ' יורה דעה')
      .replaceAll(' חומ', ' חושן משפט')
      .replaceAll('משנה תורה', 'רמבם')
      .replaceAll(' במ', 'בבא מציעא')
      .replaceAll('אהעז', 'אבן העזר')
      .replaceAll('שך', 'שפתי כהן')
      .replaceAll('סמע', 'מאירת עינים')
      .replaceAll('בש', 'בית שמואל')
      .replaceAll('קצהח', 'קצות החושן')
      .replaceAll('נתיהמ', 'נתיבות המשפט')
      .replaceAll('פתש', 'פתחי תשובה')
      .replaceAll('משנב', 'משנה ברורה')
      .replaceAll('שטמק', 'שיטה מקובצת')
      .replaceAll('פמג', 'פרי מגדים')
      .replaceAll('פרמג', 'פרי מגדים')
      .replaceAll(' פרח', ' פרי חדש')
      .replaceAll(' שע', ' שולחן ערוך');

  if (s.startsWith("טז")) {
    s = s.replaceFirst("טז", "טורי זהב");
  }

  if (s.startsWith("מב")) {
    s = s.replaceFirst("מב", "משנה ברורה");
  }

  return s;
}

//פונקציה לחלוקת פרשנים לפי תקופה
Future<Map<String, List<String>>> splitByEra(
  List<String> titles,
) async {
  // יוצרים מבנה נתונים ריק לכל שלוש הקטגוריות
  final Map<String, List<String>> byEra = {
    'ראשונים': [],
    'אחרונים': [],
    'מחברי זמננו': [],
  };

  // ממיינים כל פרשן לקטגוריה הראשונה שמתאימה לו
  for (final t in titles) {
    if (await hasTopic(t, 'ראשונים')) {
      byEra['ראשונים']!.add(t);
    } else if (await hasTopic(t, 'אחרונים')) {
      byEra['אחרונים']!.add(t);
    } else if (await hasTopic(t, 'מחברי זמננו')) {
      byEra['מחברי זמננו']!.add(t);
    }
  }
  return byEra;
}
