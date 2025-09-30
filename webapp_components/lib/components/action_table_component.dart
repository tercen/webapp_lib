import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_components/components/fetch_component.dart';

import 'package:webapp_components/definitions/component.dart';

import 'package:webapp_components/definitions/list_action.dart';
import 'package:webapp_components/extra/infobox.dart';
import 'package:webapp_components/extra/row_color_formatter.dart';

import 'package:webapp_components/mixins/infobox_component.dart';

import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

import 'package:uuid/uuid.dart';
import 'package:webapp_utils/functions/list_utils.dart';

typedef RowFilterFunction = bool Function(WebappTable rowData);

class RowFilter {
  final RowFilterFunction filter;
  final Icon iconOn;
  final Icon iconOff;
  final String? tooltip;
  bool isOn = false;

  RowFilter(
      {required this.filter,
      required this.iconOn,
      required this.iconOff,
      this.tooltip});

  void toggle() {
    isOn = !isOn;
  }
}

class ActionTableComponent extends FetchComponent
    with ComponentInfoBox
    implements Component {
  final List<int> selected = [];

  final List<String>? excludeColumns;
  List<String>? hideColumns;
  List<String> colNames = [];
  final List<ListAction> actions;
  final List<RowFilter> rowFilters;

  RowTextColorFormatter? rowFormatter;

  String sortingCol = "";
  String sortDirection = "";

  String currentRowKey = "";
  int currentRow = -1;
  bool shouldSave;

  ActionTableComponent(
      super.id, super.groupId, super.componentLabel, super.dataFetchCallback, this.actions,
      {this.excludeColumns,
      this.hideColumns,
      InfoBoxBuilder? infoBoxBuilder,
      cache = true,
      this.rowFormatter,
      this.shouldSave = false,
      this.rowFilters = const []}) {
    // super.id = id;
    // super.groupId = groupId;
    // super.componentLabel = componentLabel;
    super.infoBoxBuilder = infoBoxBuilder;
    super.useCache = cache;
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


  TableRow createTableRow(BuildContext context, WebappTable rowEls, 
      String rowKey, List<ListAction> rowActions, 
      {int rowIndex = -1, List<String> displayCols = const []}) {
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

    final cols = displayCols.isEmpty ? colNames : displayCols;

    for (var ci = 0; ci < cols.length; ci++) {
      if (shouldDisplayColumn(cols[ci])) {
        var rowStyle = Styles()["text"];
        if (rowFormatter != null && rowFormatter!.shouldHighlight(rowEls)) {
          rowStyle = rowFormatter!.highlightStyle();
        }

        dataRow.add(TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  rowEls[cols[ci]].first,
                  style: rowStyle,
                ))));
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
        children: actionWidgets.isEmpty ? [Container()] : actionWidgets,
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

    var widths = <double>[];
    var di = 0;
    for (var si = 0; si < indices.length; si++) {
      var ri = indices[si];
      var key = table.columns[".key"]![ri];
      
      var displayEls = colNames
          .where((col) => col != "Id")
          .where((col) => col != ".key")
          .map((col) => table.columns[col]![ri])
          .toList();
      if (widths.isEmpty) {
        widths.addAll(displayEls.map((el) => el.length as double));

        // widths = widths.map((w) => (w/totalWidth) * 0.9).toList();
      } else {
        var tmp = displayEls.map((el) => el.length as double).toList();

        for (var k = 0; k < widths.length; k++) {
          widths[k] = widths[k] + tmp[k];
        }
      }

      var displayRow = true;
      for (var filter in rowFilters) {
        if (filter.isOn) {
          displayRow = displayRow && filter.filter(table.select([ri]));
        }
      }

      if (displayRow) {
        rows.add(createTableRow(context, table.select([ri]), key, actions,  rowIndex: di));
        di = di + 1;
      }
    }

    var totalWidth = widths.reduce((a, b) => a + b);
    final relativeWidth = widths.map((w) => (w / totalWidth) * 0.95).toList();

    Map<int, TableColumnWidth> colWidths = infoBoxBuilder == null
        ? {0: const FixedColumnWidth(5)}
        : {0: const FixedColumnWidth(50)};

    for (var k = 0; k < relativeWidth.length; k++) {
      colWidths[k + 1] = FractionColumnWidth(relativeWidth[k]);
    }

    var tableWidget = Table(
      columnWidths: colWidths,
      children: rows,
    );

    if (rowFilters.isNotEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [createFilterRow(), tableWidget],
      );
    } else {
      return tableWidget;
    }
  }

  Widget createFilterRow() {
    var wdgList = <Widget>[];
    for (var f in rowFilters) {
      wdgList.add(IconButton(
        icon: f.isOn ? f.iconOn : f.iconOff,
        tooltip: f.tooltip,
        onPressed: () {
          f.toggle();
          notifyListeners();
        },
      ));
    }
    return Row(
      children: wdgList,
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return build(context);
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
  void setComponentValue(value) {}
}
