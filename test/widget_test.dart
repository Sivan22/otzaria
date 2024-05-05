import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:otzaria/main.dart';
import 'package:otzaria/screens/main_window_screen.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OtzariaApp());

    await tester.pumpWidget(const MainWindowScreen());

    //verify that the navigation sidebar is visible
    expect(find.byType(NavigationRail), findsOneWidget);
  });
}
