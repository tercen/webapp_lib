// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'linked_apps.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LinkedApps _$LinkedAppsFromJson(Map<String, dynamic> json) => LinkedApps(
      webappOperators: (json['webappOperators'] as List<dynamic>)
          .map((e) => LinkedWebapp.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LinkedAppsToJson(LinkedApps instance) =>
    <String, dynamic>{
      'webappOperators': instance.webappOperators,
    };
