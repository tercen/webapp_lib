import 'package:webapp_model/settings/operator_settings_filter_expr.dart';
import 'package:json_annotation/json_annotation.dart';

part "operator_settings_filter.g.dart";

@JsonSerializable()
class OperatorSettingsFilter {
  final List<OperatorSettingsFilterExpr> filters;

  OperatorSettingsFilter({required this.filters});

  factory OperatorSettingsFilter.fromJson(Map<String, dynamic> json) =>
      _$OperatorSettingsFilterFromJson(json);

  Map<String, dynamic> toJson() => _$OperatorSettingsFilterToJson(this);


}
