import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdfrx/pdfrx.dart';
import 'pdf_book_event.dart';
import 'pdf_book_state.dart';

class PdfBookBloc extends Bloc<PdfBookEvent, PdfBookState> {
  PdfViewerController? _controller;

  PdfBookBloc() : super(const PdfBookInitial()) {
    on<LoadPdfBook>(_onLoadPdfBook);
    on<ChangePage>(_onChangePage);
    on<ToggleLeftPane>(_onToggleLeftPane);
    on<TogglePinLeftPane>(_onTogglePinLeftPane);
    on<ZoomIn>(_onZoomIn);
    on<ZoomOut>(_onZoomOut);
    on<UpdateSearchText>(_onUpdateSearchText);
    on<LoadOutline>(_onLoadOutline);
    on<UpdateDocumentRef>(_onUpdateDocumentRef);
    on<OnViewerReady>(_onViewerReady);
  }

  void _onLoadPdfBook(LoadPdfBook event, Emitter<PdfBookState> emit) {
    emit(const PdfBookLoading());
    try {
      _controller = PdfViewerController();
      emit(PdfBookLoaded(
        currentPage: event.initialPage,
        totalPages: 0, // Will be updated when viewer is ready
        isLeftPaneVisible: false,
        isLeftPanePinned: false,
        zoomLevel: 1.0,
        controller: _controller!,
      ));
    } catch (e) {
      emit(PdfBookError(e.toString()));
    }
  }

  void _onChangePage(ChangePage event, Emitter<PdfBookState> emit) {
    if (state is PdfBookLoaded) {
      final currentState = state as PdfBookLoaded;
      _controller?.goToPage(pageNumber: event.pageNumber);
      emit(currentState.copyWith(currentPage: event.pageNumber));
    }
  }

  void _onToggleLeftPane(ToggleLeftPane event, Emitter<PdfBookState> emit) {
    if (state is PdfBookLoaded) {
      final currentState = state as PdfBookLoaded;
      emit(currentState.copyWith(
        isLeftPaneVisible: !currentState.isLeftPaneVisible,
      ));
    }
  }

  void _onTogglePinLeftPane(
      TogglePinLeftPane event, Emitter<PdfBookState> emit) {
    if (state is PdfBookLoaded) {
      final currentState = state as PdfBookLoaded;
      emit(currentState.copyWith(
        isLeftPanePinned: !currentState.isLeftPanePinned,
      ));
    }
  }

  void _onZoomIn(ZoomIn event, Emitter<PdfBookState> emit) {
    if (state is PdfBookLoaded) {
      final currentState = state as PdfBookLoaded;
      _controller?.zoomUp();
      emit(currentState.copyWith(
        zoomLevel: currentState.zoomLevel * 1.1,
      ));
    }
  }

  void _onZoomOut(ZoomOut event, Emitter<PdfBookState> emit) {
    if (state is PdfBookLoaded) {
      final currentState = state as PdfBookLoaded;
      _controller?.zoomDown();
      emit(currentState.copyWith(
        zoomLevel: currentState.zoomLevel / 1.1,
      ));
    }
  }

  void _onUpdateSearchText(UpdateSearchText event, Emitter<PdfBookState> emit) {
    if (state is PdfBookLoaded) {
      final currentState = state as PdfBookLoaded;
      emit(currentState.copyWith(searchText: event.text));
    }
  }

  // Outline is loaded in onViewerReady
  void _onLoadOutline(LoadOutline event, Emitter<PdfBookState> emit) {
    // No-op as outline is handled in onViewerReady
  }

  void _onUpdateDocumentRef(
      UpdateDocumentRef event, Emitter<PdfBookState> emit) {
    if (state is PdfBookLoaded) {
      final currentState = state as PdfBookLoaded;
      emit(currentState.copyWith(documentRef: event.documentRef));
    }
  }

  void _onViewerReady(OnViewerReady event, Emitter<PdfBookState> emit) async {
    if (state is PdfBookLoaded) {
      final currentState = state as PdfBookLoaded;
      final outline = await event.document.loadOutline();
      emit(currentState.copyWith(
        totalPages: event.controller.pageCount,
        outline: outline,
        documentRef: event.controller.documentRef,
        isLeftPaneVisible: true,
      ));
    }
  }

  @override
  Future<void> close() {
    _controller = null;
    return super.close();
  }
}
