import 'dart:io';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

class NavigationRepository {
  bool checkLibraryIsEmpty() {
    final libraryPath = Settings.getValue<String>('key-library-path');
    if (libraryPath == null) {
      return true;
    }

    final libraryDir = Directory('$libraryPath${Platform.pathSeparator}אוצריא');
    if (!libraryDir.existsSync() || libraryDir.listSync().isEmpty) {
      return true;
    }

    return false;
  }

  Future<void> refreshLibrary() async {
    // This will be implemented when we migrate the library bloc
    // For now, it's a placeholder for the refresh functionality
  }
}
