// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operator_settings_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OperatorSettingsFilter _$OperatorSettingsFilterFromJson(
        Map<String, dynamic> json) =>
    OperatorSettingsFilter(
      filters: (json['filters'] as List<dynamic>)
          .map((e) =>
              OperatorSettingsFilterExpr.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OperatorSettingsFilterToJson(
        OperatorSettingsFilter instance) =>
    <String, dynamic>{
      'filters': instance.filters,
    };
