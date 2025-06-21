// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:synchronized/extension.dart';

//
// Simple Text Search View
//
class PdfBookSearchView extends StatefulWidget {
  const PdfBookSearchView({
    required this.textSearcher,
    required this.searchController,
    required this.focusNode,
    this.initialSearchText = '',
    this.onSearchResultNavigated, // Add this
    super.key,
  });

  final PdfTextSearcher textSearcher;
  final TextEditingController searchController;
  final FocusNode focusNode;
  final String initialSearchText; // Remains for now, parent will provide tab.searchText

  final VoidCallback? onSearchResultNavigated; // Add this


  @override
  State<PdfBookSearchView> createState() => _PdfBookSearchViewState();
}

class _PdfBookSearchViewState extends State<PdfBookSearchView> {
  // final searchTextController = TextEditingController(); // Removed
  late final pageTextStore =
      PdfPageTextCache(textSearcher: widget.textSearcher);
  final scrollController = ScrollController();
  @override
  void initState() {
    super.initState(); // Moved to the top
    widget.textSearcher.addListener(_searchResultUpdated);
    widget.searchController.addListener(_searchTextUpdated);

    // If the controller (from PdfBookTab) already has text when view is initialized,
    // start the search. This ensures that if the sidebar is reopened with existing
    // search text, the search is re-executed and results are displayed.
    if (widget.searchController.text.isNotEmpty) {
      // We pass goToFirstMatch: false because the _onTextSearcherUpdated listener
      // in _PdfBookScreenState is responsible for restoring the specific currentIndex later.
      widget.textSearcher.startTextSearch(widget.searchController.text, goToFirstMatch: false);
      _searchResultUpdated();
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    widget.textSearcher.removeListener(_searchResultUpdated);
    widget.searchController.removeListener(_searchTextUpdated); // Changed
    // searchTextController.dispose(); // Removed
    super.dispose();
  }

  void _searchTextUpdated() {
    widget.textSearcher.startTextSearch(widget.searchController.text, goToFirstMatch: false); // Changed
  }

  int? _currentSearchSession;
  final _matchIndexToListIndex = <int>[];
  final _listIndexToMatchIndex = <int>[];

  void _searchResultUpdated() {
    final previousListCount = _listIndexToMatchIndex.length;

    // Force a full rebuild of the internal lists if:
    // 1. The search session ID from the textSearcher has changed.
    // 2. Or, our internal list for ListView (_listIndexToMatchIndex) is empty,
    //    but the textSearcher actually has matches. This covers cases where
    //    the view might be reconstructed/refreshed and lost its local list state,
    //    but the underlying searcher still holds valid results.
    if (_currentSearchSession != widget.textSearcher.searchSession ||
        (_listIndexToMatchIndex.isEmpty && widget.textSearcher.hasMatches)) {
      _currentSearchSession = widget.textSearcher.searchSession;
      _matchIndexToListIndex.clear();
      _listIndexToMatchIndex.clear();
    }

    // Populate _listIndexToMatchIndex and _matchIndexToListIndex.
    // This loop will either:
    //  - Fully rebuild the lists if they were cleared above.
    //  - Or, append new matches if the session is the same and lists weren't cleared
    //    (e.g., during an incremental search update).
    for (int i = _matchIndexToListIndex.length; // Start from the current end of _matchIndexToListIndex
        i < widget.textSearcher.matches.length;
        i++) {
      if (i == 0 ||
          widget.textSearcher.matches[i - 1].pageNumber !=
              widget.textSearcher.matches[i].pageNumber) {
        // Add a negative page number to indicate a page header in the list
        _listIndexToMatchIndex.add(-widget.textSearcher.matches[i].pageNumber);
      }
      _matchIndexToListIndex.add(_listIndexToMatchIndex.length); // Store mapping for scrolling
      _listIndexToMatchIndex.add(i); // Add actual match index
    }

    // Call setState to rebuild the UI if:
    // - The component is still mounted.
    // - And, either the new list has items (implying a change or initial population)
    // - Or, the previous list had items (implying a potential clear or change).
    // This avoids unnecessary rebuilds if the list was and remains empty.
    if (mounted && (_listIndexToMatchIndex.isNotEmpty || previousListCount > 0)) {
      setState(() {});
    }
    // _conditionScrollPosition(); // Consider if this is needed here or if current item highlighting handles it.
    // The original code had setState({}) and then _conditionScrollPosition() was called from button presses.
    // The highlighting of the current search item is based on `widget.textSearcher.currentIndex`
    // which is managed by the `PdfTextSearcher` itself when `goToMatchOfIndex` or arrow buttons are used.
    // So, simply ensuring the list is correctly built should be sufficient.
  }

  // Public method to scroll to current match - can be called from parent
  void scrollToCurrentMatch() {
    if (widget.textSearcher.currentIndex != null && 
        widget.textSearcher.currentIndex! < _matchIndexToListIndex.length) {
      _conditionScrollPosition();
    }
  }

  static const double itemHeight = 50;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widget.textSearcher.isSearching
            ? LinearProgressIndicator(
                value: widget.textSearcher.searchProgress,
                minHeight: 4,
              )
            : const SizedBox(height: 4),
        Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  TextField(
                    autofocus: true,
                    focusNode: widget.focusNode,
                    controller: widget.searchController,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        onPressed: widget.searchController.text.isNotEmpty
                            ? () {
                                widget.searchController.text = '';
                                widget.textSearcher.resetTextSearch();
                                widget.focusNode.requestFocus();
                              }
                            : null,
                        icon: const Icon(Icons.close),
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    // onSubmitted: (value) {
                    //   // just focus back to the text field
                    //   focusNode.requestFocus();
                    // },
                  ),
                  // Result count moved below
                ],
              ),
            ),
            // Icons removed for cleaner UI
          ],
        ),
        if (widget.textSearcher.hasMatches)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                '${widget.textSearcher.currentIndex! + 1} / ${widget.textSearcher.matches.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            key: Key(widget.searchController.text), // Changed
            controller: scrollController,
            itemCount: _listIndexToMatchIndex.length,
            itemBuilder: (context, index) {
              final matchIndex = _listIndexToMatchIndex[index];
              if (matchIndex >= 0 &&
                  matchIndex < widget.textSearcher.matches.length) {
                final match = widget.textSearcher.matches[matchIndex];
                return SearchResultTile(
                  key: ValueKey(index),
                  match: match,
                  onTap: () async {
                    await widget.textSearcher.goToMatchOfIndex(matchIndex);
                    widget.onSearchResultNavigated?.call(); // Add this line
                    if (mounted) setState(() {});
                  },
                  pageTextStore: pageTextStore,
                  height: itemHeight,
                  isCurrent: matchIndex == widget.textSearcher.currentIndex,
                );
              } else {
                return Container(
                  height: itemHeight,
                  alignment: Alignment.bottomRight, // Changed from bottomLeft
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'עמוד ${-matchIndex}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: TextDirection.rtl, // Added this
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  void _conditionScrollPosition() {
    final pos = scrollController.position;
    final newPos =
        itemHeight * _matchIndexToListIndex[widget.textSearcher.currentIndex!];
    if (newPos + itemHeight > pos.pixels + pos.viewportDimension) {
      scrollController.animateTo(
        newPos + itemHeight - pos.viewportDimension,
        duration: const Duration(milliseconds: 300),
        curve: Curves.decelerate,
      );
    } else if (newPos < pos.pixels) {
      scrollController.animateTo(
        newPos,
        duration: const Duration(milliseconds: 300),
        curve: Curves.decelerate,
      );
    }

    if (mounted) setState(() {});
  }
}

class SearchResultTile extends StatefulWidget {
  const SearchResultTile({
    required this.match,
    required this.onTap,
    required this.pageTextStore,
    required this.height,
    required this.isCurrent,
    super.key,
  });

  final PdfTextRangeWithFragments match;
  final void Function() onTap;
  final PdfPageTextCache pageTextStore;
  final double height;
  final bool isCurrent;

  @override
  State<SearchResultTile> createState() => _SearchResultTileState();
}

class _SearchResultTileState extends State<SearchResultTile> {
  PdfPageText? pageText;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _release() {
    if (pageText != null) {
      widget.pageTextStore.releaseText(pageText!.pageNumber);
    }
  }

  Future<void> _load() async {
    _release();
    pageText = await widget.pageTextStore.loadText(widget.match.pageNumber);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Text.rich(createTextSpanForMatch(pageText, widget.match));

    return SizedBox(
      height: widget.height,
      child: Material(
        color: widget.isCurrent
            ? DefaultSelectionStyle.of(context).selectionColor!
            : null,
        child: InkWell(
          onTap: () => widget.onTap(),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.black12,
                  width: 0.5,
                ),
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: text,
          ),
        ),
      ),
    );
  }

  TextSpan createTextSpanForMatch(
      PdfPageText? pageText, PdfTextRangeWithFragments match,
      {TextStyle? style}) {
    style ??= const TextStyle(
      fontSize: 14,
    );
    if (pageText == null) {
      return TextSpan(
        text: match.fragments.map((f) => f.text).join(),
        style: style,
      );
    }
    final fullText = pageText.fullText;
    int first = 0;
    for (int i = match.fragments.first.index - 1; i >= 0;) {
      if (fullText[i] == '\n') {
        first = i + 1;
        break;
      }
      i--;
    }
    int last = fullText.length;
    for (int i = match.fragments.last.end; i < fullText.length; i++) {
      if (fullText[i] == '\n') {
        last = i;
        break;
      }
    }

    final header =
        fullText.substring(first, match.fragments.first.index + match.start);
    final body = fullText.substring(match.fragments.first.index + match.start,
        match.fragments.last.index + match.end);
    final footer =
        fullText.substring(match.fragments.last.index + match.end, last);

    return TextSpan(
      children: [
        TextSpan(text: header),
        TextSpan(
          text: body,
          style: const TextStyle(
            backgroundColor: Colors.yellow,
          ),
        ),
        TextSpan(text: footer),
      ],
      style: style,
    );
  }
}

/// A helper class to cache loaded page texts.
class PdfPageTextCache {
  final PdfTextSearcher textSearcher;
  PdfPageTextCache({
    required this.textSearcher,
  });

  final _pageTextRefs = <int, _PdfPageTextRefCount>{};

  /// load the text of the given page number.
  Future<PdfPageText> loadText(int pageNumber) async {
    final ref = _pageTextRefs[pageNumber];
    if (ref != null) {
      ref.refCount++;
      return ref.pageText;
    }
    return await synchronized(() async {
      var ref = _pageTextRefs[pageNumber];
      if (ref == null) {
        final pageText = await textSearcher.loadText(pageNumber: pageNumber);
        ref = _pageTextRefs[pageNumber] = _PdfPageTextRefCount(pageText!);
      }
      ref.refCount++;
      return ref.pageText;
    });
  }

  /// Release the text of the given page number.
  void releaseText(int pageNumber) {
    final ref = _pageTextRefs[pageNumber]!;
    ref.refCount--;
    if (ref.refCount == 0) {
      _pageTextRefs.remove(pageNumber);
    }
  }
}

class _PdfPageTextRefCount {
  _PdfPageTextRefCount(this.pageText);
  final PdfPageText pageText;
  int refCount = 0;
}
