import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart' as xml;
import 'dart:convert';

ZipDecoder? _zipDecoder;

/// Processes a run element and returns HTML-formatted text with styling
String _processRun(xml.XmlElement node, {double defaultFontSize = 12}) {
  final rPr = node.getElement('w:rPr');
  final text = node.getElement('w:t')?.innerText ?? '';
  if (text.isEmpty) return '';

  var result = text;

  if (rPr != null) {
    // Font size
    final sz = rPr.getElement('w:sz')?.getAttribute('w:val');
    if (sz != null) {
      final fontSize = double.parse(sz) / 2; // Word uses half-points
      if (fontSize > defaultFontSize) {
        result = '<big>$result</big>';
      } else if (fontSize < defaultFontSize) {
        result = '<small>$result</small>';
      }
    }

    // Font color
    final color = rPr.getElement('w:color')?.getAttribute('w:val');
    if (color != null) {
      result = '<span style="color:#$color">$result</span>';
    }

    // Font family
    final fontFamily = rPr.getElement('w:rFonts')?.getAttribute('w:ascii') ??
        rPr.getElement('w:rFonts')?.getAttribute('w:eastAsia');
    if (fontFamily != null) {
      result = '<span style="font-family:$fontFamily">$result</span>';
    }

    // Underline
    if (rPr.getElement('w:u') != null) {
      result = '<u>$result</u>';
    }

    // Italic
    if (rPr.getElement('w:i') != null) {
      result = '<i>$result</i>';
    }

    // Bold
    if (rPr.getElement('w:b') != null) {
      result = '<b>$result</b>';
    }
  }

  return result;
}

/// Extracts footnotes from the document
Map<String, String> _extractFootnotes(Archive archive) {
  final footnotes = <String, String>{};

  for (final file in archive) {
    if (file.isFile && file.name == 'word/footnotes.xml') {
      final content = utf8.decode(file.content);
      final document = xml.XmlDocument.parse(content);

      final footnoteNodes = document.findAllElements('w:footnote');
      for (final footnote in footnoteNodes) {
        final id = footnote.getAttribute('w:id');
        if (id != null && id != '-1' && id != '0') {
          // Skip automatic footnotes
          final text =
              footnote.findAllElements('w:t').map((e) => e.innerText).join('');
          footnotes[id] = text;
        }
      }
      break;
    }
  }

  return footnotes;
}

/// Converts a docx file to text.
/// Marks up headings, lists, text styling, and includes footnotes after their respective paragraphs
String docxToText(Uint8List bytes, String title) {
  _zipDecoder ??= ZipDecoder();

  final archive = _zipDecoder!.decodeBytes(bytes);
  final footnotes = _extractFootnotes(archive);
  final List<String> list = ['<h1>$title</h1>'];

  for (final file in archive) {
    if (file.isFile && file.name == 'word/document.xml') {
      final fileContent = utf8.decode(file.content);
      final document = xml.XmlDocument.parse(fileContent);

      final paragraphNodes = document.findAllElements('w:p');
      var footnoteCounter = 1;
      var paragraphFootnotes = <String>[];

      for (final paragraph in paragraphNodes) {
        final textNodes = paragraph.findAllElements('w:r');
        var text = '';
        paragraphFootnotes.clear();

        for (final node in textNodes) {
          // Check for footnote reference
          final footnoteRef = node.getElement('w:footnoteReference');
          if (footnoteRef != null) {
            final footnoteId = footnoteRef.getAttribute('w:id');
            if (footnoteId != null && footnotes.containsKey(footnoteId)) {
              text += '<sup>$footnoteCounter</sup>';
              paragraphFootnotes
                  .add('$footnoteCounter) ${footnotes[footnoteId]}');
              footnoteCounter++;
            }
          } else {
            text += _processRun(node);
          }
        }

        // Process paragraph style
        var style = paragraph
            .getElement('w:pPr')
            ?.getElement('w:pStyle')
            ?.getAttribute('w:val');

        // Handle headings
        if (style != null && double.tryParse(style) != null) {
          int styleNum = int.parse(style) + 1;
          text = '<h$styleNum>$text</h$styleNum>';
        }

        // Handle lists
        var numbering = paragraph.getElement('w:pPr')?.getElement('w:numPr');
        if (numbering != null) {
          String? level = numbering.getElement('w:ilvl')?.getAttribute('w:val');
          if (level != null) {
            int levelInt = int.parse(level);
            for (int i = 0; i <= levelInt; i++) {
              text = '<ul><li>$text</li></ul>';
            }
          }
        }

        // Add paragraph with its footnotes
        if (text.trim().isNotEmpty) {
          list.add(text);
          if (paragraphFootnotes.isNotEmpty) {
            list.add(
                '<div class="footnotes"><small>${paragraphFootnotes.join('<br>')}</small></div>');
          }
        }
      }
    }
  }

  return list.join('\n');
}
