sealed class FileSyncEvent {
  const FileSyncEvent();
}

class StartSync extends FileSyncEvent {
  const StartSync();
}

class StopSync extends FileSyncEvent {
  const StopSync();
}

class UpdateProgress extends FileSyncEvent {
  final int current;
  final int total;

  const UpdateProgress({
    required this.current,
    required this.total,
  });
}

class ResetState extends FileSyncEvent {
  const ResetState();
}
