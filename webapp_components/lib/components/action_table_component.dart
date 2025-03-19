import 'dart:math';

import 'package:flutter/material.dart';

import 'package:webapp_components/components/multiselect_table_component.dart';

import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/definitions/functions.dart';
import 'package:webapp_components/abstract/multi_value_component.dart';
import 'package:webapp_components/abstract/single_value_component.dart';
import 'package:webapp_components/definitions/list_action.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_model/id_element_table.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_components/mixins/component_cache.dart';
import 'package:webapp_components/widgets/wait_indicator.dart';
import 'package:webapp_model/utils/key_utils.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/functions/list_utils.dart';

class ActionTableComponent extends MultiSelectTableComponent {
  final List<ListAction> actions;
  ActionTableComponent(
      super.id, super.groupId, super.componentLabel, super.dataFetchCallback,
      this.actions,
      {super.excludeColumns,
      super.saveState = false,
      super.hideColumns,
      super.infoBoxBuilder});

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
      },
      onTap: () {
        // Ignore selection

        // var clickedEl = KeyUtils.listToKey(selectionValues);
        // if (isSelected(clickedEl)) {
        //   deselect(clickedEl);
        // } else {
        //   if (selected.isNotEmpty) {
        //     selected.clear();
        //   }
        //   select(clickedEl);
        // }

        // notifyListeners();
      },
      child: contentWdg,
    );
  }
}
