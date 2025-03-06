import 'package:flutter/material.dart';

import 'package:webapp_components/abstract/single_value_component.dart';
import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

class SelectDropDownComponent
    with ChangeNotifier, ComponentBase
    implements SingleValueComponent {
  final List<IdElement> options = [];
  IdElement selected = IdElement("", "");

  SelectDropDownComponent(id, groupId, componentLabel) {
    super.id = id;
    super.groupId = groupId;
    super.componentLabel = componentLabel;
  }

  @override
  Widget buildContent(BuildContext context) {
    var wdg = DropdownButton(
        borderRadius: Styles()["borderRounding"],
        value: selected,
        icon: const Icon(Icons.arrow_downward),
        focusColor: Colors.transparent,
        items: options.map<DropdownMenuItem>((IdElement value) {
          return DropdownMenuItem(
            value: value,
            child: Text(
              value.label,
              style: Styles()["text"],
            ),
          );
        }).toList(),
        onChanged: (var value) {
          selected = value;
          notifyListeners();
        });

    return wdg;
  }

  void setOptions(List<IdElement> optList) {
    options.clear();
    options.addAll(optList);
  }

  @override
  getValue() {
    return selected;
  }

  @override
  bool isFulfilled() {
    return getValue().id != "";
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.simple;
  }

  @override
  void setValue(IdElement value) {
    selected = value;
  }
}
