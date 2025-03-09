import 'package:flutter_settings_screens/flutter_settings_screens.dart';

/// A wrapper around the static Settings class to make it more testable.
/// This allows us to mock the Settings class in tests.
class SettingsWrapper {
  /// Gets a value from settings with a default value if not found.
  T getValue<T>(String key, {required T defaultValue}) {
    return Settings.getValue<T>(key, defaultValue: defaultValue) ??
        defaultValue;
  }

  /// Sets a value in settings.
  Future<void> setValue<T>(String key, T value) async {
    await Settings.setValue<T>(key, value);
  }
}
