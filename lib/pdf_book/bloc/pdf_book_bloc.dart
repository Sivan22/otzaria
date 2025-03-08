import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdfrx/pdfrx.dart';
import 'pdf_book_event.dart';
import 'pdf_book_state.dart';

class PdfBookBloc extends Bloc<PdfBookEvent, PdfBookState> {
  PdfBookBloc(int initialIndex)
      : super(PdfBookState(currentPage: initialIndex)) {
    on<ChangePage>(_onChangePage);
    on<ToggleLeftPane>(_onToggleLeftPane);
    on<TogglePinLeftPane>(_onTogglePinLeftPane);
    on<ZoomIn>(_onZoomIn);
    on<ZoomOut>(_onZoomOut);
    on<UpdateSearchText>(_onUpdateSearchText);
    on<OnViewerReady>(_onViewerReady);
    on<UpdateCurrentTitle>(_onUpdateCurrentTitle);
  }

  void _onChangePage(ChangePage event, Emitter<PdfBookState> emit) async {
    if (!state.controller.isReady) return;
    state.controller.goToPage(pageNumber: event.pageNumber);
  }

  void _onToggleLeftPane(ToggleLeftPane event, Emitter<PdfBookState> emit) {
    emit(state.copyWith(
        isLeftPaneVisible: !state.isLeftPaneVisible, status: state.status));
  }

  void _onTogglePinLeftPane(
      TogglePinLeftPane event, Emitter<PdfBookState> emit) {
    emit(state.copyWith(
        isLeftPanePinned: !state.isLeftPanePinned, status: state.status));
  }

  void _onZoomIn(ZoomIn event, Emitter<PdfBookState> emit) {
    if (!state.controller.isReady) return;
    state.controller.zoomUp();
    emit(
        state.copyWith(zoomLevel: state.zoomLevel * 1.1, status: state.status));
  }

  void _onZoomOut(ZoomOut event, Emitter<PdfBookState> emit) {
    if (!state.controller.isReady) return;
    state.controller.zoomDown();
    emit(
        state.copyWith(zoomLevel: state.zoomLevel / 1.1, status: state.status));
  }

  void _onUpdateSearchText(UpdateSearchText event, Emitter<PdfBookState> emit) {
    emit(state.copyWith(searchText: event.text, status: state.status));
  }

  void _onViewerReady(OnViewerReady event, Emitter<PdfBookState> emit) async {
    final outline = await event.document.loadOutline();
    emit(state.copyWith(
        totalPages: state.totalPages ?? event.controller.pageCount,
        outline: state.outline ?? outline,
        status: PdfBookStatus.ready));
  }

  void _onUpdateCurrentTitle(
      UpdateCurrentTitle event, Emitter<PdfBookState> emit) async {
    if (!state.controller.isReady) return;
    emit(state.copyWith(
        currentTitle: await refFromPageNumber(
          state.outline ?? [],
          state.controller.pageNumber ?? 1,
        ),
        status: state.status));
  }

  Future<String> refFromPageNumber(
    List<PdfOutlineNode> entries,
    int pageNumber,
  ) async {
    List<String> texts = [];
    void searchOutline(List<PdfOutlineNode> entries, {int level = 1}) {
      for (final entry in entries) {
        if (entry.dest?.pageNumber != null &&
            entry.dest!.pageNumber > pageNumber) {
          return;
        }
        if (level > texts.length) {
          texts.add(entry.title);
        } else {
          texts[level - 1] = entry.title;
          texts = texts.getRange(0, level).toList();
        }
        searchOutline(entry.children, level: level + 1);
      }
    }

    searchOutline(
      entries,
    );
    texts = texts.map((e) => e.trim()).toList();
    return texts.join(', ');
  }
}
