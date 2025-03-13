// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingsFilter _$SettingsFilterFromJson(Map<String, dynamic> json) =>
    SettingsFilter(
      filters: (json['filters'] as List<dynamic>)
          .map((e) => SettingsFilterExpr.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SettingsFilterToJson(SettingsFilter instance) =>
    <String, dynamic>{
      'filters': instance.filters,
    };
