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

String replaceHolyNames(String s) {
  s = s
      .replaceAll("יהוה", "יקוק")
      .replaceAll("יְהֹוָה", "יְקׂוָק")
      .replaceAll("יְהֹוָ֤ה", "יְקׂוָ֤ק")
      .replaceAll("יְהֹוָ֨ה", "יְקׂוָ֨ק")
      .replaceAll("יְהֹוָ֥ה", "יְקׂוָ֥ק")
      .replaceAll("יְהֹוָ֖ה", "יְקׂוָ֖ק")
      .replaceAll("יְהֹוָ֧ה", "יְקׂוָ֧ק")
      .replaceAll("יְהֹוָ֣ה", "יְקׂוָ֣ק")
      .replaceAll("יְהֹוָה֙", "יְקׂוָק֙")
      .replaceAll("יְהֹוָֽה", "יְקׂוָֽק")
      .replaceAll("יְהֹוָ֛ה", "יְְקׂוָ֛ק")
      .replaceAll("יְהֹוָ֜ה", "יְקׂוָ֜ק")
      .replaceAll("ַֽיהֹוָ֣ה", "ַֽיקׂוָ֣ק")
      .replaceAll("יהֹוָ֗ה", "יקׂוָ֗ק")
      .replaceAll("יְהֹוָ֞ה", "יְקׂוָ֞ק")
      .replaceAll("יהֹוָֽה", "יקׂוָֽק")
      .replaceAll("יהֹוָה֮", "יקׂוָק֮")
      .replaceAll("ַיהֹוָ֥ה", "ַיקׂוָ֥ק")
      .replaceAll("יְהֹוָ֔ה", "יְקׂוָ֔ק")
      .replaceAll("יְהֹוָ֑ה", "יְקׂוָ֑ק");
  return s;
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
