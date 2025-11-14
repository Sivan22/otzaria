import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/tools/measurement_converter/measurement_converter_screen.dart';
import 'package:otzaria/tools/gematria/gematria_search_screen.dart';
import 'package:otzaria/settings/calendar_settings_dialog.dart';
import 'package:otzaria/settings/gematria_settings_dialog.dart';
import 'package:shamor_zachor/shamor_zachor.dart';
import 'calendar_widget.dart';
import 'calendar_cubit.dart';
import 'package:otzaria/personal_notes/view/personal_notes_screen.dart';
import 'package:otzaria/settings/settings_repository.dart';
import 'package:otzaria/i18n/translations.g.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late final CalendarCubit _calendarCubit;
  late final SettingsRepository _settingsRepository;
  final GlobalKey<GematriaSearchScreenState> _gematriaKey =
      GlobalKey<GematriaSearchScreenState>();
  late final PageController _pageController;

  // Title for the ShamorZachor section (dynamic from the package)
  late String _shamorZachorTitle;

  /// Update the ShamorZachor title
  void _updateShamorZachorTitle(String title) {
    setState(() {
      _shamorZachorTitle = title;
    });
  }

  @override
  void initState() {
    super.initState();
    _settingsRepository = SettingsRepository();
    _calendarCubit = CalendarCubit(settingsRepository: _settingsRepository);
    _pageController = PageController(initialPage: 0);
    _shamorZachorTitle = ''; // Will be set by _updateShamorZachorTitle callback
  }

  /// Reset to calendar page - public method for external access
  void resetToCalendar() {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }



  @override
  void dispose() {
    _calendarCubit.close();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize title if not set
    if (_shamorZachorTitle.isEmpty) {
      _shamorZachorTitle = context.t.more.shamorZachor;
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 700;

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        title: Text(
          _getTitle(context, _selectedIndex),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: _getActions(context, _selectedIndex),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (isSmallScreen) {
            // במסכים קטנים - השתמש ב-BottomNavigationBar
            return Column(
              children: [
                Expanded(
                  child: PageView(
                    scrollDirection: orientation == Orientation.landscape
                        ? Axis.vertical
                        : Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    children: [
                      BlocProvider.value(
                        value: _calendarCubit,
                        child: const CalendarWidget(),
                      ),
                      ShamorZachorWidget(
                        onTitleChanged: _updateShamorZachorTitle,
                      ),
                      const MeasurementConverterScreen(),
                      const PersonalNotesManagerScreen(),
                      GematriaSearchScreen(key: _gematriaKey),
                    ],
                  ),
                ),
              ],
            );
          }
          // במסכים רחבים - השתמש ב-NavigationRail
          return Row(
            children: [
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (int index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                  if (_pageController.hasClients) {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                labelType: NavigationRailLabelType.all,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    label: Text(context.t.more.calendar),
                  ),
                  NavigationRailDestination(
                    icon: ImageIcon(AssetImage('assets/icon/זכור ושמור.png')),
                    label: Text(context.t.more.shamorZachor),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.straighten),
                    label: Text(context.t.more.measurements),
                  ),
                  NavigationRailDestination(
                    icon: Icon(FluentIcons.note_24_regular),
                    label: Text(context.t.more.personalNotes),
                  ),
                  NavigationRailDestination(
                    icon: Icon(FluentIcons.calculator_24_regular),
                    label: Text(context.t.more.gematria),
                  ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: PageView(
                  scrollDirection: orientation == Orientation.landscape
                      ? Axis.vertical
                      : Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  children: [
                    BlocProvider.value(
                      value: _calendarCubit,
                      child: const CalendarWidget(),
                    ),
                    ShamorZachorWidget(
                      onTitleChanged: _updateShamorZachorTitle,
                    ),
                    const MeasurementConverterScreen(),
                    const PersonalNotesManagerScreen(),
                    GematriaSearchScreen(key: _gematriaKey),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: isSmallScreen
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
                if (_pageController.hasClients) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 11,
              unselectedFontSize: 10,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month_outlined, size: 20),
                  label: context.t.more.calendar,
                ),
                BottomNavigationBarItem(
                  icon: ImageIcon(AssetImage('assets/icon/זכור ושמור.png'), size: 20),
                  label: context.t.more.shamorZachor,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.straighten, size: 20),
                  label: context.t.more.measurementsShort,
                ),
                BottomNavigationBarItem(
                  icon: Icon(FluentIcons.note_24_regular, size: 20),
                  label: context.t.more.personalNotesShort,
                ),
                BottomNavigationBarItem(
                  icon: Icon(FluentIcons.calculator_24_regular, size: 20),
                  label: context.t.more.gematria,
                ),
              ],
            )
          : null,
    );
  }

  String _getTitle(BuildContext context, int index) {
    switch (index) {
      case 0:
        return context.t.more.calendar;
      case 1:
        return _shamorZachorTitle;
      case 2:
        return context.t.more.measurements;
      case 3:
        return context.t.more.personalNotes;
      case 4:
        return context.t.more.gematria;
      default:
        return context.t.navigation.tools;
    }
  }

  List<Widget>? _getActions(BuildContext context, int index) {
    Widget buildSettingsButton(VoidCallback onPressed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: IconButton(
          icon: const Icon(FluentIcons.settings_24_regular),
          tooltip: context.t.navigation.settings,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    switch (index) {
      case 0:
        return [
          buildSettingsButton(() => showCalendarSettingsDialog(
                context,
                calendarCubit: context.read<CalendarCubit>(),
              ))
        ];
      case 4:
        return [buildSettingsButton(() => showGematriaSettingsDialog(context))];
      default:
        return null;
    }
  }


}
