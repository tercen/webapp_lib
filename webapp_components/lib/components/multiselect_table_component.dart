import 'dart:math';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:webapp_components/abstract/serializable_component.dart';
import 'package:webapp_components/components/fetch_component.dart';
import 'package:webapp_components/definitions/component.dart';

import 'package:webapp_components/extra/infobox.dart';

import 'package:webapp_components/mixins/infobox_component.dart';

import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/functions/list_utils.dart';

class MultiSelectTableComponent extends FetchComponent
    with ComponentInfoBox
    implements SerializableComponent {
  final List<String> selected = [];

  final List<String>? excludeColumns;
  List<String>? hideColumns;
  List<String> colNames = [];
  final String valueSeparator = "|@|";

  String sortingCol = "";
  String sortDirection = "";
  bool saveState;

  String currentRowKey = "";
  int currentRow = -1;

  MultiSelectTableComponent(
      id, groupId, componentLabel, super.dataFetchCallback,
      {this.excludeColumns,
      this.saveState = true,
      this.hideColumns,
      InfoBoxBuilder? infoBoxBuilder,
      cache = true}) {
    super.id = id;
    super.groupId = groupId;
    super.componentLabel = componentLabel;
    super.infoBoxBuilder = infoBoxBuilder;
    useCache = cache;
  }

  @override
  WebappTable postLoad(WebappTable table) {
    var idCol = List<int>.generate(table.nRows, (i) => i)
        .map((row) => const Uuid().v4())
        .toList();
    table.addColumn(".key", data: idCol);
    if (hideColumns == null) {
      hideColumns = [".key"];
    } else {
      hideColumns!.add(".key");
    }
    return table;
  }

  void rotateSortingDirection() {
    if (sortDirection == "desc") {
      sortDirection = "";
    } else if (sortDirection == "asc") {
      sortDirection = "desc";
    } else {
      sortDirection = "asc";
    }
  }

  Widget createHeaderCell(String text) {
    Widget sortingIcon = Container();
    if (sortingCol == text && sortDirection == "asc") {
      sortingIcon = const Icon(Icons.arrow_drop_up);
    }
    if (sortingCol == text && sortDirection == "desc") {
      sortingIcon = const Icon(Icons.arrow_drop_down);
    }

    return SizedBox(
        height: 40,
        child: Column(
          children: [
            Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: 30,
                  child: InkWell(
                    onTap: () {
                      if (sortingCol == text) {
                        rotateSortingDirection();
                      } else {
                        sortingCol = text;
                        sortDirection = "asc";
                      }
                      notifyListeners();
                    },
                    child: Row(
                      children: [
                        Text(
                          text,
                          style: Styles()["textBold"],
                        ),
                        sortingIcon
                      ],
                    ),
                  ),
                )),
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: 1,
                child: Container(
                  color: Colors.grey,
                ),
              ),
            )
          ],
        ));
  }

  TableRow createTableHeader(List<String> colNames) {
    // var infoboxHeader = infoBoxBuilder == null ? createHeaderCell( "I" ): const SizedBox(width: 5,);
    var infoboxHeader = TableCell(child: createHeaderCell(""));
    var nameRows = colNames.map((el) {
      return TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: createHeaderCell(el));
    }).toList();
    TableRow row = TableRow(children: [
      const SizedBox(
        width: 30,
      ),
      infoboxHeader,
      ...nameRows,
    ]);

    return row;
  }

  bool shouldDisplayColumn(String colName) {
    return hideColumns == null || !hideColumns!.contains(colName);
  }

  bool shouldIncludeColumn(String colName) {
    return excludeColumns == null || !excludeColumns!.contains(colName);
  }

  void setSelectionRow(String rowKey) {
    currentRowKey = rowKey;
  }

  Widget wrapSelectable(
      Widget contentWdg, List<String> selectionValues, String rowKey) {
    return InkWell(
      onHover: (value) {
        if (!value) {
          currentRowKey = "";
        } else {
          setSelectionRow(rowKey);
        }

        uiUpdate.value = Random().nextInt(1 << 32 - 1);

        // notifyListeners();
      },
      onTap: () {
        if (isSelected(rowKey)) {
          deselect(rowKey);
        } else {
          select(rowKey);
        }
        notifyListeners();
      },
      child: contentWdg,
    );
  }

  void select(String rowKey) {
    selected.add(rowKey);
  }

  void deselect(String rowKey) {
    selected.remove(rowKey);
  }

  bool isSelected(String rowKey) {
    // print("Checking selection: $selected  vs. {$rowHash} ]");
    return selected.any((e) => e == rowKey);
  }

  TableRow createTableRow(
      BuildContext context, List<String> rowEls, String rowKey,
      {int rowIndex = -1}) {
    Widget selectedWidget = isSelected(rowKey)
        ? const SizedBox(
            width: 30,
            height: 30,
            child: Icon(Icons.check),
          )
        : const SizedBox(
            width: 30,
            height: 30,
          );
    selectedWidget = wrapSelectable(selectedWidget, rowEls, rowKey);

    var rowDecoration = BoxDecoration(color: Styles()["white"]);
    if (rowIndex > -1) {
      if (rowKey == currentRowKey) {
        rowDecoration = BoxDecoration(color: Styles()["hoverBg"]);
      } else {
        rowDecoration = rowIndex % 2 == 0
            ? BoxDecoration(color: Styles()["evenRow"])
            : BoxDecoration(color: Styles()["oddRow"]);
      }
    }

    List<Widget> dataRow = [];

    dataRow.add(TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: buildInfoBoxIcon(rowEls, context, iconCellWidth: 20)));
    for (var ci = 0; ci < colNames.length; ci++) {
      if (shouldDisplayColumn(colNames[ci])) {
        dataRow.add(TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: wrapSelectable(
              SizedBox(
                  height: 30,
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        rowEls[ci],
                        style: Styles()["text"],
                      ))),
              rowEls,
              rowKey),
        ));
      }
    }
    //

    TableRow row = TableRow(
        decoration: rowDecoration, children: [selectedWidget, ...dataRow]);

    return row;
  }

  @override
  Widget createWidget(BuildContext context) {
    // dataTable = table;
    var table = dataTable;
    var nRows = table.nRows;

    colNames = table.colNames
        .where((colName) => shouldIncludeColumn(colName))
        .toList();
    // if (excludeColumns != null) {
    //   colNames = colNames.where((e) => !excludeColumns!.contains(e)).toList();
    // }

    List<TableRow> rows = [];
    rows.add(createTableHeader(
        colNames.where((colName) => shouldDisplayColumn(colName)).toList()));

    var indices = List<int>.generate(nRows, (i) => i);
    if (sortDirection != "" && sortingCol != "") {
      indices = ListUtils.getSortedIndices(table.columns[sortingCol]!);

      if (sortDirection == "desc") {
        indices = indices.reversed.toList();
      }
    }

    for (var si = 0; si < indices.length; si++) {
      var ri = indices[si];
      var key = table.columns[".key"]![ri];
      var rowEls = colNames.map((col) => table.columns[col]![ri]).toList();
      rows.add(createTableRow(context, rowEls, key, rowIndex: si));
    }

    Map<int, TableColumnWidth> colWidths = infoBoxBuilder == null
        ? const {0: FixedColumnWidth(50), 1: FixedColumnWidth(10)}
        : {0: const FixedColumnWidth(50), 1: const FixedColumnWidth(50)};

    var tableWidget = Table(
      columnWidths: colWidths,
      children: rows,
    );

    return tableWidget;
  }

  // @override
  // Future<void> init() async {
  //   if (!isInit) {
  //     super.init();
  //   }
  // }
  // Future<bool> loadTable() async {
  //   if (!isInit) {
  //     busy();
  //     var cacheKey = getCacheKey();
  //     if (hasCachedValue(cacheKey)) {
  //       dataTable = getCachedValue(cacheKey);
  //     } else {
  //       dataTable = await dataFetchCallback();
  //       addToCache(cacheKey, dataTable);
  //     }
  //     idle();
  //   }
  //   return true;
  // }

  @override
  Widget buildContent(BuildContext context) {
    return build(context);
    // if (isBusy) {
    //   return SizedBox(
    //       height: 100,
    //       child: TercenWaitIndicator()
    //           .waitingMessage(suffixMsg: "  Loading Table"));
    // } else {
    //   if (dataTable.nRows == 0) {
    //     return Container();
    //   } else {
    //     return buildTable(dataTable, context);
    //   }
    // }
  }

  @override
  bool isFulfilled() {
    return dataTable.nRows > 0 && selected.isNotEmpty;
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.table;
  }

  @override
  void reset() {
    super.reset();
    selected.clear();
  }

  @override
  getComponentValue() {
    var idx = dataTable.getColumnIndex(".key");
    var rowData =
        dataTable.where((row) => selected.contains(row[idx])).toList();
    var outTbl = WebappTable.fromData(dataTable.colNames, rowData);
    outTbl.removeColumn(".key");
    return outTbl;
  }

  @override
  String getStateValue() {
    return selected.join("|");
  }

  @override
  void setComponentValue(value) {
    selected.clear();
    selected.addAll(value);
  }

  @override
  void setStateValue(String value) {
    if (value != "") {
      selected.clear();

      selected.addAll(value.split("|"));
    }
  }

  @override
  bool shouldSaveState() {
    return saveState;
  }
}
