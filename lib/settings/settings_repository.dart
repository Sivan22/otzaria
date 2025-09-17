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
  static const String keyDefaultNikud = 'key-default-nikud';
  static const String keyRemoveNikudFromTanach = 'key-remove-nikud-tanach';
  static const String keyDefaultSidebarOpen = 'key-default-sidebar-open';
  static const String keyPinSidebar = 'key-pin-sidebar';
  static const String keySidebarWidth = 'key-sidebar-width';
  static const String keyFacetFilteringWidth = 'key-facet-filtering-width';
  static const String keyCalendarType = 'key-calendar-type';
  static const String keySelectedCity = 'key-selected-city';
  static const String keyCalendarEvents = 'key-calendar-events';
  static const String keyCopyWithHeaders = 'key-copy-with-headers';
  static const String keyCopyHeaderFormat = 'key-copy-header-format';

  final SettingsWrapper _settings;

  SettingsRepository({SettingsWrapper? settings})
      : _settings = settings ?? SettingsWrapper();

  Future<Map<String, dynamic>> loadSettings() async {
    // Initialize default settings to disk if needed
    await _initializeDefaultsIfNeeded();

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
      'defaultRemoveNikud': _settings.getValue<bool>(
        keyDefaultNikud,
        defaultValue: false,
      ),
      'removeNikudFromTanach': _settings.getValue<bool>(
        keyRemoveNikudFromTanach,
        defaultValue: false,
      ),
      'defaultSidebarOpen': _settings.getValue<bool>(
        keyDefaultSidebarOpen,
        defaultValue: false,
      ),
      'pinSidebar': _settings.getValue<bool>(
        keyPinSidebar,
        defaultValue: false,
      ),
      'sidebarWidth':
          _settings.getValue<double>(keySidebarWidth, defaultValue: 300),
      'facetFilteringWidth':
          _settings.getValue<double>(keyFacetFilteringWidth, defaultValue: 235),
      'calendarType': _settings.getValue<String>(
        keyCalendarType,
        defaultValue: 'combined',
      ),
      'selectedCity': _settings.getValue<String>(
        keySelectedCity,
        defaultValue: 'ירושלים',
      ),
      'calendarEvents': _settings.getValue<String>(
        keyCalendarEvents,
        defaultValue: '[]',
      ),
      'copyWithHeaders': _settings.getValue<String>(
        keyCopyWithHeaders,
        defaultValue: 'none',
      ),
      'copyHeaderFormat': _settings.getValue<String>(
        keyCopyHeaderFormat,
        defaultValue: 'same_line_after_brackets',
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

  Future<void> updateDefaultRemoveNikud(bool value) async {
    await _settings.setValue(keyDefaultNikud, value);
  }

  Future<void> updateRemoveNikudFromTanach(bool value) async {
    await _settings.setValue(keyRemoveNikudFromTanach, value);
  }

  Future<void> updateDefaultSidebarOpen(bool value) async {
    await _settings.setValue(keyDefaultSidebarOpen, value);
  }

  Future<void> updatePinSidebar(bool value) async {
    await _settings.setValue(keyPinSidebar, value);
  }

  Future<void> updateSidebarWidth(double value) async {
    await _settings.setValue(keySidebarWidth, value);
  }

  Future<void> updateFacetFilteringWidth(double value) async {
    await _settings.setValue(keyFacetFilteringWidth, value);
  }

  Future<void> updateCalendarType(String value) async {
    await _settings.setValue(keyCalendarType, value);
  }

  Future<void> updateSelectedCity(String value) async {
    await _settings.setValue(keySelectedCity, value);
  }

  Future<void> updateCalendarEvents(String eventsJson) async {
    await _settings.setValue(keyCalendarEvents, eventsJson);
  }

  Future<void> updateCopyWithHeaders(String value) async {
    await _settings.setValue(keyCopyWithHeaders, value);
  }

  Future<void> updateCopyHeaderFormat(String value) async {
    await _settings.setValue(keyCopyHeaderFormat, value);
  }

  /// Initialize default settings to disk if this is the first app launch
  Future<void> _initializeDefaultsIfNeeded() async {
    if (await _checkIfDefaultsNeeded()) {
      await _writeDefaultsToStorage();
    }
  }

  /// Check if default settings need to be initialized
  Future<bool> _checkIfDefaultsNeeded() async {
    // Use a dedicated flag to track initialization
    return !_settings.getValue<bool>('settings_initialized',
        defaultValue: false);
  }

  /// Write all default settings to persistent storage
  Future<void> _writeDefaultsToStorage() async {
    await _settings.setValue(keyDarkMode, false);
    await _settings.setValue(keySwatchColor, '#ff2c1b02');
    await _settings.setValue(keyPaddingSize, 10.0);
    await _settings.setValue(keyFontSize, 16.0);
    await _settings.setValue(keyFontFamily, 'FrankRuhlCLM');
    await _settings.setValue(keyShowOtzarHachochma, false);
    await _settings.setValue(keyShowHebrewBooks, false);
    await _settings.setValue(keyShowExternalBooks, false);
    await _settings.setValue(keyShowTeamim, true);
    await _settings.setValue(keyUseFastSearch, true);
    await _settings.setValue(keyReplaceHolyNames, true);
    await _settings.setValue(keyAutoUpdateIndex, true);
    await _settings.setValue(keyDefaultNikud, false);
    await _settings.setValue(keyRemoveNikudFromTanach, false);
    await _settings.setValue(keyDefaultSidebarOpen, false);
    await _settings.setValue(keyPinSidebar, false);
    await _settings.setValue(keySidebarWidth, 300.0);
    await _settings.setValue(keyFacetFilteringWidth, 235.0);
    await _settings.setValue(keyCalendarType, 'combined');
    await _settings.setValue(keySelectedCity, 'ירושלים');
    await _settings.setValue(keyCalendarEvents, '[]');
    await _settings.setValue(keyCopyWithHeaders, 'none');
    await _settings.setValue(keyCopyHeaderFormat, 'same_line_after_brackets');

    // Mark as initialized
    await _settings.setValue('settings_initialized', true);
  }
}
