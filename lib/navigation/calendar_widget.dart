import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'calendar_cubit.dart';
import 'package:otzaria/daf_yomi/daf_yomi_helper.dart';

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
          child: LayoutBuilder(
            builder: (ctx, cons) => SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCalendar(context, state),
                  const SizedBox(height: 16),
                  _buildEventsCard(context, state),
                ],
              ),
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
            _buildCalendarHeader(context, state),
            const SizedBox(height: 16),
            _buildCalendarGrid(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader(BuildContext context, CalendarState state) {
    Widget buildViewButton(CalendarView view, IconData icon, String tooltip) {
      final bool isSelected = state.calendarView == view;
      return Tooltip(
        message: tooltip,
        child: IconButton(
          isSelected: isSelected,
          icon: Icon(icon),
          onPressed: () =>
              context.read<CalendarCubit>().changeCalendarView(view),
          style: IconButton.styleFrom(
            // כאן אנו מגדירים את הריבוע הצבעוני סביב הכפתור הנבחר
            foregroundColor:
                isSelected ? Theme.of(context).colorScheme.primary : null,
            backgroundColor: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                : null,
            side: isSelected
                ? BorderSide(color: Theme.of(context).colorScheme.primary)
                : BorderSide.none,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }

    return Column(
      children: [
        // שורה עליונה עם כפתורים וכותרת
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Wrap(
              children: [
                ElevatedButton(
                  onPressed: () => context.read<CalendarCubit>().jumpToToday(),
                  child: const Text('היום'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showJumpToDateDialog(context),
                  child: const Text('קפוץ אל'),
                ),
              ],
            ),
            Expanded(
              child: Text(
                _getCurrentMonthYearText(state),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // כפתורים עם סמלים בלבד
                buildViewButton(
                    CalendarView.month, Icons.calendar_view_month, 'חודש'),
                buildViewButton(
                    CalendarView.week, Icons.calendar_view_week, 'שבוע'),
                buildViewButton(
                    CalendarView.day, Icons.calendar_view_day, 'יום'),

                // קו הפרדה קטן
                Container(
                  height: 24,
                  width: 1,
                  color: Theme.of(context).dividerColor,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),

                // מעבר בין חודשים
                IconButton(
                  onPressed: () =>
                      context.read<CalendarCubit>().previousMonth(),
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed: () => context.read<CalendarCubit>().nextMonth(),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context, CalendarState state) {
    switch (state.calendarView) {
      case CalendarView.month:
        return _buildMonthView(context, state);
      case CalendarView.week:
        return _buildWeekView(context, state);
      case CalendarView.day:
        return _buildDayView(context, state);
    }
  }

  Widget _buildMonthView(BuildContext context, CalendarState state) {
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _buildWeekView(BuildContext context, CalendarState state) {
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        _buildWeekDays(context, state),
      ],
    );
  }

  Widget _buildDayView(BuildContext context, CalendarState state) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor,
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              hebrewDays[state.selectedGregorianDate.weekday % 7],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatHebrewDay(state.selectedJewishDate.getJewishDayOfMonth())} ${hebrewMonths[state.selectedJewishDate.getJewishMonth() - 1]}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${state.selectedGregorianDate.day} ${_getGregorianMonthName(state.selectedGregorianDate.month)} ${state.selectedGregorianDate.year}',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildWeekDays(BuildContext context, CalendarState state) {
    final selectedDate = state.selectedGregorianDate;
    final startOfWeek =
        selectedDate.subtract(Duration(days: selectedDate.weekday % 7));

    List<Widget> weekDays = [];
    for (int i = 0; i < 7; i++) {
      final dayDate = startOfWeek.add(Duration(days: i));
      final jewishDate = JewishDate.fromDateTime(dayDate);

      final isSelected = dayDate.day == selectedDate.day &&
          dayDate.month == selectedDate.month &&
          dayDate.year == selectedDate.year;

      final isToday = dayDate.day == DateTime.now().day &&
          dayDate.month == DateTime.now().month &&
          dayDate.year == DateTime.now().year;

      weekDays.add(
        Expanded(
          child: _HoverableDayCell(
            onAdd: () {
              // לפני פתיחת הדיאלוג, נבחר את התא שנלחץ
              context.read<CalendarCubit>().selectDate(jewishDate, dayDate);
              _showCreateEventDialog(context,
                  context.read<CalendarCubit>().state); // קבלת המצב המעודכן
            },
            child: GestureDetector(
              onTap: () =>
                  context.read<CalendarCubit>().selectDate(jewishDate, dayDate),
              child: Container(
                margin: const EdgeInsets.all(2),
                height: 88,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : isToday
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.25)
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainer
                              .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : isToday
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                    width: isToday ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${dayDate.day}',
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatHebrewDay(jewishDate.getJewishDayOfMonth()),
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withOpacity(0.85)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _DayExtras(
                        date: dayDate,
                        jewishCalendar: JewishCalendar.fromDateTime(dayDate),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Row(children: weekDays);
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

    final isToday = gregorianDate.day == DateTime.now().day &&
        gregorianDate.month == DateTime.now().month &&
        gregorianDate.year == DateTime.now().year;

    return _HoverableDayCell(
      onAdd: () => _showCreateEventDialog(context, state),
      child: GestureDetector(
        onTap: () =>
            context.read<CalendarCubit>().selectDate(jewishDate, gregorianDate),
        child: Container(
          margin: const EdgeInsets.all(2),
          height: 88,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : isToday
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.25)
                    : Theme.of(context)
                        .colorScheme
                        .surfaceContainer
                        .withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : isToday
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
              width: isToday ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 4,
                right: 4,
                child: Text(
                  _formatHebrewDay(day),
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize:
                        state.calendarType == CalendarType.combined ? 12 : 14,
                  ),
                ),
              ),
              if (state.calendarType == CalendarType.combined)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Text(
                    '${gregorianDate.day}',
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withOpacity(0.85)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
              Positioned(
                top: 30,
                left: 4,
                right: 4,
                child: _DayExtras(
                  date: gregorianDate,
                  jewishCalendar: JewishCalendar.fromDateTime(gregorianDate),
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

    final isToday = gregorianDate.day == DateTime.now().day &&
        gregorianDate.month == DateTime.now().month &&
        gregorianDate.year == DateTime.now().year;

    return _HoverableDayCell(
      onAdd: () => _showCreateEventDialog(context, state),
      child: GestureDetector(
        onTap: () =>
            context.read<CalendarCubit>().selectDate(jewishDate, gregorianDate),
        child: Container(
          margin: const EdgeInsets.all(2),
          height: 88,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : isToday
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.25)
                    : Theme.of(context)
                        .colorScheme
                        .surfaceContainer
                        .withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : isToday
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
              width: isToday ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 4,
                right: 4,
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize:
                        state.calendarType == CalendarType.combined ? 12 : 14,
                  ),
                ),
              ),
              if (state.calendarType == CalendarType.combined)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Text(
                    _formatHebrewDay(jewishDate.getJewishDayOfMonth()),
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withOpacity(0.85)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
              Positioned(
                top: 30,
                left: 4,
                right: 4,
                child: _DayExtras(
                  date: gregorianDate,
                  jewishCalendar: JewishCalendar.fromDateTime(gregorianDate),
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
            style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                _buildCityDropdownWithSearch(context, state),
              ],
            ),
            const SizedBox(height: 16),
            _buildTimesGrid(context, state),
            const SizedBox(height: 16),
            _buildDafYomiButtons(context, state),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(76),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: Theme.of(context).primaryColor, width: 1),
              ),
              child: Text(
                'אין לסמוך על הזמנים!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimesGrid(BuildContext context, CalendarState state) {
    final dailyTimes = state.dailyTimes;
    final jewishCalendar =
        JewishCalendar.fromDateTime(state.selectedGregorianDate);

    // זמנים בסיסיים
    final List<Map<String, String?>> timesList = [
      {'name': 'עלות השחר', 'time': dailyTimes['alos']},
      {
        'name': 'עלות השחר (שיטת 72 דקות) במעלות',
        'time': dailyTimes['alos16point1Degrees']
      },
      {
        'name': 'עלות השחר (שיטת 90 דקות) במעלות',
        'time': dailyTimes['alos19point8Degrees']
      },
      {'name': 'זריחה', 'time': dailyTimes['sunrise']},
      {'name': 'סוף זמן ק"ש - מג"א', 'time': dailyTimes['sofZmanShmaMGA']},
      {'name': 'סוף זמן ק"ש - גר"א', 'time': dailyTimes['sofZmanShmaGRA']},
      {'name': 'סוף זמן תפילה - מג"א', 'time': dailyTimes['sofZmanTfilaMGA']},
      {'name': 'סוף זמן תפילה - גר"א', 'time': dailyTimes['sofZmanTfilaGRA']},
      {'name': 'חצות היום', 'time': dailyTimes['chatzos']},
      {'name': 'חצות הלילה', 'time': dailyTimes['chatzosLayla']},
      {'name': 'מנחה גדולה', 'time': dailyTimes['minchaGedola']},
      {'name': 'מנחה קטנה', 'time': dailyTimes['minchaKetana']},
      {'name': 'פלג המנחה', 'time': dailyTimes['plagHamincha']},
      {'name': 'שקיעה', 'time': dailyTimes['sunset']},
      {'name': 'צאת הכוכבים', 'time': dailyTimes['tzais']},
      {'name': 'צאת הכוכבים ר"ת', 'time': dailyTimes['sunsetRT']},
    ];

    // הוספת זמנים מיוחדים לערב פסח
    if (jewishCalendar.getYomTovIndex() == JewishCalendar.EREV_PESACH) {
      timesList.addAll([
        {
          'name': 'סוף זמן אכילת חמץ - מג"א',
          'time': dailyTimes['sofZmanAchilasChametzMGA']
        },
        {
          'name': 'סוף זמן אכילת חמץ - גר"א',
          'time': dailyTimes['sofZmanAchilasChametzGRA']
        },
        {
          'name': 'סוף זמן ביעור חמץ - מג"א',
          'time': dailyTimes['sofZmanBiurChametzMGA']
        },
        {
          'name': 'סוף זמן ביעור חמץ - גר"א',
          'time': dailyTimes['sofZmanBiurChametzGRA']
        },
      ]);
    }

    // הוספת זמני כניסת שבת/חג
    if (jewishCalendar.getDayOfWeek() == 6 || jewishCalendar.isErevYomTov()) {
      timesList
          .add({'name': 'הדלקת נרות', 'time': dailyTimes['candleLighting']});
    }

    // הוספת זמני יציאת שבת/חג
    if (jewishCalendar.getDayOfWeek() == 7 || jewishCalendar.isYomTov()) {
      final String exitName;
      final String exitName2;

      if (jewishCalendar.getDayOfWeek() == 7 && !jewishCalendar.isYomTov()) {
        exitName = 'יציאת שבת';
        exitName2 = 'צאת השבת חזו"א';
      } else if (jewishCalendar.isYomTov()) {
        final holidayName = _getHolidayName(jewishCalendar);
        exitName = 'יציאת $holidayName';
        exitName2 = 'יציאת $holidayName חזו"א';
      } else {
        exitName = 'יציאת שבת';
        exitName2 = 'צאת השבת חזו"א';
      }

      timesList.addAll([
        {'name': exitName, 'time': dailyTimes['shabbosExit1']},
        {'name': exitName2, 'time': dailyTimes['shabbosExit2']},
      ]);
    }

    // הוספת זמן ספירת העומר
    if (jewishCalendar.getDayOfOmer() != -1) {
      timesList
          .add({'name': 'ספירת העומר', 'time': dailyTimes['omerCounting']});
    }

    // הוספת זמני תענית
    if (jewishCalendar.isTaanis() &&
        jewishCalendar.getYomTovIndex() != JewishCalendar.YOM_KIPPUR) {
      timesList.addAll([
        {'name': 'תחילת התענית', 'time': dailyTimes['fastStart']},
        {'name': 'סיום התענית', 'time': dailyTimes['fastEnd']},
      ]);
    }

    // הוספת זמני קידוש לבנה
    if (dailyTimes['kidushLevanaEarliest'] != null ||
        dailyTimes['kidushLevanaLatest'] != null) {
      if (dailyTimes['kidushLevanaEarliest'] != null) {
        timesList.add({
          'name': 'תחילת זמן קידוש לבנה',
          'time': dailyTimes['kidushLevanaEarliest']
        });
      }
      if (dailyTimes['kidushLevanaLatest'] != null) {
        timesList.add({
          'name': 'סוף זמן קידוש לבנה',
          'time': dailyTimes['kidushLevanaLatest']
        });
      }
    }

    // הוספת זמני חנוכה
    if (jewishCalendar.isChanukah()) {
      timesList.add(
          {'name': 'הדלקת נרות חנוכה', 'time': dailyTimes['chanukahCandles']});
    }

    // הוספת זמני קידוש לבנה
    if (dailyTimes['tchilasKidushLevana'] != null) {
      timesList.add({
        'name': 'תחילת זמן קידוש לבנה',
        'time': dailyTimes['tchilasKidushLevana']
      });
    }
    if (dailyTimes['sofZmanKidushLevana'] != null) {
      timesList.add({
        'name': 'סוף זמן קידוש לבנה',
        'time': dailyTimes['sofZmanKidushLevana']
      });
    }

    // סינון זמנים שלא קיימים
    final filteredTimesList =
        timesList.where((timeData) => timeData['time'] != null).toList();

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: filteredTimesList.length,
      itemBuilder: (context, index) {
        final timeData = filteredTimesList[index];
        final isSpecialTime = _isSpecialTime(timeData['name']!);
        final bgColor =
            isSpecialTime ? scheme.tertiaryContainer : scheme.surfaceVariant;
        final border =
            isSpecialTime ? Border.all(color: scheme.tertiary, width: 1) : null;
        final titleColor = isSpecialTime
            ? scheme.onTertiaryContainer
            : scheme.onSurfaceVariant;
        final timeColor =
            isSpecialTime ? scheme.onTertiaryContainer : scheme.onSurface;

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: border,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                timeData['name']!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: titleColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                timeData['time'] ?? '--:--',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: timeColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDafYomiButtons(BuildContext context, CalendarState state) {
    final jewishCalendar =
        JewishCalendar.fromDateTime(state.selectedGregorianDate);

    // חישוב דף יומי בבלי
    final dafYomiBavli = YomiCalculator.getDafYomiBavli(jewishCalendar);
    final bavliTractate = dafYomiBavli.getMasechta();
    final bavliDaf = dafYomiBavli.getDaf();

    // חישוב דף יומי ירושלמי
    final dafYomiYerushalmi =
        YerushalmiYomiCalculator.getDafYomiYerushalmi(jewishCalendar);
    final yerushalmiTractate = dafYomiYerushalmi.getMasechta();
    final yerushalmiDaf = dafYomiYerushalmi.getDaf();

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              openDafYomiBook(
                  context, bavliTractate, ' ${_formatDafNumber(bavliDaf)}.');
            },
            icon: const Icon(Icons.book),
            label: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'דף היומי בבלי',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$bavliTractate ${_formatDafNumber(bavliDaf)}',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              openDafYomiYerushalmiBook(context, yerushalmiTractate,
                  ' ${_formatDafNumber(yerushalmiDaf)}.');
            },
            icon: const Icon(Icons.menu_book),
            label: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'דף היומי ירושלמי',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$yerushalmiTractate ${_formatDafNumber(yerushalmiDaf)}',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDafNumber(int daf) {
    return HebrewDateFormatter()
        .formatHebrewNumber(daf)
        .replaceAll('״', '')
        .replaceAll('׳', '');
  }

  bool _isSpecialTime(String timeName) {
    return timeName.contains('חמץ') ||
        timeName.contains('הדלקת נרות') ||
        timeName.contains('יציאת') ||
        timeName.contains('צאת השבת') ||
        timeName.contains('ספירת העומר') ||
        timeName.contains('תענית') ||
        timeName.contains('חנוכה') ||
        timeName.contains('קידוש לבנה');
  }

  String _getHolidayName(JewishCalendar jewishCalendar) {
    final yomTovIndex = jewishCalendar.getYomTovIndex();

    switch (yomTovIndex) {
      case JewishCalendar.ROSH_HASHANA:
        return 'ראש השנה';
      case JewishCalendar.YOM_KIPPUR:
        return 'יום כיפור';
      case JewishCalendar.SUCCOS:
        return 'חג הסוכות';
      case JewishCalendar.SHEMINI_ATZERES:
        return 'שמיני עצרת';
      case JewishCalendar.SIMCHAS_TORAH:
        return 'שמחת תורה';
      case JewishCalendar.PESACH:
        return 'חג הפסח';
      case JewishCalendar.SHAVUOS:
        return 'חג השבועות';
      case JewishCalendar.CHANUKAH:
        return 'חנוכה';
      case 17: // HOSHANA_RABBA
        return 'הושענא רבה';
      case 2: // CHOL_HAMOED_PESACH
        return 'חול המועד פסח';
      case 16: // CHOL_HAMOED_SUCCOS
        return 'חול המועד סוכות';
      default:
        return 'חג';
    }
  }

  // פונקציות העזר שלא תלויות במצב נשארות כאן
  String _getCurrentMonthYearText(CalendarState state) {
    final gregName = _getGregorianMonthName(state.currentGregorianDate.month);
    final gregNum = state.currentGregorianDate.month;
    final hebName = hebrewMonths[state.currentJewishDate.getJewishMonth() - 1];
    final hebYear = _formatHebrewYear(state.currentJewishDate.getJewishYear());

    // Show both calendars for clarity
    return '$hebName $hebYear • $gregName ($gregNum) ${state.currentGregorianDate.year}';
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
      if (hundreds == 900) {
        result += 'תתק';
      } else if (hundreds == 800) {
        result += 'תת';
      } else if (hundreds == 700) {
        result += 'תש';
      } else if (hundreds == 600) {
        result += 'תר';
      } else if (hundreds == 500) {
        result += 'תק';
      } else if (hundreds == 400) {
        result += 'ת';
      } else if (hundreds == 300) {
        result += 'ש';
      } else if (hundreds == 200) {
        result += 'ר';
      } else if (hundreds == 100) {
        result += 'ק';
      }
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

  // פונקציות עזר חדשות לפענוח תאריך עברי
  int _hebrewNumberToInt(String hebrew) {
    final Map<String, int> hebrewValue = {
      'א': 1, 'ב': 2, 'ג': 3, 'ד': 4, 'ה': 5, 'ו': 6, 'ז': 7, 'ח': 8, 'ט': 9,
      'י': 10, 'כ': 20, 'ל': 30, 'מ': 40, 'נ': 50, 'ס': 60, 'ע': 70, 'פ': 80, 'צ': 90,
      'ק': 100, 'ר': 200, 'ש': 300, 'ת': 400
    };

    String cleanHebrew = hebrew.replaceAll('"', '').replaceAll("'", "");
    if (cleanHebrew == 'טו') return 15;
    if (cleanHebrew == 'טז') return 16;

    int sum = 0;
    for (int i = 0; i < cleanHebrew.length; i++) {
      sum += hebrewValue[cleanHebrew[i]] ?? 0;
    }
    return sum;
  }

  int _hebrewMonthToInt(String monthName) {
    final cleanMonth = monthName.trim();
    final monthIndex = hebrewMonths.indexOf(cleanMonth);
    if (monthIndex != -1) return monthIndex + 1;

    // טיפול בשמות חלופיים
    if (cleanMonth == 'חשוון' || cleanMonth == 'מרחשוון') return 8;
    if (cleanMonth == 'סיוון') return 3;

    throw Exception('Invalid month name');
  }

  int _hebrewYearToInt(String hebrewYear) {
    String cleanYear = hebrewYear.replaceAll('"', '').replaceAll("'", "");
    int baseYear = 0;

    // בדוק אם השנה מתחילה ב-'ה'
    if (cleanYear.startsWith('ה')) {
      baseYear = 5000;
      cleanYear = cleanYear.substring(1);
    }
    
    // המר את שאר האותיות למספר
    int yearFromLetters = _hebrewNumberToInt(cleanYear);

    // אם לא היתה 'ה' בהתחלה, אבל קיבלנו מספר שנראה כמו שנה,
    // נניח אוטומטית שהכוונה היא לאלף הנוכחי (5000)
    if (baseYear == 0 && yearFromLetters > 0) {
        baseYear = 5000;
    }

    return baseYear + yearFromLetters;
  }
  
  void _showJumpToDateDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    final TextEditingController dateController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            return AlertDialog(
              title: const Text('קפוץ לתאריך'),
              content: SizedBox(
                width: 350,
                height: 450,
                child: Column(
                  children: [
                    // הזנת תאריך ידנית
                    TextField(
                      controller: dateController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'הזן תאריך',
                        hintText: 'דוגמאות: 15/3/2025, כ״ה אדר תשפ״ה',
                        border: OutlineInputBorder(),
                        helperText:
                            'ניתן להזין תאריך לועזי (יום/חודש/שנה) או עברי',
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: 20),

                    const Divider(),
                    const Text(
                      'או בחר מלוח השנה:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // לוח שנה
                    Expanded(
                      child: CalendarDatePicker(
                        initialDate: selectedDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                        onDateChanged: (date) {
                          setState(() {
                            selectedDate = date;
                            // עדכן את תיבת הטקסט עם התאריך שנבחר
                            dateController.text =
                                '${date.day}/${date.month}/${date.year}';
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('ביטול'),
                ),
                ElevatedButton(
                  onPressed: () {
                    DateTime? dateToJump;

                    if (dateController.text.isNotEmpty) {
                      // נסה לפרש את הטקסט שהוזן
                      dateToJump = _parseInputDate(context, dateController.text);

                      if (dateToJump == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'לא הצלחנו לפרש את התאריך.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    } else {
                      // אם לא הוזן כלום, השתמש בתאריך שנבחר מהלוח
                      dateToJump = selectedDate;
                    }

                    context.read<CalendarCubit>().jumpToDate(dateToJump);
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('קפוץ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  DateTime? _parseInputDate(BuildContext context, String input) {
    String cleanInput = input.trim();

    // 1. נסה לפרש כתאריך לועזי (יום/חודש/שנה)
    RegExp gregorianPattern = RegExp(r'^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$');
    Match? match = gregorianPattern.firstMatch(cleanInput);

    if (match != null) {
      try {
        int day = int.parse(match.group(1)!);
        int month = int.parse(match.group(2)!);
        int year = int.parse(match.group(3)!);
        if (year >= 1900 && year <= 2200) {
          return DateTime(year, month, day);
        }
      } catch (e) { /* אם נכשל, נמשיך לנסות לפרש כעברי */ }
    }

    // 2. נסה לפרש כתאריך עברי (למשל: י"ח אלול תשפ"ה)
    try {
      final parts = cleanInput.split(RegExp(r'\s+'));
      if (parts.length < 2 || parts.length > 3) return null;

      final day = _hebrewNumberToInt(parts[0]);
      final month = _hebrewMonthToInt(parts[1]);
      int year;

      if (parts.length == 3) {
        year = _hebrewYearToInt(parts[2]);
      } else {
        // אם השנה הושמטה, נשתמש בשנה העברית הנוכחית שמוצגת בלוח
        year = context.read<CalendarCubit>().state.currentJewishDate.getJewishYear();
      }

      if (day > 0 && month > 0 && year > 5000) {
        final jewishDate = JewishDate();
        jewishDate.setJewishDate(year, month, day);
        return jewishDate.getGregorianCalendar();
      }
    } catch (e) {
      return null; // הפענוח נכשל
    }

    return null;
  }

  void _showCreateEventDialog(BuildContext context, CalendarState state,
      {CustomEvent? existingEvent}) {
    final cubit = context.read<CalendarCubit>();
    final isEditMode = existingEvent != null;

    final TextEditingController titleController =
        TextEditingController(text: existingEvent?.title);
    final TextEditingController descriptionController =
        TextEditingController(text: existingEvent?.description);
    final TextEditingController yearsController = TextEditingController(
        text: existingEvent?.recurringYears?.toString() ?? '1');

    bool isRecurring = existingEvent?.recurring ?? false;
    bool useHebrewCalendar = existingEvent?.recurOnHebrew ?? true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditMode ? 'ערוך אירוע' : 'צור אירוע חדש'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'כותרת האירוע',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'תיאור (אופציונלי)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // תאריך נבחר
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'תאריך לועזי: ${state.selectedGregorianDate.day}/${state.selectedGregorianDate.month}/${state.selectedGregorianDate.year}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'תאריך עברי: ${_formatHebrewDay(state.selectedJewishDate.getJewishDayOfMonth())} ${hebrewMonths[state.selectedJewishDate.getJewishMonth() - 1]} ${_formatHebrewYear(state.selectedJewishDate.getJewishYear())}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // אירוע חוזר
                      SwitchListTile(
                        title: const Text('אירוע חוזר'),
                        value: isRecurring,
                        onChanged: (value) =>
                            setState(() => isRecurring = value),
                      ),
                      if (isRecurring) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            children: [
                              DropdownButtonFormField<bool>(
                                value: useHebrewCalendar,
                                decoration: const InputDecoration(
                                  labelText: 'חזור לפי',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  DropdownMenuItem<bool>(
                                    value: true,
                                    child: Text(
                                        'לוח עברי (${_formatHebrewDay(state.selectedJewishDate.getJewishDayOfMonth())} ${hebrewMonths[state.selectedJewishDate.getJewishMonth() - 1]})'),
                                  ),
                                  DropdownMenuItem<bool>(
                                    value: false,
                                    child: Text(
                                        'לוח לועזי (${state.selectedGregorianDate.day}/${state.selectedGregorianDate.month})'),
                                  ),
                                ],
                                onChanged: (value) => setState(
                                    () => useHebrewCalendar = value ?? true),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: yearsController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'חזור למשך (שנים)',
                                  hintText: 'השאר ריק לחזרה ללא הגבלה',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('ביטול'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('יש למלא כותרת לאירוע.'),
                            backgroundColor: Colors.red),
                      );
                      return;
                    }

                    final recurringYears =
                        int.tryParse(yearsController.text.trim());

                    if (isEditMode) {
                      final updatedEvent = existingEvent!.copyWith(
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        recurring: isRecurring,
                        recurOnHebrew: useHebrewCalendar,
                        recurringYears: recurringYears,
                      );
                      cubit.updateEvent(updatedEvent);
                    } else {
                      cubit.addEvent(
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        baseGregorianDate: state.selectedGregorianDate,
                        isRecurring: isRecurring,
                        recurOnHebrew: useHebrewCalendar,
                        recurringYears: recurringYears,
                      );
                    }
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(isEditMode ? 'שמור שינויים' : 'צור'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // הוספת הוויג'ט החדש לבחירת עיר עם סינון
  Widget _buildCityDropdownWithSearch(
      BuildContext context, CalendarState state) {
    return ElevatedButton(
      onPressed: () => _showCitySearchDialog(context, state),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(state.selectedCity),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  // דיאלוג חיפוש ערים
  void _showCitySearchDialog(BuildContext context, CalendarState state) {
    showDialog(
      context: context,
      builder: (dialogContext) => _CitySearchDialog(
        currentCity: state.selectedCity,
        onCitySelected: (city) {
          context.read<CalendarCubit>().changeCity(city);
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  Widget _buildEventsCard(BuildContext context, CalendarState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
                  onPressed: () => _showCreateEventDialog(context, state),
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
            _buildEventsList(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, CalendarState state) {
    final events = context
        .read<CalendarCubit>()
        .eventsForDate(state.selectedGregorianDate);

    if (events.isEmpty) {
      return const Center(child: Text('אין אירועים ליום זה'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).primaryColor.withAlpha(76),
            ),
          ),
          child: Row(
            children: [
              // פרטי האירוע
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (event.recurring) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.repeat,
                            size: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.recurOnHebrew
                                ? 'חוזר לפי לוח עברי'
                                : 'חוזר לפי לוח לועזי',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // לחצני פעולות
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'ערוך אירוע',
                    onPressed: () => _showCreateEventDialog(context, state,
                        existingEvent: event),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    tooltip: 'מחק אירוע',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('אישור מחיקה'),
                          content: Text(
                              'האם אתה בטוח שברצונך למחוק את האירוע "${event.title}"?'),
                          actions: [
                            TextButton(
                              child: const Text('ביטול'),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                            ),
                            TextButton(
                              child: const Text('מחק'),
                              onPressed: () {
                                context
                                    .read<CalendarCubit>()
                                    .deleteEvent(event.id);
                                Navigator.of(dialogContext).pop();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}

// מציג תוספות קטנות בכל יום: זמני זריחה/שקיעה, מועדים, וכמות אירועים מותאמים
class _DayExtras extends StatelessWidget {
  final DateTime date;
  final JewishCalendar jewishCalendar;
  const _DayExtras({required this.date, required this.jewishCalendar});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CalendarCubit>();
    final events = cubit.eventsForDate(date);

    final List<Widget> lines = [];

    for (final e in _calcJewishEvents(jewishCalendar).take(2)) {
      lines.add(Text(
        e,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ));
    }

    for (final e in events.take(2)) {
      lines.add(Text(
        '• ${e.title}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: lines,
    );
  }

  static List<String> _calcJewishEvents(JewishCalendar jc) {
    final List<String> l = [];
    if (jc.isRoshChodesh()) l.add('ר"ח');

    // טיפול מיוחד בתעניות - הצגת השם המלא במקום "צום"
    switch (jc.getYomTovIndex()) {
      case JewishCalendar.ROSH_HASHANA:
        l.add('ראש השנה');
        break;
      case JewishCalendar.YOM_KIPPUR:
        l.add('יום כיפור');
        break;
      case JewishCalendar.SUCCOS:
        l.add('סוכות');
        break;
      case JewishCalendar.SHEMINI_ATZERES:
        l.add('שמיני עצרת');
        break;
      case JewishCalendar.SIMCHAS_TORAH:
        l.add('שמחת תורה');
        break;
      case JewishCalendar.PESACH:
        l.add('פסח');
        break;
      case JewishCalendar.SHAVUOS:
        l.add('שבועות');
        break;
      case JewishCalendar.CHANUKAH:
        l.add('חנוכה');
        break;

      default:
        // בדיקה נוספת לתעניות שלא מזוהות בYomTovIndex
        if (jc.isTaanis()) {
          // אם זה תענית שלא זוהתה למעלה, נציג שם כללי
          final jewishMonth = jc.getJewishMonth();
          final jewishDay = jc.getJewishDayOfMonth();

          if (jewishMonth == 7 && jewishDay == 3) {
            l.add('צום גדליה');
          } else if (jewishMonth == 10 && jewishDay == 10) {
            l.add('עשרה בטבת');
          } else if (jewishMonth == 4 && jewishDay == 17) {
            l.add('שבעה עשר בתמוז');
          } else if (jewishMonth == 5 && jewishDay == 9) {
            l.add('תשעה באב');
          } else {
            l.add('תענית');
          }
        }
        break;
    }
    return l;
  }
}

// דיאלוג לחיפוש ובחירת עיר
class _CitySearchDialog extends StatefulWidget {
  final String currentCity;
  final ValueChanged<String> onCitySelected;

  const _CitySearchDialog({
    required this.currentCity,
    required this.onCitySelected,
  });

  @override
  State<_CitySearchDialog> createState() => _CitySearchDialogState();
}

class _CitySearchDialogState extends State<_CitySearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  late Map<String, Map<String, Map<String, double>>> _filteredCities;

  @override
  void initState() {
    super.initState();
    _filteredCities = cityCoordinates;
    _searchController.addListener(_filterCities);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCities);
    _searchController.dispose();
    super.dispose();
  }

  void _filterCities() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCities = cityCoordinates;
      } else {
        _filteredCities = {};
        cityCoordinates.forEach((country, cities) {
          final matchingCities = Map.fromEntries(cities.entries.where(
              (cityEntry) => cityEntry.key.toLowerCase().contains(query)));
          if (matchingCities.isNotEmpty) {
            _filteredCities[country] = matchingCities;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = [];
    _filteredCities.forEach((country, cities) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            country,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              fontSize: 16,
            ),
          ),
        ),
      );
      cities.forEach((city, data) {
        items.add(
          ListTile(
            title: Text(city),
            onTap: () {
              widget.onCitySelected(city);
            },
          ),
        );
      });
      items.add(const Divider());
    });
    if (items.isNotEmpty) {
      items.removeLast(); // Remove last divider
    }

    return AlertDialog(
      title: const Text('חיפוש עיר'),
      content: SizedBox(
        width: 400, // הגדרת רוחב קבוע
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'הקלד שם עיר...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredCities.isEmpty
                  ? const Center(child: Text('לא נמצאו ערים'))
                  : ListView(children: items),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ביטול'),
        ),
      ],
    );
  }
}

// ווידג'ט עזר שמציג לחצן הוספה בריחוף
class _HoverableDayCell extends StatefulWidget {
  final Widget child;
  final VoidCallback onAdd;

  const _HoverableDayCell({required this.child, required this.onAdd});

  @override
  State<_HoverableDayCell> createState() => _HoverableDayCellState();
}

class _HoverableDayCellState extends State<_HoverableDayCell> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          // כפתור הוספה שמופיע בריחוף
          AnimatedOpacity(
            opacity: _isHovering ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_isHovering, // מונע מהכפתור לחסום קליקים כשהוא שקוף
              child: Tooltip(
                message: 'צור אירוע',
                child: IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: widget.onAdd,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    visualDensity:
                        VisualDensity.compact, // הופך אותו לקצת יותר קטן
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
