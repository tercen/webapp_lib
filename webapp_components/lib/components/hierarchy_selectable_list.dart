import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webapp_components/components/fetch_component.dart';
import 'package:webapp_components/abstract/serializable_component.dart';
import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/extra/infobox.dart';

import 'package:webapp_components/mixins/infobox_component.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

typedef TileBuilderCallback2 = Widget Function(
    BuildContext context, String name, int level,
    {bool isEven, bool bold});

enum SelectionBehavior { none, single, multiLeaf, multi }

class SelectionNode {
  int level;
  String value;

  SelectionNode(this.level, this.value);

  @override
  bool operator ==(Object other) {
    if (other is! SelectionNode) {
      return false;
    }

    if (level != other.level) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => "${level.toString()}_$value".hashCode;

  @override
  String toString() {
    return "$level: $value";
  }

  String toMapString() {
    return "{'level':'$level', 'value':'$value'}";
  }

  static SelectionNode fromMapString(String json) {
    var valMap = jsonDecode(json);
    return SelectionNode(int.parse(valMap['level']), valMap['value']);
  }
}

class HierarchySelectableListComponent extends FetchComponent
    with ComponentInfoBox
    implements SerializableComponent {
  List<SelectionNode> selectedNodes = [];

  final SelectionBehavior selectionBehavior;

  final List<String> columnHierarchy;
  final List<String> expandedLevels = [];

  late TileBuilderCallback2 nonLeafCallback;
  late TileBuilderCallback2 leafCallback;
  int maxLevel = 0;
  final bool shouldSave;


  HierarchySelectableListComponent(id, groupId, componentLabel, super.dataFetchCallback,
      {cache = true,
      this.selectionBehavior = SelectionBehavior.none, 
      this.columnHierarchy = const [],
      InfoBoxBuilder? infoBoxBuilder,
      this.shouldSave = false}) {
    super.id = id;
    super.groupId = groupId;
    super.componentLabel = componentLabel;
    super.infoBoxBuilder = infoBoxBuilder;
    super.useCache = cache;



    maxLevel = columnHierarchy.length - 1;

    if (selectionBehavior == SelectionBehavior.single ||
        selectionBehavior == SelectionBehavior.multi ||
        selectionBehavior == SelectionBehavior.multiLeaf) {
      leafCallback = selectableLeafRowBuilder;
    } else {
      leafCallback = nonSelectableRowBuilder;
    }

    if (selectionBehavior == SelectionBehavior.multi) {
      nonLeafCallback = selectableLeafRowBuilder;
    } else {
      nonLeafCallback = selectableLeafRowBuilder;
    }
  }

  @override
  WebappTable postLoad(WebappTable table) {
    var colNames = table.colNames;
    for (var colName in colNames) {
      if (!columnHierarchy.contains(colName)) {
        table.removeColumn(colName);
      }
    }

    return table;
  }


  @override
  Widget createWidget(BuildContext context) {
    for (var col in columnHierarchy) {
      if (!dataTable.columns.containsKey(col)) {
        print(
            "[WARNING] Column $col is not present in the hierarchical list. Returning blank.");
        return Container();
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: buildWidgetTree(context),
    );
  }

  @override
  Future<void> init() async {
    if (!isInit) {
      super.init();
      expandedLevels.addAll(columnHierarchy);
    }
  }

  @override
  Widget buildContent(BuildContext context) {
    return build(context);
  }

  Widget nonSelectableRowBuilder(BuildContext context, String name, int level,
      {bool isEven = true, bool bold = false}) {
    var row = Row(
      children: [
        // SizedBox(width: 20 ),
        Container(
          height: 30,
          color: isEven ? Styles()["evenRow"] : Styles()["oddRow"],
          child: Text(
            name,
            style: bold ? Styles()["textH2"] : Styles()["text"],
          ),
        )
      ],
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: row,
    );
  }

  bool isSelected(SelectionNode node) {
    return selectedNodes.contains(node);
  }

  void select(SelectionNode node) {
    if (!isSelected(node)) {
      selectedNodes.add(node);
    }
  }

  void deselect(SelectionNode node) {
    selectedNodes.remove(node);
  }

  void selectChildren(WebappTable clickedRow, int level) {
    if (level < maxLevel) {
      var clickedValue = clickedRow[columnHierarchy[level]].first;
      var children =
          dataTable.selectByColValue([columnHierarchy[level]], [clickedValue]);

      for (var i = 0; i < children.nRows; i++) {
        var row = children.select([i]);
        var selectedNode =
            SelectionNode(level + 1, row[columnHierarchy[level + 1]].first);
        select(selectedNode);
        selectChildren(row, level + 1);
      }
    }
  }

  void deselectChildren(WebappTable clickedRow, int level) {
    if (level < maxLevel) {
      var clickedValue = clickedRow[columnHierarchy[level]].first;
      var children =
          dataTable.selectByColValue([columnHierarchy[level]], [clickedValue]);

      for (var i = 0; i < children.nRows; i++) {
        var row = children.select([i]);
        var selectedNode =
            SelectionNode(level + 1, row[columnHierarchy[level + 1]].first);
        deselect(selectedNode);
        deselectChildren(row, level + 1);
      }
    }
  }

  void selectFather(WebappTable clickedRow, int level) {
    if (level > 0) {
      var parentVal = clickedRow[columnHierarchy[level - 1]].first;
      var parentNode = SelectionNode(level - 1, parentVal);
      select(parentNode);
      selectFather(clickedRow, level - 1);
    }
  }

  void checkSiblings(WebappTable clickedRow, int level) {
    if (level > 0) {
      var parentVal = clickedRow[columnHierarchy[level - 1]].first;
      var value = clickedRow[columnHierarchy[level]].first;
      var children =
          dataTable.selectByColValue([columnHierarchy[level - 1]], [parentVal]);

      if (children.every((rowEls) {
        var node = SelectionNode(level, rowEls[level]);
        return rowEls[level] == value || !isSelected(node);
      })) {
        var parentNode = SelectionNode(level - 1, parentVal);
        deselect(parentNode);
      }
    }
  }

  Widget buildSelectableEntry(BuildContext context, String name, int level,
      {bool bold = false}) {
    var colName = columnHierarchy[level];
    var clickedRow = dataTable.selectByColValue([colName], [name]);
    var selectedNode = SelectionNode(level, name);

    var textWdg = Text(
      name,
      style: bold ? Styles()["textH2"] : Styles()["text"],
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
            value: isSelected(selectedNode),
            checkColor: Styles()["black"],
            side: WidgetStateBorderSide.resolveWith((states) => BorderSide(
                  color: Styles()["black"],
                  width: 1.5,
                )),
            fillColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
              return Styles()["clear"];
            }),
            onChanged: (value) {
              if (value == true) {
                if (selectionBehavior == SelectionBehavior.single) {
                  selectedNodes.clear();
                }

                select(selectedNode);

                if (selectionBehavior == SelectionBehavior.multi) {
                  selectFather(clickedRow, level);
                  selectChildren(clickedRow, level);
                }
              } else {
                deselect(selectedNode);

                if (selectionBehavior == SelectionBehavior.multi) {
                  checkSiblings(clickedRow, level);
                  deselectChildren(clickedRow, level);
                }
              }
              notifyListeners();
            }),
        const SizedBox(
          width: 5,
        ),
        textWdg
      ],
    );
  }

  WebappTable selectedAsTable() {
    var level = maxLevel;

    var nodes = selectedNodes
        .where((node) => node.level == level)
        .map((node) => node.value)
        .toList();
    var rows = dataTable.where((row) => nodes.contains(row[level])).toList();
    var tbl = WebappTable();
    for (int i = 0; i <= maxLevel; i++) {
      tbl.addColumn(columnHierarchy[i],
          data: rows.map((row) => row[i]).toList());
    }

    return tbl;
  }

  Widget selectableLeafRowBuilder(BuildContext context, String name, int level,
      {bool isEven = true, bool bold = false}) {
    var row = Row(
      children: [
        Container(
          height: 30,
          color: isEven ? Styles()["evenRow"] : Styles()["oddRow"],
          child: buildSelectableEntry(context, name, level),
        )
      ],
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: row,
    );
  }

  List<Widget> buildWidgetTree(BuildContext context) {
    return createWidgets(context, 0);
  }

  Widget createTabulatedEntry(int level, Widget wdg, {bool isEven = false}) {
    var clr = isEven ? Styles()["evenRow"] : Styles()["oddRow"];
    var offset = (level == 0 ? 0 : 50) as double;
    var row = Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        constraints: BoxConstraints(minWidth: level * 50 + offset),
      ),
      Flexible(child: wdg)
    ]);

    return Container(
      color: clr,
      child: row,
    );
  }

  List<String> getLevelList(int level, String? parent) {
    if (level == 0 || parent == null) {
      return dataTable[columnHierarchy[level]].toSet().toList();
    } else {
      return dataTable
          .selectByColValue(
              [columnHierarchy[level - 1]], [parent])[columnHierarchy[level]]
          .toSet()
          .toList();
    }
  }

  List<Widget> createWidgets(BuildContext context, int level,
      {String? parentId}) {
    List<Widget> wdg = [];
    List<String> levelList = getLevelList(level, parentId);

    var levelColumn = columnHierarchy[level];
    for (var ri = 0; ri < levelList.length; ri++) {
      if (level == maxLevel) {
        wdg.add(createTabulatedEntry(level,
            leafCallback(context, levelList[ri], level, isEven: ri % 2 == 0),
            isEven: ri % 2 == 0));
      } else {
        wdg.add(createTabulatedEntry(
            level,
            ExpansionTile(
              controlAffinity: ListTileControlAffinity.leading,
              initiallyExpanded: expandedLevels.contains(levelColumn),
              title: nonLeafCallback(context, levelList[ri], level,
                  isEven: ri % 2 == 0, bold: true),
              children:
                  createWidgets(context, level + 1, parentId: levelList[ri]),
            ),
            isEven: ri % 2 == 0));
      }
    }

    return wdg;
  }

  @override
  void reset() {
    selectedNodes.clear();
    super.reset();
    // cancelAllOperations();
    // isInit = false;
    // init();
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.list;
  }

  @override
  getComponentValue() {
    return selectedAsTable();
  }

  @override
  String getStateValue() {
    List<String> stateValues = [];

    for (var node in selectedNodes) {
      stateValues.add(node.toMapString());
    }
    return stateValues.join("|@|");
  }

  @override
  bool isFulfilled() {
    return selectedNodes.isNotEmpty;
  }

  @override
  void setComponentValue(value) {}

  @override
  void setStateValue(String value) {
    var nodeStrings = value.split("|@|");
    for (var v in nodeStrings) {
      selectedNodes.add(SelectionNode.fromMapString(v));
    }
  }

  @override
  bool shouldSaveState() {
    return shouldSave;
  }
}
