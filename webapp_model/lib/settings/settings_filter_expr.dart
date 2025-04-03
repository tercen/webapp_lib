import 'package:json_annotation/json_annotation.dart';

part "settings_filter_expr.g.dart";

@JsonSerializable()
class SettingsFilterExpr {
  final String screen;
  final String type;
  final String? block;
  final String? stepId;
  final String? stepName;
  final List<String>? settingNames;

  SettingsFilterExpr(
      {required this.screen, required this.type, this.block,  this.stepId, this.stepName, this.settingNames});

  factory SettingsFilterExpr.fromJson(Map<String, dynamic> json) =>
      _$SettingsFilterExprFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsFilterExprToJson(this);
}
