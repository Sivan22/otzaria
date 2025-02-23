import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/file_sync/file_sync_event.dart';
import 'package:otzaria/file_sync/file_sync_state.dart';
import 'package:otzaria/file_sync/file_sync_repository.dart';

class FileSyncBloc extends Bloc<FileSyncEvent, FileSyncState> {
  final FileSyncRepository repository;
  Timer? _progressTimer;

  FileSyncBloc({required this.repository}) : super(const FileSyncState()) {
    on<StartSync>(_onStartSync);
    on<StopSync>(_onStopSync);
    on<UpdateProgress>(_onUpdateProgress);
    on<ResetState>(_onResetState);

    // Check for auto-sync setting
    if (Settings.getValue<bool>('key-auto-sync') ?? false) {
      add(const StartSync());
    }
  }

  Future<void> _onStartSync(
      StartSync event, Emitter<FileSyncState> emit) async {
    // If already syncing or completed, reset first
    if (state.status == FileSyncStatus.syncing ||
        state.status == FileSyncStatus.completed) {
      emit(const FileSyncState());
    }

    emit(state.copyWith(
      status: FileSyncStatus.syncing,
      message: 'מסנכרן קבצים...',
    ));

    // Set up a timer to update progress periodically
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (repository.isSyncing && repository.totalFiles > 0) {
        add(UpdateProgress(
          current: repository.currentProgress,
          total: repository.totalFiles,
        ));
      }
    });

    try {
      final successCount = await repository.syncFiles();
      _progressTimer?.cancel();

      if (successCount > 0) {
        emit(state.copyWith(
          status: FileSyncStatus.completed,
          hasNewSync: true,
          message: 'סונכרנו $successCount קבצים חדשים',
        ));
      } else {
        emit(const FileSyncState());
      }
    } catch (e) {
      _progressTimer?.cancel();
      emit(state.copyWith(
        status: FileSyncStatus.error,
        message: 'שגיאה בסנכרון: ${e.toString()}',
        errorMessage: e.toString(),
      ));
    }
  }

  void _onStopSync(StopSync event, Emitter<FileSyncState> emit) {
    _progressTimer?.cancel();
    repository.stopSyncing();
    emit(const FileSyncState());
  }

  void _onUpdateProgress(UpdateProgress event, Emitter<FileSyncState> emit) {
    emit(state.copyWith(
      currentProgress: event.current,
      totalFiles: event.total,
      message: 'מסנכרן קבצים... ${event.current}/${event.total}',
    ));
  }

  void _onResetState(ResetState event, Emitter<FileSyncState> emit) {
    emit(const FileSyncState());
  }

  @override
  Future<void> close() {
    _progressTimer?.cancel();
    return super.close();
  }
}
