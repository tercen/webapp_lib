import 'package:flutter/material.dart';

import 'package:list_picker/list_picker.dart';
import 'package:webapp_components/abstract/serializable_component.dart';
import 'package:webapp_components/definitions/component.dart';

import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_components/mixins/input_validator.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

class SelectFromListComponent with ChangeNotifier, ComponentBase, InputValidator implements SerializableComponent {
  final List<String> options = [];
  String selectedUser = "";
  final bool saveState;
  SelectFromListComponent(id, groupId, componentLabel, {String? user, this.saveState = true}){
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
              style: Styles()["text"],
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
    return getComponentValue() != "" && isInputValid( getComponentValue() );
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.simple;
  }


  
  @override
  getComponentValue() {
    return selectedUser;
  }
  
  @override
  String getStateValue() {
    return selectedUser;
  }
  
  @override
  void setComponentValue(value) {
    selectedUser = value;
  }
  
  @override
  void setStateValue(String value) {
    selectedUser = value;
  }
  
  @override
  bool shouldSaveState() {
    return saveState;
  }
  
  @override
  void addUiListener(VoidCallback listener) {
    // TODO: implement addUiListener
  }}
