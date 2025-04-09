import 'package:json_annotation/json_annotation.dart';
import 'package:webapp_model/settings/linked_webapp.dart';

part "linked_apps.g.dart";

@JsonSerializable()
class LinkedApps {

  final List<LinkedWebapp> webappOperators;

  LinkedApps({required this.webappOperators});


  factory LinkedApps.fromJson(Map<String, dynamic> json) =>
      _$LinkedAppsFromJson(json);

  Map<String, dynamic> toJson() => _$LinkedAppsToJson(this);

}