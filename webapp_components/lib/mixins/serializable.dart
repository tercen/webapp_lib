import 'package:webapp_components/commons/component_data.dart';

mixin Serializable {
  final List<ComponentData> componentData = [];
  static const String LIST_BREAK = "|@|";

  void setValue(String screenId, String key, List<String> values) {
    componentData.clear();
    componentData.add(ComponentData(id: screenId, key: key, values: values));
  }

  void addValues(String key, String screenId, List<String> values) {
    for (var cd in componentData) {
      if (cd.key == key) {
        cd.values.addAll(values);
      }
    }
    componentData.add(ComponentData(id: screenId, key: key, values: values));
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
