import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/serializable_component.dart';
import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_components/widgets/widget_builder.dart';

class BooleanComponent with ChangeNotifier, ComponentBase implements SerializableComponent {

  bool selected;
  bool shouldSave;

  BooleanComponent( id, groupId, componentLabel, { this.selected = false, this.shouldSave = true} ){
    super.id = id;
    super.groupId = groupId;
    super.componentLabel = componentLabel;
  }

  void onClick(Map<String, dynamic> params, bool newCheckValue ){
    
    selected = newCheckValue;
    notifyListeners();
  }


  @override
  void reset() {
    selected = false;
  }

  @override
  Widget buildContent(BuildContext context) {
    return CommonWidgets.checkbox(selected, onClick, {});
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
    return selected ? "t" : "f";
  }

  @override
  bool isFulfilled() {
    return selected == true;
  }

  @override
  void setComponentValue(value) {
    selected = value;
  }

  @override
  void setStateValue(String value) {
    selected = value == "t" ? true : false;
  }

  @override
  bool shouldSaveState() {
    return shouldSave;
  }
}