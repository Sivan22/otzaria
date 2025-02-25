import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_event.dart';
import 'package:otzaria/settings/settings_state.dart';
import '../../unit/mocks/mock_settings_repository.mocks.dart';

void main() {
  group('SettingsBloc', () {
    late SettingsBloc settingsBloc;
    late MockSettingsRepository mockRepository;

    setUp(() {
      mockRepository = MockSettingsRepository();
      settingsBloc = SettingsBloc(repository: mockRepository);
    });

    tearDown(() {
      settingsBloc.close();
    });

    test('initial state is correct', () {
      expect(settingsBloc.state, equals(SettingsState.initial()));
    });

    group('LoadSettings', () {
      final mockSettings = {
        'isDarkMode': true,
        'seedColor': Colors.blue,
        'paddingSize': 15.0,
        'fontSize': 18.0,
        'fontFamily': 'Rubik',
        'showOtzarHachochma': true,
        'showHebrewBooks': true,
        'showExternalBooks': true,
        'showTeamim': false,
        'useFastSearch': false,
        'replaceHolyNames': false,
        'autoUpdateIndex': false,
      };

      blocTest<SettingsBloc, SettingsState>(
        'emits updated state when LoadSettings is added',
        build: () {
          when(mockRepository.loadSettings())
              .thenAnswer((_) async => mockSettings);
          return settingsBloc;
        },
        act: (bloc) => bloc.add(LoadSettings()),
        expect: () => [
          SettingsState(
            isDarkMode: mockSettings['isDarkMode'] as bool,
            seedColor: mockSettings['seedColor'] as Color,
            paddingSize: mockSettings['paddingSize'] as double,
            fontSize: mockSettings['fontSize'] as double,
            fontFamily: mockSettings['fontFamily'] as String,
            showOtzarHachochma: mockSettings['showOtzarHachochma'] as bool,
            showHebrewBooks: mockSettings['showHebrewBooks'] as bool,
            showExternalBooks: mockSettings['showExternalBooks'] as bool,
            showTeamim: mockSettings['showTeamim'] as bool,
            useFastSearch: mockSettings['useFastSearch'] as bool,
            replaceHolyNames: mockSettings['replaceHolyNames'] as bool,
            autoUpdateIndex: mockSettings['autoUpdateIndex'] as bool,
          ),
        ],
        verify: (_) {
          verify(mockRepository.loadSettings()).called(1);
        },
      );
    });

    group('UpdateDarkMode', () {
      blocTest<SettingsBloc, SettingsState>(
        'emits updated state when UpdateDarkMode is added',
        build: () => settingsBloc,
        act: (bloc) => bloc.add(const UpdateDarkMode(true)),
        expect: () => [
          settingsBloc.state.copyWith(isDarkMode: true),
        ],
        verify: (_) {
          verify(mockRepository.updateDarkMode(true)).called(1);
        },
      );
    });

    group('UpdateSeedColor', () {
      final newColor = Colors.red;

      blocTest<SettingsBloc, SettingsState>(
        'emits updated state when UpdateSeedColor is added',
        build: () => settingsBloc,
        act: (bloc) => bloc.add(UpdateSeedColor(newColor)),
        expect: () => [
          settingsBloc.state.copyWith(seedColor: newColor),
        ],
        verify: (_) {
          verify(mockRepository.updateSeedColor(newColor)).called(1);
        },
      );
    });

    group('UpdateFontSize', () {
      const newFontSize = 20.0;

      blocTest<SettingsBloc, SettingsState>(
        'emits updated state when UpdateFontSize is added',
        build: () => settingsBloc,
        act: (bloc) => bloc.add(const UpdateFontSize(newFontSize)),
        expect: () => [
          settingsBloc.state.copyWith(fontSize: newFontSize),
        ],
        verify: (_) {
          verify(mockRepository.updateFontSize(newFontSize)).called(1);
        },
      );
    });

    group('UpdateFontFamily', () {
      const newFontFamily = 'NotoSerifHebrew';

      blocTest<SettingsBloc, SettingsState>(
        'emits updated state when UpdateFontFamily is added',
        build: () => settingsBloc,
        act: (bloc) => bloc.add(const UpdateFontFamily(newFontFamily)),
        expect: () => [
          settingsBloc.state.copyWith(fontFamily: newFontFamily),
        ],
        verify: (_) {
          verify(mockRepository.updateFontFamily(newFontFamily)).called(1);
        },
      );
    });
  });
}
