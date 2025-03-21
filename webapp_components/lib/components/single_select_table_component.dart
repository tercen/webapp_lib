import 'dart:math';

import 'package:flutter/material.dart';
import 'package:webapp_components/components/multiselect_table_component.dart';


import 'package:webapp_model/utils/key_utils.dart';


class SingleSelectTableComponent extends MultiSelectTableComponent {
  SingleSelectTableComponent(
      super.id, super.groupId, super.componentLabel, super.dataFetchCallback,
      {super.excludeColumns,
      super.saveState = true,
      super.hideColumns,
      super.infoBoxBuilder,
      super.cache = true});

  @override
  Widget wrapSelectable(Widget contentWdg, List<String> selectionValues) {
    return InkWell(
      onHover: (value) {
        if (!value) {
          currentRowKey = -1;
        } else {
          setSelectionRow(selectionValues);
        }
        uiUpdate.value = Random().nextInt(1 << 32 - 1);

        // notifyListeners();
      },
      onTap: () {
        var clickedEl = KeyUtils.listToKey(selectionValues);
        if (isSelected(clickedEl)) {
          deselect(clickedEl);
        } else {
          if (selected.isNotEmpty) {
            selected.clear();
          }
          select(clickedEl);
        }

        notifyListeners();
      },
      child: contentWdg,
    );
  }
}
