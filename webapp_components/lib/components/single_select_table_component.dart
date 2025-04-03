import 'dart:math';

import 'package:flutter/material.dart';
import 'package:webapp_components/components/multiselect_table_component.dart';



class SingleSelectTableComponent extends MultiSelectTableComponent {
  SingleSelectTableComponent(
      super.id, super.groupId, super.componentLabel, super.dataFetchCallback,
      {super.excludeColumns,
      super.saveState = true,
      super.hideColumns,
      super.infoBoxBuilder,
      super.cache = true});

  @override
  Widget wrapSelectable(Widget contentWdg, List<String> selectionValues, String rowKey) {
    return InkWell(
      onHover: (value) {
        if (!value) {
          currentRowKey = "";
        } else {
          setSelectionRow(rowKey);
        }
        uiUpdate.value = Random().nextInt(1 << 32 - 1);

        // notifyListeners();
      },
      onTap: () {
        if (isSelected(rowKey)) {
          deselect(rowKey);
        } else {
          if (selected.isNotEmpty) {
            selected.clear();
          }
          select(rowKey);
        }

        notifyListeners();
      },
      child: contentWdg,
    );
  }
}
