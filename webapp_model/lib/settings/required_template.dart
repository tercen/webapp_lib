import 'package:json_annotation/json_annotation.dart';

part 'required_template.g.dart';

@JsonSerializable()
class RequiredTemplate {
  final String iid;
  final String name;
  final String url;
  final String version;

  RequiredTemplate(
      {required this.iid,
      required this.name,
      required this.url,
      required this.version});

  factory RequiredTemplate.fromJson(Map<String, dynamic> json) =>
      _$RequiredTemplateFromJson(json);

  Map<String, dynamic> toJson() => _$RequiredTemplateToJson(this);
}
