import 'package:json_annotation/json_annotation.dart';

part 'step_map.g.dart';

@JsonSerializable()
class StepMap {
  final String workflowRef;
  final String shortName;
  final String stepName;
  final String stepId;

  StepMap({required this.workflowRef, required this.shortName, required this.stepName, required this.stepId});

  factory StepMap.fromJson(Map<String, dynamic> json) =>
      _$StepMapFromJson(json);

  Map<String, dynamic> toJson() => _$StepMapToJson(this);


}