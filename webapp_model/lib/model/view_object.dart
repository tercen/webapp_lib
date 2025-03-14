import 'package:json_annotation/json_annotation.dart';

part 'view_object.g.dart';

@JsonSerializable()
class ViewObject {
  String key;
  List<String> values;

  ViewObject({required this.key, required this.values});

  factory ViewObject.fromJson(Map<String, dynamic> json) =>
      _$ViewObjectFromJson(json);

  Map<String, dynamic> toJson() => _$ViewObjectToJson(this);

}