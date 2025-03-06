import 'package:flutter/material.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_model/id_element_table.dart';

import 'package:webapp_components/mixins/infobox_component.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

typedef TileBuilderCallback = Widget Function(
    BuildContext context, String id, String name, int row, int col,
    {bool isEven});

//TODO Add option to sort
class HierarchyList extends ComponentInfoBox {
  List<IdElement> selectedElements = [];

  late IdElementTable table;
  late int maxDepth;

  final List<String> columnHierarchy = [];
  final List<String> expandedLevels = [];
  final List<List<IdElement>> hierarchicalList = [];

  bool multiSelection = true;

  late TileBuilderCallback nonLeafCallback;
  late TileBuilderCallback leafCallback;

  void clearLists() {
    columnHierarchy.clear();
    expandedLevels.clear();
    hierarchicalList.clear();
  }

  void load(IdElementTable idElementTable, List<String> hierarchy,
      List<IdElement> selection,
      {Map<String, String> titles = const {}}) {
    selectedElements = selection;
    multiSelection = true;

    for (var titleEntry in titles.entries) {
      var colIdx = hierarchy.indexOf(titleEntry.key);
      if (colIdx > 0) {
        List<IdElement> proxyCol = [];
        for (var ri = 0; ri < idElementTable.nRows(); ri++) {
          proxyCol.add(IdElement("", titleEntry.value));
        }
        String colKey = "${titleEntry.key}_TITLE";
        expandedLevels.add(colKey);
        idElementTable.addColumn(colKey, data: proxyCol);
        columnHierarchy.insert(colIdx, colKey);
      }
    }

    table = idElementTable;
    columnHierarchy.addAll(hierarchy);

    for (var colName in hierarchy) {
      List<IdElement> els = table.columns[colName]!;
      hierarchicalList.add(els);
    }
    maxDepth = hierarchicalList.length - 1;
  }

  List<int> findIndices(List l, String value) {
    List<int> indices = [];

    for (var i = 0; i < l.length; i++) {
      if (l[i] == value) {
        indices.add(i);
      }
    }

    return indices;
  }


  void deselect(String id) {
    var tmpEls =
        List<IdElement>.from(selectedElements.where((e) => e.id != id));
    selectedElements.clear();
    selectedElements.addAll(tmpEls);
  }

  void select(String id, String name) {
    if (!multiSelection) {
      selectedElements.clear();
    }
    selectedElements.add(IdElement(id, name));
  }

  List<IdElement> getSelectionParentByChildColumn(String colName) {
    int level = columnHierarchy.indexWhere((e) => e == colName);

    if (level == -1) {
      throw Exception(
          "Column $colName not found in HierarchyList.getSelectionParent");
    }
    int parentLevel = level - 1;

    if (parentLevel < 0) {
      return [];
    }

    var parentElements = table.columns[table.colNames[parentLevel]]!;
    var childElements = table.columns[table.colNames[level]]!;

    var nRows = table.nRows();

    List<IdElement> els = [];
    for (var ri = 0; ri < nRows; ri++) {
      if (isSelected(childElements[ri])) {
        els.add(parentElements[ri]);
      }
    }

    return els;
  }

  List<Widget> createWidgets(BuildContext context, int level,
      {String? parentId}) {
    List<String> addedIds = [];
    List<Widget> wdg = [];
    List<IdElement> levelList = hierarchicalList[level];

    var levelColumn = columnHierarchy[level];
    for (var ri = 0; ri < levelList.length; ri++) {
      var idEl = levelList[ri];
      // CHeck if belongs to parent
      if (level > 0) {
        var pId = hierarchicalList[level - 1][ri].id;
        if (parentId != null && pId != parentId) {
          continue;
        }
      }

      if (!addedIds.contains(idEl.id)) {
        addedIds.add(idEl.id);

        if (level == maxDepth) {
          wdg.add(createTabulatedEntry(
              level,
              leafCallback(context, idEl.id, idEl.label, ri, level,
                  isEven: ri % 2 == 0),
              isEven: ri % 2 == 0));
        } else {
          wdg.add(createTabulatedEntry(
              level,
              ExpansionTile(
                initiallyExpanded: expandedLevels.contains(levelColumn),
                title: nonLeafCallback(context, idEl.id, idEl.label, ri, level,
                    isEven: ri % 2 == 0),
                children: createWidgets(context, level + 1, parentId: idEl.id),
              ),
              isEven: ri % 2 == 0));
        }
      }
    }

    return wdg;
  }

  List<IdElement> getAllChildren(int parentLevel, String parentId) {
    List<IdElement> children = [];

    if (parentLevel < maxDepth) {
      var parentList = hierarchicalList[parentLevel];
      var childList = hierarchicalList[parentLevel + 1];

      for (var i = 0; i < childList.length; i++) {
        if (parentList[i].id == parentId) {
          children.add(childList[i]);
        }
      }
    }

    return children;
  }

  bool isSelected(IdElement el) {
    for (var e in selectedElements) {
      if (e.id == el.id) {
        return true;
      }
    }
    return false;
  }

  Widget createTabulatedEntry(int level, Widget wdg, {bool isEven = false}) {
    var clr = isEven ? Styles()["evenRow"] : Styles()["oddRow"];
    var row = Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        constraints: BoxConstraints(minWidth: level * 50),
      ),
      Flexible(child: wdg)
    ]);

    return Container(
      color: clr,
      child: row,
    );
  }

  List<Widget> buildWidgetTree(BuildContext context) {
    return createWidgets(context, 0);
  }
}
