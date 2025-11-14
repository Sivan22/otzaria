import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/navigation/calendar_cubit.dart';
import 'package:otzaria/settings/settings_repository.dart';
import 'package:otzaria/i18n/translations.g.dart';

/// פונקציה גלובלית להצגת דיאלוג הגדרות לוח שנה
/// ניתן לקרוא לה מכל מקום באפליקציה
void showCalendarSettingsDialog(BuildContext context,
    {CalendarCubit? calendarCubit}) {
  // אם נמסר Cubit במפורש נשתמש בו, אחרת ננסה לקרוא מה-context
  CalendarCubit? existingCubit = calendarCubit;
  bool shouldCloseAfter = false;

  if (existingCubit == null) {
    try {
      existingCubit = context.read<CalendarCubit>();
    } catch (e) {
      // אם אין CalendarCubit זמין, ניצור חדש
      final settingsRepository = SettingsRepository();
      existingCubit = CalendarCubit(settingsRepository: settingsRepository);
      shouldCloseAfter = true;
    }
  }

  final cubit = existingCubit;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return BlocProvider.value(
        value: cubit,
        child: _CalendarSettingsDialog(calendarCubit: cubit),
      );
    },
  ).then((_) {
    if (shouldCloseAfter) {
      cubit.close();
    }
  });
}

/// דיאלוג הגדרות לוח שנה עם אפשרות להרחבה לבחירת עיר
class _CalendarSettingsDialog extends StatefulWidget {
  final CalendarCubit calendarCubit;

  const _CalendarSettingsDialog({required this.calendarCubit});

  @override
  State<_CalendarSettingsDialog> createState() =>
      _CalendarSettingsDialogState();
}

class _CalendarSettingsDialogState extends State<_CalendarSettingsDialog> {
  bool _showCitySearch = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      bloc: widget.calendarCubit,
      builder: (context, state) {
        return AlertDialog(
          title: Text(context.t.calendar.title), // Old: 'הגדרות לוח שנה'
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t.calendar.calendarType, // Old: 'סוג לוח:'
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  RadioGroup<CalendarType>(
                    groupValue: state.calendarType,
                    onChanged: (value) {
                      if (value != null) {
                        widget.calendarCubit.changeCalendarType(value);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<CalendarType>(
                          title: Text(context.t.calendar.hebrew),
                          value: CalendarType.hebrew,
                        ),
                        RadioListTile<CalendarType>(
                          title: Text(context.t.calendar.gregorian),
                          value: CalendarType.gregorian,
                        ),
                        RadioListTile<CalendarType>(
                          title: Text(context.t.calendar.combined),
                          value: CalendarType.combined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.t.calendar.city, // Old: 'עיר:'
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showCitySearch = !_showCitySearch;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(state.selectedCity),
                            const SizedBox(width: 8),
                            Icon(
                              _showCitySearch
                                  ? FluentIcons.chevron_up_24_regular
                                  : FluentIcons.chevron_down_24_regular,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // הרחבה לחיפוש עיר
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _showCitySearch
                        ? Column(
                            children: [
                              const SizedBox(height: 16),
                              _CitySearchWidget(
                                currentCity: state.selectedCity,
                                onCitySelected: (city) {
                                  widget.calendarCubit.changeCity(city);
                                  setState(() {
                                    _showCitySearch = false;
                                  });
                                },
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.t.common.close), // Old: 'סגור'
            ),
          ],
        );
      },
    );
  }
}

/// Widget לחיפוש ובחירת עיר (מוטמע בתוך הדיאלוג)
class _CitySearchWidget extends StatefulWidget {
  final String currentCity;
  final ValueChanged<String> onCitySelected;

  const _CitySearchWidget({
    required this.currentCity,
    required this.onCitySelected,
  });

  @override
  State<_CitySearchWidget> createState() => _CitySearchWidgetState();
}

class _CitySearchWidgetState extends State<_CitySearchWidget> {
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
            dense: true,
          ),
        );
      });
      items.add(const Divider());
    });
    if (items.isNotEmpty) {
      items.removeLast(); // Remove last divider
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText:
                    context.t.calendar.searchCity, // Old: 'הקלד שם עיר...'
                prefixIcon: const Icon(FluentIcons.search_24_regular),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 300,
            child: _filteredCities.isEmpty
                ? Center(
                    child: Text(context
                        .t.calendar.noCitiesFound)) // Old: 'לא נמצאו ערים'
                : ListView(children: items),
          ),
        ],
      ),
    );
  }
}
