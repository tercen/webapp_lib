import 'package:flutter/material.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_model/id_element_table.dart';
import 'package:webapp_components/components/hierarchy_list.dart';
import 'package:webapp_components/mixins/infobox_component.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

mixin LeafSelectionList on HierarchyList, ComponentInfoBox, ChangeNotifier {
  @override
  void load(IdElementTable idElementTable, List<String> hierarchy,
      List<IdElement> selection,
      {infoBoxBuilder, Map<String, String> titles = const {}}) {
    super.clearLists();
    super.load(idElementTable, hierarchy, selection, titles: titles);

    super.multiSelection = false;
    super.infoBoxBuilder = infoBoxBuilder;

    nonLeafCallback = _nonLeafLevelWidget;
    leafCallback = _leafWidget;
  }

  Widget _leafWidget(
      BuildContext context, String id, String name, int row, int level,
      {bool isEven = true}) {
    return Container(
        // color: isEven ? Styles.evenRow : Styles.oddRow,
        height: 50,
        child: _workflowRowWidget(context, id, name, row, level));
  }

  Widget _nonLeafLevelWidget(
      BuildContext context, String id, String name, int row, int level,
      {bool isEven = true}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        name,
        style: Styles.textH2,
      ),
    );
  }

  Widget _workflowRowWidget(
      BuildContext context, String id, String name, int row, int level) {
    var isElSelected = isSelected(IdElement(id, name));

    Widget selectedMarkWdg = isElSelected
        ? const SizedBox(
            width: 50,
            child: Icon(Icons.check),
          )
        : const SizedBox(
            width: 50,
          );

    var rowWidget = Row(
      children: [
        selectedMarkWdg,
        buildInfoBoxIcon(id, name, context),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            name.split("/").last,
            style: Styles.text,
          ),
        )
      ],
    );
    return InkWell(
      onTap: () {
        isElSelected ? deselect(id) : select(id, name);

        notifyListeners();
      },
      child: rowWidget,
    );
  }
}
