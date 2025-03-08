import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

enum PdfBookStatus { initial, ready, error }

class PdfBookState extends Equatable {
  final int currentPage;
  final int? totalPages;
  final bool isLeftPaneVisible;
  final bool isLeftPanePinned;
  final double zoomLevel;
  final List<PdfOutlineNode>? outline;
  final String searchText;
  final PdfViewerController controller = PdfViewerController();
  late final PdfTextSearcher textSearcher;
  final TextEditingController searchController = TextEditingController();
  final String? currentTitle;
  final String? errorMessage;
  final PdfBookStatus status;
  PdfBookState(
      {required this.currentPage,
      this.totalPages,
      this.isLeftPaneVisible = true,
      this.isLeftPanePinned = false,
      this.zoomLevel = 1.0,
      this.outline,
      this.searchText = '',
      this.currentTitle,
      this.errorMessage,
      this.status = PdfBookStatus.initial}) {
    textSearcher = PdfTextSearcher(controller);
  }

  PdfBookState copyWith(
      {int? currentPage,
      int? totalPages,
      bool? isLeftPaneVisible,
      bool? isLeftPanePinned,
      double? zoomLevel,
      List<PdfOutlineNode>? outline,
      String? searchText,
      String? currentTitle,
      required PdfBookStatus status}) {
    return PdfBookState(
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
        isLeftPaneVisible: isLeftPaneVisible ?? this.isLeftPaneVisible,
        isLeftPanePinned: isLeftPanePinned ?? this.isLeftPanePinned,
        zoomLevel: zoomLevel ?? this.zoomLevel,
        outline: outline ?? this.outline,
        searchText: searchText ?? this.searchText,
        currentTitle: currentTitle,
        status: status);
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
        controller,
        textSearcher,
        searchController,
        currentTitle,
        status
      ];
}
