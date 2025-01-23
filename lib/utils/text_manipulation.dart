import 'dart:io';

import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:otzaria/models/books.dart';

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

Future<String> refFromIndex(
    int index, Future<List<TocEntry>> tableOfContents) async {
  List<TocEntry> toc = await tableOfContents;
  List<String> texts = [];

  void searchToc(List<TocEntry> entries, int index) {
    for (final TocEntry entry in entries) {
      if (entry.index > index) {
        return;
      }
      if (entry.level > texts.length) {
        texts.add(entry.text);
      } else {
        texts[entry.level - 1] = entry.text;
        texts = texts.getRange(0, entry.level).toList();
      }

      searchToc(entry.children, index);
    }
  }

  searchToc(toc, index);

  texts = texts.map((e) => e.trim()).toList();
  return texts.join(', ');
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
  s = s.replaceAll("יהוה", "יקוק").replaceAll("יְהֹוָה", "יְקׂוָק");
  return s;
}

String removeTeamim(String s) => s
    .replaceAll('־', ' ')
    .replaceAll(' ׀', '')
    .replaceAll('ֽ', '')
    .replaceAll('׀', '')
    .replaceAll(RegExp(r'[\u0591-\u05AF]'), '');
