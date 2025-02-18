enum FileSyncStatus { initial, syncing, completed, error }

class FileSyncState {
  final FileSyncStatus status;
  final int currentProgress;
  final int totalFiles;
  final String message;
  final bool hasNewSync;
  final String? errorMessage;

  const FileSyncState({
    this.status = FileSyncStatus.initial,
    this.currentProgress = 0,
    this.totalFiles = 0,
    this.message = 'לחץ לסנכרון קבצים',
    this.hasNewSync = false,
    this.errorMessage,
  });

  FileSyncState copyWith({
    FileSyncStatus? status,
    int? currentProgress,
    int? totalFiles,
    String? message,
    bool? hasNewSync,
    String? errorMessage,
  }) {
    return FileSyncState(
      status: status ?? this.status,
      currentProgress: currentProgress ?? this.currentProgress,
      totalFiles: totalFiles ?? this.totalFiles,
      message: message ?? this.message,
      hasNewSync: hasNewSync ?? this.hasNewSync,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
