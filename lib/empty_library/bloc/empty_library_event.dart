import 'package:equatable/equatable.dart';

abstract class EmptyLibraryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class DownloadLibraryRequested extends EmptyLibraryEvent {}

class PickDirectoryRequested extends EmptyLibraryEvent {}

class PickAndExtractZipRequested extends EmptyLibraryEvent {}

class CancelDownloadRequested extends EmptyLibraryEvent {}

class DownloadProgressUpdated extends EmptyLibraryEvent {
  final double progress;
  final double downloadedMB;
  final double downloadSpeed;
  final String currentOperation;

  DownloadProgressUpdated({
    required this.progress,
    required this.downloadedMB,
    required this.downloadSpeed,
    required this.currentOperation,
  });

  @override
  List<Object?> get props =>
      [progress, downloadedMB, downloadSpeed, currentOperation];
}
