import 'package:webapp_model/settings/settings_filter_expr.dart';
import 'package:json_annotation/json_annotation.dart';

part "settings_filter.g.dart";

@JsonSerializable()
class SettingsFilter {
  final List<SettingsFilterExpr> filters;

  SettingsFilter({required this.filters});

  factory SettingsFilter.fromJson(Map<String, dynamic> json) =>
      _$SettingsFilterFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsFilterToJson(this);


}
