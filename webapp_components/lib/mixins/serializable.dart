import 'dart:math';

import 'package:flutter/material.dart';
import 'package:webapp_components/commons/component_data.dart';

mixin Serializable {
  final List<ComponentData> componentData = [];
  ValueNotifier updateTrack = ValueNotifier<int>(0);
  static const String LIST_BREAK = "|@|";


  void initValue(String screenId, String key, List<String> values, {bool notify = true}) {
    setValue(screenId, key, values, notify: notify);
  }

  void setValue(String screenId, String key, List<String> values, {bool notify = false}) {
    print("NEW Value ${values}");
    componentData.clear();
    componentData.add(ComponentData(id: screenId, key: key, values: values));

    if(notify){
      updateTrack.value = Random().nextInt(1<<32-1);
    }
    
  }

  void addValues(String key, String screenId, List<String> values, {bool notify = false}) {
    for (var cd in componentData) {
      if (cd.key == key) {
        cd.values.addAll(values);
      }
    }
    componentData.add(ComponentData(id: screenId, key: key, values: values));
    if(notify){
      updateTrack.value = Random().nextInt(1<<32-1);
    }
  }

  List<String> getValues(String key, String screenId) {
    return componentData
        .firstWhere(
          (data) => data.key == key && data.id == screenId,
          orElse: () => ComponentData(id: screenId, key: key, values: []),
        )
        .values;
  }

  String getValuesAsString(String key, String screenId) {
    return componentData
        .firstWhere(
          (data) => data.key == key && data.id == screenId,
          orElse: () => ComponentData(id: screenId, key: key, values: []),
        )
        .values
        .join(Serializable.LIST_BREAK);
  }
}
