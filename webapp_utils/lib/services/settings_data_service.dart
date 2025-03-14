import 'package:flutter/services.dart';
import 'package:json_string/json_string.dart';
import 'package:webapp_model/settings/required_template.dart';
import 'package:webapp_model/settings/settings_filter.dart';
import 'package:webapp_model/settings/workflow_steps.dart';
import 'package:webapp_model/settings/template_config.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:webapp_utils/functions/workflow_utils.dart';

class SettingsDataService{
  static final SettingsDataService _singleton = SettingsDataService._internal();
  
  factory SettingsDataService() {
    return _singleton;
  }

  SettingsDataService._internal();

  
  var settingsFilters = SettingsFilter(filters: []);
  var workflowStepsMapper = WorkflowSteps(steps: []);
  var templateConfig = TemplateConfig(repos: []);


  bool hasFilter( String screenName ){
    return settingsFilters.filters.any((filter) => filter.screen == screenName);
  }


  List<RequiredTemplate> get requiredWorkflows => templateConfig.repos;




  Future<void> loadTemplateConfig(String assetPath ) async {
    if( assetPath == ""){
      return;
    }
    var assetString = await rootBundle.loadString(assetPath);
    final jsonString = JsonString(assetString);

    templateConfig = TemplateConfig.fromJson(jsonString.decodedValueAsMap);
  }



  Future<void> loadWorkflowStepMapper(String assetPath ) async {
    if( assetPath == ""){
      return;
    }
    var assetString = await rootBundle.loadString(assetPath);
    final jsonString = JsonString(assetString);
    workflowStepsMapper = WorkflowSteps.fromJson(jsonString.decodedValueAsMap);
  }

  Future<void> loadSettingsFilter(String assetPath) async {
    if( assetPath == ""){
      return;
    }
    var assetString = await rootBundle.loadString(assetPath);
    final jsonString = JsonString(assetString);

    settingsFilters = SettingsFilter.fromJson(jsonString.decodedValueAsMap);
  }

}