import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'calendar_cubit.dart'; // ודא שהנתיב נכון

// הפכנו את הווידג'ט ל-Stateless כי הוא כבר לא מנהל מצב בעצמו.
class CalendarWidget extends StatelessWidget {
  const CalendarWidget({super.key});

  // העברנו את רשימות הקבועים לכאן כדי שיהיו זמינים
  final List<String> hebrewMonths = const [
    'ניסן',
    'אייר',
    'סיון',
    'תמוז',
    'אב',
    'אלול',
    'תשרי',
    'חשון',
    'כסלו',
    'טבת',
    'שבט',
    'אדר'
  ];

  final List<String> hebrewDays = const [
    'ראשון',
    'שני',
    'שלישי',
    'רביעי',
    'חמישי',
    'שישי',
    'שבת'
  ];

  @override
  Widget build(BuildContext context) {
    // BlocBuilder מאזין לשינויים ב-Cubit ובונה מחדש את הממשק בכל פעם שהמצב משתנה
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        return Scaffold(
          // אין צורך ב-AppBar כאן אם הוא מגיע ממסך האב
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 800;
              if (isWideScreen) {
                return _buildWideScreenLayout(context, state);
              } else {
                return _buildNarrowScreenLayout(context, state);
              }
            },
          ),
        );
      },
    );
  }

  // כל הפונקציות מקבלות כעת את context ואת state
  Widget _buildWideScreenLayout(BuildContext context, CalendarState state) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildCalendar(context, state),
                const SizedBox(height: 16),
                Expanded(child: _buildEventsCard(context, state)),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildDayDetailsWithoutEvents(context, state),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowScreenLayout(BuildContext context, CalendarState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildCalendar(context, state),
          const SizedBox(height: 16),
          _buildEventsCard(context, state),
          const SizedBox(height: 16),
          _buildDayDetailsWithoutEvents(context, state),
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, CalendarState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildMonthYearSelector(context, state),
            const SizedBox(height: 16),
            _buildCalendarGrid(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthYearSelector(BuildContext context, CalendarState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => context.read<CalendarCubit>().previousMonth(),
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          _getCurrentMonthYearText(state),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: () => context.read<CalendarCubit>().nextMonth(),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context, CalendarState state) {
    return Column(
      children: [
        Row(
          children: hebrewDays
              .map((day) => Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        _buildCalendarDays(context, state),
      ],
    );
  }

  Widget _buildCalendarDays(BuildContext context, CalendarState state) {
    if (state.calendarType == CalendarType.gregorian) {
      return _buildGregorianCalendarDays(context, state);
    } else {
      return _buildHebrewCalendarDays(context, state);
    }
  }

  Widget _buildHebrewCalendarDays(BuildContext context, CalendarState state) {
    final currentJewishDate = state.currentJewishDate;
    final daysInMonth = currentJewishDate.getDaysInJewishMonth();
    final firstDayOfMonth = JewishDate();
    firstDayOfMonth.setJewishDate(
      currentJewishDate.getJewishYear(),
      currentJewishDate.getJewishMonth(),
      1,
    );
    final startingWeekday = firstDayOfMonth.getGregorianCalendar().weekday % 7;

    List<Widget> dayWidgets =
        List.generate(startingWeekday, (_) => const SizedBox());

    for (int day = 1; day <= daysInMonth; day++) {
      dayWidgets.add(_buildHebrewDayCell(context, state, day));
    }

    List<Widget> rows = [];
    for (int i = 0; i < dayWidgets.length; i += 7) {
      final rowWidgets = dayWidgets.sublist(
          i, i + 7 > dayWidgets.length ? dayWidgets.length : i + 7);
      while (rowWidgets.length < 7) {
        rowWidgets.add(const SizedBox());
      }
      rows.add(
          Row(children: rowWidgets.map((w) => Expanded(child: w)).toList()));
    }

    return Column(children: rows);
  }

  Widget _buildGregorianCalendarDays(
      BuildContext context, CalendarState state) {
    final currentGregorianDate = state.currentGregorianDate;
    final firstDayOfMonth =
        DateTime(currentGregorianDate.year, currentGregorianDate.month, 1);
    final lastDayOfMonth =
        DateTime(currentGregorianDate.year, currentGregorianDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday % 7;

    List<Widget> dayWidgets =
        List.generate(startingWeekday, (_) => const SizedBox());

    for (int day = 1; day <= daysInMonth; day++) {
      dayWidgets.add(_buildGregorianDayCell(context, state, day));
    }

    List<Widget> rows = [];
    for (int i = 0; i < dayWidgets.length; i += 7) {
      final rowWidgets = dayWidgets.sublist(
          i, i + 7 > dayWidgets.length ? dayWidgets.length : i + 7);
      while (rowWidgets.length < 7) {
        rowWidgets.add(const SizedBox());
      }
      rows.add(
          Row(children: rowWidgets.map((w) => Expanded(child: w)).toList()));
    }

    return Column(children: rows);
  }

  Widget _buildHebrewDayCell(
      BuildContext context, CalendarState state, int day) {
    final jewishDate = JewishDate();
    jewishDate.setJewishDate(
      state.currentJewishDate.getJewishYear(),
      state.currentJewishDate.getJewishMonth(),
      day,
    );
    final gregorianDate = jewishDate.getGregorianCalendar();

    final isSelected = state.selectedJewishDate.getJewishDayOfMonth() == day &&
        state.selectedJewishDate.getJewishMonth() ==
            jewishDate.getJewishMonth() &&
        state.selectedJewishDate.getJewishYear() == jewishDate.getJewishYear();

    return GestureDetector(
      onTap: () =>
          context.read<CalendarCubit>().selectDate(jewishDate, gregorianDate),
      child: Container(
        margin: const EdgeInsets.all(2),
        height: 50,
        decoration: BoxDecoration(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatHebrewDay(day),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize:
                      state.calendarType == CalendarType.combined ? 14 : 16,
                ),
              ),
              if (state.calendarType == CalendarType.combined)
                Text(
                  '${gregorianDate.day}',
                  style: TextStyle(
                    color: isSelected ? Colors.white70 : Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGregorianDayCell(
      BuildContext context, CalendarState state, int day) {
    final gregorianDate = DateTime(
        state.currentGregorianDate.year, state.currentGregorianDate.month, day);
    final jewishDate = JewishDate.fromDateTime(gregorianDate);

    final isSelected = state.selectedGregorianDate.day == day &&
        state.selectedGregorianDate.month == gregorianDate.month &&
        state.selectedGregorianDate.year == gregorianDate.year;

    return GestureDetector(
      onTap: () =>
          context.read<CalendarCubit>().selectDate(jewishDate, gregorianDate),
      child: Container(
        margin: const EdgeInsets.all(2),
        height: 50,
        decoration: BoxDecoration(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize:
                      state.calendarType == CalendarType.combined ? 14 : 16,
                ),
              ),
              if (state.calendarType == CalendarType.combined)
                Text(
                  _formatHebrewDay(jewishDate.getJewishDayOfMonth()),
                  style: TextStyle(
                    color: isSelected ? Colors.white70 : Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayDetailsWithoutEvents(
      BuildContext context, CalendarState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateHeader(context, state),
          const SizedBox(height: 16),
          _buildTimesCard(context, state),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, CalendarState state) {
    final dayOfWeek = hebrewDays[state.selectedGregorianDate.weekday % 7];
    final jewishDateStr =
        '${_formatHebrewDay(state.selectedJewishDate.getJewishDayOfMonth())} ${hebrewMonths[state.selectedJewishDate.getJewishMonth() - 1]}';
    final gregorianDateStr =
        '${state.selectedGregorianDate.day} ${_getGregorianMonthName(state.selectedGregorianDate.month)} ${state.selectedGregorianDate.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$dayOfWeek $jewishDateStr',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            gregorianDateStr,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTimesCard(BuildContext context, CalendarState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule),
                const SizedBox(width: 8),
                const Text(
                  'זמני היום',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: state.selectedCity,
                  items: cityCoordinates.keys.map((city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      context.read<CalendarCubit>().changeCity(value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTimesGrid(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildTimesGrid(BuildContext context, CalendarState state) {
    final dailyTimes = state.dailyTimes;
    final timesList = [
      {'name': 'עלות השחר', 'time': dailyTimes['alos']},
      {'name': 'זריחה', 'time': dailyTimes['sunrise']},
      {'name': 'סוף זמן קריאת שמע', 'time': dailyTimes['sofZmanShma']},
      {'name': 'סוף זמן תפילה', 'time': dailyTimes['sofZmanTfila']},
      {'name': 'חצות היום', 'time': dailyTimes['chatzos']},
      {'name': 'מנחה גדולה', 'time': dailyTimes['minchaGedola']},
      {'name': 'מנחה קטנה', 'time': dailyTimes['minchaKetana']},
      {'name': 'פלג המנחה', 'time': dailyTimes['plagHamincha']},
      {'name': 'שקיעה', 'time': dailyTimes['sunset']},
      {'name': 'צאת הכוכבים', 'time': dailyTimes['tzais']},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: timesList.length,
      itemBuilder: (context, index) {
        final timeData = timesList[index];
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                timeData['name']!,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                timeData['time'] ?? '--:--',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  // פונקציות העזר שלא תלויות במצב נשארות כאן
  String _getCurrentMonthYearText(CalendarState state) {
    if (state.calendarType == CalendarType.gregorian) {
      return '${_getGregorianMonthName(state.currentGregorianDate.month)} ${state.currentGregorianDate.year}';
    } else {
      return '${hebrewMonths[state.currentJewishDate.getJewishMonth() - 1]} ${_formatHebrewYear(state.currentJewishDate.getJewishYear())}';
    }
  }

  String _formatHebrewYear(int year) {
    final thousands = year ~/ 1000;
    final remainder = year % 1000;
    if (thousands == 5) {
      final hebrewNumber = _numberToHebrewWithoutQuotes(remainder);
      return 'ה\'$hebrewNumber';
    } else {
      return _numberToHebrewWithoutQuotes(year);
    }
  }

  String _formatHebrewDay(int day) {
    return _numberToHebrewWithoutQuotes(day);
  }

  String _numberToHebrewWithoutQuotes(int number) {
    if (number <= 0) return '';
    String result = '';
    int num = number;
    if (num >= 100) {
      int hundreds = (num ~/ 100) * 100;
      if (hundreds == 900)
        result += 'תתק';
      else if (hundreds == 800)
        result += 'תת';
      else if (hundreds == 700)
        result += 'תש';
      else if (hundreds == 600)
        result += 'תר';
      else if (hundreds == 500)
        result += 'תק';
      else if (hundreds == 400)
        result += 'ת';
      else if (hundreds == 300)
        result += 'ש';
      else if (hundreds == 200)
        result += 'ר';
      else if (hundreds == 100) result += 'ק';
      num %= 100;
    }
    const ones = ['', 'א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ז', 'ח', 'ט'];
    const tens = ['', 'י', 'כ', 'ל', 'מ', 'נ', 'ס', 'ע', 'פ', 'צ'];
    if (num == 15) {
      result += 'טו';
    } else if (num == 16) {
      result += 'טז';
    } else {
      if (num >= 10) {
        result += tens[num ~/ 10];
        num %= 10;
      }
      if (num > 0) {
        result += ones[num];
      }
    }
    return result;
  }

  String _getGregorianMonthName(int month) {
    const months = [
      'ינואר',
      'פברואר',
      'מרץ',
      'אפריל',
      'מאי',
      'יוני',
      'יולי',
      'אוגוסט',
      'ספטמבר',
      'אוקטובר',
      'נובמבר',
      'דצמבר'
    ];
    return months[month - 1];
  }

  // החלק של האירועים עדיין לא עבר ריפקטורינג, הוא יישאר לא פעיל בינתיים
  Widget _buildEventsCard(BuildContext context, CalendarState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event),
                const SizedBox(width: 8),
                const Text(
                  'אירועים',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {/* TODO: Implement create event with cubit */},
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('צור אירוע'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(child: Text('אין אירועים ליום זה')),
          ],
        ),
      ),
    );
  }
}
