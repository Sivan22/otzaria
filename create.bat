REM Clean Flutter build
flutter clean

REM Get Dart dependencies
dart pub get

REM Build Flutter Windows app
flutter build windows

REM Run Inno Setup scripts
iscc installer\otzaria.iss
iscc installer\otzaria_full.iss

echo Build and packaging complete.
pause