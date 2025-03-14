import 'package:json_annotation/json_annotation.dart';

part 'component_data.g.dart';

@JsonSerializable()
class ComponentData {
  String id;
  String key;
  List<String> values;

  ComponentData({required this.id, required this.key, required this.values});

    factory ComponentData.fromJson(Map<String, dynamic> json) =>
      _$ComponentDataFromJson(json);

  Map<String, dynamic> toJson() => _$ComponentDataToJson(this);
}