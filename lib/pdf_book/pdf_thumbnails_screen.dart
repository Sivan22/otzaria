//
// Super simple thumbnails view
//
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class ThumbnailsView extends StatelessWidget {
  const ThumbnailsView({super.key, this.controller});

  final PdfViewerController? controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      child: controller?.isReady != true || controller?.documentRef == null
          ? null
          : PdfDocumentViewBuilder(
              documentRef: controller!.documentRef,
              builder: (context, document) => ListView.builder(
                itemCount: document?.pages.length ?? 0,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.all(8),
                    height: 240,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 220,
                          child: InkWell(
                            onTap: () => controller!.goToPage(
                              pageNumber: index + 1,
                            ),
                            child: PdfPageView(
                              document: document,
                              pageNumber: index + 1,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                        Text(
                          '${index + 1}',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
