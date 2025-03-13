// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TemplateConfig _$TemplateConfigFromJson(Map<String, dynamic> json) =>
    TemplateConfig(
      repos: (json['repos'] as List<dynamic>)
          .map((e) => RequiredTemplate.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TemplateConfigToJson(TemplateConfig instance) =>
    <String, dynamic>{
      'repos': instance.repos,
    };
