import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_components/extra/settings_component_generator.dart';
import 'package:webapp_model/settings/operator_settings_filter_expr.dart';
import 'package:webapp_model/webapp_data_base.dart';
import 'package:webapp_utils/model/workflow_setting.dart';
import 'package:webapp_utils/services/settings_data_service.dart';
import 'package:webapp_utils/services/workflow_data_service.dart';

class OperatorSettingsComponentGenerator extends SettingComponentGenerator {
  Future<List<Component>> getSettings(String workflowId,
      String stepId, List<String> filterIdList,
      {String? operatorVersion}) async {
    final fExpr = SettingsDataService()
        .operatorSettingsFilters
        .filters
        .firstWhere((f) => filterIdList.contains( f.filterId));


    final workflow = await WorkflowDataService().fetch(workflowId);
    final step =
        workflow.steps.firstWhere((step) => step.id == stepId) as sci.DataStep;
    final filters = SettingsDataService()
        .operatorSettingsFilters
        .filters
        .where((f) => filterIdList.contains(f.filterId));
    final opProperties = SettingsDataService()
        .getOperatorProperties(fExpr.operatorUrl, fExpr.operatorVersion);

    return opProperties
        .where((prop) => _shouldInclude(prop, filters.toList()))
        .map((prop) => _toSetting(prop, step))
        .map((setting) {
          switch (setting.type) {
            case "int":
            case "double":
            case "string":
              return createTextNumericComponent(setting, "");
            case "boolean":
              return createBooleanComponent(setting, "");
            case "ListSingle":
              return createSingleListComponent(setting, "");
            case "ListMultiple":
              return createMultipleListComponent(setting, "");
            default:
              return createTextNumericComponent(setting, "");
          }
        })
        .whereType<Component>()
        .toList();
  }

  bool _shouldInclude(
      sci.Property prop, List<OperatorSettingsFilterExpr> filters) {
    var include = false;

    for (var f in filters) {
      if (f.type == "include") {
        if (f.settingNames != null && f.settingNames!.contains(prop.name)) {
          include = include || true;
        }
      }
      if (f.type == "exclude") {
        if (f.settingNames != null && f.settingNames!.contains(prop.name)) {
          include = include || false;
        }
      }
    }
    return include;
  }

  WorkflowSetting _toSetting(sci.Property prop, sci.DataStep step) {
    final propVal = step.model.operatorSettings.operatorRef.propertyValues
        .firstWhere((p) => p.name == prop.name);
    
    if (prop is sci.DoubleProperty || prop.kind == "DoubleProperty") {
      print("Converting ${prop.name} as double");
      return WorkflowSetting(step.name, step.id, prop.name, propVal.value,
          "double", prop.description);
    }
        if (prop is sci.EnumeratedProperty || prop.kind == "EnumeratedProperty") {
      print("Converting ${prop.name} as enumerated");
      return WorkflowSetting(
          step.name,
          step.id,
          prop.name,
          propVal.value,
          (prop as sci.EnumeratedProperty).isSingleSelection ? "ListSingle" : "ListMultiple",
          prop.description);
    }
    if (prop is sci.BooleanProperty || prop.kind == "BooleanProperty") {
      print("Converting ${prop.name} as boolean");
      return WorkflowSetting(step.name, step.id, prop.name, propVal.value,
          "boolean", prop.description);
    }
    if (prop is sci.StringProperty || prop.kind == "StringProperty") {
      print("Converting ${prop.name} as string");
      return WorkflowSetting(step.name, step.id, prop.name, propVal.value,
          "string", prop.description);
    }


    throw sci.ServiceError(500, "Unexpected property type: ${prop.toJson()}");
  }

  List<Component> getScreenSettings(
      String screenName, WebAppDataBase modelLayer,
      {bool applyFilter = true, String? block}) {
    var comps = modelLayer.workflowService.workflowSettings
        .map((setting) {
          switch (setting.type) {
            case "int":
            case "double":
            case "string":
              return createTextNumericComponent(setting, screenName);
            case "boolean":
              return createBooleanComponent(setting, screenName);
            case "ListSingle":
              return createSingleListComponent(setting, screenName);
            case "ListMultiple":
              return createMultipleListComponent(setting, screenName);
            default:
              return createTextNumericComponent(setting, screenName);
          }
        })
        .whereType<Component>()
        .toList();
    if (applyFilter) {
      comps =
          filterScreenComponents(comps, screenName, modelLayer, block: block);
    }
    return comps;
  }
}
