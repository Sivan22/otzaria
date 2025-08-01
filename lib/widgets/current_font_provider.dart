import 'package:flutter/material.dart';

class CurrentFontProvider extends InheritedWidget {
  final String? currentFont;

  const CurrentFontProvider({
    Key? key,
    required this.currentFont,
    required Widget child,
  }) : super(key: key, child: child);

  static CurrentFontProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CurrentFontProvider>();
  }

  @override
  bool updateShouldNotify(CurrentFontProvider oldWidget) {
    return currentFont != oldWidget.currentFont;
  }
}