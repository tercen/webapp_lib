import 'package:flutter/material.dart';

import 'package:webapp_components/abstract/serializable_component.dart';
import 'package:webapp_components/definitions/component.dart';

import 'package:webapp_components/components/fetch_component.dart';
import 'package:webapp_model/webapp_table.dart';

import 'package:webapp_ui_commons/styles/styles.dart';


class DropdownComponent extends FetchComponent
    implements SerializableComponent {
  String selected = "";
  String? cacheKey;
  String displayColumn;
  final bool shouldSave;
  final Future Function(WebappTable rowTable)? onChange;
  final Future<String> Function()? initValue;

  DropdownComponent(
      super.id, super.groupId, super.componentLabel, super.dataFetchFunc, this.displayColumn, 
      {infoBoxBuilder, this.initValue,
      String Function(String, {String id})? pathTransformCallback,
      this.shouldSave = true, this.onChange}) {
    // super.id = id;
    // super.groupId = groupId;
    // super.componentLabel = componentLabel;
  }

  @override
  Widget buildContent(BuildContext context) {
    return build(context);
  }


  @override
  Future<bool> loadTable({bool force = false}) async {
    if (!isInit || force == true) {
      isInit = true;
      busy();
      var cacheKey = getKey();
      if (useCache && cacheObj.hasCachedValue(cacheKey)) {
        dataTable = cacheObj.getCachedValue(cacheKey);
      } else {
        startFuture("dataLoad", dataFetchCallback());

        dataTable = await waitResult("dataLoad"); //  await dataFetchCallback();

        dataTable = postLoad(dataTable);
        if( useCache ){
          cacheObj.addToCache(cacheKey, dataTable);
        }
        
        if( initValue != null ){
          selected = await initValue!();
        }else{
          selected = dataTable[displayColumn].first;
        }
        
      }
      idle();

    }
    return true;
  }
  @override
  Widget createWidget(BuildContext context) {
    if( dataTable.isEmpty ){
      return Container();
    }
    if( selected.isEmpty ){
      selected=dataTable[displayColumn].first;
      if( onChange != null){
      onChange!( dataTable.selectByColValue([displayColumn], [selected]));
      }
    }
    return DropdownButton(
        value: selected,
        items: dataTable[displayColumn]
            .map((val) => DropdownMenuItem<String>(
                value: val,
                child: Text(
                  val,
                  style: Styles()["text"],
                )))
            .toList(),
        onChanged: (String? value) async {
          if( value != null){
            selected = value;
            if( onChange != null){
              onChange!( dataTable.selectByColValue([displayColumn], [value]));
            }
            
            notifyListeners();
          }
          
        });
  }

  bool isSelected(String id) {
    return selected == id;
  }

  @override
  bool isFulfilled() {
    return selected != "";
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.simple; 
  }

  @override
  void reset() {
    selected = "";
    super.reset();
  }

  @override
  getComponentValue() {
    return dataTable.selectByColValue([displayColumn], [selected]);
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
    return shouldSave;
  }
}
