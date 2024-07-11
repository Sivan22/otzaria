import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otzaria/screens/main_window_screen.dart';

void main() {
  testWidgets('finds main window', (WidgetTester tester) async {
    await Settings.init();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: MainWindowScreen()));

    // Verify that main window is shown
    expect(find.byType(MainWindowScreen), findsOneWidget);

    
    //if the oriention is landscape Verify that the navigation bar is shown
    expect(find.byType(Scaffold), findsOneWidget);
    
  });
}
