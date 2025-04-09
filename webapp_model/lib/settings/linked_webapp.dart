import 'package:json_annotation/json_annotation.dart';

part "linked_webapp.g.dart";

@JsonSerializable()
class LinkedWebapp {

  final String shortName;
  final String url;
  final String? version;

  LinkedWebapp({required this.shortName, required this.url, required this.version});


  factory LinkedWebapp.fromJson(Map<String, dynamic> json) =>
      _$LinkedWebappFromJson(json);

  Map<String, dynamic> toJson() => _$LinkedWebappToJson(this);

}