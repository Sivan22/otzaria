import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:flutter/material.dart';

enum CalendarType { hebrew, gregorian, combined }

// Calendar State
class CalendarState extends Equatable {
  final JewishDate selectedJewishDate;
  final DateTime selectedGregorianDate;
  final String selectedCity;
  final Map<String, String> dailyTimes;
  final JewishDate currentJewishDate;
  final DateTime currentGregorianDate;
  final CalendarType calendarType;

  const CalendarState({
    required this.selectedJewishDate,
    required this.selectedGregorianDate,
    required this.selectedCity,
    required this.dailyTimes,
    required this.currentJewishDate,
    required this.currentGregorianDate,
    required this.calendarType,
  });

  factory CalendarState.initial() {
    final now = DateTime.now();
    final jewishNow = JewishDate();
    
    return CalendarState(
      selectedJewishDate: jewishNow,
      selectedGregorianDate: now,
      selectedCity: 'ירושלים',
      dailyTimes: const {},
      currentJewishDate: jewishNow,
      currentGregorianDate: now,
      calendarType: CalendarType.combined,
    );
  }

  CalendarState copyWith({
    JewishDate? selectedJewishDate,
    DateTime? selectedGregorianDate,
    String? selectedCity,
    Map<String, String>? dailyTimes,
    JewishDate? currentJewishDate,
    DateTime? currentGregorianDate,
    CalendarType? calendarType,
  }) {
    return CalendarState(
      selectedJewishDate: selectedJewishDate ?? this.selectedJewishDate,
      selectedGregorianDate: selectedGregorianDate ?? this.selectedGregorianDate,
      selectedCity: selectedCity ?? this.selectedCity,
      dailyTimes: dailyTimes ?? this.dailyTimes,
      currentJewishDate: currentJewishDate ?? this.currentJewishDate,
      currentGregorianDate: currentGregorianDate ?? this.currentGregorianDate,
      calendarType: calendarType ?? this.calendarType,
    );
  }


  @override
  List<Object?> get props => [
        selectedJewishDate.getJewishYear(),
        selectedJewishDate.getJewishMonth(),
        selectedJewishDate.getJewishDayOfMonth(),
        
        selectedGregorianDate,
        selectedCity,
        dailyTimes,

        // "פירקנו" גם את התאריך של תצוגת החודש
        currentJewishDate.getJewishYear(),
        currentJewishDate.getJewishMonth(),
        currentJewishDate.getJewishDayOfMonth(),
        
        currentGregorianDate,
        calendarType
      ];
}

// Calendar Cubit
class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit() : super(CalendarState.initial()) {
    _updateTimesForDate(state.selectedGregorianDate, state.selectedCity);
  }

  void _updateTimesForDate(DateTime date, String city) {
    final newTimes = _calculateDailyTimes(date, city);
    emit(state.copyWith(dailyTimes: newTimes));
  }

  void selectDate(JewishDate jewishDate, DateTime gregorianDate) {
    final newTimes = _calculateDailyTimes(gregorianDate, state.selectedCity);
    emit(state.copyWith(
      selectedJewishDate: jewishDate,
      selectedGregorianDate: gregorianDate,
      dailyTimes: newTimes,
    ));
  }

  void changeCity(String newCity) {
    final newTimes = _calculateDailyTimes(state.selectedGregorianDate, newCity);
    emit(state.copyWith(
      selectedCity: newCity,
      dailyTimes: newTimes,
    ));
  }

  void previousMonth() {
    if (state.calendarType == CalendarType.gregorian) {
      final current = state.currentGregorianDate;
      final newDate = current.month == 1
          ? DateTime(current.year - 1, 12, 1)
          : DateTime(current.year, current.month - 1, 1);
      emit(state.copyWith(currentGregorianDate: newDate));
    } else {
      final current = state.currentJewishDate;
      final newJewishDate = JewishDate();
      if (current.getJewishMonth() == 1) {
        newJewishDate.setJewishDate(
          current.getJewishYear() - 1,
          12,
          1,
        );
      } else {
        newJewishDate.setJewishDate(
          current.getJewishYear(),
          current.getJewishMonth() - 1,
          1,
        );
      }
      emit(state.copyWith(currentJewishDate: newJewishDate));
    }
  }

  void nextMonth() {
    if (state.calendarType == CalendarType.gregorian) {
      final current = state.currentGregorianDate;
      final newDate = current.month == 12
          ? DateTime(current.year + 1, 1, 1)
          : DateTime(current.year, current.month + 1, 1);
      emit(state.copyWith(currentGregorianDate: newDate));
    } else {
      final current = state.currentJewishDate;
      final newJewishDate = JewishDate();
      if (current.getJewishMonth() == 12) {
        newJewishDate.setJewishDate(
          current.getJewishYear() + 1,
          1,
          1,
        );
      } else {
        newJewishDate.setJewishDate(
          current.getJewishYear(),
          current.getJewishMonth() + 1,
          1,
        );
      }
      emit(state.copyWith(currentJewishDate: newJewishDate));
    }
  }

  void changeCalendarType(CalendarType type) {
    emit(state.copyWith(calendarType: type));
  }
}

// City coordinates map
const Map<String, Map<String, double>> cityCoordinates = {
  'ירושלים': {'lat': 31.7683, 'lng': 35.2137, 'elevation': 800.0},
  'תל אביב': {'lat': 32.0853, 'lng': 34.7818, 'elevation': 5.0},
  'חיפה': {'lat': 32.7940, 'lng': 34.9896, 'elevation': 30.0},
  'באר שבע': {'lat': 31.2518, 'lng': 34.7915, 'elevation': 280.0},
  'נתניה': {'lat': 32.3215, 'lng': 34.8532, 'elevation': 30.0},
  'אשדוד': {'lat': 31.8044, 'lng': 34.6553, 'elevation': 50.0},
  'פתח תקווה': {'lat': 32.0870, 'lng': 34.8873, 'elevation': 80.0},
  'בני ברק': {'lat': 32.0809, 'lng': 34.8338, 'elevation': 50.0},
  'מודיעין עילית': {'lat': 31.9254, 'lng': 35.0364, 'elevation': 400.0},
  'צפת': {'lat': 32.9650, 'lng': 35.4951, 'elevation': 900.0},
  'טבריה': {'lat': 32.7940, 'lng': 35.5308, 'elevation': -200.0},
  'אילת': {'lat': 29.5581, 'lng': 34.9482, 'elevation': 12.0},
  'רחובות': {'lat': 31.8947, 'lng': 34.8096, 'elevation': 89.0},
  'הרצליה': {'lat': 32.1624, 'lng': 34.8443, 'elevation': 40.0},
  'רמת גן': {'lat': 32.0719, 'lng': 34.8244, 'elevation': 80.0},
  'חולון': {'lat': 32.0117, 'lng': 34.7689, 'elevation': 54.0},
  'בת ים': {'lat': 32.0167, 'lng': 34.7500, 'elevation': 5.0},
  'רמלה': {'lat': 31.9297, 'lng': 34.8667, 'elevation': 108.0},
  'לוד': {'lat': 31.9516, 'lng': 34.8958, 'elevation': 50.0},
  'אשקלון': {'lat': 31.6688, 'lng': 34.5742, 'elevation': 50.0},
};

// Calculate daily times function
Map<String, String> _calculateDailyTimes(DateTime date, String city) {
  final targetDate = date;
  final isSummer = targetDate.month >= 4 && targetDate.month <= 9;

  print('Calculating times for date: ${targetDate.day}/${targetDate.month}/${targetDate.year}, city: $city');

  final dayOfYear = targetDate.difference(DateTime(targetDate.year, 1, 1)).inDays;
  final seasonalAdjustment = _getSeasonalAdjustment(dayOfYear);

  Map<String, String> baseTimes;
  final cityData = cityCoordinates[city]!;
  final isJerusalem = city == 'ירושלים';

  if (isJerusalem) {
    baseTimes = isSummer
        ? {
            'alos': _adjustTime('04:20', seasonalAdjustment),
            'sunrise': _adjustTime('05:45', seasonalAdjustment),
            'sofZmanShma': _adjustTime('09:00', seasonalAdjustment),
            'sofZmanTfila': _adjustTime('10:15', seasonalAdjustment),
            'chatzos': _adjustTime('12:45', seasonalAdjustment),
            'minchaGedola': _adjustTime('13:30', seasonalAdjustment),
            'minchaKetana': _adjustTime('17:15', seasonalAdjustment),
            'plagHamincha': _adjustTime('18:30', seasonalAdjustment),
            'sunset': _adjustTime('19:45', seasonalAdjustment),
            'tzais': _adjustTime('20:30', seasonalAdjustment),
          }
        : {
            'alos': _adjustTime('05:45', seasonalAdjustment),
            'sunrise': _adjustTime('06:30', seasonalAdjustment),
            'sofZmanShma': _adjustTime('09:15', seasonalAdjustment),
            'sofZmanTfila': _adjustTime('10:00', seasonalAdjustment),
            'chatzos': _adjustTime('12:00', seasonalAdjustment),
            'minchaGedola': _adjustTime('12:30', seasonalAdjustment),
            'minchaKetana': _adjustTime('15:00', seasonalAdjustment),
            'plagHamincha': _adjustTime('16:15', seasonalAdjustment),
            'sunset': _adjustTime('17:30', seasonalAdjustment),
            'tzais': _adjustTime('18:15', seasonalAdjustment),
          };
  } else {
    final latAdjustment = ((cityData['lat']! - 31.7683) * 2).round();
    baseTimes = isSummer
        ? {
            'alos': _adjustTime('04:30', seasonalAdjustment + latAdjustment),
            'sunrise': _adjustTime('05:50', seasonalAdjustment + latAdjustment),
            'sofZmanShma': _adjustTime('09:10', seasonalAdjustment + latAdjustment),
            'sofZmanTfila': _adjustTime('10:20', seasonalAdjustment + latAdjustment),
            'chatzos': _adjustTime('12:50', seasonalAdjustment + latAdjustment),
            'minchaGedola': _adjustTime('13:35', seasonalAdjustment + latAdjustment),
            'minchaKetana': _adjustTime('17:20', seasonalAdjustment + latAdjustment),
            'plagHamincha': _adjustTime('18:35', seasonalAdjustment + latAdjustment),
            'sunset': _adjustTime('19:50', seasonalAdjustment + latAdjustment),
            'tzais': _adjustTime('20:35', seasonalAdjustment + latAdjustment),
          }
        : {
            'alos': _adjustTime('05:50', seasonalAdjustment + latAdjustment),
            'sunrise': _adjustTime('06:35', seasonalAdjustment + latAdjustment),
            'sofZmanShma': _adjustTime('09:20', seasonalAdjustment + latAdjustment),
            'sofZmanTfila': _adjustTime('10:05', seasonalAdjustment + latAdjustment),
            'chatzos': _adjustTime('12:05', seasonalAdjustment + latAdjustment),
            'minchaGedola': _adjustTime('12:35', seasonalAdjustment + latAdjustment),
            'minchaKetana': _adjustTime('15:05', seasonalAdjustment + latAdjustment),
            'plagHamincha': _adjustTime('16:20', seasonalAdjustment + latAdjustment),
            'sunset': _adjustTime('17:35', seasonalAdjustment + latAdjustment),
            'tzais': _adjustTime('18:20', seasonalAdjustment + latAdjustment),
          };
  }

  return baseTimes;
}

int _getSeasonalAdjustment(int dayOfYear) {
  if (dayOfYear < 80 || dayOfYear > 300) {
    return -15; // Winter - earlier times
  } else if (dayOfYear > 120 && dayOfYear < 260) {
    return 15; // Summer - later times
  } else {
    return 0; // Spring/Fall
  }
}

String _adjustTime(String timeStr, int adjustmentMinutes) {
  final parts = timeStr.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);

  final totalMinutes = hour * 60 + minute + adjustmentMinutes;
  final adjustedHour = (totalMinutes ~/ 60) % 24;
  final adjustedMinute = totalMinutes % 60;

  return '${adjustedHour.toString().padLeft(2, '0')}:${adjustedMinute.toString().padLeft(2, '0')}';
}