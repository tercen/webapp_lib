import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/serializable_component.dart';
import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/definitions/functions.dart';


import 'package:webapp_model/id_element.dart';
import 'package:webapp_model/id_element_table.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_components/mixins/component_cache.dart';
import 'package:webapp_components/widgets/wait_indicator.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/functions/list_utils.dart';

class MultiSelectTableComponent
    with ChangeNotifier, ComponentBase, ComponentCache
    implements SerializableComponent {
  final List<int> selected = [];
  final DataFetchCallback dataFetchCallback;
  final List<String>? excludeColumns;
  List<String> colNames = [];
  final String valueSeparator = "|@|";

  String sortingCol = "";
  String sortDirection = "";
  bool saveState;

  int currentRowHash = 0;

  //Variables useful for cosmetic behavior
  int currentRow = -1;
  WebappTable dataTable = WebappTable();

  MultiSelectTableComponent(id, groupId, componentLabel, this.dataFetchCallback,
      {this.excludeColumns, this.saveState = true}) {
    super.id = id;
    super.groupId = groupId;
    super.componentLabel = componentLabel;
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
    var nameRows = colNames.map((el) {
      return TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: createHeaderCell(el));
    }).toList();
    TableRow row = TableRow(children: [
      const SizedBox(
        width: 30,
      ),
      ...nameRows
    ]);

    return row;
  }



  void setSelectionRow(List<String> selectionValues) {
    currentRowHash = selectionValues.join("").hashCode;
  }

  Widget wrapSelectable(Widget contentWdg, List<String> selectionValues) {
    return InkWell(
      onHover: (value) {
        if (!value) {
          currentRowHash = -1;
        } else {
          setSelectionRow(selectionValues);
        }

        notifyListeners();
      },
      onTap: () {
        var clickedEl = selectionValues.hashCode;
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
    selected.add(el.hashCode);
  }

  void deselect(int el) {
    selected.remove(el.hashCode);
  }

  bool isSelected(int rowHash) {
    return selected.any((e) => e.hashCode == rowHash);
  }

  TableRow createTableRow(List<String> rowEls, {int rowIndex = -1}) {
    Widget selectedWidget = isSelected(rowEls.join().hashCode)
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
      if (rowIndex == currentRow) {
        rowDecoration =  BoxDecoration(color: Styles()["hoverBg"]);
      } else {
        rowDecoration = rowIndex % 2 == 0
            ? BoxDecoration(color: Styles()["evenRow"])
            : BoxDecoration(color: Styles()["oddRow"]);
      }
    }

    var dataRow = rowEls.map((el) {
      return TableCell(
        child: wrapSelectable(
            SizedBox(
                height: 30,
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      el,
                      style: Styles()["text"],
                    ))),
            rowEls),
      );
    }).toList();
    TableRow row = TableRow(
        decoration: rowDecoration, children: [selectedWidget, ...dataRow]);

    return row;
  }

  Widget buildTable(WebappTable table) {
    dataTable = table;
    var nRows = table.nRows;

    colNames = table.colNames;
    if (excludeColumns != null) {
      colNames = colNames.where((e) => !excludeColumns!.contains(e)).toList();
    }

    List<TableRow> rows = [];
    rows.add(createTableHeader(colNames));

    var indices = List<int>.generate(nRows, (i) => i);
    if (sortDirection != "" && sortingCol != "") {
      indices = ListUtils.getSortedIndices(
          table.columns[sortingCol]!);

      if (sortDirection == "desc") {
        indices = indices.reversed.toList();
      }
    }

    for (var si = 0; si < indices.length; si++) {
      var ri = indices[si];
      var rowEls =
          colNames.map((col) => table.columns[col]![ri]).toList();
      rows.add(createTableRow(rowEls, rowIndex: si));
    }

    var tableWidget = Table(
      columnWidths: const {0: FixedColumnWidth(50)},
      children: rows,
    );

    return tableWidget;
  }

  String getCacheKey() {
    var key = "${getId()}${getGroupId()}";

    return key;
  }

  @override
  Widget buildContent(BuildContext context) {
    var cacheKey = getCacheKey();
    if (hasCachedValue(cacheKey)) {
      return buildTable(getCachedValue(cacheKey));
    } else {
      return FutureBuilder(
          future: dataFetchCallback(),
          builder: (context, snapshot) {
            if (snapshot.data != null &&
                snapshot.hasData &&
                snapshot.connectionState != ConnectionState.waiting) {
              addToCache(cacheKey, snapshot.data);
              return buildTable(snapshot.data!);
            } else if (snapshot.hasError) {
              throw Exception(snapshot.error);
            } else {
              return SizedBox(
                  height: 100,
                  child: TercenWaitIndicator()
                      .waitingMessage(suffixMsg: "  Loading Table"));
            }
          });
    }
  }

  WebappTable getValueAsTable() {
    return dataTable.selectByKey(selected);
  }


  @override
  bool isFulfilled() {
    return getValueAsTable().nRows > 0;
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.table;
  }


  @override
  void reset() {
    selected.clear();
  }
  
  @override
  getComponentValue() {
    return dataTable.selectByKey(selected);
  }
  
  @override
  String getStateValue() {
    return selected.map((e) => e.toString()).join("");
  }
  
  @override
  void setComponentValue(value) {
    selected.clear();
    selected.addAll(value);
  }
  
  @override
  void setStateValue(String value) {
    selected.clear();
    selected.addAll( value.split("|").map((e) => int.parse(e)) );
  }
  
  @override
  bool shouldSaveState() {
    return saveState;
  }
  
  @override
  void addUiListener(VoidCallback listener) {
    // TODO: implement addUiListener
  }
}
