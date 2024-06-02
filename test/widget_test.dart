import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otzaria/screens/main_window_screen.dart';

void main() {
  testWidgets('showing app test', (WidgetTester tester) async {
    await Settings.init();
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MainWindowScreen());

    //verify that the navigation sidebar is visible
    expect(find.byType(NavigationRail), findsOneWidget);
  });
}
