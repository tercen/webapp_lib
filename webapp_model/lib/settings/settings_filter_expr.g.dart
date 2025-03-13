// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_filter_expr.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingsFilterExpr _$SettingsFilterExprFromJson(Map<String, dynamic> json) =>
    SettingsFilterExpr(
      type: json['type'] as String,
      stepId: json['stepId'] as String?,
      stepName: json['stepName'] as String?,
      settingNames: json['settingNames'] as String?,
    );

Map<String, dynamic> _$SettingsFilterExprToJson(SettingsFilterExpr instance) =>
    <String, dynamic>{
      'type': instance.type,
      'stepId': instance.stepId,
      'stepName': instance.stepName,
      'settingNames': instance.settingNames,
    };
