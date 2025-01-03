import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/definitions.dart';
import 'package:webapp_components/abstract/multi_value_component.dart';
import 'package:webapp_components/abstract/single_value_component.dart';
import 'package:webapp_components/commons/id_element.dart';
import 'package:webapp_components/commons/id_element_table.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_components/mixins/component_cache.dart';
import 'package:webapp_components/widgets/wait_indicator.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/list_utils.dart';



class MultiSelectTableComponent
    with ChangeNotifier, ComponentBase, ComponentCache
    implements MultiValueComponent {
  final List<IdElement> selected = [];
  final DataFetchCallback dataFetchCallback;
  final List<String>? excludeColumns;
  List<String> colNames = [];
  final String valueSeparator = "|@|";

  String sortingCol = "";
  String sortDirection = "";

  //Variables useful for cosmetic behavior
  int currentRow = -1;
  IdElementTable dataTable = IdElementTable();

  MultiSelectTableComponent(id, groupId, componentLabel, this.dataFetchCallback,
      {this.excludeColumns}) {
    super.id = id;
    super.groupId = groupId;
    super.componentLabel = componentLabel;
  }

  void _rotateSortingDirection() {
    if (sortDirection == "desc") {
      sortDirection = "";
    } else if (sortDirection == "asc") {
      sortDirection = "desc";
    } else {
      sortDirection = "asc";
    }
  }

  Widget _createHeaderCell(String text) {
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
                        _rotateSortingDirection();
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
                          style: Styles.textBold,
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
          child: _createHeaderCell(el));
    }).toList();
    TableRow row = TableRow(children: [
      const SizedBox(
        width: 30,
      ),
      ...nameRows
    ]);

    return row;
  }

  List<IdElement> _idElementToLine(IdElement value) {
    if (!value.id.startsWith("MV")) {
      throw Exception(
          "TableComponent _idElementToLine error. ${value.id}:${value.label} ");
    }

    var ids = value.id.replaceFirst("MV", "").split(valueSeparator);
    var labels = value.label.split(valueSeparator);

    List<IdElement> elLine = [];
    for (var i = 0; i < ids.length; i++) {
      elLine.add(IdElement(ids[i], labels[i]));
    }

    return elLine;
  }

  IdElement _lineToIdElement(List<IdElement> values) {
    String id = "MV${values.map((e) => e.id).join(valueSeparator)}";
    String value = values.map((e) => e.id).join(valueSeparator);

    return IdElement(id, value);
  }

  void _setSelectionRow(List<IdElement> selectionValues) {
    var nRows = dataTable.nRows();
    currentRow = -1;
    for (var ri = 0; ri < nRows; ri++) {
      List<IdElement> rowEls =
          colNames.map((col) => dataTable.columns[col]![ri]).toList();
      var lineEl = _lineToIdElement(rowEls);
      if (lineEl.id == _lineToIdElement(selectionValues).id) {
        currentRow = ri;
      }
    }
  }

  Widget _wrapSelectable(Widget contentWdg, List<IdElement> selectionValues) {
    return InkWell(
      onHover: (value) {
        if (!value) {
          currentRow = -1;
        } else {
          _setSelectionRow(selectionValues);
        }

        notifyListeners();
      },
      onTap: () {
        var clickedEl = _lineToIdElement(selectionValues);
        if (_isSelected(selectionValues)) {
          _deselect(clickedEl);
        } else {
          _select(clickedEl);
        }
        notifyListeners();
      },
      child: contentWdg,
    );
  }

  void _select(IdElement el) {
    selected.add(el);
  }

  void _deselect(IdElement el) {
    selected.remove(el);
  }

  bool _isSelected(List<IdElement> rowEls) {
    var lineEl = _lineToIdElement(rowEls);

    return selected.any((e) => e.id == lineEl.id);
  }

  TableRow createTableRow(List<IdElement> rowEls, {int rowIndex = -1}) {
    Widget selectedWidget = _isSelected(rowEls)
        ? const SizedBox(
            width: 30,
            height: 30,
            child: Icon(Icons.check),
          )
        : const SizedBox(
            width: 30,
            height: 30,
          );
    selectedWidget = _wrapSelectable(selectedWidget, rowEls);

    var rowDecoration = const BoxDecoration(color: Colors.white);
    if (rowIndex > -1) {
      if (rowIndex == currentRow) {
        rowDecoration = const BoxDecoration(color: Styles.hoverBg);
      } else {
        rowDecoration = rowIndex % 2 == 0
            ? const BoxDecoration(color: Styles.evenRow)
            : const BoxDecoration(color: Styles.oddRow);
      }
    }

    var dataRow = rowEls.map((el) {
      return TableCell(
        child: _wrapSelectable(
            SizedBox(
                height: 30,
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      el.label,
                      style: Styles.text,
                    ))),
            rowEls),
      );
    }).toList();
    TableRow row = TableRow(
        decoration: rowDecoration, children: [selectedWidget, ...dataRow]);

    return row;
  }

  Widget buildTable(IdElementTable table) {
    dataTable = table;
    var nRows = table.nRows();

    colNames = table.colNames;
    if (excludeColumns != null) {
      colNames = colNames.where((e) => !excludeColumns!.contains(e)).toList();
    }

    List<TableRow> rows = [];
    rows.add(createTableHeader(colNames));

    var indices = List<int>.generate(nRows, (i) => i);
    if (sortDirection != "" && sortingCol != "") {
      indices = ListUtils.getSortedIndices(table.columns[sortingCol]!.map((e) => e.label).toList());

      if (sortDirection == "desc") {
        indices = indices.reversed.toList();
      }
    }

    for (var si = 0; si < indices.length; si++) {
      var ri = indices[si];
      List<IdElement> rowEls =
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
    for (var a in ancestors) {
      if (a is SingleValueComponent) {
        key = "$key${a.getValue().id}";
      }
    }
    return key;
  }

  @override
  Widget buildContent(BuildContext context) {
    var cacheKey = getCacheKey();
    if (hasCachedValue(cacheKey)) {
      return buildTable(getCachedValue(cacheKey));
    } else {
      return FutureBuilder(
          future: dataFetchCallback(getParentIds(), groupId),
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
                child: TercenWaitIndicator().waitingMessage(suffixMsg: "  Loading Table")
              );

            }
          });
    }
  }

  IdElementTable getValueAsTable() {
    IdElementTable tbl = IdElementTable();

    for (var colName in colNames) {
      tbl.addColumn(colName);
    }

    for (var row in selected) {
      var els = _idElementToLine(row);
      for (var ci = 0; ci < els.length; ci++) {
        tbl.columns[colNames[ci]]!.add(els[ci]);
      }
    }

    return tbl;
  }

  @override
  getValue() {
    return selected;
  }

  @override
  bool isFulfilled() {
    return getValue().isNotEmpty;
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.table;
  }

  @override
  void setValue(List<IdElement> value) {
    selected.clear();
    selected.addAll(value);
  }

  @override
  void reset() {
    selected.clear();
  }
}
