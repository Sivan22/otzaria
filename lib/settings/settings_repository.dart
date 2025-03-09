import 'package:flutter/material.dart';
import 'package:otzaria/utils/color_utils.dart';
import 'package:otzaria/utils/settings_wrapper.dart';

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

  final SettingsWrapper _settings;

  SettingsRepository({SettingsWrapper? settings})
      : _settings = settings ?? SettingsWrapper();

  Future<Map<String, dynamic>> loadSettings() async {
    return {
      'isDarkMode': _settings.getValue<bool>(keyDarkMode, defaultValue: false),
      'seedColor': ColorUtils.colorFromString(
        _settings.getValue<String>(keySwatchColor, defaultValue: '#ff2c1b02'),
      ),
      'paddingSize':
          _settings.getValue<double>(keyPaddingSize, defaultValue: 10),
      'fontSize': _settings.getValue<double>(keyFontSize, defaultValue: 16),
      'fontFamily': _settings.getValue<String>(
        keyFontFamily,
        defaultValue: 'FrankRuhlCLM',
      ),
      'showOtzarHachochma': _settings.getValue<bool>(
        keyShowOtzarHachochma,
        defaultValue: false,
      ),
      'showHebrewBooks': _settings.getValue<bool>(
        keyShowHebrewBooks,
        defaultValue: false,
      ),
      'showExternalBooks': _settings.getValue<bool>(
        keyShowExternalBooks,
        defaultValue: false,
      ),
      'showTeamim': _settings.getValue<bool>(
        keyShowTeamim,
        defaultValue: true,
      ),
      'useFastSearch': _settings.getValue<bool>(
        keyUseFastSearch,
        defaultValue: true,
      ),
      'replaceHolyNames': _settings.getValue<bool>(
        keyReplaceHolyNames,
        defaultValue: true,
      ),
      'autoUpdateIndex': _settings.getValue<bool>(
        keyAutoUpdateIndex,
        defaultValue: true,
      ),
    };
  }

  Future<void> updateDarkMode(bool value) async {
    await _settings.setValue(keyDarkMode, value);
  }

  Future<void> updateSeedColor(Color value) async {
    await _settings.setValue(keySwatchColor, ColorUtils.colorToString(value));
  }

  Future<void> updatePaddingSize(double value) async {
    await _settings.setValue(keyPaddingSize, value);
  }

  Future<void> updateFontSize(double value) async {
    await _settings.setValue(keyFontSize, value);
  }

  Future<void> updateFontFamily(String value) async {
    await _settings.setValue(keyFontFamily, value);
  }

  Future<void> updateShowOtzarHachochma(bool value) async {
    await _settings.setValue(keyShowOtzarHachochma, value);
  }

  Future<void> updateShowHebrewBooks(bool value) async {
    await _settings.setValue(keyShowHebrewBooks, value);
  }

  Future<void> updateShowExternalBooks(bool value) async {
    await _settings.setValue(keyShowExternalBooks, value);
  }

  Future<void> updateShowTeamim(bool value) async {
    await _settings.setValue(keyShowTeamim, value);
  }

  Future<void> updateUseFastSearch(bool value) async {
    await _settings.setValue(keyUseFastSearch, value);
  }

  Future<void> updateReplaceHolyNames(bool value) async {
    await _settings.setValue(keyReplaceHolyNames, value);
  }

  Future<void> updateAutoUpdateIndex(bool value) async {
    await _settings.setValue(keyAutoUpdateIndex, value);
  }
}
