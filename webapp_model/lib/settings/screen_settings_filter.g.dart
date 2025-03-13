// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screen_settings_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScreenSettingsFilter _$ScreenSettingsFilterFromJson(
        Map<String, dynamic> json) =>
    ScreenSettingsFilter(
      screenFilters: (json['screenFilters'] as List<dynamic>)
          .map((e) => SettingsFilter.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ScreenSettingsFilterToJson(
        ScreenSettingsFilter instance) =>
    <String, dynamic>{
      'screenFilters': instance.screenFilters,
    };
