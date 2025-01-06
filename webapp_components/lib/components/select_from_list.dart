import 'package:flutter/material.dart';

import 'package:list_picker/list_picker.dart';
import 'package:webapp_components/abstract/definitions.dart';
import 'package:webapp_components/abstract/single_value_component.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

class SelectFromListComponent with ChangeNotifier, ComponentBase implements SingleValueComponent {
  final List<String> options = [];
  String selectedUser = "";

  SelectFromListComponent(id, groupId, componentLabel, {String? user}){
    super.id = id;
    super.groupId = groupId;
    super.componentLabel = componentLabel;

    if( user != null ){
      selectedUser = user;
    }
  }

  @override
  Widget buildContent(BuildContext context) {
    
    return Row(children: [
      IconButton(
          onPressed: () async {
            String team = (await showPickerDialog(
              context: context,
              label: "",
              items: options,
            ))!;
            selectedUser = team;
            notifyListeners();
          },
          icon: const Icon(Icons.group_add)),
      selectedUser != "" 
          ? Text(
              selectedUser,
              style: Styles.text,
            )
          : Container()
    ]);
  }

  void setOptions(List<String> optList) {
    options.clear();
    options.addAll(optList);
  }




  @override
  bool isFulfilled() {
    return getValue() != "";
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.simple;
  }

  
  @override
  IdElement getValue() {
    return IdElement(selectedUser, selectedUser);
  }

  @override
  setValue(IdElement value) {
    selectedUser = value.label;
  }}
