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
      calendarType:
          CalendarType.combined, // ברירת מחדל, יעודכן ב-_initializeCalendar
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
        // אם אנחנו בניסן (חודש 1), עוברים לאדר של השנה הקודמת
        // אבל השנה לא משתנה כי השנה מתחלפת בתשרי
        newJewishDate.setJewishDate(
          current.getJewishYear(),
          12,
          1,
        );
      } else if (current.getJewishMonth() == 7) {
        // אם אנחנו בתשרי (חודש 7), עוברים לאלול של השנה הקודמת
        // כאן כן משתנה השנה כי תשרי הוא תחילת השנה
        newJewishDate.setJewishDate(
          current.getJewishYear() - 1,
          6,
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
        // אם אנחנו באדר (חודש 12), עוברים לניסן של אותה שנה
        // השנה לא משתנה כי השנה מתחלפת בתשרי
        newJewishDate.setJewishDate(
          current.getJewishYear(),
          1,
          1,
        );
      } else if (current.getJewishMonth() == 6) {
        // אם אנחנו באלול (חודש 6), עוברים לתשרי של השנה הבאה
        // כאן כן משתנה השנה כי תשרי הוא תחילת השנה
        newJewishDate.setJewishDate(
          current.getJewishYear() + 1,
          7,
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

// City coordinates map - מסודר לפי מדינות ובסדר א-ב
const Map<String, Map<String, Map<String, double>>> cityCoordinates = {
  'ארץ ישראל': {
    'אופקים': {'lat': 31.3111, 'lng': 34.6214, 'elevation': 140.0},
    'אילת': {'lat': 29.5581, 'lng': 34.9482, 'elevation': 12.0},
    'אריאל': {'lat': 32.1069, 'lng': 35.1897, 'elevation': 650.0},
    'אשדוד': {'lat': 31.8044, 'lng': 34.6553, 'elevation': 50.0},
    'אשקלון': {'lat': 31.6688, 'lng': 34.5742, 'elevation': 50.0},
    'באר שבע': {'lat': 31.2518, 'lng': 34.7915, 'elevation': 280.0},
    'ביתר עילית': {'lat': 31.7025, 'lng': 35.1156, 'elevation': 740.0},
    'בית שמש': {'lat': 31.7245, 'lng': 34.9886, 'elevation': 220.0},
    'בני ברק': {'lat': 32.0809, 'lng': 34.8338, 'elevation': 50.0},
    'בת ים': {'lat': 32.0167, 'lng': 34.7500, 'elevation': 5.0},
    'גבעת זאב': {'lat': 31.8467, 'lng': 35.1667, 'elevation': 600.0},
    'גבעתיים': {'lat': 32.0706, 'lng': 34.8103, 'elevation': 80.0},
    'דימונה': {'lat': 31.0686, 'lng': 35.0333, 'elevation': 550.0},
    'הוד השרון': {'lat': 32.1506, 'lng': 34.8889, 'elevation': 40.0},
    'הרצליה': {'lat': 32.1624, 'lng': 34.8443, 'elevation': 40.0},
    'חיפה': {'lat': 32.7940, 'lng': 34.9896, 'elevation': 30.0},
    'חולון': {'lat': 32.0117, 'lng': 34.7689, 'elevation': 54.0},
    'טבריה': {'lat': 32.7940, 'lng': 35.5308, 'elevation': -200.0},
    'יבנה': {'lat': 31.8781, 'lng': 34.7378, 'elevation': 25.0},
    'ירושלים': {'lat': 31.7683, 'lng': 35.2137, 'elevation': 800.0},
    'כפר סבא': {'lat': 32.1742, 'lng': 34.9067, 'elevation': 75.0},
    'כרמיאל': {'lat': 32.9186, 'lng': 35.2958, 'elevation': 300.0},
    'לוד': {'lat': 31.9516, 'lng': 34.8958, 'elevation': 50.0},
    'מודיעין עילית': {'lat': 31.9254, 'lng': 35.0364, 'elevation': 400.0},
    'מצפה רמון': {'lat': 30.6097, 'lng': 34.8017, 'elevation': 860.0},
    'מעלה אדומים': {'lat': 31.7767, 'lng': 35.2973, 'elevation': 740.0},
    'נתיבות': {'lat': 31.4214, 'lng': 34.5911, 'elevation': 140.0},
    'נתניה': {'lat': 32.3215, 'lng': 34.8532, 'elevation': 30.0},
    'נצרת עילית': {'lat': 32.6992, 'lng': 35.3289, 'elevation': 400.0},
    'עפולה': {'lat': 32.6078, 'lng': 35.2897, 'elevation': 60.0},
    'פתח תקווה': {'lat': 32.0870, 'lng': 34.8873, 'elevation': 80.0},
    'צפת': {'lat': 32.9650, 'lng': 35.4951, 'elevation': 900.0},
    'קרית אונו': {'lat': 32.0539, 'lng': 34.8581, 'elevation': 75.0},
    'קרית ארבע': {'lat': 31.5244, 'lng': 35.1031, 'elevation': 930.0},
    'קרית גת': {'lat': 31.6100, 'lng': 34.7642, 'elevation': 68.0},
    'קרית מלאכי': {'lat': 31.7289, 'lng': 34.7456, 'elevation': 108.0},
    'קרית שמונה': {'lat': 33.2072, 'lng': 35.5692, 'elevation': 135.0},
    'ראשון לציון': {'lat': 31.9642, 'lng': 34.8047, 'elevation': 68.0},
    'רחובות': {'lat': 31.8947, 'lng': 34.8096, 'elevation': 89.0},
    'רמלה': {'lat': 31.9297, 'lng': 34.8667, 'elevation': 108.0},
    'רמת גן': {'lat': 32.0719, 'lng': 34.8244, 'elevation': 80.0},
    'רעננה': {'lat': 32.1847, 'lng': 34.8706, 'elevation': 45.0},
    'תל אביב': {'lat': 32.0853, 'lng': 34.7818, 'elevation': 5.0},
    'תפרח': {'lat': 31.3889, 'lng': 34.6861, 'elevation': 160.0},
  },
  'ארצות הברית': {
    'אטלנטה': {'lat': 33.7490, 'lng': -84.3880, 'elevation': 320.0},
    'בוסטון': {'lat': 42.3601, 'lng': -71.0589, 'elevation': 43.0},
    'בלטימור': {'lat': 39.2904, 'lng': -76.6122, 'elevation': 10.0},
    'דטרויט': {'lat': 42.3314, 'lng': -83.0458, 'elevation': 183.0},
    'דנבר': {'lat': 39.7392, 'lng': -104.9903, 'elevation': 1609.0},
    'לאס וגאס': {'lat': 36.1699, 'lng': -115.1398, 'elevation': 610.0},
    'לוס אנג\'לס': {'lat': 34.0522, 'lng': -118.2437, 'elevation': 71.0},
    'מיאמי': {'lat': 25.7617, 'lng': -80.1918, 'elevation': 2.0},
    'ניו יורק': {'lat': 40.7128, 'lng': -74.0060, 'elevation': 10.0},
    'סיאטל': {'lat': 47.6062, 'lng': -122.3321, 'elevation': 56.0},
    'סן פרנסיסקו': {'lat': 37.7749, 'lng': -122.4194, 'elevation': 16.0},
    'פילדלפיה': {'lat': 39.9526, 'lng': -75.1652, 'elevation': 12.0},
    'פיניקס': {'lat': 33.4484, 'lng': -112.0740, 'elevation': 331.0},
    'קליבלנד': {'lat': 41.4993, 'lng': -81.6944, 'elevation': 199.0},
    'שיקגו': {'lat': 41.8781, 'lng': -87.6298, 'elevation': 181.0},
  },
  'קנדה': {
    'אדמונטון': {'lat': 53.5461, 'lng': -113.4938, 'elevation': 645.0},
    'אוטווה': {'lat': 45.4215, 'lng': -75.6972, 'elevation': 70.0},
    'ונקובר': {'lat': 49.2827, 'lng': -123.1207, 'elevation': 70.0},
    'טורונטו': {'lat': 43.6532, 'lng': -79.3832, 'elevation': 76.0},
    'מונטריאול': {'lat': 45.5017, 'lng': -73.5673, 'elevation': 36.0},
    'קלגרי': {'lat': 51.0447, 'lng': -114.0719, 'elevation': 1048.0},
  },
  'בריטניה': {
    'אדינבורו': {'lat': 55.9533, 'lng': -3.1883, 'elevation': 47.0},
    'לונדון': {'lat': 51.5074, 'lng': -0.1278, 'elevation': 35.0},
  },
  'צרפת': {
    'פריז': {'lat': 48.8566, 'lng': 2.3522, 'elevation': 35.0},
  },
  'גרמניה': {
    'ברלין': {'lat': 52.5200, 'lng': 13.4050, 'elevation': 34.0},
  },
  'איטליה': {
    'מילאנו': {'lat': 45.4642, 'lng': 9.1900, 'elevation': 122.0},
    'רומא': {'lat': 41.9028, 'lng': 12.4964, 'elevation': 21.0},
  },
  'ספרד': {
    'מדריד': {'lat': 40.4168, 'lng': -3.7038, 'elevation': 650.0},
  },
  'הולנד': {
    'אמסטרדם': {'lat': 52.3676, 'lng': 4.9041, 'elevation': -2.0},
  },
  'שוויץ': {
    'ציריך': {'lat': 47.3769, 'lng': 8.5417, 'elevation': 408.0},
  },
  'אוסטריה': {
    'וינה': {'lat': 48.2082, 'lng': 16.3738, 'elevation': 171.0},
  },
  'הונגריה': {
    'בודפשט': {'lat': 47.4979, 'lng': 19.0402, 'elevation': 102.0},
  },
  'צ\'כיה': {
    'פראג': {'lat': 50.0755, 'lng': 14.4378, 'elevation': 200.0},
  },
  'פולין': {
    'ורשה': {'lat': 52.2297, 'lng': 21.0122, 'elevation': 100.0},
  },
  'רוסיה': {
    'מוסקבה': {'lat': 55.7558, 'lng': 37.6176, 'elevation': 156.0},
  },
  'טורקיה': {
    'איסטנבול': {'lat': 41.0082, 'lng': 28.9784, 'elevation': 39.0},
  },
  'פורטוגל': {
    'ליסבון': {'lat': 38.7223, 'lng': -9.1393, 'elevation': 2.0},
  },
  'אירלנד': {
    'דבלין': {'lat': 53.3498, 'lng': -6.2603, 'elevation': 85.0},
  },
  'שוודיה': {
    'סטוקהולם': {'lat': 59.3293, 'lng': 18.0686, 'elevation': 28.0},
  },
  'דנמרק': {
    'קופנהגן': {'lat': 55.6761, 'lng': 12.5683, 'elevation': 24.0},
  },
  'פינלנד': {
    'הלסינקי': {'lat': 60.1699, 'lng': 24.9384, 'elevation': 26.0},
  },
  'נורווגיה': {
    'אוסלו': {'lat': 59.9139, 'lng': 10.7522, 'elevation': 23.0},
  },
  'איסלנד': {
    'רייקיאוויק': {'lat': 64.1466, 'lng': -21.9426, 'elevation': 61.0},
  },
  'ארגנטינה': {
    'בואנוס איירס': {'lat': -34.6118, 'lng': -58.3960, 'elevation': 25.0},
  },
  'ברזיל': {
    'ריו דה ז\'נרו': {'lat': -22.9068, 'lng': -43.1729, 'elevation': 2.0},
    'סאו פאולו': {'lat': -23.5505, 'lng': -46.6333, 'elevation': 760.0},
  },
  'צ\'ילה': {
    'סנטיאגו': {'lat': -33.4489, 'lng': -70.6693, 'elevation': 520.0},
  },
  'ונצואלה': {
    'קראקס': {'lat': 10.4806, 'lng': -66.9036, 'elevation': 900.0},
  },
  'פרו': {
    'לימה': {'lat': -12.0464, 'lng': -77.0428, 'elevation': 154.0},
  },
  'מקסיקו': {
    'מקסיקו סיטי': {'lat': 19.4326, 'lng': -99.1332, 'elevation': 2240.0},
  },
  'מרוקו': {
    'קזבלנקה': {'lat': 33.5731, 'lng': -7.5898, 'elevation': 50.0},
  },
  'דרום אפריקה': {
    'יוהנסבורג': {'lat': -26.2041, 'lng': 28.0473, 'elevation': 1753.0},
    'קייפטאון': {'lat': -33.9249, 'lng': 18.4241, 'elevation': 42.0},
  },
  'מצרים': {
    'אלכסנדריה': {'lat': 31.2001, 'lng': 29.9187, 'elevation': 12.0},
    'קהיר': {'lat': 30.0444, 'lng': 31.2357, 'elevation': 74.0},
  },
  'הודו': {
    'דלהי': {'lat': 28.7041, 'lng': 77.1025, 'elevation': 216.0},
    'מומבאי': {'lat': 19.0760, 'lng': 72.8777, 'elevation': 14.0},
  },
  'תאילנד': {
    'בנגקוק': {'lat': 13.7563, 'lng': 100.5018, 'elevation': 1.5},
  },
  'סינגפור': {
    'סינגפור': {'lat': 1.3521, 'lng': 103.8198, 'elevation': 15.0},
  },
  'הונג קונג': {
    'הונג קונג': {'lat': 22.3193, 'lng': 114.1694, 'elevation': 552.0},
  },
  'יפן': {
    'טוקיו': {'lat': 35.6762, 'lng': 139.6503, 'elevation': 40.0},
  },
  'דרום קוריאה': {
    'סיאול': {'lat': 37.5665, 'lng': 126.9780, 'elevation': 38.0},
  },
  'סין': {
    'בייג\'ינג': {'lat': 39.9042, 'lng': 116.4074, 'elevation': 43.5},
    'שנחאי': {'lat': 31.2304, 'lng': 121.4737, 'elevation': 4.0},
  },
  'איחוד האמירויות': {
    'דובאי': {'lat': 25.2048, 'lng': 55.2708, 'elevation': 16.0},
  },
  'כווית': {
    'כווית': {'lat': 29.3759, 'lng': 47.9774, 'elevation': 55.0},
  },
  'אוסטרליה': {
    'בריסביין': {'lat': -27.4698, 'lng': 153.0251, 'elevation': 27.0},
    'מלבורן': {'lat': -37.8136, 'lng': 144.9631, 'elevation': 31.0},
    'פרת': {'lat': -31.9505, 'lng': 115.8605, 'elevation': 46.0},
    'סידני': {'lat': -33.8688, 'lng': 151.2093, 'elevation': 58.0},
  },
};

Map<String, double>? _getCityData(String cityName) {
  for (var country in cityCoordinates.values) {
    if (country.containsKey(cityName)) {
      return country[cityName];
    }
  }
  return null;
}

// Calculate daily times function
Map<String, String> _calculateDailyTimes(DateTime date, String city) {
  final cityData = _getCityData(city);
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
  location.setElevation(elevation > 0 ? elevation : 0);

  final zmanimCalendar = ComplexZmanimCalendar.intGeoLocation(location);

  final jewishCalendar = JewishCalendar.fromDateTime(date);
  final Map<String, String> times = {
    'alos': _formatTime(zmanimCalendar.getAlosHashachar()!),
    'alos16point1Degrees':
        _formatTime(zmanimCalendar.getAlos16Point1Degrees()!),
    'alos19point8Degrees':
        _formatTime(zmanimCalendar.getAlos19Point8Degrees()!),
    'sunrise': _formatTime(zmanimCalendar.getSunrise()!),
    'sofZmanShmaMGA': _formatTime(zmanimCalendar.getSofZmanShmaMGA()!),
    'sofZmanShmaGRA': _formatTime(zmanimCalendar.getSofZmanShmaGRA()!),
    'sofZmanTfilaMGA': _formatTime(zmanimCalendar.getSofZmanTfilaMGA()!),
    'sofZmanTfilaGRA': _formatTime(zmanimCalendar.getSofZmanTfilaGRA()!),
    'chatzos': _formatTime(zmanimCalendar.getChatzos()!),
    'chatzosLayla': _formatTime(_calculateChatzosLayla(zmanimCalendar)),
    'minchaGedola': _formatTime(zmanimCalendar.getMinchaGedola()!),
    'minchaKetana': _formatTime(zmanimCalendar.getMinchaKetana()!),
    'plagHamincha': _formatTime(zmanimCalendar.getPlagHamincha()!),
    'sunset': _formatTime(zmanimCalendar.getSunset()!),
    'sunsetRT': _formatTime(_calculateSunsetRT(zmanimCalendar)),
    'tzais': _formatTime(zmanimCalendar.getTzais()!),
  };

  // הוספת זמנים מיוחדים לחגים
  _addSpecialTimes(times, jewishCalendar, zmanimCalendar, city);

  return times;
}

String _formatTime(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// חישוב חצות לילה - 12 שעות אחרי חצות היום
DateTime _calculateChatzosLayla(ComplexZmanimCalendar zmanimCalendar) {
  final chatzos = zmanimCalendar.getChatzos()!;
  return chatzos.add(const Duration(hours: 12));
}

// חישוב שקיעה לפי רבנו תם - בין השמשות רבנו תם
DateTime _calculateSunsetRT(ComplexZmanimCalendar zmanimCalendar) {
  // רבנו תם - 72 דקות אחרי השקיעה
  final sunset = zmanimCalendar.getSunset()!;
  return sunset.add(const Duration(minutes: 72));
}

// הוספת זמנים מיוחדים לחגים
void _addSpecialTimes(Map<String, String> times, JewishCalendar jewishCalendar,
    ComplexZmanimCalendar zmanimCalendar, String city) {
  // זמנים מיוחדים לערב פסח
  if (jewishCalendar.getYomTovIndex() == JewishCalendar.EREV_PESACH) {
    // סוף זמן אכילת חמץ - מג"א (4 שעות זמניות)
    final sofZmanAchilasChametzMGA =
        zmanimCalendar.getSofZmanAchilasChametzMGA72Minutes();
    if (sofZmanAchilasChametzMGA != null) {
      times['sofZmanAchilasChametzMGA'] = _formatTime(sofZmanAchilasChametzMGA);
    }

    // סוף זמן אכילת חמץ - גר"א (4 שעות זמניות)
    final sofZmanAchilasChametzGRA =
        zmanimCalendar.getSofZmanAchilasChametzGRA();
    if (sofZmanAchilasChametzGRA != null) {
      times['sofZmanAchilasChametzGRA'] = _formatTime(sofZmanAchilasChametzGRA);
    }

    // סוף זמן ביעור חמץ - מג"א (5 שעות זמניות)
    final sofZmanBiurChametzMGA =
        zmanimCalendar.getSofZmanBiurChametzMGA72Minutes();
    if (sofZmanBiurChametzMGA != null) {
      times['sofZmanBiurChametzMGA'] = _formatTime(sofZmanBiurChametzMGA);
    }

    // סוף זמן ביעור חמץ - גר"א (5 שעות זמניות)
    final sofZmanBiurChametzGRA = zmanimCalendar.getSofZmanBiurChametzGRA();
    if (sofZmanBiurChametzGRA != null) {
      times['sofZmanBiurChametzGRA'] = _formatTime(sofZmanBiurChametzGRA);
    }
  }

  // זמני כניסת שבת/חג
  if (jewishCalendar.getDayOfWeek() == 6 || jewishCalendar.isErevYomTov()) {
    final candleLightingTime =
        _calculateCandleLightingTime(zmanimCalendar, city);
    if (candleLightingTime != null) {
      times['candleLighting'] = _formatTime(candleLightingTime);
    }
  }

  // זמני יציאת שבת/חג
  if (jewishCalendar.getDayOfWeek() == 7 || jewishCalendar.isYomTov()) {
    final shabbosExitTime1 = _calculateShabbosExitTime1(zmanimCalendar);
    final shabbosExitTime2 = _calculateShabbosExitTime2(zmanimCalendar);

    if (shabbosExitTime1 != null) {
      times['shabbosExit1'] = _formatTime(shabbosExitTime1);
    }
    if (shabbosExitTime2 != null) {
      times['shabbosExit2'] = _formatTime(shabbosExitTime2);
    }
  }

  // זמן ספירת העומר (מליל יום שני של פסח עד ערב שבועות)
  if (jewishCalendar.getDayOfOmer() != -1) {
    final omerCountingTime = _calculateOmerCountingTime(zmanimCalendar);
    if (omerCountingTime != null) {
      times['omerCounting'] = _formatTime(omerCountingTime);
    }
  }

  // זמני תענית
  if (jewishCalendar.isTaanis() &&
      jewishCalendar.getYomTovIndex() != JewishCalendar.YOM_KIPPUR) {
    final fastStartTime = _calculateFastStartTime(zmanimCalendar);
    final fastEndTime = _calculateFastEndTime(zmanimCalendar);

    if (fastStartTime != null) {
      times['fastStart'] = _formatTime(fastStartTime);
    }
    if (fastEndTime != null) {
      times['fastEnd'] = _formatTime(fastEndTime);
    }
  }

  // זמן קידוש לבנה
  if (_isKidushLevanaTime(jewishCalendar)) {
    final kidushLevanaEarliest =
        _calculateKidushLevanaEarliest(jewishCalendar, zmanimCalendar);
    final kidushLevanaLatest =
        _calculateKidushLevanaLatest(jewishCalendar, zmanimCalendar);

    if (kidushLevanaEarliest != null) {
      times['kidushLevanaEarliest'] = _formatTime(kidushLevanaEarliest);
    }
    if (kidushLevanaLatest != null) {
      times['kidushLevanaLatest'] = _formatTime(kidushLevanaLatest);
    }
  }

  // זמני חנוכה - הדלקת נרות
  if (jewishCalendar.isChanukah()) {
    final chanukahCandleLighting =
        _calculateChanukahCandleLighting(zmanimCalendar);
    if (chanukahCandleLighting != null) {
      times['chanukahCandles'] = _formatTime(chanukahCandleLighting);
    }
  }

  // זמני קידוש לבנה
  final tchilasKidushLevana = zmanimCalendar.getTchilasZmanKidushLevana3Days();
  final sofZmanKidushLevana =
      zmanimCalendar.getSofZmanKidushLevanaBetweenMoldos();

  if (tchilasKidushLevana != null) {
    times['tchilasKidushLevana'] = _formatTime(tchilasKidushLevana);
  }
  if (sofZmanKidushLevana != null) {
    times['sofZmanKidushLevana'] = _formatTime(sofZmanKidushLevana);
  }
}

// חישוב זמן הדלקת נרות לפי עיר
DateTime? _calculateCandleLightingTime(
    ComplexZmanimCalendar zmanimCalendar, String city) {
  final sunset = zmanimCalendar.getSunset();
  if (sunset == null) return null;

  int minutesBefore;
  switch (city) {
    case 'ירושלים':
      minutesBefore = 40;
      break;
    case 'בני ברק':
      minutesBefore = 22;
      break;
    case 'מודיעין עילית':
      minutesBefore = 30;
      break;
    default:
      minutesBefore = 30;
      break;
  }

  return sunset.subtract(Duration(minutes: minutesBefore));
}

// חישוב זמן יציאת שבת 1 - 34 דקות אחרי השקיעה
DateTime? _calculateShabbosExitTime1(ComplexZmanimCalendar zmanimCalendar) {
  final sunset = zmanimCalendar.getSunset();
  if (sunset == null) return null;

  return sunset.add(const Duration(minutes: 34));
}

// חישוב זמן יציאת שבת 2 - צאת השבת חזו"א - 38 דקות אחרי השקיעה
DateTime? _calculateShabbosExitTime2(ComplexZmanimCalendar zmanimCalendar) {
  final sunset = zmanimCalendar.getSunset();
  if (sunset == null) return null;

  return sunset.add(const Duration(minutes: 38));
}

// חישוב זמן ספירת העומר - אחרי צאת הכוכבים
DateTime? _calculateOmerCountingTime(ComplexZmanimCalendar zmanimCalendar) {
  return zmanimCalendar.getTzais();
}

// חישוב תחילת תענית - עלות השחר
DateTime? _calculateFastStartTime(ComplexZmanimCalendar zmanimCalendar) {
  return zmanimCalendar.getAlosHashachar();
}

// חישוב סיום תענית - צאת הכוכבים
DateTime? _calculateFastEndTime(ComplexZmanimCalendar zmanimCalendar) {
  return zmanimCalendar.getTzais();
}

// בדיקה אם זה זמן קידוש לבנה (מיום 3 עד יום 15 בחודש)
bool _isKidushLevanaTime(JewishCalendar jewishCalendar) {
  final dayOfMonth = jewishCalendar.getJewishDayOfMonth();
  return dayOfMonth >= 3 && dayOfMonth <= 15;
}

// חישוב תחילת זמן קידוש לבנה - 3 ימים אחרי המולד
DateTime? _calculateKidushLevanaEarliest(
    JewishCalendar jewishCalendar, ComplexZmanimCalendar zmanimCalendar) {
  // זמן קידוש לבנה מתחיל 3 ימים אחרי המולד, אחרי צאת הכוכבים
  if (jewishCalendar.getJewishDayOfMonth() == 3) {
    return zmanimCalendar.getTzais();
  }
  return null;
}

// חישוב סוף זמן קידוש לבנה - 15 ימים אחרי המולד
DateTime? _calculateKidushLevanaLatest(
    JewishCalendar jewishCalendar, ComplexZmanimCalendar zmanimCalendar) {
  // זמן קידוש לבנה מסתיים ביום 15, לפני עלות השחר
  if (jewishCalendar.getJewishDayOfMonth() == 15) {
    return zmanimCalendar.getAlosHashachar();
  }
  return null;
}

// חישוב זמן הדלקת נרות חנוכה - אחרי צאת הכוכבים
DateTime? _calculateChanukahCandleLighting(
    ComplexZmanimCalendar zmanimCalendar) {
  return zmanimCalendar.getTzais();
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
