import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/utils/color_utils.dart';

class SettingsRepository {
  static const String keyDarkMode = 'key-dark-mode';
  static const String keySwatchColor = 'key-swatch-color';
  static const String keyPaddingSize = 'key-padding-size';
  static const String keyFontSize = 'key-font-size';
  static const String keyFontFamily = 'key-font-family';
  static const String keyShowOtzarHachochma = 'key-show-otzar-hachochma';
  static const String keyShowHebrewBooks = 'key-show-hebrew-books';
  static const String keyShowExternalBooks = 'key-show-external-books';
  static const String keyShowTeamim = 'key-show-teamim';
  static const String keyUseFastSearch = 'key-use-fast-search';
  static const String keyReplaceHolyNames = 'key-replace-holy-names';
  static const String keyAutoUpdateIndex = 'key-auto-index-update';

  Future<Map<String, dynamic>> loadSettings() async {
    return {
      'isDarkMode': Settings.getValue<bool>(keyDarkMode, defaultValue: false),
      'seedColor': ColorUtils.colorFromString(
        Settings.getValue<String>(keySwatchColor, defaultValue: '#ff2c1b02'),
      ),
      'paddingSize':
          Settings.getValue<double>(keyPaddingSize, defaultValue: 10),
      'fontSize': Settings.getValue<double>(keyFontSize, defaultValue: 16),
      'fontFamily': Settings.getValue<String>(
        keyFontFamily,
        defaultValue: 'FrankRuhlCLM',
      ),
      'showOtzarHachochma': Settings.getValue<bool>(
        keyShowOtzarHachochma,
        defaultValue: false,
      ),
      'showHebrewBooks': Settings.getValue<bool>(
        keyShowHebrewBooks,
        defaultValue: false,
      ),
      'showExternalBooks': Settings.getValue<bool>(
        keyShowExternalBooks,
        defaultValue: false,
      ),
      'showTeamim': Settings.getValue<bool>(
        keyShowTeamim,
        defaultValue: true,
      ),
      'useFastSearch': Settings.getValue<bool>(
        keyUseFastSearch,
        defaultValue: true,
      ),
      'replaceHolyNames': Settings.getValue<bool>(
        keyReplaceHolyNames,
        defaultValue: true,
      ),
      'autoUpdateIndex': Settings.getValue<bool>(
        keyAutoUpdateIndex,
        defaultValue: true,
      ),
    };
  }

  Future<void> updateDarkMode(bool value) async {
    await Settings.setValue(keyDarkMode, value);
  }

  Future<void> updateSeedColor(Color value) async {
    await Settings.setValue(keySwatchColor, ColorUtils.colorToString(value));
  }

  Future<void> updatePaddingSize(double value) async {
    await Settings.setValue(keyPaddingSize, value);
  }

  Future<void> updateFontSize(double value) async {
    await Settings.setValue(keyFontSize, value);
  }

  Future<void> updateFontFamily(String value) async {
    await Settings.setValue(keyFontFamily, value);
  }

  Future<void> updateShowOtzarHachochma(bool value) async {
    await Settings.setValue(keyShowOtzarHachochma, value);
  }

  Future<void> updateShowHebrewBooks(bool value) async {
    await Settings.setValue(keyShowHebrewBooks, value);
  }

  Future<void> updateShowExternalBooks(bool value) async {
    await Settings.setValue(keyShowExternalBooks, value);
  }

  Future<void> updateShowTeamim(bool value) async {
    await Settings.setValue(keyShowTeamim, value);
  }

  Future<void> updateUseFastSearch(bool value) async {
    await Settings.setValue(keyUseFastSearch, value);
  }

  Future<void> updateReplaceHolyNames(bool value) async {
    await Settings.setValue(keyReplaceHolyNames, value);
  }

  Future<void> updateAutoUpdateIndex(bool value) async {
    await Settings.setValue(keyAutoUpdateIndex, value);
  }
}
