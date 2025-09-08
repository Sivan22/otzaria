import 'package:flutter/material.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/models/books.dart';
import 'package:pdfrx/pdfrx.dart';

// A cache for the generated page maps to avoid rebuilding them on every conversion.
final _pageMapCache = <String, _PageMap>{};

/// Converts a text book page index to the corresponding PDF page number.
///
/// This function uses a cached, anchor-based map with local interpolation for accuracy and performance.
Future<int?> textToPdfPage(TextBook textBook, int textIndex) async {
  final pdfBook = (await DataRepository.instance.library)
      .findBookByTitle(textBook.title, PdfBook) as PdfBook?;
  if (pdfBook == null) {
    return null;
  }

  // It's better to get the outline from a provider/tab if available than to load it every time.
  // For now, we load it directly as a fallback.
  final outline =
      await PdfDocument.openFile(pdfBook.path).then((doc) => doc.loadOutline());
  final key = '${pdfBook.path}::${textBook.title}';
  final map =
      _pageMapCache[key] ??= await _buildPageMap(pdfBook, outline, textBook);

  return map.textToPdf(textIndex);
}

/// Converts a PDF page number to the corresponding text book index.
///
/// This function uses a cached, anchor-based map with local interpolation for accuracy and performance.
Future<int?> pdfToTextPage(PdfBook pdfBook, List<PdfOutlineNode> outline,
    int pdfPage, BuildContext ctx) async {
  final textBook = (await DataRepository.instance.library)
      .findBookByTitle(pdfBook.title, TextBook) as TextBook?;
  if (textBook == null) {
    return null;
  }
  final key = '${pdfBook.path}::${textBook.title}';
  final map =
      _pageMapCache[key] ??= await _buildPageMap(pdfBook, outline, textBook);

  return map.pdfToText(pdfPage);
}

/// A class that holds a synchronized map of PDF pages and text indices
/// and performs interpolation between them.
class _PageMap {
  // Sorted lists of corresponding anchor points.
  final List<int> pdfPages; // 1-based
  final List<int> textIndices; // 0-based

  _PageMap(this.pdfPages, this.textIndices);

  /// Converts a PDF page to a text index using binary search and linear interpolation.
  int? pdfToText(int page) {
    if (pdfPages.isEmpty) return null;

    final i = _lowerBound(pdfPages, page);
    if (i == 0) return textIndices.first;
    if (i >= pdfPages.length) return textIndices.last;

    final pA = pdfPages[i - 1], pB = pdfPages[i];
    final tA = textIndices[i - 1], tB = textIndices[i];

    if (pB == pA) return tA; // Avoid division by zero

    // Linear interpolation
    final t = tA + ((page - pA) * (tB - tA) / (pB - pA)).round();
    return t;
  }

  /// Converts a text index to a PDF page using binary search and linear interpolation.
  int? textToPdf(int index) {
    if (textIndices.isEmpty) return null;

    final i = _lowerBound(textIndices, index);
    if (i == 0) return pdfPages.first;
    if (i >= textIndices.length) return pdfPages.last;

    final tA = textIndices[i - 1], tB = textIndices[i];
    final pA = pdfPages[i - 1], pB = pdfPages[i];

    if (tB == tA) return pA; // Avoid division by zero

    // Linear interpolation
    final p = pA + ((index - tA) * (pB - pA) / (tB - tA)).round();
    return p;
  }

  /// Custom implementation of lower_bound for binary search on a sorted list.
  int _lowerBound(List<int> a, int x) {
    var lo = 0, hi = a.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (a[mid] < x) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }
}

/// Builds the synchronized anchor map from PDF outline and text Table of Contents.
Future<_PageMap> _buildPageMap(
    PdfBook pdf, List<PdfOutlineNode> outline, TextBook text) async {
  // 1. Collect PDF anchors: (page, normalized_path)
  final anchorsPdf = _collectPdfAnchors(outline);

  // 2. Collect text anchors from TOC: (index, normalized_path)
  final toc = await text.tableOfContents;
  final anchorsText = _collectTextAnchors(toc);

  // 3. Match anchors by the normalized path.
  final pdfPages = <int>[];
  final textIndices = <int>[];
  final mapTextByRef = <String, int>{};

  for (final a in anchorsText) {
    mapTextByRef[a.ref] = a.index;
  }

  for (final p in anchorsPdf) {
    final idx = mapTextByRef[p.ref];
    if (idx != null) {
      // To avoid duplicates which can break interpolation logic
      if (!pdfPages.contains(p.page) && !textIndices.contains(idx)) {
        pdfPages.add(p.page);
        textIndices.add(idx);
      }
    }
  }

  // Ensure the lists are sorted, as matching might break order.
  final zipped =
      List.generate(pdfPages.length, (i) => Tuple(pdfPages[i], textIndices[i]));
  zipped.sort((a, b) => a.item1.compareTo(b.item1));

  final sortedPdfPages = zipped.map((e) => e.item1).toList();
  final sortedTextIndices = zipped.map((e) => e.item2).toList();

  // Fallback: if there are too few matches, add start/end points.
  if (sortedPdfPages.length < 2) {
    if (sortedPdfPages.isEmpty) {
      sortedPdfPages.add(1);
      sortedTextIndices.add(0);
    }
    // Potentially add last page and last index as another anchor.
  }

  return _PageMap(sortedPdfPages, sortedTextIndices);
}

List<({int page, String ref})> _collectPdfAnchors(List<PdfOutlineNode> nodes,
    [String prefix = '']) {
  final List<({int page, String ref})> anchors = [];
  for (final node in nodes) {
    final page = node.dest?.pageNumber;
    if (page != null && page > 0) {
      final currentPath =
          prefix.isEmpty ? node.title.trim() : '$prefix/${node.title.trim()}';
      anchors.add((page: page, ref: _normalize(currentPath)));
      anchors.addAll(_collectPdfAnchors(node.children, currentPath));
    }
  }
  return anchors;
}

List<({int index, String ref})> _collectTextAnchors(List<TocEntry> entries,
    [String prefix = '']) {
  final List<({int index, String ref})> anchors = [];
  for (final entry in entries) {
    final currentPath =
        prefix.isEmpty ? entry.text.trim() : '$prefix/${entry.text.trim()}';
    anchors.add((index: entry.index, ref: _normalize(currentPath)));
    anchors.addAll(_collectTextAnchors(entry.children, currentPath));
  }
  return anchors;
}

/// Normalizes a string for comparison by removing extra whitespace, punctuation, etc.
String _normalize(String s) {
  return s
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s/.-]', unicode: true), '')
      .toLowerCase()
      .trim();
}

// A simple tuple class for sorting pairs.
class Tuple<T1, T2> {
  final T1 item1;
  final T2 item2;
  Tuple(this.item1, this.item2);
}
