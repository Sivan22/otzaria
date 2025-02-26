import 'package:equatable/equatable.dart';
import 'package:otzaria/tabs/models/pdf_tab.dart';
import 'package:pdfrx/pdfrx.dart';

abstract class PdfBookEvent extends Equatable {
  const PdfBookEvent();

  @override
  List<Object?> get props => [];
}

class LoadPdfBook extends PdfBookEvent {
  final String path;
  final int initialPage;
  final PdfBookTab tab;

  const LoadPdfBook({
    required this.tab,
    required this.path,
    this.initialPage = 1,
  });

  @override
  List<Object?> get props => [path, initialPage];
}

class ChangePage extends PdfBookEvent {
  final int pageNumber;
  final List<PdfOutlineNode>? outline;

  const ChangePage(this.pageNumber, {this.outline});

  @override
  List<Object?> get props => [pageNumber, outline];
}

class ToggleLeftPane extends PdfBookEvent {
  const ToggleLeftPane();
}

class TogglePinLeftPane extends PdfBookEvent {
  const TogglePinLeftPane();
}

class ZoomIn extends PdfBookEvent {
  const ZoomIn();
}

class ZoomOut extends PdfBookEvent {
  const ZoomOut();
}

class UpdateCurrentTitle extends PdfBookEvent {
  const UpdateCurrentTitle();
}

class UpdateSearchText extends PdfBookEvent {
  final String text;

  const UpdateSearchText(this.text);

  @override
  List<Object?> get props => [text];
}

class LoadOutline extends PdfBookEvent {
  const LoadOutline();
}

class UpdateDocumentRef extends PdfBookEvent {
  final PdfDocumentRef? documentRef;

  const UpdateDocumentRef(this.documentRef);

  @override
  List<Object?> get props => [documentRef];
}

class OnViewerReady extends PdfBookEvent {
  final PdfDocument document;
  final PdfViewerController controller;

  const OnViewerReady(this.document, this.controller);

  @override
  List<Object?> get props => [document, controller];
}
