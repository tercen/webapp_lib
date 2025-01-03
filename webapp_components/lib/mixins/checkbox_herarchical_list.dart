import 'package:flutter/material.dart';

import 'package:webapp_components/commons/id_element.dart';
import 'package:webapp_components/commons/id_element_table.dart';
import 'package:webapp_components/components/hierarchy_list.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

// mixin LeafSelectionList on HierarchyList, ChangeNotifier{
mixin CheckboxHerarchicalList on HierarchyList, ChangeNotifier {
  @override
  load(IdElementTable idElementTable, List<String> hierarchy,
      List<IdElement> selection,
      {Map<String, String> titles = const {}}) {
    super.clearLists();
    super.load(idElementTable, hierarchy, selection, titles: titles);

    // super.columnHierarchy.addAll(hierarchy);

    nonLeafCallback = _checkboxRowWidget;
    leafCallback = _checkboxRowWidget;

    // for( var colName in columnHierarchy ){
    //   List<IdElement> els = table.columns[colName]!;
    //   hierarchicalList.add(els);
    // }
    // maxDepth = hierarchicalList.length-1;
  }

  bool _anyChildSelected(int parentLevel, String parentId) {
    for (var child in getAllChildren(parentLevel, parentId)) {
      if (isSelected(child)) {
        return true;
      }
    }

    return false;
  }

  void _checkParentSelection(
      int row, int level, bool isElSelected, String childId) {
    if (level > 0) {
      var parent = hierarchicalList[level - 1][row];
      var parentIsSelected = isSelected(parent);

      if (!parentIsSelected && isElSelected) {
        select(parent.id, parent.label);
      }

      if (parentIsSelected && !isElSelected) {
        if (!_anyChildSelected(level - 1, parent.id)) {
          deselect(parent.id);
        }
      }
    }
  }

  void _checkChildrenSelection(int level, bool isElSelected, String parentId) {
    var children = getAllChildren(level, parentId);

    for (var child in children) {
      if (isElSelected) {
        select(child.id, child.label);
      } else {
        deselect(child.id);
      }
    }
  }

  IconButton _checkBoxWidget(
      String id, String name, int row, int level, bool isSelected,
      {Function? onClick}) {
    return IconButton(
        onPressed: () {
          isSelected ? deselect(id) : select(id, name);

          _checkParentSelection(row, level, !isSelected, id);
          _checkChildrenSelection(level, !isSelected, id);

          // notifyListeners();
          if (onClick != null) {
            onClick();
          }
          notifyListeners();
        },
        icon: isSelected
            ? const Icon(Icons.check_box_outlined)
            : const Icon(Icons.check_box_outline_blank));
  }

  Row _checkboxRowWidget(
      BuildContext context, String id, String name, int row, int level,
      {bool isEven = true}) {
    var isElSelected = isSelected(IdElement(id, name));

    return Row(
      children: [
        SizedBox(
            width: 50,
            child: _checkBoxWidget(id, name, row, level, isElSelected)),
        Container(
          height: 20,
          color: isEven ? Styles.evenRow : Styles.oddRow,
          child: Text(
            name,
            style: Styles.text,
          ),
        )
      ],
    );
  }
}
