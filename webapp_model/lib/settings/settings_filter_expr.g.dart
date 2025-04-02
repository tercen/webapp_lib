// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_filter_expr.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingsFilterExpr _$SettingsFilterExprFromJson(Map<String, dynamic> json) =>
    SettingsFilterExpr(
      screen: json['screen'] as String,
      type: json['type'] as String,
      block: json['block'] as String?,
      stepId: json['stepId'] as String?,
      stepName: json['stepName'] as String?,
      settingNames: json['settingNames'] as String?,
    );

Map<String, dynamic> _$SettingsFilterExprToJson(SettingsFilterExpr instance) =>
    <String, dynamic>{
      'screen': instance.screen,
      'type': instance.type,
      'block': instance.block,
      'stepId': instance.stepId,
      'stepName': instance.stepName,
      'settingNames': instance.settingNames,
    };
