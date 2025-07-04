import 'package:flutter/material.dart';

import 'package:list_picker/list_picker.dart';
import 'package:webapp_components/abstract/serializable_component.dart';
import 'package:webapp_components/components/fetch_component.dart';
import 'package:webapp_components/definitions/component.dart';

import 'package:webapp_ui_commons/styles/styles.dart';

class SelectFromListComponent extends FetchComponent
    implements SerializableComponent {
  final List<String> options = [];
  String selectedUser = "";
  final bool shouldSave;
  final String displayColumn;

  SelectFromListComponent(super.id, super.groupId, super.componentLabel, super.dataFetchFunc, this.displayColumn,
      {String? user, this.shouldSave = true}) {
    if (user != null) {
      selectedUser = user;
    }
  }


  @override
  Widget buildContent(BuildContext context) {
    return build(context);
  }


  @override
  Widget createWidget(BuildContext context) {
    return Row(children: [
      IconButton(
          onPressed: () async {
            String team = (await showPickerDialog(
              context: context,
              label: "",
              items: dataTable[displayColumn],
            )) ?? selectedUser;
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
    return getComponentValue() != "";
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
    return shouldSave;
  }
}
