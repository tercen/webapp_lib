// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'view_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ViewState _$ViewStateFromJson(Map<String, dynamic> json) => ViewState(
      objects: (json['objects'] as List<dynamic>)
          .map((e) => ViewObject.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ViewStateToJson(ViewState instance) => <String, dynamic>{
      'objects': instance.objects,
    };
