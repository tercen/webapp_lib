import 'package:flutter/services.dart';
import 'package:json_string/json_string.dart';
import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:webapp_model/settings/operator_settings_filter.dart';
import 'package:webapp_model/settings/operator_settings_filter_expr.dart';
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
  var operatorSettingsFilters = OperatorSettingsFilter(filters: []);
  var workflowStepsMapper = WorkflowSteps(steps: []);
  var templateConfig = TemplateConfig(repos: []);

  final Map<String, sci.Operator> operators = {};

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
      throw sci.ServiceError(500, "Required Step does not exist",
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



  Future<void> loadOperator(OperatorSettingsFilterExpr f) async {
    final key = "${f.operatorUrl}_${f.operatorVersion}";

    if (!operators.containsKey(key)) {
      final factory = tercen.ServiceFactory();
      final opList = await factory.documentService.findOperatorByUrlAndVersion(
          startKey: [f.operatorUrl, f.operatorVersion],
          endKey: [f.operatorUrl, f.operatorVersion]);
      if( opList.isEmpty ){
        throw sci.ServiceError(500, "Operator ${f.operatorUrl}@${f.operatorVersion} required by filters could not be found");
      }
      // final op =await factory.operatorService.get( opList.first.id );
      
      
      operators[key] = await factory.operatorService.get( opList.first.id );
    }
  }

  List<sci.Property> getOperatorProperties( String url, String version ){
    final key = "${url}_${version}";
    if( operators.containsKey(key)){
      return List<sci.Property>.from(operators[key]!.properties);
    }else{
      return [];
    }
    
  }

  Future<void> loadOperatorSettingsFilter(String assetPath) async {
    if (assetPath == "") {
      return;
    }
    var assetString = await rootBundle.loadString(assetPath);
    final jsonString = JsonString(assetString);

    operatorSettingsFilters =
        OperatorSettingsFilter.fromJson(jsonString.decodedValueAsMap);

    for (var f in operatorSettingsFilters.filters) {}
  }
}
