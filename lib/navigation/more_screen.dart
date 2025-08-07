import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/tools/measurement_converter/measurement_converter_screen.dart';
import 'package:otzaria/settings/settings_repository.dart';
import 'calendar_widget.dart';
import 'calendar_cubit.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({Key? key}) : super(key: key);

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  int _selectedIndex = 0;
  late final CalendarCubit _calendarCubit;
  late final SettingsRepository _settingsRepository;

  @override
  void initState() {
    super.initState();
    _settingsRepository = SettingsRepository();
    _calendarCubit = CalendarCubit(settingsRepository: _settingsRepository);
  }

  @override
  void dispose() {
    _calendarCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(_selectedIndex)),
        centerTitle: true,
        actions: _getActions(context, _selectedIndex),
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.calendar_today),
                label: Text('לוח שנה'),
              ),
              NavigationRailDestination(
                icon: ImageIcon(AssetImage('assets/icon/שמור וזכור.png')),
                label: Text('זכור ושמור'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.straighten),
                label: Text('ממיר מידות'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calculate),
                label: Text('גימטריות'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _buildCurrentWidget(_selectedIndex),
          ),
        ],
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'לוח שנה';
      case 1:
        return 'זכור ושמור';
      case 2:
        return 'ממיר מידות';
      case 3:
        return 'גימטריות';
      default:
        return 'עוד';
    }
  }

  List<Widget>? _getActions(BuildContext context, int index) {
    if (index == 0) {
      return [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => _showSettingsDialog(context),
        ),
      ];
    }
    return null;
  }

  Widget _buildCurrentWidget(int index) {
    switch (index) {
      case 0:
        return BlocProvider.value(
          value: _calendarCubit,
          child: const CalendarWidget(),
        );
      case 1:
        return const Center(child: Text('בקרוב...'));
      case 2:
        return const MeasurementConverterScreen();
      case 3:
        return const Center(child: Text('בקרוב...'));
      default:
        return Container();
    }
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocBuilder<CalendarCubit, CalendarState>(
          bloc: _calendarCubit,
          builder: (context, state) {
            return AlertDialog(
              title: const Text('הגדרות לוח שנה'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<CalendarType>(
                    title: const Text('לוח עברי'),
                    value: CalendarType.hebrew,
                    groupValue: state.calendarType,
                    onChanged: (value) {
                      if (value != null) {
                        _calendarCubit.changeCalendarType(value);
                      }
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                  RadioListTile<CalendarType>(
                    title: const Text('לוח לועזי'),
                    value: CalendarType.gregorian,
                    groupValue: state.calendarType,
                    onChanged: (value) {
                      if (value != null) {
                        _calendarCubit.changeCalendarType(value);
                      }
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                  RadioListTile<CalendarType>(
                    title: const Text('לוח משולב'),
                    value: CalendarType.combined,
                    groupValue: state.calendarType,
                    onChanged: (value) {
                      if (value != null) {
                        _calendarCubit.changeCalendarType(value);
                      }
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('סגור'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
