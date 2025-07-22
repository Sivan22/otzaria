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
    .replaceAll('קטן ', '')
    .replaceAll('משנה ', '')
    .replaceAll('י', '')
    .replaceAll('ו', '')
    .replaceAll('"', '')
    .replaceAll("'", '')
    .replaceAll(',', '')
    .replaceAll(':', ' ב')
    .replaceAll('.', ' א');

String replaceParaphrases(String s) {
  s = s
      .replaceAll(' מהדורא תנינא', ' מהדו"ת')
      .replaceAll(' מהדורא', ' מהדורה')
      .replaceAll(' מהדורה', ' מהדורא')
      .replaceAll(' פני', ' פני יהושע')
      .replaceAll(' תניינא', ' תנינא')
      .replaceAll(' תנינא', ' תניינא')
      .replaceAll(' אא', ' אשל אברהם')
      .replaceAll(' אבהע', ' אבן העזר')
      .replaceAll(' אבעז', ' אבן עזרא')
      .replaceAll(' אדז', ' אדרא זוטא')
      .replaceAll(' אדרא רבה', ' אדרא')
      .replaceAll(' אדרות', ' אדרא')
      .replaceAll(' אהע', ' אבן העזר')
      .replaceAll(' אהעז', ' אבן העזר')
      .replaceAll(' אוהח', ' אור החיים')
      .replaceAll(' אוח', ' אורח חיים')
      .replaceAll(' אורח', ' אורח חיים')
      .replaceAll(' אידרא', ' אדרא')
      .replaceAll(' אידרות', ' אדרא')
      .replaceAll(' ארבעה טורים', ' טור')
      .replaceAll(' באהג', ' באר הגולה')
      .replaceAll(' באוה', ' ביאור הלכה')
      .replaceAll(' באוהל', ' ביאור הלכה')
      .replaceAll(' באור הלכה', ' ביאור הלכה')
      .replaceAll(' בב', ' בבא בתרא')
      .replaceAll(' בהגרא', ' ביאור הגרא')
      .replaceAll(' בי', ' ביאור')
      .replaceAll(' בי', ' בית יוסף')
      .replaceAll(' ביאהל', ' ביאור הלכה')
      .replaceAll(' ביאו', ' ביאור')
      .replaceAll(' ביאוה', ' ביאור הלכה')
      .replaceAll(' ביאוהג', ' ביאור הגרא')
      .replaceAll(' ביאוהל', ' ביאור הלכה')
      .replaceAll(' ביהגרא', ' ביאור הגרא')
      .replaceAll(' ביהל', ' בית הלוי')
      .replaceAll(' במ', ' בבא מציעא')
      .replaceAll(' במדבר', ' במדבר רבה')
      .replaceAll(' במח', ' באר מים חיים')
      .replaceAll(' במר', ' במדבר רבה')
      .replaceAll(' בעהט', ' בעל הטורים')
      .replaceAll(' בק', ' בבא קמא')
      .replaceAll(' בר', ' בראשית רבה')
      .replaceAll(' ברר', ' בראשית רבה')
      .replaceAll(' בש', ' בית שמואל')
      .replaceAll(' ד', ' דף')
      .replaceAll(' דבר', ' דברים רבה')
      .replaceAll(' דהי', ' דברי הימים')
      .replaceAll(' דויד', ' דוד')
      .replaceAll(' דמ', ' דגול מרבבה')
      .replaceAll(' דמ', ' דרכי משה')
      .replaceAll(' דמר', ' דגול מרבבה')
      .replaceAll(' דרך ה', ' דרך השם')
      .replaceAll(' דרך פיקודיך', ' דרך פקודיך')
      .replaceAll(' דרמ', ' דרכי משה')
      .replaceAll(' דרפ', ' דרך פקודיך')
      .replaceAll(' האריזל', ' הארי')
      .replaceAll(' הגהות מיימוני', ' הגהות מיימוניות')
      .replaceAll(' הגהות מימוניות', ' הגהות מיימוניות')
      .replaceAll(' הגהמ', ' הגהות מיימוניות')
      .replaceAll(' הגמ', ' הגהות מיימוניות')
      .replaceAll(' הילכות', ' הלכות')
      .replaceAll(' הל', ' הלכות')
      .replaceAll(' הלכ', ' הלכות')
      .replaceAll(' הלכה', ' הלכות')
      .replaceAll(' המשנה', ' המשניות')
      .replaceAll(' ויקר', ' ויקרא רבה')
      .replaceAll(' ויר', ' ויקרא רבה')
      .replaceAll(' זהח', ' זוהר חדש')
      .replaceAll(' זהר חדש', ' זוהר חדש')
      .replaceAll(' זהר', ' זוהר')
      .replaceAll(' זוהח', ' זוהר חדש')
      .replaceAll(' זח', ' זוהר חדש')
      .replaceAll(' חדושי', ' חי')
      .replaceAll(' חוד', ' חוות דעת')
      .replaceAll(' חוהל', ' חובת הלבבות')
      .replaceAll(' חווד', ' חוות דעת')
      .replaceAll(' חומ', ' חושן משפט')
      .replaceAll(' חח', ' חפץ חיים')
      .replaceAll(' חי', ' חדושי')
      .replaceAll(' חידושי אגדות', ' חדושי אגדות')
      .replaceAll(' חידושי הלכות', ' חדושי הלכות')
      .replaceAll(' חידושי', ' חדושי')
      .replaceAll(' חידושי', ' חי')
      .replaceAll(' חתס', ' חתם סופר')
      .replaceAll(' יד החזקה', ' רמבם')
      .replaceAll(' יהושוע', ' יהושע')
      .replaceAll(' יוד', ' יורה דעה')
      .replaceAll(' יוט', ' יום טוב')
      .replaceAll(' יורד', ' יורה דעה')
      .replaceAll(' ילקוט', ' ילקוט שמעוני')
      .replaceAll(' ילקוש', ' ילקוט שמעוני')
      .replaceAll(' ילקש', ' ילקוט שמעוני')
      .replaceAll(' ירוש', ' ירושלמי')
      .replaceAll(' ירמי', ' ירמיהו')
      .replaceAll(' ירמיה', ' ירמיהו')
      .replaceAll(' ישעי', ' ישעיהו')
      .replaceAll(' ישעיה', ' ישעיהו')
      .replaceAll(' כופ', ' כרתי ופלתי')
      .replaceAll(' כפ', ' כרתי ופלתי')
      .replaceAll(' כרופ', ' כרתי ופלתי')
      .replaceAll(' כתס', ' כתב סופר')
      .replaceAll(' לחמ', ' לחם משנה')
      .replaceAll(' ליקוטי אמרים', ' תניא')
      .replaceAll(' מ', ' משנה')
      .replaceAll(' מאוש', ' מאור ושמש')
      .replaceAll(' מב', ' משנה ברורה')
      .replaceAll(' מגא', ' מגיני ארץ')
      .replaceAll(' מגא', ' מגן אברהם')
      .replaceAll(' מגילת', ' מגלת')
      .replaceAll(' מגמ', ' מגיד משנה')
      .replaceAll(' מד רבה', ' מדרש רבה')
      .replaceAll(' מד', ' מדרש')
      .replaceAll(' מדות', ' מידות')
      .replaceAll(' מדר', ' מדרש רבה')
      .replaceAll(' מדר', ' מדרש')
      .replaceAll(' מדרש רבא', ' מדרש רבה')
      .replaceAll(' מדת', ' מדרש תהלים')
      .replaceAll(' מהרשא', ' חדושי אגדות')
      .replaceAll(' מהרשא', ' חדושי הלכות')
      .replaceAll(' מונ', ' מורה נבוכים')
      .replaceAll(' מז', ' משבצות זהב')
      .replaceAll(' ממ', ' מגיד משנה')
      .replaceAll(' מסי', ' מסילת ישרים')
      .replaceAll(' מפרג', ' מפראג')
      .replaceAll(' מקוח', ' מקור חיים')
      .replaceAll(' מרד', ' מרדכי')
      .replaceAll(' משבז', ' משבצות זהב')
      .replaceAll(' משנב', ' משנה ברורה')
      .replaceAll(' משנה תורה', ' רמבם')
      .replaceAll(' משנה', ' משניות')
      .replaceAll(' נהמ', ' נתיבות המשפט')
      .replaceAll(' נובי', ' נודע ביהודה')
      .replaceAll(' נובית', ' נודע ביהודה תניא')
      .replaceAll(' נועא', ' נועם אלימלך')
      .replaceAll(' נפהח', ' נפש החיים')
      .replaceAll(' נפש החים', ' נפש החיים')
      .replaceAll(' נתיבוש', ' נתיבות שלום')
      .replaceAll(' נתיהמ', ' נתיבות המשפט')
      .replaceAll(' ס', ' סעיף')
      .replaceAll(' סדצ', ' ספרא דצניעותא')
      .replaceAll(' סהמ', ' ספר המצוות')
      .replaceAll(' סהמצ', ' ספר המצוות')
      .replaceAll(' סי', ' סימן')
      .replaceAll(' סמע', ' מאירת עינים')
      .replaceAll(' סע', ' סעיף')
      .replaceAll(' סעי', ' סעיף')
      .replaceAll(' ספדצ', ' ספרא דצניעותא')
      .replaceAll(' ספהמצ', ' ספר המצוות')
      .replaceAll(' ספר המצות', ' ספר המצוות')
      .replaceAll(' ספרא', ' תורת כהנים')
      .replaceAll(' ע"מ', ' עמוד')
      .replaceAll(' עא', ' עמוד א')
      .replaceAll(' עב', ' עמוד ב')
      .replaceAll(' עהש', ' ערוך השולחן')
      .replaceAll(' עח', ' עץ חיים')
      .replaceAll(' עי', ' עין יעקב')
      .replaceAll(' ערהש', ' ערוך השולחן')
      .replaceAll(' ערוך השלחן', ' ערוך השולחן')
      .replaceAll(' פ', ' פרק')
      .replaceAll(' פי', ' פירוש')
      .replaceAll(' פיהמ', ' פירוש המשניות')
      .replaceAll(' פיהמש', ' פירוש המשניות')
      .replaceAll(' פיסקי', ' פסקי')
      .replaceAll(' פירו', ' פירוש')
      .replaceAll(' פירוש המשנה', ' פירוש המשניות')
      .replaceAll(' פמג', ' פרי מגדים')
      .replaceAll(' פסז', ' פסיקתא זוטרתא')
      .replaceAll(' פסיקתא זוטא', ' פסיקתא זוטרתא')
      .replaceAll(' פסיקתא רבה', ' פסיקתא רבתי')
      .replaceAll(' פסר', ' פסיקתא רבתי')
      .replaceAll(' פעח', ' פרי עץ חיים')
      .replaceAll(' פרח', ' פרי חדש')
      .replaceAll(' צפנפ', ' צפנת פענח')
      .replaceAll(' קדושל', ' קדושת לוי')
      .replaceAll(' קוא', ' קול אליהו')
      .replaceAll(' קידושין', ' קדושין')
      .replaceAll(' קיצור', ' קצור')
      .replaceAll(' קצהח', ' קצות החושן')
      .replaceAll(' קצוהח', ' קצות החושן')
      .replaceAll(' קצור', ' קיצור')
      .replaceAll(' קצשוע', ' קיצור שולחן ערוך')
      .replaceAll(' קשוע', ' קיצור שולחן ערוך')
      .replaceAll(' ר חיים', ' הגרח')
      .replaceAll(' ר', ' רבי')
      .replaceAll(' רא בהרמ', ' רבי אברהם בן הרמבם')
      .replaceAll(' ראבע', ' אבן עזרא')
      .replaceAll(' ראשיח', ' ראשית חכמה')
      .replaceAll(' רבה', ' מדרש רבה')
      .replaceAll(' רבה', ' רבא')
      .replaceAll(' רבי חיים', ' הגרח')
      .replaceAll(' רבי נחמן', ' מוהרן')
      .replaceAll(' רבי נתן', ' מוהרנת')
      .replaceAll(' רבינו חיים', ' הגרח')
      .replaceAll(' רבינו', ' רבי')
      .replaceAll(' רבנו', ' רבי')
      .replaceAll(' רבנו', ' רבינו')
      .replaceAll(' רח', ' רבנו חננאל')
      .replaceAll(' ריהל', ' רבי יהודה הלוי')
      .replaceAll(' רעא', ' רבי עקיבא איגר')
      .replaceAll(' רעמ', ' רעיא מהימנא')
      .replaceAll(' רעקא', ' רבי עקיבא איגר')
      .replaceAll(' שבהל', ' שבלי הלקט')
      .replaceAll(' שהג', ' שער הגלגולים')
      .replaceAll(' שהש', ' שיר השירים')
      .replaceAll(' שולחן ערוך הגרז', ' שולחן ערוך הרב')
      .replaceAll(' שוע הגאון רבי זלמן', ' שוע הגרז')
      .replaceAll(' שוע הגאון רבי זלמן', ' שוע הרב')
      .replaceAll(' שוע הגרז', ' שוע הרב')
      .replaceAll(' שוע הרב', ' שולחן ערוך הרב')
      .replaceAll(' שוע הרב', ' שוע הגרז')
      .replaceAll(' שוע', ' שולחן ערוך')
      .replaceAll(' שורש', ' שרש')
      .replaceAll(' שורשים', ' שרשים')
      .replaceAll(' שות', ' תשו')
      .replaceAll(' שות', ' תשובה')
      .replaceAll(' שות', ' תשובות')
      .replaceAll(' שטה מקובצת', ' שיטה מקובצת')
      .replaceAll(' שטמק', ' שיטה מקובצת')
      .replaceAll(' שיהש', ' שיר השירים')
      .replaceAll(' שיטמק', ' שיטה מקובצת')
      .replaceAll(' שך', ' שפתי כהן')
      .replaceAll(' שלחן ערוך', ' שולחן ערוך')
      .replaceAll(' שמור', ' שמות רבה')
      .replaceAll(' שמטה', ' שמיטה')
      .replaceAll(' שמיהל', ' שמירת הלשון')
      .replaceAll(' שע', ' שולחן ערוך')
      .replaceAll(' שעק', ' שערי קדושה')
      .replaceAll(' שעת', ' שערי תשובה')
      .replaceAll(' שפח', ' שפתי חכמים')
      .replaceAll(' שפתח', ' שפתי חכמים')
      .replaceAll(' תבואש', ' תבואות שור')
      .replaceAll(' תבוש', ' תבואות שור')
      .replaceAll(' תהילים', ' תהלים')
      .replaceAll(' תהלים', ' תהילים')
      .replaceAll(' תוכ', ' תורת כהנים')
      .replaceAll(' תומד', ' תומר דבורה')
      .replaceAll(' תוס', ' תוספות')
      .replaceAll(' תוס', ' תוספתא')
      .replaceAll(' תוספ', ' תוספתא')
      .replaceAll(' תנדא', ' תנא דבי אליהו')
      .replaceAll(' תנדבא', ' תנא דבי אליהו')
      .replaceAll(' תנח', ' תנחומא')
      .replaceAll(' תקוז', ' תיקוני זוהר')
      .replaceAll(' תשו', ' שות')
      .replaceAll(' תשו', ' תשובה')
      .replaceAll(' תשו', ' תשובות')
      .replaceAll(' תשובה', ' שות')
      .replaceAll(' תשובה', ' תשו')
      .replaceAll(' תשובה', ' תשובות')
      .replaceAll(' תשובות', ' שות')
      .replaceAll(' תשובות', ' תשו')
      .replaceAll(' תשובות', ' תשובה')
      .replaceAll(' תשובת', ' שות')
      .replaceAll(' תשובת', ' תשו')
      .replaceAll(' תשובת', ' תשובה')
      .replaceAll(' תשובת', ' תשובות')
      .replaceAll('משנב', ' משנה ברורה ')
      .replaceAll('פרמג', ' פרי מגדים ')
      .replaceAll('פתש', ' פתחי תשובה ')
      .replaceAll('שטמק', ' שיטה מקובצת ');

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
