import 'package:flutter/material.dart';

class ColorUtils {
  static Color colorFromString(String? colorString) {
    if (colorString == null) {
      return const Color(0xff2c1b02); // Default color
    }
    if (colorString.startsWith('#')) {
      colorString = colorString.substring(1);
    }
    if (colorString.length == 6) {
      colorString = 'ff$colorString';
    }
    return Color(int.parse(colorString, radix: 16));
  }

  static String colorToString(Color color) {
    return color.value.toRadixString(16);
  }
}
