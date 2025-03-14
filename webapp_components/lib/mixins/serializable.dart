import 'dart:math';

import 'package:flutter/material.dart';
import 'package:webapp_components/commons/component_data.dart';

mixin Serializable {
  final List<ComponentData> componentData = [];
  ValueNotifier updateTrack = ValueNotifier<int>(0);
  static const String LIST_BREAK = "|@|";


  void initValue(String id, String screenId, List<String> values, {bool notify = true}) {
    setValue(id, screenId, values, notify: notify);
  }

  void setValue(String id, String screenId, List<String> values, {bool notify = false}) {
    componentData.clear();
    componentData.add(ComponentData(id: id, key: screenId, values: values));

    if(notify){
      updateTrack.value = Random().nextInt(1<<32-1);
    }
    
  }

  void addValues(String id, String screenId, List<String> values, {bool notify = false}) {
    for (var cd in componentData) {
      if (cd.key == id) {
        cd.values.addAll(values);
      }
    }
    componentData.add(ComponentData(id: screenId, key: id, values: values));
    if(notify){
      updateTrack.value = Random().nextInt(1<<32-1);
    }
  }

  List<String> getValues(String id, String screenId) {
    return componentData
        .firstWhere(
          (data) => data.key == id && data.id == screenId,
          orElse: () => ComponentData(id: screenId, key: id, values: []),
        )
        .values;
  }

  String getValuesAsString(String id, String screenId) {
    return componentData
        .firstWhere(
          (data) => data.key == id && data.id == screenId,
          orElse: () => ComponentData(id: screenId, key: id, values: []),
        )
        .values
        .join(Serializable.LIST_BREAK);
  }
}
