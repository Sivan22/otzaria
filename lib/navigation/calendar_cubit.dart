import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:otzaria/settings/settings_repository.dart';

enum CalendarType { hebrew, gregorian, combined }

enum CalendarView { month, week, day }

// Calendar State
class CalendarState extends Equatable {
  final JewishDate selectedJewishDate;
  final DateTime selectedGregorianDate;
  final String selectedCity;
  final Map<String, String> dailyTimes;
  final JewishDate currentJewishDate;
  final DateTime currentGregorianDate;
  final CalendarType calendarType;
  final CalendarView calendarView;

  const CalendarState({
    required this.selectedJewishDate,
    required this.selectedGregorianDate,
    required this.selectedCity,
    required this.dailyTimes,
    required this.currentJewishDate,
    required this.currentGregorianDate,
    required this.calendarType,
    required this.calendarView,
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
      calendarType: CalendarType.combined, // ברירת מחדל, יעודכן ב-_initializeCalendar
      calendarView: CalendarView.month,
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
    CalendarView? calendarView,
  }) {
    return CalendarState(
      selectedJewishDate: selectedJewishDate ?? this.selectedJewishDate,
      selectedGregorianDate:
          selectedGregorianDate ?? this.selectedGregorianDate,
      selectedCity: selectedCity ?? this.selectedCity,
      dailyTimes: dailyTimes ?? this.dailyTimes,
      currentJewishDate: currentJewishDate ?? this.currentJewishDate,
      currentGregorianDate: currentGregorianDate ?? this.currentGregorianDate,
      calendarType: calendarType ?? this.calendarType,
      calendarView: calendarView ?? this.calendarView,
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
        calendarType,
        calendarView
      ];
}

// Calendar Cubit
class CalendarCubit extends Cubit<CalendarState> {
  final SettingsRepository _settingsRepository;

  CalendarCubit({SettingsRepository? settingsRepository}) 
      : _settingsRepository = settingsRepository ?? SettingsRepository(),
        super(CalendarState.initial()) {
    _initializeCalendar();
  }

  Future<void> _initializeCalendar() async {
    final settings = await _settingsRepository.loadSettings();
    final calendarTypeString = settings['calendarType'] as String;
    final calendarType = _stringToCalendarType(calendarTypeString);
    final selectedCity = settings['selectedCity'] as String;
    
    emit(state.copyWith(
      calendarType: calendarType,
      selectedCity: selectedCity,
    ));
    _updateTimesForDate(state.selectedGregorianDate, selectedCity);
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
    // שמור את הבחירה בהגדרות
    _settingsRepository.updateSelectedCity(newCity);
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
    // שמור את הבחירה בהגדרות
    _settingsRepository.updateCalendarType(_calendarTypeToString(type));
  }

  void changeCalendarView(CalendarView view) {
    emit(state.copyWith(calendarView: view));
  }

  void jumpToToday() {
    final now = DateTime.now();
    final jewishNow = JewishDate();
    final newTimes = _calculateDailyTimes(now, state.selectedCity);

    emit(state.copyWith(
      selectedJewishDate: jewishNow,
      selectedGregorianDate: now,
      currentJewishDate: jewishNow,
      currentGregorianDate: now,
      dailyTimes: newTimes,
    ));
  }

  void jumpToDate(DateTime date) {
    final jewishDate = JewishDate.fromDateTime(date);
    final newTimes = _calculateDailyTimes(date, state.selectedCity);

    emit(state.copyWith(
      selectedJewishDate: jewishDate,
      selectedGregorianDate: date,
      currentJewishDate: jewishDate,
      currentGregorianDate: date,
      dailyTimes: newTimes,
    ));
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
  final cityData = cityCoordinates[city];
  if (cityData == null) {
    return {};
  }

  final locationName = city;
  final latitude = cityData['lat']!;
  final longitude = cityData['lng']!;
  final elevation = cityData['elevation']!;

  final location = GeoLocation();
  location.setLocationName(locationName);
  location.setLatitude(latitude: latitude);
  location.setLongitude(longitude: longitude);
  location.setDateTime(date);
  location.setElevation(elevation);

  final zmanimCalendar = ZmanimCalendar.intGeolocation(location);

  return {
    'alos': _formatTime(zmanimCalendar.getAlosHashachar()!),
    'sunrise': _formatTime(zmanimCalendar.getSunrise()!),
    'sofZmanShma': _formatTime(zmanimCalendar.getSofZmanShmaGRA()!),
    'sofZmanTfila': _formatTime(zmanimCalendar.getSofZmanTfilaGRA()!),
    'chatzos': _formatTime(zmanimCalendar.getChatzos()!),
    'minchaGedola': _formatTime(zmanimCalendar.getMinchaGedola()!),
    'minchaKetana': _formatTime(zmanimCalendar.getMinchaKetana()!),
    'plagHamincha': _formatTime(zmanimCalendar.getPlagHamincha()!),
    'sunset': _formatTime(zmanimCalendar.getSunset()!),
    'tzais': _formatTime(zmanimCalendar.getTzais()!),
  };
}

String _formatTime(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// Helper functions for CalendarType conversion
CalendarType _stringToCalendarType(String value) {
  switch (value) {
    case 'hebrew':
      return CalendarType.hebrew;
    case 'gregorian':
      return CalendarType.gregorian;
    case 'combined':
    default:
      return CalendarType.combined;
  }
}

String _calendarTypeToString(CalendarType type) {
  switch (type) {
    case CalendarType.hebrew:
      return 'hebrew';
    case CalendarType.gregorian:
      return 'gregorian';
    case CalendarType.combined:
      return 'combined';
  }
}
