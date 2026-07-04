import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerPage extends StatelessWidget {
  final String filePath;
  final String title;

  const PdfViewerPage({super.key, required this.filePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SfPdfViewer.file(
        File(filePath),
        canShowScrollHead: true,
        canShowScrollStatus: true,
      ),
    );
  }
}
