import 'dart:io';
import 'dart:isolate';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PrintingScreen extends StatefulWidget {
  final Future<String> data;
  final bool removeNikud;
  final int startLine;
  const PrintingScreen(
      {Key? key,
      required this.data,
      this.startLine = 0,
      this.removeNikud = false})
      : super(key: key);
  @override
  State<PrintingScreen> createState() => _PrintingScreenState();
}

class _PrintingScreenState extends State<PrintingScreen> {
  double fontSize = 15.0;
  String fontName = 'NotoSerifHebrew';
  late int startLine;
  late int endLine;
  late Future<Uint8List> pdf;
  pw.PageOrientation orientation = pw.PageOrientation.portrait;
  PdfPageFormat format = PdfPageFormat.a4;
  double pageMargin = 20.0;

  @override
  void initState() {
    super.initState();
    startLine = widget.startLine;
    endLine = startLine + 3;
    pdf = createPdf(format);
  }

  @override
  void setState(VoidCallback fn) {
    pdf = createPdf(format);
    if (mounted) {
      super.setState(fn);
    }
  }

  void printPdf() {
    Printing.layoutPdf(onLayout: createPdf);
  }

  Future<Uint8List> createPdf(PdfPageFormat format) async {
    final font = pw.Font.ttf(await rootBundle.load(fonts[fontName]!));
    String dataString = await widget.data;
    if (orientation == pw.PageOrientation.landscape) {
      format = format.landscape;
    }
    if (widget.removeNikud) {
      dataString = removeVolwels(dataString);
    }
    List<String> data = stripHtmlIfNeeded(dataString).split('\n').toList();
    final pageMargin = this.pageMargin;
    final fontSize = this.fontSize;

    final bookName = data[0];
    data = data.getRange(startLine, endLine).toList();

    final result = await Isolate.run(() async {
      final pdfData =
          pw.Document(compress: false, pageMode: PdfPageMode.outlines);
      pdfData.addPage(pw.MultiPage(
          theme: pw.ThemeData.withFont(
            base: font,
          ),
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          textDirection: pw.TextDirection.rtl,
          maxPages: 1000000,
          margin: pw.EdgeInsets.all(
            pageMargin,
          ),
          pageFormat: format,
          header: (pw.Context context) {
            return pw.Container(
                alignment: pw.Alignment.topCenter,
                margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
                child: pw.Text(bookName,
                    style: pw.Theme.of(context)
                        .defaultTextStyle
                        .copyWith(color: PdfColors.grey)));
          },
          footer: (pw.Context context) {
            return pw.Container(
                alignment: pw.Alignment.bottomCenter,
                margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
                child: pw.Text(
                    'עמוד ${context.pageNumber} מתוך ${context.pagesCount} - הודפס מתוכנת אוצריא',
                    style: pw.Theme.of(context)
                        .defaultTextStyle
                        .copyWith(color: PdfColors.grey)));
          },
          build: (pw.Context context) => data
              .map(
                (i) => pw.Padding(
                  padding: const pw.EdgeInsets.all(8.0),
                  child: pw.Paragraph(
                      text: i.replaceAll('\n', ''),
                      textAlign: pw.TextAlign.justify,
                      style: pw.TextStyle(fontSize: fontSize, font: font)),
                ),
              )
              .toList()));

      return await pdfData.save();
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('הדפסה'),
        actions: [
          IconButton(
            onPressed: () async {
              final path = await FilePicker.platform.saveFile(
                  dialogTitle: "שמירת קובץ PDF", allowedExtensions: ['pdf']);
              if (path != null) {
                final file = File('$path.pdf');
                await file.writeAsBytes(await pdf);
              }
            },
            icon: const Icon(Icons.save),
            tooltip: 'שמירה כקובץ PDF',
          ),
          IconButton(
            onPressed: () async {
              //display dialog to choose the pages to print

              await Printing.layoutPdf(
                usePrinterSettings: true,
                onLayout: (PdfPageFormat format) async => pdf,
                format: format,
              );
            },
            icon: const Icon(Icons.print),
            tooltip: 'הדפסה',
          ),
        ],
      ),
      body: FutureBuilder(
        future: widget.data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Row(children: [
              SizedBox.fromSize(
                size: const Size.fromWidth(350),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    showValueIndicator: ShowValueIndicator.always,
                  ),
                  child: Column(
                    children: [
                      Text('טווח הדפסה',
                          style: Theme.of(context).textTheme.labelLarge),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: RangeSlider(
                          min: 0.0,
                          max: snapshot.data!.split('\n').length.toDouble(),
                          labels:
                              RangeLabels('${startLine + 1}', "${endLine + 1}"),
                          values: RangeValues(
                              startLine.toDouble(), endLine.toDouble()),
                          onChanged: (value) {
                            startLine = value.start.toInt();
                            endLine = value.end.toInt();
                            setState(() {});
                          },
                        ),
                      ),
                      Text('גודל גופן',
                          style: Theme.of(context).textTheme.labelLarge),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Slider(
                          value: fontSize,
                          min: 10.0,
                          max: 50.0,
                          onChanged: (value) {
                            setState(() {
                              fontSize = value;
                            });
                          },
                        ),
                      ),
                      Text('שוליים',
                          style: Theme.of(context).textTheme.labelLarge),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Slider(
                          value: pageMargin,
                          min: 10.0,
                          max: 100.0,
                          onChanged: (value) {
                            setState(() {
                              pageMargin = value;
                            });
                          },
                        ),
                      ),
                      Text('גופן',
                          style: Theme.of(context).textTheme.labelLarge),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: DropdownButton<String>(
                          value: fontName,
                          onChanged: (String? value) {
                            fontName = value!;
                            setState(() {});
                          },
                          items: <String>[
                            'Tinos',
                            'TaameyDavidCLM',
                            'TaameyAshkenaz',
                            'NotoSerifHebrew',
                            'FrankRuehlCLM',
                            'KeterYG',
                            'Shofar',
                            'NotoRashiHebrew',
                            'Rubik'
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                      Text('פריסה',
                          style: Theme.of(context).textTheme.labelLarge),
                      DropDownSettingsTile<PdfPageFormat>(
                          title: 'גודל עמוד',
                          settingKey: 'key-page-sizw',
                          selected: format,
                          values: formats,
                          onChange: (value) {
                            format = value;
                            setState(() {});
                          }),

                      // Text('גודל עמוד',
                      //     style: Theme.of(context).textTheme.labelLarge),
                      // Padding(
                      //   padding: const EdgeInsets.all(8.0),
                      //   child: DropdownButton<String>(
                      //     value: formats.keys
                      //         .firstWhere((k) => formats[k] == format),
                      //     onChanged: (String? value) {
                      //       setState(() {
                      //         format = formats[value!]!;
                      //       });
                      //     },
                      //     items: formats.keys
                      //         .map<DropdownMenuItem<String>>((String value) {
                      //       return DropdownMenuItem<String>(
                      //         value: value,
                      //         child: Text(value),
                      //       );
                      //     }).toList(),
                      //   ),

                      DropDownSettingsTile(
                        title: 'כיוון',
                        settingKey: 'orientation',
                        selected: pw.PageOrientation.portrait,
                        values: const {
                          pw.PageOrientation.portrait: 'לאורך',
                          pw.PageOrientation.landscape: 'לרוחב',
                        },
                        onChange: (value) {
                          orientation = value;
                          setState(() {});
                        },
                      ),
                      // DropdownButton<String>(
                      //   value: orientation == pw.PageOrientation.portrait
                      //       ? 'לאורך'
                      //       : 'לרוחב',
                      //   onChanged: (String? value) {
                      //     setState(() {
                      //       orientation = value == 'לאורך'
                      //           ? pw.PageOrientation.portrait
                      //           : pw.PageOrientation.landscape;
                      //     });
                      //   },
                      //   items: <String>[
                      //     'לאורך',
                      //     'לרוחב',
                      //   ].map<DropdownMenuItem<String>>((String value) {
                      //     return DropdownMenuItem<String>(
                      //       value: value,
                      //       child: Text(value),
                      //     );
                      //   }).toList(),
                      // ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder(
                    future: pdf,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return PdfViewer.data(snapshot.data!,
                            sourceName: 'printing');
                      }
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }),
                // child: PdfPreview(
                //   dpi: 10,
                //   build: (format) => pdf,
                //   allowSharing: false,
                //   actions: [
                //     PdfPreviewAction(
                //       icon: const Icon(Icons.save),
                //       onPressed: _saveAsFile,
                //     )
                //   ],
                //   actionBarTheme: PdfActionBarTheme(
                //       backgroundColor: Theme.of(context).primaryColor),
                // ),
              )
            ]);
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  final Map<String, String> fonts = {
    'Tinos': 'fonts/Tinos-Regular.ttf',
    'TaameyDavidCLM': 'fonts/TaameyDavidCLM-Medium.ttf',
    'TaameyAshkenaz': 'fonts/TaameyAshkenaz-Medium.ttf',
    'NotoSerifHebrew': 'fonts/NotoSerifHebrew-VariableFont_wdth,wght.ttf',
    'FrankRuehlCLM': 'fonts/FrankRuehlCLM-Medium.ttf',
    'KeterYG': 'fonts/KeterYG-Medium.ttf',
    'Shofar': 'fonts/ShofarRegular.ttf',
    'NotoRashiHebrew': 'fonts/NotoRashiHebrew-VariableFont_wght.ttf',
    'Rubik': 'fonts/Rubik-VariableFont_wght.ttf',
  };

  final Map<PdfPageFormat, String> formats = {
    PdfPageFormat.a4: 'A4',
    PdfPageFormat.letter: 'Letter',
    PdfPageFormat.legal: 'Legal',
    PdfPageFormat.a5: 'A5',
    PdfPageFormat.a3: 'A3',
  };
}
