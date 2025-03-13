import 'package:json_annotation/json_annotation.dart';
import 'package:webapp_model/settings/required_template.dart';


part 'template_config.g.dart';

@JsonSerializable()
class TemplateConfig {
  final List<RequiredTemplate> repos;

  TemplateConfig({required this.repos});

  factory TemplateConfig.fromJson(Map<String, dynamic> json) =>
      _$TemplateConfigFromJson(json);

  Map<String, dynamic> toJson() => _$TemplateConfigToJson(this);

}