import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final Map<String, LogicalKeySet> shortcuts = {
  'ctrl+a': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA),
  'ctrl+b': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB),
  'ctrl+c': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC),
  'ctrl+d': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyD),
  'ctrl+e': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyE),
  'ctrl+f': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF),
  'ctrl+g': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyG),
  'ctrl+h': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyH),
  'ctrl+i': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI),
  'ctrl+j': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyJ),
  'ctrl+k': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK),
  'ctrl+l': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyL),
  'ctrl+m': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyM),
  'ctrl+n': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN),
  'ctrl+o': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyO),
  'ctrl+p': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyP),
  'ctrl+q': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyQ),
  'ctrl+r': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR),
  'ctrl+s': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS),
  'ctrl+t': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyT),
  'ctrl+u': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyU),
  'ctrl+v': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV),
  'ctrl+w': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyW),
  'ctrl+x': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyX),
  'ctrl+y': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY),
  'ctrl+z': LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ),
  'ctrl+0':
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit0),
  'ctrl+1':
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit1),
  'ctrl+2':
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit2),
  'ctrl+3':
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit3),
  'ctrl+4':
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit4),
  'ctrl+5':
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit5),
  'ctrl+6':
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit6),
  'ctrl+7':
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit7),
  'ctrl+8':
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit8),
  'ctrl+9':
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit9),
};