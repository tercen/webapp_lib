import 'package:flutter/services.dart';
import 'package:json_string/json_string.dart';
import 'package:sci_tercen_client/sci_client.dart';
import 'package:webapp_model/settings/required_template.dart';
import 'package:webapp_model/settings/settings_filter.dart';
import 'package:webapp_model/settings/workflow_steps.dart';
import 'package:webapp_model/settings/template_config.dart';


class SettingsDataService {
  static final SettingsDataService _singleton = SettingsDataService._internal();

  factory SettingsDataService() {
    return _singleton;
  }

  SettingsDataService._internal();

  var settingsFilters = SettingsFilter(filters: []);
  var workflowStepsMapper = WorkflowSteps(steps: []);
  var templateConfig = TemplateConfig(repos: []);

  bool hasFilter(String screenName) {
    return settingsFilters.filters.any((filter) => filter.screen == screenName);
  }

  List<RequiredTemplate> get requiredWorkflows => templateConfig.repos;

  String getStepId(String workflowRef, String stepRef) {
    try {
      return workflowStepsMapper.steps
          .firstWhere((step) =>
              step.shortName == stepRef && step.workflowRef == workflowRef)
          .stepId;
    } catch (e) {
      throw ServiceError(500, "Required Step does not exist",
          "Required step $stepRef does not exist in $workflowRef. Please check the Workflo Step Mapper configuration in the assets.");
    }
  }

  Future<void> loadTemplateConfig(String assetPath) async {
    if (assetPath == "") {
      return;
    }
    var assetString = await rootBundle.loadString(assetPath);
    final jsonString = JsonString(assetString);

    templateConfig = TemplateConfig.fromJson(jsonString.decodedValueAsMap);
  }

  Future<void> loadWorkflowStepMapper(String assetPath) async {
    if (assetPath == "") {
      return;
    }
    var assetString = await rootBundle.loadString(assetPath);
    final jsonString = JsonString(assetString);
    workflowStepsMapper = WorkflowSteps.fromJson(jsonString.decodedValueAsMap);
  }

  Future<void> loadSettingsFilter(String assetPath) async {
    if (assetPath == "") {
      return;
    }
    var assetString = await rootBundle.loadString(assetPath);
    final jsonString = JsonString(assetString);

    settingsFilters = SettingsFilter.fromJson(jsonString.decodedValueAsMap);
  }
}
