import 'package:flutter/material.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/models/books.dart';
import 'package:pdfrx/pdfrx.dart';

/// Represents a node in the hierarchy with its full path
class HierarchyNode<T> {
  final T node;
  final List<String> path;

  HierarchyNode(this.node, this.path);
}

/// Converts a text book page index to the corresponding PDF page number
///
/// [bookTitle] is the title of the book
/// [textIndex] is the index in the text version
/// Returns the corresponding page number in the PDF version, or null if not found
Future<int?> textToPdfPage(TextBook textBook, int textIndex) async {
  final library = await DataRepository.instance.library;

  // Get both text and PDF versions of the book

  final pdfBook = library.findBookByTitle(textBook.title, PdfBook) as PdfBook?;

  if (pdfBook == null) {
    return null;
  }
  // Find the closest TOC entry with its full hierarchy
  final toc = await textBook.tableOfContents;
  final hierarchyNode = _findClosestEntryWithHierarchy(toc, textIndex);
  if (hierarchyNode == null) {
    return null;
  }

  // Find matching outline entry in PDF using the hierarchy
  final outlines =
      await PdfDocument.openFile(pdfBook.path).then((doc) => doc.loadOutline());
  final outlineEntry =
      _findMatchingOutlineByHierarchy(outlines, hierarchyNode.path);

  return outlineEntry?.dest?.pageNumber;
}

/// Converts a PDF page number to the corresponding text book index
///
/// [bookTitle] is the title of the book
/// [pdfPage] is the page number in the PDF version
/// Returns the corresponding index in the text version, or null if not found
Future<int?> pdfToTextPage(PdfBook pdfBook, List<PdfOutlineNode> outline,
    int pdfPage, BuildContext context) async {
  final library = await DataRepository.instance.library;

  // Get both text and PDF versions of the book
  final textBook =
      library.findBookByTitle(pdfBook.title, TextBook) as TextBook?;

  if (textBook == null) {
    return null;
  }

  // Find the outline entry with its full hierarchy

  final hierarchyNode = _findOutlineByPageWithHierarchy(outline, pdfPage);
  if (hierarchyNode == null) {
    return null;
  }

  // Find matching TOC entry using the hierarchy
  final toc = await textBook.tableOfContents;
  final tocEntry = _findMatchingTocByHierarchy(toc, hierarchyNode.path);

  return tocEntry?.index;
}

/// Finds the closest TOC entry before the target index and builds its hierarchy
HierarchyNode<TocEntry>? _findClosestEntryWithHierarchy(
    List<TocEntry> entries, int targetIndex,
    [List<String> currentPath = const []]) {
  HierarchyNode<TocEntry>? closest;

  for (var entry in entries) {
    final path = [...currentPath, entry.text.trim()];

    // Check if this entry is before target and later than current closest
    if (entry.index <= targetIndex &&
        (closest == null || entry.index > closest.node.index)) {
      closest = HierarchyNode(entry, path);
    }

    // Recursively search children with updated path
    final childResult =
        _findClosestEntryWithHierarchy(entry.children, targetIndex, path);
    if (childResult != null &&
        (closest == null || childResult.node.index > closest.node.index)) {
      closest = childResult;
    }
  }

  return closest;
}

/// Finds an outline entry by page number and builds its hierarchy
HierarchyNode<PdfOutlineNode>? _findOutlineByPageWithHierarchy(
    List<PdfOutlineNode> outlines, int targetPage,
    [List<String> currentPath = const []]) {
  for (var outline in outlines) {
    final path = [...currentPath, outline.title.trim()];

    if (outline.dest?.pageNumber == targetPage) {
      return HierarchyNode(outline, path);
    }

    // Recursively search children with updated path
    final result =
        _findOutlineByPageWithHierarchy(outline.children, targetPage, path);
    if (result != null) {
      return result;
    }
  }
  return null;
}

/// Finds a matching outline entry using a hierarchy path
PdfOutlineNode? _findMatchingOutlineByHierarchy(
    List<PdfOutlineNode> outlines, List<String> targetPath,
    [int level = 0]) {
  if (level >= targetPath.length) {
    return null;
  }

  final targetTitle = targetPath[level];

  for (var outline in outlines) {
    if (outline.title.trim() == targetTitle) {
      // If we've reached the last level, this is our match
      if (level == targetPath.length - 1) {
        return outline;
      }

      // Otherwise, search the next level in the children
      final result = _findMatchingOutlineByHierarchy(
          outline.children, targetPath, level + 1);
      if (result != null) {
        return result;
      }
    }
  }

  return null;
}

/// Finds a matching TOC entry using a hierarchy path
TocEntry? _findMatchingTocByHierarchy(
    List<TocEntry> entries, List<String> targetPath,
    [int level = 0]) {
  if (level >= targetPath.length) {
    return null;
  }

  final targetText = targetPath[level];

  for (var entry in entries) {
    if (entry.text.trim() == targetText) {
      // If we've reached the last level, this is our match
      if (level == targetPath.length - 1) {
        return entry;
      }

      // Otherwise, search the next level in the children
      final result =
          _findMatchingTocByHierarchy(entry.children, targetPath, level + 1);
      if (result != null) {
        return result;
      }
    }
  }

  return null;
}
