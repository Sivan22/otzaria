import 'package:equatable/equatable.dart';
import 'package:pdfrx/pdfrx.dart';

abstract class PdfBookState extends Equatable {
  const PdfBookState();

  @override
  List<Object?> get props => [];
}

class PdfBookInitial extends PdfBookState {
  const PdfBookInitial();
}

class PdfBookLoading extends PdfBookState {
  const PdfBookLoading();
}

class PdfBookError extends PdfBookState {
  final String message;

  const PdfBookError(this.message);

  @override
  List<Object?> get props => [message];
}

class PdfBookLoaded extends PdfBookState {
  final int currentPage;
  final int totalPages;
  final bool isLeftPaneVisible;
  final bool isLeftPanePinned;
  final double zoomLevel;
  final List<PdfOutlineNode>? outline;
  final String searchText;
  final PdfDocumentRef? documentRef;
  final PdfViewerController controller;
  final String? currentTitle;

  const PdfBookLoaded(
      {required this.currentPage,
      required this.totalPages,
      required this.isLeftPaneVisible,
      required this.isLeftPanePinned,
      required this.zoomLevel,
      required this.controller,
      this.outline,
      this.searchText = '',
      this.documentRef,
      this.currentTitle});

  PdfBookLoaded copyWith(
      {int? currentPage,
      int? totalPages,
      bool? isLeftPaneVisible,
      bool? isLeftPanePinned,
      double? zoomLevel,
      List<PdfOutlineNode>? outline,
      String? searchText,
      PdfDocumentRef? documentRef,
      PdfViewerController? controller,
      String? currentTitle}) {
    return PdfBookLoaded(
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
        isLeftPaneVisible: isLeftPaneVisible ?? this.isLeftPaneVisible,
        isLeftPanePinned: isLeftPanePinned ?? this.isLeftPanePinned,
        zoomLevel: zoomLevel ?? this.zoomLevel,
        outline: outline ?? this.outline,
        searchText: searchText ?? this.searchText,
        documentRef: documentRef ?? this.documentRef,
        controller: controller ?? this.controller,
        currentTitle: currentTitle);
  }

  @override
  List<Object?> get props => [
        currentPage,
        totalPages,
        isLeftPaneVisible,
        isLeftPanePinned,
        zoomLevel,
        outline,
        searchText,
        documentRef,
        controller,
        currentTitle
      ];
}
