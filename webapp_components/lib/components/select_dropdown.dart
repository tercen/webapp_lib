import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/serializable_component.dart';


import 'package:webapp_components/definitions/component.dart';

import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

class SelectDropDownComponent
    with ChangeNotifier, ComponentBase
    implements SerializableComponent {
  final List<String> options = [];
  String selected = "";
  final bool saveState;
  SelectDropDownComponent(id, groupId, componentLabel, {this.saveState = true}) {
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
        items: options.map<DropdownMenuItem>((String value) {
          return DropdownMenuItem(
            value: value,
            child: Text(
              value,
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

  void setOptions(List<String> optList) {
    options.clear();
    options.addAll(optList);
  }


  @override
  bool isFulfilled() {
    return getComponentValue() != "";
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.simple;
  }

  
  @override
  getComponentValue() {
    return selected;
  }
  
  @override
  String getStateValue() {
    return selected;
  }
  
  @override
  void setComponentValue(value) {
    selected = value;
  }
  
  @override
  void setStateValue(String value) {
    selected = value;
  }
  
  @override
  bool shouldSaveState() {
    return saveState;
  }
  

}
