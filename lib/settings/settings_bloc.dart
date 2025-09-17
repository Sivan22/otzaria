import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/settings/settings_event.dart';
import 'package:otzaria/settings/settings_repository.dart';
import 'package:otzaria/settings/settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _repository;

  SettingsBloc({required SettingsRepository repository})
      : _repository = repository,
        super(SettingsState.initial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateDarkMode>(_onUpdateDarkMode);
    on<UpdateSeedColor>(_onUpdateSeedColor);
    on<UpdatePaddingSize>(_onUpdatePaddingSize);
    on<UpdateFontSize>(_onUpdateFontSize);
    on<UpdateFontFamily>(_onUpdateFontFamily);
    on<UpdateShowOtzarHachochma>(_onUpdateShowOtzarHachochma);
    on<UpdateShowHebrewBooks>(_onUpdateShowHebrewBooks);
    on<UpdateShowExternalBooks>(_onUpdateShowExternalBooks);
    on<UpdateShowTeamim>(_onUpdateShowTeamim);
    on<UpdateUseFastSearch>(_onUpdateUseFastSearch);
    on<UpdateReplaceHolyNames>(_onUpdateReplaceHolyNames);
    on<UpdateAutoUpdateIndex>(_onUpdateAutoUpdateIndex);
    on<UpdateDefaultRemoveNikud>(_onUpdateDefaultRemoveNikud);
    on<UpdateRemoveNikudFromTanach>(_onUpdateRemoveNikudFromTanach);
    on<UpdateDefaultSidebarOpen>(_onUpdateDefaultSidebarOpen);
    on<UpdatePinSidebar>(_onUpdatePinSidebar);
    on<UpdateSidebarWidth>(_onUpdateSidebarWidth);
    on<UpdateFacetFilteringWidth>(_onUpdateFacetFilteringWidth);
    on<UpdateCopyWithHeaders>(_onUpdateCopyWithHeaders);
    on<UpdateCopyHeaderFormat>(_onUpdateCopyHeaderFormat);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final settings = await _repository.loadSettings();
    emit(SettingsState(
      isDarkMode: settings['isDarkMode'],
      seedColor: settings['seedColor'],
      paddingSize: settings['paddingSize'],
      fontSize: settings['fontSize'],
      fontFamily: settings['fontFamily'],
      showOtzarHachochma: settings['showOtzarHachochma'],
      showHebrewBooks: settings['showHebrewBooks'],
      showExternalBooks: settings['showExternalBooks'],
      showTeamim: settings['showTeamim'],
      useFastSearch: settings['useFastSearch'],
      replaceHolyNames: settings['replaceHolyNames'],
      autoUpdateIndex: settings['autoUpdateIndex'],
      defaultRemoveNikud: settings['defaultRemoveNikud'],
      removeNikudFromTanach: settings['removeNikudFromTanach'],
      defaultSidebarOpen: settings['defaultSidebarOpen'],
      pinSidebar: settings['pinSidebar'],
      sidebarWidth: settings['sidebarWidth'],
      facetFilteringWidth: settings['facetFilteringWidth'],
      copyWithHeaders: settings['copyWithHeaders'],
      copyHeaderFormat: settings['copyHeaderFormat'],
    ));
  }

  Future<void> _onUpdateDarkMode(
    UpdateDarkMode event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateDarkMode(event.isDarkMode);
    emit(state.copyWith(isDarkMode: event.isDarkMode));
  }

  Future<void> _onUpdateSeedColor(
    UpdateSeedColor event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateSeedColor(event.seedColor);
    emit(state.copyWith(seedColor: event.seedColor));
  }

  Future<void> _onUpdatePaddingSize(
    UpdatePaddingSize event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updatePaddingSize(event.paddingSize);
    emit(state.copyWith(paddingSize: event.paddingSize));
  }

  Future<void> _onUpdateFontSize(
    UpdateFontSize event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateFontSize(event.fontSize);
    emit(state.copyWith(fontSize: event.fontSize));
  }

  Future<void> _onUpdateFontFamily(
    UpdateFontFamily event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateFontFamily(event.fontFamily);
    emit(state.copyWith(fontFamily: event.fontFamily));
  }

  Future<void> _onUpdateShowOtzarHachochma(
    UpdateShowOtzarHachochma event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateShowOtzarHachochma(event.showOtzarHachochma);
    emit(state.copyWith(showOtzarHachochma: event.showOtzarHachochma));
  }

  Future<void> _onUpdateShowHebrewBooks(
    UpdateShowHebrewBooks event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateShowHebrewBooks(event.showHebrewBooks);
    emit(state.copyWith(showHebrewBooks: event.showHebrewBooks));
  }

  Future<void> _onUpdateShowExternalBooks(
    UpdateShowExternalBooks event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateShowExternalBooks(event.showExternalBooks);
    emit(state.copyWith(showExternalBooks: event.showExternalBooks));
  }

  Future<void> _onUpdateShowTeamim(
    UpdateShowTeamim event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateShowTeamim(event.showTeamim);
    emit(state.copyWith(showTeamim: event.showTeamim));
  }

  Future<void> _onUpdateUseFastSearch(
    UpdateUseFastSearch event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateUseFastSearch(event.useFastSearch);
    emit(state.copyWith(useFastSearch: event.useFastSearch));
  }

  Future<void> _onUpdateReplaceHolyNames(
    UpdateReplaceHolyNames event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateReplaceHolyNames(event.replaceHolyNames);
    emit(state.copyWith(replaceHolyNames: event.replaceHolyNames));
  }

  Future<void> _onUpdateAutoUpdateIndex(
    UpdateAutoUpdateIndex event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateAutoUpdateIndex(event.autoUpdateIndex);
    emit(state.copyWith(autoUpdateIndex: event.autoUpdateIndex));
  }

  Future<void> _onUpdateDefaultRemoveNikud(
    UpdateDefaultRemoveNikud event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateDefaultRemoveNikud(event.defaultRemoveNikud);
    emit(state.copyWith(defaultRemoveNikud: event.defaultRemoveNikud));
  }

  Future<void> _onUpdateRemoveNikudFromTanach(
    UpdateRemoveNikudFromTanach event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateRemoveNikudFromTanach(event.removeNikudFromTanach);
    emit(state.copyWith(removeNikudFromTanach: event.removeNikudFromTanach));
  }

  Future<void> _onUpdateDefaultSidebarOpen(
    UpdateDefaultSidebarOpen event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateDefaultSidebarOpen(event.defaultSidebarOpen);
    emit(state.copyWith(defaultSidebarOpen: event.defaultSidebarOpen));
  }

  Future<void> _onUpdatePinSidebar(
    UpdatePinSidebar event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updatePinSidebar(event.pinSidebar);
    emit(state.copyWith(pinSidebar: event.pinSidebar));
  }

  Future<void> _onUpdateSidebarWidth(
    UpdateSidebarWidth event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateSidebarWidth(event.sidebarWidth);
    emit(state.copyWith(sidebarWidth: event.sidebarWidth));
  }

  Future<void> _onUpdateFacetFilteringWidth(
    UpdateFacetFilteringWidth event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateFacetFilteringWidth(event.facetFilteringWidth);
    emit(state.copyWith(facetFilteringWidth: event.facetFilteringWidth));
  }

  Future<void> _onUpdateCopyWithHeaders(
    UpdateCopyWithHeaders event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateCopyWithHeaders(event.copyWithHeaders);
    emit(state.copyWith(copyWithHeaders: event.copyWithHeaders));
  }

  Future<void> _onUpdateCopyHeaderFormat(
    UpdateCopyHeaderFormat event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateCopyHeaderFormat(event.copyHeaderFormat);
    emit(state.copyWith(copyHeaderFormat: event.copyHeaderFormat));
  }
}
