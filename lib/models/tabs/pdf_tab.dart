import 'package:flutter/material.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/tabs/tabs.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:pdfrx/pdfrx.dart';

/// Represents a tab with a PDF book.
///
/// The [PdfBookTab] class contains information about the PDF book,
/// such as its [book] and the current [pageNumber].
/// It also contains a [pdfViewerController] to control the viewer.
class PdfBookTab extends OpenedTab {
  /// The PDF book.
  final PdfBook book;

  /// The current page number.
  int pageNumber;

  /// The pdf viewer controller.
  final PdfViewerController pdfViewerController = PdfViewerController();

  final outline = ValueNotifier<List<PdfOutlineNode>?>(null);

  final documentRef = ValueNotifier<PdfDocumentRef?>(null);

  final TextEditingController searchController = TextEditingController();

  final String searchText;

  ///a flag that tells if the left pane should be shown
  late final ValueNotifier<bool> showLeftPane;

  ///a flag that tells if the left pane should be pinned on scrolling
  final pinLeftPane = ValueNotifier<bool>(false);

  /// Creates a new instance of [PdfBookTab].
  ///
  /// The [book] parameter represents the PDF book, and the [pageNumber]
  /// parameter represents the current page number.
  PdfBookTab(this.book, this.pageNumber,
      {bool openLeftPane = false, this.searchText = ''})
      : super(book.title) {
    showLeftPane = ValueNotifier<bool>(openLeftPane);
    searchController.text = searchText;
  }

  /// Creates a new instance of [PdfBookTab] from a JSON map.
  ///
  /// The JSON map should have 'path' and 'pageNumber' keys.
  factory PdfBookTab.fromJson(Map<String, dynamic> json) {
    return PdfBookTab(
        PdfBook(title: getTitleFromPath(json['path']), path: json['path']),
        json['pageNumber']);
  }

  /// Converts the [PdfBookTab] instance into a JSON map.
  ///
  /// The JSON map contains 'path', 'pageNumber' and 'type' keys.
  @override
  Map<String, dynamic> toJson() {
    return {
      'path': book.path,
      'pageNumber':
          (pdfViewerController.isReady ? pdfViewerController.pageNumber : 1),
      'type': 'PdfBookTab'
    };
  }
}
