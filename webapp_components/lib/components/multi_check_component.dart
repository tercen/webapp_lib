import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/serializable_component.dart';
import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

class MultiCheckComponent
    with ChangeNotifier, ComponentBase
    implements SerializableComponent {
  final List<String> options = [];
  final List<String> selected = [];

  final int columns;
  final bool hasSelectAll;
  bool selectAll;
  late bool allSelected;
  double? columnWidth;
  final bool saveState;

  MultiCheckComponent(id, groupId, componentLabel,
      {this.columns = 5,
      this.hasSelectAll = false,
      this.selectAll = false,
      this.columnWidth,
      this.saveState = true}) {
    super.id = id;
    super.groupId = groupId;
    super.componentLabel = componentLabel;
    allSelected = selectAll;
  }

  void select(String el) {
    if (!selected.contains(el)) {
      selected.add(el);
      if (options.where((e) => selected.contains(e)).length == options.length) {
        allSelected = true;
      }
    }
  }

  void deselect(String el) {
    selected.remove(el);
    allSelected = false;
  }

  Widget checkBox(String name, bool isSelected, {Function? onClick}) {
    bool isSelected = selected.contains(name);
    var checkIcon = IconButton(
        onPressed: () {
          isSelected ? deselect(name) : select(name);

          notifyListeners();
          if (onClick != null) {
            onClick();
          }
        },
        icon: isSelected
            ? const Icon(Icons.check_box_outlined)
            : const Icon(Icons.check_box_outline_blank));

    return Row(
      children: [
        checkIcon,
        Text(
          name,
          style: Styles()["text"],
        )
      ],
    );
  }

  Widget selectAllCheckBox() {
    var checkIcon = IconButton(
        onPressed: () {
          if (!allSelected) {
            for (var opt in options) {
              if (!selected.contains(opt)) {
                select(opt);
              }
            }
            allSelected = true;
          } else {
            for (var opt in options) {
              if (selected.contains(opt)) {
                deselect(opt);
              }
            }
            allSelected = false;
          }

          notifyListeners();
        },
        icon: allSelected
            ? const Icon(Icons.check_box_outlined)
            : const Icon(Icons.check_box_outline_blank));

    return Row(
      children: [
        checkIcon,
        Text(
          "Select All",
          style: Styles()["text"],
        )
      ],
    );
  }

  TableRow createSelectAllRow() {
    int nCols = options.length > columns ? columns : options.length;
    List<Widget> rowWidgets = [];

    rowWidgets.add(selectAllCheckBox());
    for (var ci = 1; ci < nCols; ci++) {
      rowWidgets.add(Container());
    }

    return TableRow(children: rowWidgets);
  }

  Widget buildCheckTable() {
    int nCols = options.length > columns ? columns : options.length;
    int nRows = (options.length / columns).ceil();

    int idx = 0;
    List<TableRow> tableRows = [];
    if (hasSelectAll) {
      tableRows.add(createSelectAllRow());
    }

    for (var ri = 0; ri < nRows; ri++) {
      List<Widget> rowWidgets = [];
      for (var ci = 0; ci < nCols; ci++) {
        if (idx < options.length) {
          rowWidgets.add(checkBox(options[idx], true));
          idx++;
        } else {
          rowWidgets.add(Container());
        }
      }

      tableRows.add(TableRow(children: rowWidgets));
    }

    Map<int, TableColumnWidth>? colWidthMap;
    if (columnWidth != null) {
      colWidthMap = {};
      for (var ci = 0; ci < nCols; ci++) {
        colWidthMap[ci] = FixedColumnWidth(columnWidth!);
      }
    }

    return Table(
      columnWidths: colWidthMap,
      children: tableRows,
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return buildCheckTable();
  }

  void setOptions(List<String> optList) {
    options.clear();

    options.addAll(optList);

    if (selectAll) {
      for (var opt in options) {
        select(opt);
      }
      selectAll = false;
    }
  }

  @override
  bool isFulfilled() {
    return getComponentValue().isNotEmpty;
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.simple;
  }

  @override
  void reset() {
    selected.clear();
  }

  @override
  getComponentValue() {
    return selected;
  }

  @override
  String getStateValue() {
    return selected.join("|@|");
  }

  @override
  void setComponentValue(value) {
    selected.clear();
    selected.addAll(value);
  }

  @override
  void setStateValue(String value) {
    selected.clear();
    selected.addAll(value.split("|@|"));
  }

  @override
  bool shouldSaveState() {
    return saveState;
  }
}
