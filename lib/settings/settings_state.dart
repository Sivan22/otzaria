import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final bool isDarkMode;
  final Color seedColor;
  final double paddingSize;
  final double fontSize;
  final String fontFamily;
  final bool showOtzarHachochma;
  final bool showHebrewBooks;
  final bool showExternalBooks;
  final bool showTeamim;
  final bool useFastSearch;
  final bool replaceHolyNames;
  final bool autoUpdateIndex;

  const SettingsState({
    required this.isDarkMode,
    required this.seedColor,
    required this.paddingSize,
    required this.fontSize,
    required this.fontFamily,
    required this.showOtzarHachochma,
    required this.showHebrewBooks,
    required this.showExternalBooks,
    required this.showTeamim,
    required this.useFastSearch,
    required this.replaceHolyNames,
    required this.autoUpdateIndex,
  });

  factory SettingsState.initial() {
    return const SettingsState(
      isDarkMode: false,
      seedColor: Colors.brown,
      paddingSize: 10,
      fontSize: 16,
      fontFamily: 'FrankRuhlCLM',
      showOtzarHachochma: false,
      showHebrewBooks: false,
      showExternalBooks: false,
      showTeamim: true,
      useFastSearch: true,
      replaceHolyNames: true,
      autoUpdateIndex: true,
    );
  }

  SettingsState copyWith({
    bool? isDarkMode,
    Color? seedColor,
    double? paddingSize,
    double? fontSize,
    String? fontFamily,
    bool? showOtzarHachochma,
    bool? showHebrewBooks,
    bool? showExternalBooks,
    bool? showTeamim,
    bool? useFastSearch,
    bool? replaceHolyNames,
    bool? autoUpdateIndex,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      seedColor: seedColor ?? this.seedColor,
      paddingSize: paddingSize ?? this.paddingSize,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      showOtzarHachochma: showOtzarHachochma ?? this.showOtzarHachochma,
      showHebrewBooks: showHebrewBooks ?? this.showHebrewBooks,
      showExternalBooks: showExternalBooks ?? this.showExternalBooks,
      showTeamim: showTeamim ?? this.showTeamim,
      useFastSearch: useFastSearch ?? this.useFastSearch,
      replaceHolyNames: replaceHolyNames ?? this.replaceHolyNames,
      autoUpdateIndex: autoUpdateIndex ?? this.autoUpdateIndex,
    );
  }

  @override
  List<Object?> get props => [
        isDarkMode,
        seedColor,
        paddingSize,
        fontSize,
        fontFamily,
        showOtzarHachochma,
        showHebrewBooks,
        showExternalBooks,
        showTeamim,
        useFastSearch,
        replaceHolyNames,
        autoUpdateIndex,
      ];
}
