import 'package:kosher_dart/kosher_dart.dart';

String getDafYomi(DateTime date) {
  JewishCalendar jewishCalendar = JewishCalendar.fromDateTime(date);
  Daf dafYomi = YomiCalculator.getDafYomiBavli(jewishCalendar);
  int dafNumber = dafYomi.getDaf();
  String masechtaNameHebrew = dafYomi.getMasechta();
  Object dafNumberHebrew = HebrewDateFormatter().formatHebrewNumber(dafNumber);
  return '$masechtaNameHebrew $dafNumberHebrew';
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
