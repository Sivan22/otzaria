import 'dart:io';

import 'package:otzaria/data/data_providers/file_system_data_provider.dart';

String stripHtmlIfNeeded(String text) {
  return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '');
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

String paraphrase(String text) {
  Map<String, String> paraphrases = {
    '־': ' ',
    'שוע': 'שולחן ערוך',
    'שך': 'שפתי כהן',
    'טז': 'טורי זהב',
    'חומ': 'חושן משפט',
    'יוד': 'יורה דעה',
    'אהעז': 'אבן העזר',
    'אוח': 'אורח חיים',
    'בק': 'בבא קמא',
    'במ': 'בבא מציעא',
    'בב': 'בבא בתרא',
    'ראבד': 'ראב"ד',
    'בח': 'ב"ח'
  };
  for (var key in paraphrases.keys) {
    text = text.replaceAll(key, paraphrases[key] ?? key);
  }

  return text;
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
      .replaceAll("יְהֹוָ֑ה", "יְקׂוָ֑ק");
  return s;
}

String removeTeamim(String s) => s
    .replaceAll('־', ' ')
    .replaceAll(' ׀', '')
    .replaceAll('ֽ', '')
    .replaceAll('׀', '')
    .replaceAll(RegExp(r'[\u0591-\u05AF]'), '');
