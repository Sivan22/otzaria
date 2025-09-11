import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class UpdateDarkMode extends SettingsEvent {
  final bool isDarkMode;

  const UpdateDarkMode(this.isDarkMode);

  @override
  List<Object?> get props => [isDarkMode];
}

class UpdateSeedColor extends SettingsEvent {
  final Color seedColor;

  const UpdateSeedColor(this.seedColor);

  @override
  List<Object?> get props => [seedColor];
}

class UpdatePaddingSize extends SettingsEvent {
  final double paddingSize;

  const UpdatePaddingSize(this.paddingSize);

  @override
  List<Object?> get props => [paddingSize];
}

class UpdateFontSize extends SettingsEvent {
  final double fontSize;

  const UpdateFontSize(this.fontSize);

  @override
  List<Object?> get props => [fontSize];
}

class UpdateFontFamily extends SettingsEvent {
  final String fontFamily;

  const UpdateFontFamily(this.fontFamily);

  @override
  List<Object?> get props => [fontFamily];
}

class UpdateShowOtzarHachochma extends SettingsEvent {
  final bool showOtzarHachochma;

  const UpdateShowOtzarHachochma(this.showOtzarHachochma);

  @override
  List<Object?> get props => [showOtzarHachochma];
}

class UpdateShowHebrewBooks extends SettingsEvent {
  final bool showHebrewBooks;

  const UpdateShowHebrewBooks(this.showHebrewBooks);

  @override
  List<Object?> get props => [showHebrewBooks];
}

class UpdateShowExternalBooks extends SettingsEvent {
  final bool showExternalBooks;

  const UpdateShowExternalBooks(this.showExternalBooks);

  @override
  List<Object?> get props => [showExternalBooks];
}

class UpdateShowTeamim extends SettingsEvent {
  final bool showTeamim;

  const UpdateShowTeamim(this.showTeamim);

  @override
  List<Object?> get props => [showTeamim];
}

class UpdateUseFastSearch extends SettingsEvent {
  final bool useFastSearch;

  const UpdateUseFastSearch(this.useFastSearch);

  @override
  List<Object?> get props => [useFastSearch];
}

class UpdateReplaceHolyNames extends SettingsEvent {
  final bool replaceHolyNames;

  const UpdateReplaceHolyNames(this.replaceHolyNames);

  @override
  List<Object?> get props => [replaceHolyNames];
}

class UpdateAutoUpdateIndex extends SettingsEvent {
  final bool autoUpdateIndex;

  const UpdateAutoUpdateIndex(this.autoUpdateIndex);

  @override
  List<Object?> get props => [autoUpdateIndex];
}

class UpdateDefaultRemoveNikud extends SettingsEvent {
  final bool defaultRemoveNikud;

  const UpdateDefaultRemoveNikud(this.defaultRemoveNikud);

  @override
  List<Object?> get props => [defaultRemoveNikud];
}

class UpdateRemoveNikudFromTanach extends SettingsEvent {
  final bool removeNikudFromTanach;

  const UpdateRemoveNikudFromTanach(this.removeNikudFromTanach);

  @override
  List<Object?> get props => [removeNikudFromTanach];
}

class UpdateDefaultSidebarOpen extends SettingsEvent {
  final bool defaultSidebarOpen;

  const UpdateDefaultSidebarOpen(this.defaultSidebarOpen);

  @override
  List<Object?> get props => [defaultSidebarOpen];
}

class UpdatePinSidebar extends SettingsEvent {
  final bool pinSidebar;

  const UpdatePinSidebar(this.pinSidebar);

  @override
  List<Object?> get props => [pinSidebar];
}

class UpdateSidebarWidth extends SettingsEvent {
  final double sidebarWidth;

  const UpdateSidebarWidth(this.sidebarWidth);

  @override
  List<Object?> get props => [sidebarWidth];
}

class UpdateFacetFilteringWidth extends SettingsEvent {
  final double facetFilteringWidth;

  const UpdateFacetFilteringWidth(this.facetFilteringWidth);

  @override
  List<Object?> get props => [facetFilteringWidth];
}

class UpdateCopyWithHeaders extends SettingsEvent {
  final String copyWithHeaders;

  const UpdateCopyWithHeaders(this.copyWithHeaders);

  @override
  List<Object?> get props => [copyWithHeaders];
}

class UpdateCopyHeaderFormat extends SettingsEvent {
  final String copyHeaderFormat;

  const UpdateCopyHeaderFormat(this.copyHeaderFormat);

  @override
  List<Object?> get props => [copyHeaderFormat];
}
