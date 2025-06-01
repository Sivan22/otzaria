import 'package:flutter/widgets.dart';

enum FocusTarget { none, librarySearch, findRefSearch }

class FocusRepository {
  static final FocusRepository _instance = FocusRepository._internal();
  factory FocusRepository() => _instance;
  FocusRepository._internal();

  final FocusNode librarySearchFocusNode = FocusNode();
  final FocusNode findRefSearchFocusNode = FocusNode();

  final TextEditingController librarySearchController = TextEditingController();
  final TextEditingController findRefSearchController = TextEditingController();

  FocusTarget _currentFocusTarget = FocusTarget.none;
  FocusTarget get currentFocusTarget => _currentFocusTarget;

  void requestLibrarySearchFocus({bool selectAll = false}) {
    librarySearchFocusNode.requestFocus();
    if (selectAll) {
      librarySearchController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: librarySearchController.text.length,
      );
    }
    _currentFocusTarget = FocusTarget.librarySearch;
  }

  void requestFindRefSearchFocus({bool selectAll = false}) {
    findRefSearchFocusNode.requestFocus();
    if (selectAll) {
      findRefSearchController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: findRefSearchController.text.length,
      );
    }
    _currentFocusTarget = FocusTarget.findRefSearch;
  }



  void dispose() {
    librarySearchFocusNode.dispose();
    findRefSearchFocusNode.dispose();
    librarySearchController.dispose();
    findRefSearchController.dispose();
  }
}
