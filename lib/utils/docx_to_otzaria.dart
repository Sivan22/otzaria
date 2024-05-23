import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart' as xml;
import 'dart:convert';

ZipDecoder? _zipDecoder;

/// Converts a docx file to text.
/// marks up headings and lists
String docxToText(Uint8List bytes, String title) {
  _zipDecoder ??= ZipDecoder();

  final archive = _zipDecoder!.decodeBytes(bytes);

  final List<String> list = ['<h1>$title</h1>'];

  for (final file in archive) {
    if (file.isFile && file.name == 'word/document.xml') {
      final fileContent = utf8.decode(file.content);
      final document = xml.XmlDocument.parse(fileContent);

      final paragraphNodes = document.findAllElements('w:p');

      for (final paragraph in paragraphNodes) {
        final textNodes = paragraph.findAllElements('w:t');
        var text = textNodes.map((node) => node.innerText).join();

        //mark up headings
        var style = paragraph
            .getElement('w:pPr')
            ?.getElement('w:pStyle')
            ?.getAttribute('w:val');
        //if val is a number, that means it is a heading
        if (style != null && double.tryParse(style) != null) {
          int styleNum = int.parse(style) + 1;
          text = '<h$styleNum>$text</h$styleNum>';
        }

        //mark up lists
        //get the numbering level
        var numbering = paragraph.getElement('w:pPr')?.getElement('w:numPr');
        if (numbering != null) {
          String? level = numbering.getElement('w:ilvl')?.getAttribute('w:val');
          if (level != null) {
            // indent the text with the correct amount of spaces (0 for first level)
            int levelInt = int.parse(level);
            text = '• $text';
            for (int i = 0; i < levelInt; i++) {
              text = '\t$text';
            }
          } 
        }
        list.add(text);
      }
    }
  }

  return list.join('\n');
}
