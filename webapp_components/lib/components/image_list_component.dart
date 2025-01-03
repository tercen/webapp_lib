import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/material.dart';

import 'package:syncfusion_flutter_pdf/pdf.dart' as pd;
import 'package:webapp_components/commons/id_element_table.dart';
import 'package:webapp_components/components/list_component.dart';

class ExportPageContent {
  final String title;
  final dynamic content;
  final String contentType;

  ExportPageContent(this.title, this.content, {this.contentType = "image"});
}

class ImageListComponent extends ListComponent {
  final List<dynamic> widgetExportContent = [];

  ImageListComponent(String super.id, String super.groupId,
      String super.componentLabel, super.dataFetchFunc,
      {super.sortByLabel, super.collapsible});

  Widget createImageListEntry(String title, Uint8List data) {
    return Image.memory(
      data,
      fit: BoxFit.fitHeight,
      scale: 0.6,
    );
  }

  pd.PdfDocument addEntryPage(pd.PdfDocument pdfDoc, dynamic content) {
    if (content is ExportPageContent) {
      var font = pd.PdfStandardFont(pd.PdfFontFamily.helvetica, 40);

      var bmp = pd.PdfBitmap(content.content);
      pdfDoc.pageSettings.size =
          Size(bmp.height as double, bmp.width as double);
      if (bmp.height > bmp.width) {
        pdfDoc.pageSettings.orientation = pd.PdfPageOrientation.portrait;
      } else {
        pdfDoc.pageSettings.orientation = pd.PdfPageOrientation.landscape;
      }

      var page = pdfDoc.pages.add();
      var titleSz = font.measureString(content.title);

      page.graphics.drawString(content.title, font,
          bounds: Rect.fromLTWH(0, 0, titleSz.width, titleSz.height));
      page.graphics.drawImage(
          bmp,
          Rect.fromLTWH(0, titleSz.height + 15, bmp.width as double,
              bmp.height as double));
    }

    return pdfDoc;
  }

  Future<void> doDownload(pd.PdfDocument pdfDoc) async {
    List<int> saveBytes = List.from(await pdfDoc.save());
    pdfDoc.dispose();
    const mimetype = "application/octet-stream";
    const filename = "analysis_report.pdf";
    var base64Bytes = base64.encode(saveBytes);

    html.AnchorElement(href: 'data:$mimetype;base64,$base64Bytes')
      ..target = 'blank'
      ..download = filename
      ..click();
  }

  Widget downloadActionWidget() {
    return IconButton(
        onPressed: () async {
          isBusy = true;
          notifyListeners();
          var pdfDoc = pd.PdfDocument();
          for (var content in widgetExportContent) {
            pdfDoc = addEntryPage(pdfDoc, content);
          }
          await doDownload(pdfDoc);
          // await Future.delayed(Duration(seconds: 3));
          isBusy = false;
          notifyListeners();
        },
        icon: const Icon(Icons.picture_as_pdf));
  }

  @override
  Widget createToolbar() {
    var sep = const SizedBox(
      width: 15,
    );
    return Row(
      children: [
        wrapActionWidget(expandAllActionWidget()),
        sep,
        wrapActionWidget(collapseAllActionWidget()),
        sep,
        wrapActionWidget(downloadActionWidget()),
        sep,
        wrapActionWidget(filterActionWidget(), width: 200),
      ],
    );
  }

  @override
  Widget createWidget(BuildContext context, IdElementTable table) {
    widgetExportContent.clear();
    expansionControllers.clear();

    String titleColName = table.colNames
        .firstWhere((e) => e.contains("filename"), orElse: () => "");
    String dataColName =
        table.colNames.firstWhere((e) => e.contains("data"), orElse: () => "");

    List<Widget> wdgList = [];

    for (var ri = 0; ri < table.nRows(); ri++) {
      var title = table.columns[titleColName]![ri].label;
      if (shouldIncludeEntry(title)) {
        var imgData =
            Uint8List.fromList(table.columns[dataColName]![ri].label.codeUnits);
        Widget wdg = createImageListEntry(title, imgData);

        widgetExportContent.add(ExportPageContent(title, imgData));

        if (collapsible == true) {
          wdg = collapsibleWrap(title, wdg);
        }
        wdgList.add(wdg);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [createToolbar(), ...wdgList],
    );
  }
}
