import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'calendar_widget.dart';
import 'calendar_cubit.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({Key? key}) : super(key: key);

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  Widget? currentWidget;

  @override
  Widget build(BuildContext context) {
    // אם currentWidget אינו null, הצג אותו. אחרת, הצג את התפריט.
    if (currentWidget != null) {
      return currentWidget!;
    }

    // זהו מסך התפריט הראשי
    return Scaffold(
      appBar: AppBar(
        title: const Text('עוד'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildToolItem(
              context,
              icon: Icons.calendar_today,
              title: 'לוח שנה',
              subtitle: 'לוח שנה עברי ולועזי',
              onTap: () => _showCalendar(),
            ),
            const SizedBox(height: 16),
            _buildToolItem(
              context,
              icon: Icons.straighten,
              title: 'ממיר מידות',
              subtitle: 'המרת מידות ומשקולות',
              onTap: () => _showComingSoon(context, 'ממיר מידות ומשקולות'),
            ),
            const SizedBox(height: 16),
            _buildToolItem(
              context,
              icon: Icons.calculate,
              title: 'גימטריות',
              subtitle: 'חישובי גימטריה',
              onTap: () => _showComingSoon(context, 'גימטריות'),
            ),
          ],
        ),
      ),
    );
  }

  // פונקציה זו בונה את מסך לוח השנה
  void _showCalendar() {
    setState(() {
      currentWidget = BlocProvider(
        create: (context) => CalendarCubit(),
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  currentWidget = null; // חזור למסך התפריט
                });
              },
            ),
            title: BlocBuilder<CalendarCubit, CalendarState>(
              builder: (context, state) {
                switch (state.calendarType) {
                  case CalendarType.hebrew:
                    return const Text('לוח שנה עברי');
                  case CalendarType.gregorian:
                    return const Text('לוח שנה לועזי');
                  case CalendarType.combined:
                    return const Text('לוח שנה משולב');
                }
              },
            ),
            centerTitle: true,
            actions: [
              Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => _showSettingsDialog(context),
                  );
                }
              ),
            ],
          ),
          body: const CalendarWidget(),
        ),
      );
    });
  }

  // פונקציה זו מציגה את דיאלוג ההגדרות
  void _showSettingsDialog(BuildContext context) {
    final calendarCubit = context.read<CalendarCubit>();
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocBuilder<CalendarCubit, CalendarState>(
          bloc: calendarCubit,
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
                        calendarCubit.changeCalendarType(value);
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
                        calendarCubit.changeCalendarType(value);
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
                        calendarCubit.changeCalendarType(value);
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

  // שאר הפונקציות נשארות כפי שהיו
  Widget _buildToolItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 110,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(feature),
        content: const Text('בקרוב...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('אישור'),
          ),
        ],
      ),
    );
  }
}
