import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/material.dart';

import 'package:syncfusion_flutter_pdf/pdf.dart' as pd;
import 'package:webapp_components/components/list_component.dart';
import 'package:webapp_ui_commons/mixin/progress_log.dart';

class ExportPageContent {
  final String title;
  final dynamic content;
  final String contentType;

  ExportPageContent(this.title, this.content, {this.contentType = "image"});
}

class ImageListComponent extends ListComponent with ProgressDialog{
  final List<dynamic> widgetExportContent = [];

  ImageListComponent(String super.id, String super.groupId,
      String super.componentLabel, super.dataFetchFunc,
      {super.sortByLabel, super.collapsible, super.cache, super.emptyMessage});

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
      var titleSz = font.measureString(content.title);
      var bmp = pd.PdfBitmap(content.content);
      var hMargin = pdfDoc.pageSettings.margins.left+pdfDoc.pageSettings.margins.right;
      var vMargin = pdfDoc.pageSettings.margins.top+pdfDoc.pageSettings.margins.bottom;
      pdfDoc.pageSettings.size =
          Size((bmp.height as double) + titleSz.height + 10 + vMargin, (bmp.width as double)+hMargin);
      if (bmp.height > bmp.width) {
        pdfDoc.pageSettings.orientation = pd.PdfPageOrientation.portrait;
      } else {
        pdfDoc.pageSettings.orientation = pd.PdfPageOrientation.landscape;
      }

      var page = pdfDoc.pages.add();
      

      page.graphics.drawString(content.title, font,
          bounds: Rect.fromLTWH(0, 0, titleSz.width, titleSz.height));
      page.graphics.drawImage(
          bmp,
          Rect.fromLTWH(0, titleSz.height + 10, bmp.width as double,
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

  Widget downloadActionWidget(BuildContext context) {
    return IconButton(
        onPressed: () async {
          openDialog(context, id: this.id );
          log(this.id, "Preparing download. Please wait");

          var pdfDoc = pd.PdfDocument();
          for (var content in widgetExportContent) {
            pdfDoc = addEntryPage(pdfDoc, content);
          }
          await doDownload(pdfDoc);

          closeLog(id: this.id);
        },
        icon: const Icon(Icons.picture_as_pdf));
  }

  @override
  Widget createToolbar(BuildContext context) {
    var sep = const SizedBox(
      width: 15,
    );
    return Row(
      children: [
        wrapActionWidget(expandAllActionWidget()),
        sep,
        wrapActionWidget(collapseAllActionWidget()),
        sep,
        wrapActionWidget(downloadActionWidget(context)),
        sep,
        wrapActionWidget(filterActionWidget(), width: 200),
      ],
    );
  }

  @override
  Widget createWidget(BuildContext context) {
    widgetExportContent.clear();
    expansionControllers.clear();

    String titleColName = dataTable.colNames
        .firstWhere((e) => e.contains("filename"), orElse: () => "");
    String dataColName =
        dataTable.colNames.firstWhere((e) => e.contains("data"), orElse: () => "");

    List<Widget> wdgList = [];

    for (var ri = 0; ri < dataTable.nRows; ri++) {
      var title = dataTable.columns[titleColName]![ri];
      if (shouldIncludeEntry(title)) {
        var imgData =
            Uint8List.fromList(dataTable.columns[dataColName]![ri].codeUnits);
        Widget wdg = createImageListEntry(title, imgData);

        widgetExportContent.add(ExportPageContent(title, imgData));

        if (collapsible == true) {
          wdg = collapsibleWrap(ri, title, wdg);
        }
        wdgList.add(wdg);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [createToolbar(context), ...wdgList],
    );
  }
}
