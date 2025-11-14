import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'calendar_cubit.dart';
import 'package:otzaria/daf_yomi/daf_yomi_helper.dart';
import 'package:otzaria/core/scaffold_messenger.dart';
import 'package:otzaria/settings/calendar_settings_dialog.dart';
import 'package:otzaria/widgets/confirmation_dialog.dart';
import 'package:otzaria/i18n/translations.g.dart';

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCalendar(context, state),
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
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildCalendar(context, state),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildDayDetailsWithoutEvents(context, state),
          ),
        ),
      ],
    );
  }

  // פונקציה עזר שמחזירה צבע רקע עדין לשבתות ומועדים
  Color? _getBackgroundColor(BuildContext context, DateTime date,
      bool isSelected, bool isToday, bool inIsrael) {
    if (isSelected || isToday) return null;

    final jewishCalendar = JewishCalendar.fromDateTime(date)
      ..inIsrael = inIsrael;

    final bool isShabbat = jewishCalendar.getDayOfWeek() == 7;
    final bool isYomTov = jewishCalendar.isYomTov();
    final bool isTaanis = jewishCalendar.isTaanis();
    final bool isRoshChodesh = jewishCalendar.isRoshChodesh();

    if (isShabbat || isYomTov || isTaanis || isRoshChodesh) {
      return Theme.of(context)
          .colorScheme
          .secondaryContainer
          .withValues(alpha: 0.4);
    }

    return null;
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
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
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
                  child: Text(context.t.calendar.today),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showJumpToDateDialog(context),
                  child: Text(context.t.calendar.goToDate),
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
                buildViewButton(CalendarView.month,
                    FluentIcons.calendar_month_24_regular, 'חודש'),
                buildViewButton(CalendarView.week,
                    FluentIcons.calendar_week_numbers_24_regular, 'שבוע'),
                buildViewButton(CalendarView.day,
                    FluentIcons.calendar_day_24_regular, 'יום'),

                // קו הפרדה קטן
                Container(
                  height: 24,
                  width: 1,
                  color: Theme.of(context).dividerColor,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),

                // מעבר בין תקופות
                IconButton(
                  onPressed: () => context.read<CalendarCubit>().previous(),
                  icon: const Icon(FluentIcons.chevron_left_24_regular),
                ),
                IconButton(
                  onPressed: () => context.read<CalendarCubit>().next(),
                  icon: const Icon(FluentIcons.chevron_right_24_regular),
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
              '${_formatHebrewDay(state.selectedJewishDate.getJewishDayOfMonth())} ${_getHebrewMonthNameFor(state.selectedJewishDate)}',
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
              // יצירת אירוע לתאריך הספציפי של התא, ללא שינוי התאריך הנבחר
              _showCreateEventDialog(
                context,
                context.read<CalendarCubit>().state,
                specificDate: dayDate,
              );
            },
            child: GestureDetector(
              onTap: () =>
                  context.read<CalendarCubit>().selectDate(jewishDate, dayDate),
              child: Container(
                margin: const EdgeInsets.all(2),
                height: 88,
                decoration: BoxDecoration(
                  color: _getBackgroundColor(context, dayDate, isSelected,
                          isToday, state.inIsrael) ??
                      (isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : isToday
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.25)
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainer
                                  .withValues(alpha: 0.2)),
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
                        _formatHebrewDay(jewishDate.getJewishDayOfMonth()),
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Text(
                        '${dayDate.day}',
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withValues(alpha: 0.85)
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
                        date: dayDate,
                        inIsrael: state.inIsrael,
                      ),
                    ),
                  ],
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
      onAdd: () => _showCreateEventDialog(
        context,
        state,
        specificDate: gregorianDate,
      ),
      child: GestureDetector(
        onTap: () =>
            context.read<CalendarCubit>().selectDate(jewishDate, gregorianDate),
        child: Container(
          margin: const EdgeInsets.all(2),
          height: 88,
          decoration: BoxDecoration(
            color: _getBackgroundColor(context, gregorianDate, isSelected,
                    isToday, state.inIsrael) ??
                (isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : isToday
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.25)
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainer
                            .withValues(alpha: 0.2)),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatHebrewDay(day),
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: state.calendarType == CalendarType.combined
                            ? 12
                            : 14,
                      ),
                    ),
                    if (state.calendarType == CalendarType.hebrew &&
                        (jewishDate.isJewishLeapYear() &&
                            (jewishDate.getJewishMonth() == 12 ||
                                jewishDate.getJewishMonth() == 13) &&
                            day == 1))
                      Text(
                        _getHebrewMonthNameFor(jewishDate),
                        style: TextStyle(
                          fontSize: 8,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
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
                              .withValues(alpha: 0.85)
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
                  inIsrael: state.inIsrael,
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
      onAdd: () => _showCreateEventDialog(
        context,
        state,
        specificDate: gregorianDate,
      ),
      child: GestureDetector(
        onTap: () =>
            context.read<CalendarCubit>().selectDate(jewishDate, gregorianDate),
        child: Container(
          margin: const EdgeInsets.all(2),
          height: 88,
          decoration: BoxDecoration(
            color: _getBackgroundColor(context, gregorianDate, isSelected,
                    isToday, state.inIsrael) ??
                (isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : isToday
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.25)
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainer
                            .withValues(alpha: 0.2)),
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
                              .withValues(alpha: 0.85)
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
                  inIsrael: state.inIsrael,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDateHeader(context, state),
        const SizedBox(height: 16),
        Expanded(
          child: _buildTimesAndEventsTabbed(context, state),
        ),
      ],
    );
  }

  Widget _buildDateHeader(BuildContext context, CalendarState state) {
    final dayOfWeek = hebrewDays[state.selectedGregorianDate.weekday % 7];
    final jewishDateStr =
        '${_formatHebrewDay(state.selectedJewishDate.getJewishDayOfMonth())} ${_getHebrewMonthNameFor(state.selectedJewishDate)}';
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

  Widget _buildTimesAndEventsTabbed(BuildContext context, CalendarState state) {
    return _TimesAndEventsTabView(
      state: state,
      buildTimesGrid: (ctx, st) => _buildTimesGrid(ctx, st),
      buildDafYomiButtons: (ctx, st) => _buildDafYomiButtons(ctx, st),
      buildCityDropdown: (ctx, st) => _buildCityDropdownWithSearch(ctx, st),
      buildEventsList: (ctx, st, isSearch) =>
          _buildEventsList(ctx, st, isSearch: isSearch),
      showCreateEventDialog: (ctx, st) => _showCreateEventDialog(ctx, st),
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
        'name': "עלוה\"ש (72 דק') במע'",
        'time': dailyTimes['alos16point1Degrees']
      },
      {
        'name': "עלוה\"ש (90 דק') במע'",
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

    // הוספת זמני יציאת שבת/חג (לא להוסיף בימי חול המועד והושענא רבה)
    final int yomTovIndex = jewishCalendar.getYomTovIndex();
    final bool isNotExitTimesDay =
        yomTovIndex == JewishCalendar.CHOL_HAMOED_SUCCOS ||
            yomTovIndex == JewishCalendar.CHOL_HAMOED_PESACH ||
            yomTovIndex == JewishCalendar.HOSHANA_RABBA;

    if ((jewishCalendar.getDayOfWeek() == 7 || jewishCalendar.isYomTov()) &&
        !isNotExitTimesDay) {
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
        final bgColor = isSpecialTime
            ? scheme.tertiaryContainer
            : scheme.surfaceContainerHighest;
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
    String bavliTractate;
    int bavliDaf;
    try {
      final dafYomiBavli = YomiCalculator.getDafYomiBavli(jewishCalendar);
      bavliTractate = dafYomiBavli.getMasechta();
      bavliDaf = dafYomiBavli.getDaf();
    } catch (e) {
      bavliTractate = 'לא זמין';
      bavliDaf = 0;
    }

    // חישוב דף יומי ירושלמי
    String yerushalmiTractate;
    int yerushalmiDaf;
    try {
      final dafYomiYerushalmi =
          YerushalmiYomiCalculator.getDafYomiYerushalmi(jewishCalendar);
      yerushalmiTractate = dafYomiYerushalmi.getMasechta();
      yerushalmiDaf = dafYomiYerushalmi.getDaf();
    } catch (e) {
      yerushalmiTractate = 'לא זמין';
      yerushalmiDaf = 0;
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              openDafYomiBook(
                  context, bavliTractate, ' ${_formatDafNumber(bavliDaf)}.');
            },
            icon: const Icon(FluentIcons.book_24_regular),
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
            onPressed: null,
            icon: const Icon(FluentIcons.book_24_regular),
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
    DateTime gregorianDate;
    JewishDate jewishDate;

    // For month view, use current dates (month reference)
    // For week/day views, use selected dates (what's being viewed)
    if (state.calendarView == CalendarView.month) {
      gregorianDate = state.currentGregorianDate;
      jewishDate = state.currentJewishDate;
    } else {
      gregorianDate = state.selectedGregorianDate;
      jewishDate = state.selectedJewishDate;
    }

    final gregName = _getGregorianMonthName(gregorianDate.month);
    final gregNum = gregorianDate.month;
    final hebName = _getHebrewMonthNameFor(jewishDate);
    final hebYear = _formatHebrewYear(jewishDate.getJewishYear());

    // Show both calendars for clarity
    return '$hebName $hebYear • $gregName ($gregNum) ${gregorianDate.year}';
  }

  String _formatHebrewYear(int year) {
    final hdf = HebrewDateFormatter();
    hdf.hebrewFormat = true;

    final thousands = year ~/ 1000;
    final remainder = year % 1000;

    String remainderStr = hdf.formatHebrewNumber(remainder);

    String cleanRemainderStr = remainderStr
        .replaceAll('"', '')
        .replaceAll("'", "")
        .replaceAll('׳', '')
        .replaceAll('״', '');

    String formattedRemainder;
    if (cleanRemainderStr.length > 1) {
      formattedRemainder =
          '${cleanRemainderStr.substring(0, cleanRemainderStr.length - 1)}״${cleanRemainderStr.substring(cleanRemainderStr.length - 1)}';
    } else if (cleanRemainderStr.length == 1) {
      formattedRemainder = '$cleanRemainderStr׳';
    } else {
      formattedRemainder = cleanRemainderStr;
    }
    if (thousands == 5) {
      return 'ה׳$formattedRemainder';
    }

    return formattedRemainder;
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

  String _truncateDescription(String description) {
    const int maxLength = 50; // Adjust as needed
    if (description.length <= maxLength) {
      return description;
    }
    return '${description.substring(0, maxLength)}...';
  }

  String _formatEventDate(DateTime date) {
    final jewishDate = JewishDate.fromDateTime(date);
    final hebrewStr =
        '${_formatHebrewDay(jewishDate.getJewishDayOfMonth())} ${_getHebrewMonthNameFor(jewishDate)}';
    final gregorianStr =
        '${date.day} ${_getGregorianMonthName(date.month)} ${date.year}';
    return '$hebrewStr • $gregorianStr';
  }

  // Determine Hebrew month name, including Adar I / Adar II in leap years
  String _getHebrewMonthNameFor(JewishDate jewishDate) {
    final int m = jewishDate.getJewishMonth();
    final bool leap = jewishDate.isJewishLeapYear();
    if (leap && m == 12) return 'אדר א׳';
    if (leap && m == 13) return 'אדר ב׳';
    final int idx = (m - 1).clamp(0, hebrewMonths.length - 1);
    return hebrewMonths[idx];
  }

  // פונקציות עזר חדשות לפענוח תאריך עברי
  int _hebrewNumberToInt(String hebrew) {
    final Map<String, int> hebrewValue = {
      'א': 1,
      'ב': 2,
      'ג': 3,
      'ד': 4,
      'ה': 5,
      'ו': 6,
      'ז': 7,
      'ח': 8,
      'ט': 9,
      'י': 10,
      'כ': 20,
      'ל': 30,
      'מ': 40,
      'נ': 50,
      'ס': 60,
      'ע': 70,
      'פ': 80,
      'צ': 90,
      'ק': 100,
      'ר': 200,
      'ש': 300,
      'ת': 400
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
              title: Text(context.t.calendar.jumpToDate),
              content: SizedBox(
                width: 350,
                height: 450,
                child: Column(
                  children: [
                    // הזנת תאריך ידנית
                    TextField(
                      controller: dateController,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'הזן תאריך',
                        hintText: 'דוגמאות: 15/3/2025, כ״ה אדר תשפ״ה',
                        border: OutlineInputBorder(),
                        helperText:
                            'ניתן להזין תאריך לועזי (יום/חודש/שנה) או עברי',
                      ),
                      onChanged: (value) => setState(() {}),
                      onSubmitted: (value) {
                        DateTime? dateToJump;

                        if (value.isNotEmpty) {
                          // נסה לפרש את הטקסט שהוזן
                          dateToJump = _parseInputDate(context, value);
                          if (dateToJump == null) {
                            UiSnack.showError('לא הצלחנו לפרש את התאריך.',
                                backgroundColor:
                                    Theme.of(context).colorScheme.error);
                            return;
                          }
                        } else {
                          // אם לא הוזן כלום, השתמש בתאריך שנבחר מהלוח
                          dateToJump = selectedDate;
                        }

                        context.read<CalendarCubit>().jumpToDate(dateToJump);
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                    const SizedBox(height: 20),

                    const Divider(),
                    const Text(
                      'או בחר בלוח השנה:',
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
                  child: Text(context.t.calendar.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    DateTime? dateToJump;

                    if (dateController.text.isNotEmpty) {
                      // נסה לפרש את הטקסט שהוזן
                      dateToJump =
                          _parseInputDate(context, dateController.text);

                      if (dateToJump == null) {
                        UiSnack.showError('לא הצלחנו לפרש את התאריך.',
                            backgroundColor:
                                Theme.of(context).colorScheme.error);
                        return;
                      }
                    } else {
                      // אם לא הוזן כלום, השתמש בתאריך שנבחר מהלוח
                      dateToJump = selectedDate;
                    }

                    context.read<CalendarCubit>().jumpToDate(dateToJump);
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(context.t.calendar.jump),
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
    RegExp gregorianPattern =
        RegExp(r'^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$');
    Match? match = gregorianPattern.firstMatch(cleanInput);

    if (match != null) {
      try {
        int day = int.parse(match.group(1)!);
        int month = int.parse(match.group(2)!);
        int year = int.parse(match.group(3)!);
        if (year >= 1900 && year <= 2200) {
          return DateTime(year, month, day);
        }
      } catch (e) {/* אם נכשל, נמשיך לנסות לפרש כעברי */}
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
        year = context
            .read<CalendarCubit>()
            .state
            .currentJewishDate
            .getJewishYear();
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
      {CustomEvent? existingEvent, DateTime? specificDate}) {
    final cubit = context.read<CalendarCubit>();
    final isEditMode = existingEvent != null;

    final TextEditingController titleController =
        TextEditingController(text: existingEvent?.title);
    final TextEditingController descriptionController =
        TextEditingController(text: existingEvent?.description);

    // בקר חדש שמטפל במספר השנים, יהיה ריק אם האירוע הוא "תמיד"
    final TextEditingController yearsController = TextEditingController(
        text: existingEvent?.recurringYears?.toString() ?? '');

    bool isRecurring = existingEvent?.recurring ?? false;
    bool useHebrewCalendar = existingEvent?.recurOnHebrew ?? true;
    // משתנה חדש שבודק אם האירוע מוגדר כ"תמיד"
    bool recurForever = existingEvent?.recurringYears == null;

    // קביעת התאריכים המוצגים - לפי האירוע אם עריכה, אחרת לפי התאריך הספציפי או הנבחר
    final displayedGregorianDate = existingEvent != null
        ? existingEvent.baseGregorianDate
        : (specificDate ?? state.selectedGregorianDate);
    final displayedJewishDate = existingEvent != null
        ? JewishDate.fromDateTime(existingEvent.baseGregorianDate)
        : JewishDate.fromDateTime(specificDate ?? state.selectedGregorianDate);

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
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'כותרת האירוע',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) {
                          if (titleController.text.isEmpty) {
                            UiSnack.showError('יש למלא כותרת לאירוע.',
                                backgroundColor:
                                    Theme.of(context).colorScheme.error);
                            return;
                          }

                          final int? recurringYears;
                          if (isRecurring && !recurForever) {
                            recurringYears =
                                int.tryParse(yearsController.text.trim());
                          } else {
                            recurringYears = null;
                          }

                          if (isEditMode) {
                            final updatedEvent = existingEvent.copyWith(
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
                              baseGregorianDate: displayedGregorianDate,
                              isRecurring: isRecurring,
                              recurOnHebrew: useHebrewCalendar,
                              recurringYears: recurringYears,
                            );
                          }
                          Navigator.of(dialogContext).pop();
                        },
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

                      // תאריך נבחר - השתמש בתאריכים המוצגים
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
                              'תאריך לועזי: ${displayedGregorianDate.day}/${displayedGregorianDate.month}/${displayedGregorianDate.year}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'תאריך עברי: ${_formatHebrewDay(displayedJewishDate.getJewishDayOfMonth())} ${_getHebrewMonthNameFor(displayedJewishDate)} ${_formatHebrewYear(displayedJewishDate.getJewishYear())}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // אירוע חוזר
                      SwitchListTile(
                        title: Text(context.t.calendar.recurringEvent),
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
                                initialValue: useHebrewCalendar,
                                decoration: const InputDecoration(
                                  labelText: 'חזור לפי',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  DropdownMenuItem<bool>(
                                    value: true,
                                    child: Text(
                                        'לוח עברי (${_formatHebrewDay(displayedJewishDate.getJewishDayOfMonth())} ${_getHebrewMonthNameFor(displayedJewishDate)})'),
                                  ),
                                  DropdownMenuItem<bool>(
                                    value: false,
                                    child: Text(
                                        'לוח לועזי (${displayedGregorianDate.day}/${displayedGregorianDate.month})'),
                                  ),
                                ],
                                onChanged: (value) => setState(
                                    () => useHebrewCalendar = value ?? true),
                              ),
                              const SizedBox(height: 16),

                              // --- כאן נמצא השינוי המרכזי ---
                              // הוספנו תיבת סימון לבחירת "תמיד"
                              CheckboxListTile(
                                title: Text(context.t.calendar.repeatForever),
                                value: recurForever,
                                onChanged: (value) {
                                  setState(() {
                                    recurForever = value ?? true;
                                    // אם המשתמש בחר "תמיד", ננקה את שדה מספר השנים
                                    if (recurForever) {
                                      yearsController.clear();
                                    }
                                  });
                                },
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              ),
                              const SizedBox(height: 8),

                              // שדה מספר השנים מושבת כעת אם "תמיד" מסומן
                              TextField(
                                controller: yearsController,
                                keyboardType: TextInputType.number,
                                enabled: !recurForever, // <-- החלק החשוב
                                decoration: InputDecoration(
                                  labelText: 'חזור למשך (שנים)',
                                  hintText: 'לדוגמה: 5',
                                  border: const OutlineInputBorder(),
                                  filled: !recurForever ? false : true,
                                  fillColor: !recurForever
                                      ? null
                                      : Theme.of(context)
                                          .disabledColor
                                          .withValues(alpha: 0.1),
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
                  child: Text(context.t.calendar.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isEmpty) {
                      UiSnack.showError('יש למלא כותרת לאירוע.',
                          backgroundColor: Theme.of(context).colorScheme.error);
                      return;
                    }

                    // --- לוגיקת שמירה מעודכנת ---
                    final int? recurringYears;
                    // אם האירוע חוזר, אבל לא "תמיד", ננסה לקרוא את מספר השנים
                    if (isRecurring && !recurForever) {
                      recurringYears =
                          int.tryParse(yearsController.text.trim());
                    } else {
                      // בכל מקרה אחר (לא חוזר, או חוזר "תמיד"), הערך יהיה ריק (null)
                      recurringYears = null;
                    }

                    if (isEditMode) {
                      final updatedEvent = existingEvent.copyWith(
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
                        baseGregorianDate: displayedGregorianDate,
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
      onPressed: () => showCalendarSettingsDialog(
        context,
        calendarCubit: context.read<CalendarCubit>(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(state.selectedCity),
          const SizedBox(width: 8),
          const Icon(FluentIcons.chevron_down_24_regular),
        ],
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, CalendarState state,
      {bool isSearch = false}) {
    final cubit = context.read<CalendarCubit>();
    final List<CustomEvent> events;

    if (state.eventSearchQuery.isNotEmpty) {
      events = cubit.getFilteredEvents(state.eventSearchQuery);
    } else if (state.showAllEvents) {
      // Show ALL events in the system, sorted by date
      events = List<CustomEvent>.from(state.events)
        ..sort((a, b) => a.baseGregorianDate.compareTo(b.baseGregorianDate));
    } else {
      // Show only events for the selected day
      events = cubit.eventsForDate(state.selectedGregorianDate);
    }

    if (events.isEmpty) {
      if (state.eventSearchQuery.isNotEmpty) {
        return Center(child: Text(context.t.calendar.noMatchingEvents));
      } else if (state.showAllEvents) {
        return Center(child: Text(context.t.calendar.noEventsInSystem));
      } else {
        return Center(child: Text(context.t.calendar.noEventsToday));
      }
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
                    const SizedBox(height: 4),
                    if (event.description.isNotEmpty) ...[
                      Text(
                        _truncateDescription(event.description),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      _formatEventDate(event.baseGregorianDate),
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (event.recurring) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            FluentIcons.arrow_repeat_all_24_regular,
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
                    icon: const Icon(FluentIcons.edit_24_regular, size: 20),
                    tooltip: 'ערוך אירוע',
                    onPressed: () => _showCreateEventDialog(context, state,
                        existingEvent: event),
                  ),
                  IconButton(
                    icon: const Icon(FluentIcons.delete_24_regular, size: 20),
                    tooltip: 'מחק אירוע',
                    onPressed: () async {
                      final confirmed = await showConfirmationDialog(
                        context: context,
                        title: 'אישור מחיקה',
                        content:
                            'האם אתה בטוח שברצונך למחוק את האירוע "${event.title}"?',
                        confirmText: 'מחק',
                        isDangerous: true,
                      );

                      if (confirmed == true && context.mounted) {
                        context.read<CalendarCubit>().deleteEvent(event.id);
                      }
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

// ווידג'ט עם טאבים לזמני היום ואירועים
class _TimesAndEventsTabView extends StatefulWidget {
  final CalendarState state;
  final Widget Function(BuildContext, CalendarState) buildTimesGrid;
  final Widget Function(BuildContext, CalendarState) buildDafYomiButtons;
  final Widget Function(BuildContext, CalendarState) buildCityDropdown;
  final Widget Function(BuildContext, CalendarState, bool) buildEventsList;
  final void Function(BuildContext, CalendarState) showCreateEventDialog;

  const _TimesAndEventsTabView({
    required this.state,
    required this.buildTimesGrid,
    required this.buildDafYomiButtons,
    required this.buildCityDropdown,
    required this.buildEventsList,
    required this.showCreateEventDialog,
  });

  @override
  State<_TimesAndEventsTabView> createState() => _TimesAndEventsTabViewState();
}

class _TimesAndEventsTabViewState extends State<_TimesAndEventsTabView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // שורת הטאבים - גובה מופחת
          Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  icon: const Icon(FluentIcons.calendar_clock_24_regular, size: 18),
                  iconMargin: const EdgeInsets.only(bottom: 2),
                  height: 48,
                  child: Text(context.t.calendar.timesOfDay, style: const TextStyle(fontSize: 12)),
                ),
                Tab(
                  icon: const Icon(FluentIcons.calendar_ltr_24_regular, size: 18),
                  iconMargin: const EdgeInsets.only(bottom: 2),
                  height: 48,
                  child: Text(context.t.calendar.events, style: const TextStyle(fontSize: 12)),
                ),
              ],
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
              indicatorColor: Theme.of(context).colorScheme.primary,
              dividerColor: Colors.transparent,
            ),
          ),
          // תוכן הטאבים - ממלא את כל השטח הנותר
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // טאב זמני היום
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Spacer(),
                          widget.buildCityDropdown(context, widget.state),
                        ],
                      ),
                      const SizedBox(height: 16),
                      widget.buildTimesGrid(context, widget.state),
                      const SizedBox(height: 16),
                      widget.buildDafYomiButtons(context, widget.state),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withAlpha(76),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Theme.of(context).primaryColor, width: 1),
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
                // טאב אירועים
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // כפתור "צור אירוע" בצד ימין
                          ElevatedButton.icon(
                            onPressed: () => widget.showCreateEventDialog(
                                context, widget.state),
                            icon: const Icon(FluentIcons.add_24_regular,
                                size: 16),
                            label: Text(context.t.calendar.createEvent),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const Spacer(),
                          // כפתור "הצג הכל" בצד שמאל
                          ElevatedButton.icon(
                            onPressed: () => context
                                .read<CalendarCubit>()
                                .toggleShowAllEvents(
                                    !widget.state.showAllEvents),
                            icon: Icon(
                              widget.state.showAllEvents
                                  ? FluentIcons.calendar_month_24_regular
                                  : FluentIcons.calendar_day_24_regular,
                              size: 16,
                            ),
                            label: Text(widget.state.showAllEvents
                                ? 'הצג יום נוכחי'
                                : 'הצג הכל'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: (query) => context
                            .read<CalendarCubit>()
                            .setEventSearchQuery(query),
                        decoration: InputDecoration(
                          hintText: 'חפש אירועים...',
                          prefixIcon: const Icon(FluentIcons.search_24_regular),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.state.eventSearchQuery.isNotEmpty)
                                IconButton(
                                  icon: const Icon(
                                      FluentIcons.dismiss_24_regular),
                                  tooltip: 'נקה חיפוש',
                                  onPressed: () {
                                    context
                                        .read<CalendarCubit>()
                                        .setEventSearchQuery('');
                                  },
                                ),
                              IconButton(
                                icon: Icon(widget.state.searchInDescriptions
                                    ? FluentIcons.document_text_24_regular
                                    : FluentIcons.text_t_24_regular),
                                tooltip: widget.state.searchInDescriptions
                                    ? 'חפש רק בכותרת'
                                    : 'חפש גם בתיאור',
                                onPressed: () => context
                                    .read<CalendarCubit>()
                                    .toggleSearchInDescriptions(
                                        !widget.state.searchInDescriptions),
                              ),
                            ],
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      widget.buildEventsList(context, widget.state,
                          widget.state.eventSearchQuery.isNotEmpty),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// מציג תוספות קטנות בכל יום: מועדים ואירועים מותאמים
class _DayExtras extends StatelessWidget {
  final DateTime date;
  final bool inIsrael;

  const _DayExtras({
    required this.date,
    required this.inIsrael,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CalendarCubit>();
    final events = cubit.eventsForDate(date);
    final List<Widget> lines = [];

    final jewishCalendar = JewishCalendar.fromDateTime(date)
      ..inIsrael = inIsrael;

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

  static String _numberToHebrewLetter(int n) {
    const letters = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ז', 'ח'];
    if (n > 0 && n <= letters.length) {
      return letters[n - 1];
    }
    return '';
  }

  static List<String> _calcJewishEvents(JewishCalendar jc) {
    final List<String> l = [];

    // 1. שימוש ב-Formatter הייעודי של החבילה כדי לקבל את כל שמות המועדים
    final hdf = HebrewDateFormatter();
    hdf.hebrewFormat = true; // כדי לקבל שמות בעברית

    // הפונקציה formatYomTov מחזירה את שם החג, המועד, התענית או היום המיוחד
    final yomTov = hdf.formatYomTov(jc);
    if (yomTov.isNotEmpty) {
      // הפונקציה יכולה להחזיר מספר אירועים מופרדים בפסיק, למשל "ערב שבת, ערב ראש חודש"
      // לכן אנחנו מפצלים אותם ומוסיפים כל אחד בנפרד
      l.addAll(yomTov.split(',').map((e) => e.trim()));
    }

    // הוספת פרשת השבוע לשבתות
    if (jc.getDayOfWeek() == 7) {
      // שבת
      final parsha = hdf.formatParsha(jc);
      if (parsha.isNotEmpty) {
        l.add(parsha);
      }
    }

    // 2. ה-Formatter לא תמיד מתייחס לר"ח כאל "יום טוב", אז נוסיף אותו ידנית אם צריך
    if (jc.isRoshChodesh() && !l.contains('ראש חודש')) {
      l.add('ר"ח');
    }

    // 3. שיפורים והתאמות אישיות שלנו על המידע מהחבילה
    final yomTovIndex = jc.getYomTovIndex();

    // פירוט ימי חול המועד (דורס את הטקסט הכללי "חול המועד")
    if (yomTovIndex == JewishCalendar.CHOL_HAMOED_SUCCOS ||
        yomTovIndex == JewishCalendar.CHOL_HAMOED_PESACH) {
      l.removeWhere((e) => e.contains('חול המועד')); // הסרת הטקסט הכללי
      final dayOfCholHamoed = jc.getJewishDayOfMonth() - 15;
      l.add('${_numberToHebrewLetter(dayOfCholHamoed)} דחוה"מ');
    }

    // פירוט ימי חנוכה (דורס את הטקסט הכללי "חנוכה")
    if (yomTovIndex == JewishCalendar.CHANUKAH) {
      // החלפנו את l.remove ל-l.removeWhere כדי לתפוס כל טקסט עם המילה "חנוכה"
      l.removeWhere((e) => e.contains('חנוכה'));

      // והוספנו את הטקסט המדויק שלנו
      final dayOfChanukah = jc.getDayOfChanukah();
      if (dayOfChanukah != -1) {
        l.add('נר ${_numberToHebrewLetter(dayOfChanukah)} דחנוכה');
      }
    }

    // הוספת פירוט להושענא רבה
    if (yomTovIndex == JewishCalendar.HOSHANA_RABBA) {
      l.add("ו' דחוה\"מ");
    }

    // וידוא שהלוגיקה של שמיני עצרת ושמחת תורה נשמרת
    if (jc.getJewishMonth() == 7) {
      if (jc.getJewishDayOfMonth() == 22) {
        // כ"ב בתשרי
        if (!l.contains('שמיני עצרת')) l.add('שמיני עצרת');
        if (jc.inIsrael && !l.contains('שמחת תורה')) {
          l.add('שמחת תורה');
        }
      }
      if (jc.getJewishDayOfMonth() == 23 && !jc.inIsrael) {
        if (!l.contains('שמחת תורה')) l.add('שמחת תורה');
      }
    }

    // מסיר כפילויות אפשריות (למשל אם הוספנו משהו שכבר היה קיים)
    return l.toSet().toList();
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
  bool _showButton = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _showButton = true),
      onExit: (_) => setState(() => _showButton = false),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Listener(
            onPointerDown: (_) => setState(() => _showButton = true),
            child: widget.child,
          ),
          // כפתור הוספה שמופיע בריחוף או בלחיצה
          AnimatedOpacity(
            opacity: _showButton ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: IgnorePointer(
                ignoring: !_showButton, // מונע מהכפתור לחסום קליקים כשהוא שקוף
                child: Tooltip(
                  message: 'צור אירוע',
                  verticalOffset: -40.0,
                  child: IconButton.filled(
                    icon: const Icon(FluentIcons.add_24_regular, size: 16),
                    onPressed: widget.onAdd,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(24, 24),
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
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
