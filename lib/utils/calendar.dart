import 'package:kosher_dart/kosher_dart.dart';

Daf getDafYomi(DateTime date) {
  JewishCalendar jewishCalendar = JewishCalendar.fromDateTime(date);
  return YomiCalculator.getDafYomiBavli(jewishCalendar);
}

String getHebrewDateFormattedAsString(DateTime dateTime) {
  final hebrewCalendar = JewishCalendar.fromDateTime(dateTime);
  HebrewDateFormatter hebrewDateFormatter = HebrewDateFormatter()
    ..hebrewFormat = true;
  return hebrewDateFormatter.format(hebrewCalendar);
}

String getHebrewTimeStamp() {
  return '${getHebrewDateFormattedAsString(DateTime.now())} ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}';
}

String formatAmud(int amud) {
  return HebrewDateFormatter()
      .formatHebrewNumber(amud)
      .replaceAll('״', '')
      .replaceAll('׳', '');
}
