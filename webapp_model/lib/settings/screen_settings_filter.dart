import 'package:webapp_model/settings/settings_filter.dart';
import 'package:json_annotation/json_annotation.dart';

part "screen_settings_filter.g.dart";

@JsonSerializable()
class ScreenSettingsFilter {
  final List<SettingsFilter> screenFilters;

  ScreenSettingsFilter({required this.screenFilters});

  factory ScreenSettingsFilter.fromJson(Map<String, dynamic> json) =>
      _$ScreenSettingsFilterFromJson(json);

  Map<String, dynamic> toJson() => _$ScreenSettingsFilterToJson(this);
}
