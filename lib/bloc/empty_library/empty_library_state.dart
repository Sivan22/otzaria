import 'package:equatable/equatable.dart';

abstract class EmptyLibraryState extends Equatable {
  final bool isDownloading;
  final double downloadProgress;
  final String? selectedPath;
  final double downloadedMB;
  final double downloadSpeed;
  final String currentOperation;
  final bool isCancelling;
  final String? errorMessage;

  const EmptyLibraryState({
    this.isDownloading = false,
    this.downloadProgress = 0,
    this.selectedPath,
    this.downloadedMB = 0,
    this.downloadSpeed = 0,
    this.currentOperation = '',
    this.isCancelling = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        isDownloading,
        downloadProgress,
        selectedPath,
        downloadedMB,
        downloadSpeed,
        currentOperation,
        isCancelling,
        errorMessage,
      ];
}

class EmptyLibraryInitial extends EmptyLibraryState {}

class EmptyLibraryLoading extends EmptyLibraryState {
  const EmptyLibraryLoading({
    super.isDownloading,
    super.downloadProgress,
    super.selectedPath,
    super.downloadedMB,
    super.downloadSpeed,
    super.currentOperation,
    super.isCancelling,
  });
}

class EmptyLibraryDownloaded extends EmptyLibraryState {}

class EmptyLibraryError extends EmptyLibraryState {
  const EmptyLibraryError({super.errorMessage});
}
