import 'package:json_annotation/json_annotation.dart';

part "operator_settings_filter_expr.g.dart";

@JsonSerializable()
class OperatorSettingsFilterExpr {
  final String filterId;
  final String operatorUrl;
  final String operatorVersion;
  final String type;
  final List<String>? settingNames;

  OperatorSettingsFilterExpr(
      {required this.filterId, required this.operatorUrl, required this.operatorVersion, required this.type, this.settingNames});

  factory OperatorSettingsFilterExpr.fromJson(Map<String, dynamic> json) =>
      _$OperatorSettingsFilterExprFromJson(json);

  Map<String, dynamic> toJson() => _$OperatorSettingsFilterExprToJson(this);
}
