import 'dart:math';

import 'package:flutter/material.dart';


import 'package:webapp_components/abstract/serializable_component.dart';
import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/definitions/functions.dart';
import 'package:webapp_components/extra/infobox.dart';


import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_components/mixins/component_cache.dart';
import 'package:webapp_components/mixins/infobox_component.dart';
import 'package:webapp_components/widgets/wait_indicator.dart';
import 'package:webapp_model/utils/key_utils.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/functions/list_utils.dart';

class MultiSelectTableComponent
    with ChangeNotifier, ComponentBase, ComponentCache, ComponentInfoBox
    implements SerializableComponent {
  final List<int> selected = [];

  final DataFetchCallback dataFetchCallback;
  final List<String>? excludeColumns;
  final List<String>? hideColumns;
  List<String> colNames = [];
  final String valueSeparator = "|@|";

  

  String sortingCol = "";
  String sortDirection = "";
  bool saveState;
  bool isInit = false;
  int currentRowKey = 0;

  //Variables useful for cosmetic behavior
  int currentRow = -1;
  WebappTable dataTable = WebappTable();

  MultiSelectTableComponent(
      id, groupId, componentLabel, this.dataFetchCallback,
      {this.excludeColumns, this.saveState = true, this.hideColumns, InfoBoxBuilder? infoBoxBuilder}) {
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

  TableRow createTableHeader(List<String> colNames) {
    // var infoboxHeader = infoBoxBuilder == null ? createHeaderCell( "I" ): const SizedBox(width: 5,);
    var infoboxHeader = TableCell(child:createHeaderCell(""));
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

  void setSelectionRow(List<String> selectionValues) {
    currentRowKey = KeyUtils.listToKey(selectionValues);
  }

  Widget wrapSelectable(Widget contentWdg, List<String> selectionValues) {
    return InkWell(
      onHover: (value) {
        
        if (!value) {
          currentRowKey = -1;
        } else {
          setSelectionRow(selectionValues);
        }

        uiUpdate.value = Random().nextInt(1<<32-1);

        // notifyListeners();
      },
      onTap: () {
        var clickedEl = KeyUtils.listToKey(selectionValues);
        if (isSelected(clickedEl)) {
          deselect(clickedEl);
        } else {
          select(clickedEl);
        }
        notifyListeners();
      },
      child: contentWdg,
    );
  }

  void select(int el) {
    selected.add(el);
  }

  void deselect(int el) {
    selected.remove(el);
  }

  bool isSelected(int rowKey) {
    // print("Checking selection: $selected  vs. {$rowHash} ]");
    return selected.any((e) => e == rowKey);
  }

  TableRow createTableRow(BuildContext context, List<String> rowEls,{int rowIndex = -1}) {
    Widget selectedWidget = isSelected(KeyUtils.listToKey(rowEls))
        ? const SizedBox(
            width: 30,
            height: 30,
            child: Icon(Icons.check),
          )
        : const SizedBox(
            width: 30,
            height: 30,
          );
    selectedWidget = wrapSelectable(selectedWidget, rowEls);

    var rowDecoration = BoxDecoration(color: Styles()["white"]);
    if (rowIndex > -1) {
      if (KeyUtils.listToKey(rowEls) == currentRowKey) {
        rowDecoration = BoxDecoration(color: Styles()["hoverBg"]);
      } else {
        rowDecoration = rowIndex % 2 == 0
            ? BoxDecoration(color: Styles()["evenRow"])
            : BoxDecoration(color: Styles()["oddRow"]);
      }
    }

    List<Widget> dataRow = [];

    dataRow.add(TableCell(verticalAlignment: TableCellVerticalAlignment.middle, child:  buildInfoBoxIcon(rowEls, context, iconCellWidth: 20))  );
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
              rowEls),
        ));
      }
    }
    // 
    

    TableRow row = TableRow(
        decoration: rowDecoration, children: [selectedWidget, ...dataRow]);

    return row;
  }

  Widget buildTable(WebappTable table, BuildContext context) {
    dataTable = table;
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
      var rowEls = colNames.map((col) => table.columns[col]![ri]).toList();
      rows.add(createTableRow(context, rowEls, rowIndex: si));
    }

    Map<int, TableColumnWidth> colWidths = infoBoxBuilder == null ? const {0: FixedColumnWidth(50)} :  {0: const FixedColumnWidth(50),1:const FixedColumnWidth(50) };

    var tableWidget = Table(
      columnWidths: colWidths,
      children: rows,
    );

    return tableWidget;
  }

  String getCacheKey() {
    var key = "${getId()}${getGroupId()}";

    return key;
  }

  @override
  Future<void> init() async {
    await super.init();
    await loadTable();

    notifyListeners();
  }
  
  

  Future<bool> loadTable() async{
    if( !isInit ){
      var cacheKey = getCacheKey();
      if (hasCachedValue(cacheKey)) {
        dataTable = getCachedValue(cacheKey);
      }else{
        dataTable = await dataFetchCallback();
        addToCache(cacheKey, dataTable);
      }
    }
    return true;
  }

  @override
  Widget buildContent(BuildContext context) {
    if( dataTable.nRows == 0 ){
                    return SizedBox(
                  height: 100,
                  child: TercenWaitIndicator()
                      .waitingMessage(suffixMsg: "  Loading Table"));
    }else{
      return buildTable(dataTable, context);
    }
  }

  // @override
  // Widget buildContent(BuildContext context) {
  //   print("BUILDING");
  //   var cacheKey = getCacheKey();
  //   if (hasCachedValue(cacheKey)) {
  //     print("\tfrom Cache");
  //     return buildTable(getCachedValue(cacheKey));
  //   } else {
  //     return FutureBuilder(
  //         future: dataFetchCallback(),
  //         builder: (context, snapshot) {
  //           if (snapshot.data != null &&
  //               snapshot.hasData &&
  //               snapshot.connectionState != ConnectionState.waiting) {
  //             print("\tdone Loading");

  //             addToCache(cacheKey, snapshot.data);
  //             return buildTable(snapshot.data!);
  //           } else if (snapshot.hasError) {
  //             throw sci.ServiceError(500, snapshot.error.toString());
  //           } else {
  //             return SizedBox(
  //                 height: 100,
  //                 child: TercenWaitIndicator()
  //                     .waitingMessage(suffixMsg: "  Loading Table"));
  //           }
  //         });
  //   }
  // }

  WebappTable selectByKey(WebappTable tbl, List<int> keys) {
    var outTbl = WebappTable();
    List<List<String>> rows = [];
    for (var row = 0; row < tbl.nRows; row++) {

      var rowHash =
          KeyUtils.listToKey(tbl.columns.values.map((e) => e[row]).toList());
      if (keys.contains(rowHash)) {
        rows.add(tbl.columns.values.map((e) => e[row]).toList());
      }
    }

    for (var col = 0; col < tbl.nCols; col++) {
      outTbl.addColumn(tbl.colNames[col],
          data: rows.map((row) => row[col]).toList());
    }

    return outTbl;
  }

  WebappTable getValueAsTable() {
    // print("dataTable.selectByKey(selected).nRows = ${dataTable.selectByKey(selected).nRows}");
    return selectByKey(dataTable, selected); // dataTable.selectByKey(selected);
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
    selected.clear();
    dataTable = WebappTable();
  }

  @override
  getComponentValue() {
    return selectByKey(dataTable, selected);
  }

  @override
  String getStateValue() {
    return selected.map((e) => e.toString()).join("|");
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
      
      selected.addAll(value.split("|").map((e) => int.parse(e)));
    }
  }

  @override
  bool shouldSaveState() {
    return saveState;
  }
  

}
