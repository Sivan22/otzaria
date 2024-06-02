/*
 * Copyright (C) 2017, David PHAM-VAN <dev.nfet.net@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart' as fl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:test/test.dart';
import 'package:flutter/services.dart';

void main() {
  test('Pdf Isolate', () async {
    // ignore: sdk_version_since
    final texts = ['kjfkljf', 'dkjdk'];
    fl.WidgetsFlutterBinding.ensureInitialized();
    final font = Font.ttf(await rootBundle
        .load('fonts/NotoSerifHebrew-VariableFont_wdth,wght.ttf'));
    final data = await Isolate.run(() async {
      final pdf = Document(compress: false, pageMode: PdfPageMode.outlines);
      pdf.addPage(MultiPage(
          theme: ThemeData.withFont(
            base: font,
          ),
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: TextDirection.rtl,
          maxPages: 1000000,
          margin: const EdgeInsets.all(3.0),
          pageFormat: PdfPageFormat.a3,
          header: (Context context) {
            return Container(
                alignment: Alignment.topCenter,
                margin: const EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
                child: Text('hello',
                    style: Theme.of(context)
                        .defaultTextStyle
                        .copyWith(color: PdfColors.grey)));
          },
          footer: (Context context) {
            return Container(
                alignment: Alignment.bottomCenter,
                margin: const EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
                child: Text(
                    'עמוד ${context.pageNumber} מתוך ${context.pagesCount} - הודפס מתוכנת אוצריא',
                    style: Theme.of(context)
                        .defaultTextStyle
                        .copyWith(color: PdfColors.grey)));
          },
          build: (Context context) => texts
              .map(
                (i) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Paragraph(
                      text: i.replaceAll('\n', ''),
                      textAlign: TextAlign.justify,
                      style: TextStyle(fontSize: 67, font: font)),
                ),
              )
              .toList()));

      return await pdf.save();
    });

    print('Generated a ${data.length} bytes PDF');
    final file = File('isolate.pdf');
    await file.writeAsBytes(data);
    print('File saved');
  });
}
