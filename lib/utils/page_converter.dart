import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/books.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

/// Converts a text book page index to the corresponding PDF page number
///
/// [bookTitle] is the title of the book
/// [textIndex] is the index in the text version
/// Returns the corresponding page number in the PDF version, or null if not found
Future<int?> textToPdfPage(
    String bookTitle, int textIndex, BuildContext context) async {
  final appModel = Provider.of<AppModel>(context, listen: false);

  // Get both text and PDF versions of the book
  final textBook = (await appModel.library).findBookByTitle(bookTitle, TextBook)
      as TextBook?;
  final pdfBook =
      (await appModel.library).findBookByTitle(bookTitle, PdfBook) as PdfBook?;

  if (textBook == null || pdfBook == null) {
    return null;
  }

  // Get the TOC entry for the text index
  final toc = await textBook.tableOfContents;
  final tocEntry = _findLastEntryBeforeIndex(toc, textIndex);
  if (tocEntry == null) {
    return null;
  }

  // Find matching outline entry in PDF
  final outlines =
      await PdfDocument.openFile(pdfBook.path).then((doc) => doc.loadOutline());
  final outlineEntry = _findMatchingOutline(outlines, tocEntry);

  return outlineEntry?.dest?.pageNumber;
}

/// Converts a PDF page number to the corresponding text book index
///
/// [bookTitle] is the title of the book
/// [pdfPage] is the page number in the PDF version
/// Returns the corresponding index in the text version, or null if not found
Future<int?> pdfToTextPage(
    String bookTitle, int pdfPage, BuildContext context) async {
  final appModel = Provider.of<AppModel>(context, listen: false);

  // Get both text and PDF versions of the book
  final textBook = (await appModel.library).findBookByTitle(bookTitle, TextBook)
      as TextBook?;
  final pdfBook =
      (await appModel.library).findBookByTitle(bookTitle, PdfBook) as PdfBook?;

  if (textBook == null || pdfBook == null) {
    return null;
  }

  // Get the outline entry for the PDF page
  final outlines =
      await PdfDocument.openFile(pdfBook.path).then((doc) => doc.loadOutline());
  final outlineEntry = _findOutlineByPage(outlines, pdfPage);
  if (outlineEntry == null) {
    return null;
  }

  // Find matching TOC entry in text book
  final toc = await textBook.tableOfContents;
  final tocEntry = _findMatchingTocEntry(toc, outlineEntry);

  return tocEntry?.index;
}

TocEntry? _findLastEntryBeforeIndex(List<TocEntry> entries, int targetIndex) {
  TocEntry? lastBefore;

  for (var entry in entries) {
    // Check if this entry is before target and later than current lastBefore
    if (entry.index <= targetIndex &&
        (lastBefore == null || entry.index > lastBefore.index)) {
      lastBefore = entry;
    }

    // Recursively search children
    final childResult = _findLastEntryBeforeIndex(entry.children, targetIndex);
    if (childResult != null &&
        (lastBefore == null || childResult.index > lastBefore.index)) {
      lastBefore = childResult;
    }
  }

  return lastBefore;
}

List<String> _getHierarchy(PdfOutlineNode node, List<PdfOutlineNode> outlines) {
  List<String> hierarchy = [node.title];
  PdfOutlineNode? current = node;

  while (current != null) {
    PdfOutlineNode? parent = _findParentNode(current, outlines);
    if (parent != null) {
      hierarchy.insert(0, parent.title);
    }
    current = parent;
  }

  return hierarchy;
}

List<String> _getTocHierarchy(TocEntry entry, List<TocEntry> entries) {
  List<String> hierarchy = [entry.text];
  TocEntry? current = entry;

  while (current != null) {
    TocEntry? parent = _findTocParent(current, entries);
    if (parent != null) {
      hierarchy.insert(0, parent.text);
    }
    current = parent;
  }

  return hierarchy;
}

PdfOutlineNode? _findParentNode(
    PdfOutlineNode child, List<PdfOutlineNode> nodes) {
  for (var node in nodes) {
    if (node.children.contains(child)) {
      return node;
    }
    final result = _findParentNode(child, node.children);
    if (result != null) {
      return result;
    }
  }
  return null;
}

TocEntry? _findTocParent(TocEntry child, List<TocEntry> entries) {
  for (var entry in entries) {
    if (entry.children.contains(child)) {
      return entry;
    }
    final result = _findTocParent(child, entry.children);
    if (result != null) {
      return result;
    }
  }
  return null;
}

PdfOutlineNode? _findMatchingOutline(
    List<PdfOutlineNode> outlines, TocEntry tocEntry) {
  final tocHierarchy = _getTocHierarchy(tocEntry, []);

  for (var outline in outlines) {
    final outlineHierarchy = _getHierarchy(outline, outlines);

    if (_compareHierarchies(tocHierarchy, outlineHierarchy)) {
      return outline;
    }

    // Recursively search children
    final result = _findMatchingOutline(outline.children, tocEntry);
    if (result != null) {
      return result;
    }
  }
  return null;
}

PdfOutlineNode? _findOutlineByPage(
    List<PdfOutlineNode> outlines, int targetPage) {
  for (var outline in outlines) {
    if (outline.dest?.pageNumber == targetPage) {
      return outline;
    }
    // Recursively search children
    final result = _findOutlineByPage(outline.children, targetPage);
    if (result != null) {
      return result;
    }
  }
  return null;
}

TocEntry? _findMatchingTocEntry(
    List<TocEntry> entries, PdfOutlineNode outlineNode) {
  final outlineHierarchy = _getHierarchy(outlineNode, []);

  for (var entry in entries) {
    final tocHierarchy = _getTocHierarchy(entry, entries);

    if (_compareHierarchies(tocHierarchy, outlineHierarchy)) {
      return entry;
    }

    // Recursively search children
    final result = _findMatchingTocEntry(entry.children, outlineNode);
    if (result != null) {
      return result;
    }
  }
  return null;
}

bool _compareHierarchies(List<String> hierarchy1, List<String> hierarchy2) {
  if (hierarchy1.length != hierarchy2.length) {
    return false;
  }

  for (int i = 0; i < hierarchy1.length; i++) {
    // Normalize strings by trimming whitespace and control characters
    final str1 = hierarchy1[i].trim();
    final str2 = hierarchy2[i].trim();

    // Compare normalized strings
    if (str1 != str2) {
      return false;
    }
  }

  return true;
}
