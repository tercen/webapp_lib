import 'package:json_annotation/json_annotation.dart';
import 'package:webapp_model/settings/step_map.dart';

part 'workflow_steps.g.dart';

@JsonSerializable()
class WorkflowSteps {
  final List<StepMap> steps;

  WorkflowSteps({required this.steps});

  factory WorkflowSteps.fromJson(Map<String, dynamic> json) =>
      _$WorkflowStepsFromJson(json);

  Map<String, dynamic> toJson() => _$WorkflowStepsToJson(this);


}
