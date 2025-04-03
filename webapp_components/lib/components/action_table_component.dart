import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_components/components/fetch_component.dart';

import 'package:webapp_components/definitions/component.dart';

import 'package:webapp_components/definitions/list_action.dart';
import 'package:webapp_components/extra/infobox.dart';

import 'package:webapp_components/mixins/infobox_component.dart';

import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

import 'package:uuid/uuid.dart';
import 'package:webapp_utils/functions/list_utils.dart';

class ActionTableComponent extends FetchComponent
    with ComponentInfoBox
    implements Component {
  final List<int> selected = [];

  final List<String>? excludeColumns;
  List<String>? hideColumns;
  List<String> colNames = [];
  final List<ListAction> actions;

  final bool useCache;
  String sortingCol = "";
  String sortDirection = "";

  String currentRowKey = "";
  int currentRow = -1;
  bool shouldSave;

  ActionTableComponent(
      id, groupId, componentLabel, super.dataFetchCallback, this.actions,
      {this.excludeColumns,
      this.hideColumns,
      InfoBoxBuilder? infoBoxBuilder,
      this.useCache = true,
      this.shouldSave = false}) {
    super.id = id;
    super.groupId = groupId;
    super.componentLabel = componentLabel;
    super.infoBoxBuilder = infoBoxBuilder;
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

  bool shouldDisplayColumn(String colName) {
    return hideColumns == null || !hideColumns!.contains(colName);
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

  bool shouldIncludeColumn(String colName) {
    return excludeColumns == null || !excludeColumns!.contains(colName);
  }

  void setSelectionRow(String rowKey) {
    currentRowKey = rowKey;
  }

  TableRow createTableHeader(List<String> colNames) {
    var infoboxHeader = TableCell(child: createHeaderCell(""));
    var actionsHeader = TableCell(child: createHeaderCell("Actions"));
    var nameRows = colNames.map((el) {
      return TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: createHeaderCell(el));
    }).toList();
    TableRow row = TableRow(children: [
      infoboxHeader,
      ...nameRows,
      actionsHeader,
    ]);

    return row;
  }

  TableRow createTableRow(BuildContext context, List<String> rowEls,  String rowKey,
      List<ListAction> rowActions,
      {int rowIndex = -1}) {
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
            child: SizedBox(
                height: 30,
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      rowEls[ci],
                      style: Styles()["text"],
                    )))));
      }
    }
    //

    var actionWidgets = List<Widget>.empty(growable: true);
    for (var action in rowActions) {
      actionWidgets.add(IconButton(
          onPressed: () {
            action.callAction(rowEls, context: context);
          },
          icon: action.getIcon(params: rowEls)));
    }

    TableRow row = TableRow(decoration: rowDecoration, children: [
      ...dataRow,
      Row(
        children: actionWidgets,
      )
    ]);

    return row;
  }

  @override
  Widget createWidget(BuildContext context) {
    var table = dataTable;
    var nRows = table.nRows;

    colNames = table.colNames
        .where((colName) => shouldIncludeColumn(colName))
        .toList();

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
      rows.add(createTableRow(context, rowEls, key, actions, rowIndex: si));
    }

    Map<int, TableColumnWidth> colWidths = infoBoxBuilder == null
        ? const {0: FixedColumnWidth(5)}
        : {0: const FixedColumnWidth(50)};

    var tableWidget = Table(
      columnWidths: colWidths,
      children: rows,
    );

    return tableWidget;
  }

  // @override
  // Future<void> init() async {
  //   await super.init();
  //   await loadTable();

  //   // notifyListeners();
  // }

  // Future<bool> loadTable() async {
  //   if (!isInit) {
  //     busy();

  //     var cacheKey = getCacheKey();
  //     if (hasCachedValue(cacheKey) && useCache) {
  //       dataTable = getCachedValue(cacheKey);
  //     } else {
  //       dataTable = await dataFetchCallback();
  //       if (useCache) {
  //         addToCache(cacheKey, dataTable);
  //       }
  //     }
  //     idle();
  //   }
  //   return true;
  // }

  @override
  Widget buildContent(BuildContext context) {
    return build(context);
    // if (dataTable.nRows == 0) {
    //   if (isIdle) {
    //     return Container();
    //   } else {
    //     return SizedBox(
    //         height: 100,
    //         child: TercenWaitIndicator()
    //             .waitingMessage(suffixMsg: "  Loading Table"));
    //   }
    // } else {
    //   return buildTable(dataTable, context);
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
    return '';
  }

  @override
  void setComponentValue(value) {
    // TODO: implement setComponentValue
  }
}
