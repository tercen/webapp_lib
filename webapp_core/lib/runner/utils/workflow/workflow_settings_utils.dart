import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:webapp_core/runner/utils/functions/logger.dart';

class WorkflowSettingsUtils {
  static sci.Workflow updateEnv(
      {required sci.Workflow workflow,
      required String stepId,
      required String env,
      required String value}) {
    final step = workflow.steps
        .whereType<sci.DataStep>()
        .where((step) => step.id == stepId)
        .firstOrNull;
    if (step == null) {
      Logger().log(
          level: Logger.WARN,
          message:
              "Step Id $stepId not found in workflow ${workflow.id}. $env will not be set");
      return workflow;
    }

    final ei =
        step.model.operatorSettings.environment.indexWhere((p) => p.key == env);
    if (ei < 0) {
      Logger().log(
          level: Logger.FINER,
          message:
              " $env not present in step Id $stepId not found in workflow ${workflow.id}. It will be added with value $value");
      step.model.operatorSettings.environment.add(sci.Pair.from(env, value));
    } else {
      step.model.operatorSettings.environment[ei].value = value;
    }

    return workflow;
  }

  sci.Workflow updateSetting(
      {required sci.Workflow workflow,
      required String stepId,
      required String settingName,
      required String value}) {
    final step = workflow.steps
        .whereType<sci.DataStep>()
        .where((step) => step.id == stepId)
        .firstOrNull;

    if (step == null) {
      throw sci.ServiceError(404, "step.not.found",
          "Step $stepId could not be found when updating setting");
    }

    final propIdx = step.model.operatorSettings.operatorRef.propertyValues.indexWhere((prop) => prop.name == settingName);
    if( propIdx == -1){
      throw sci.ServiceError(404, "property.not.found", "property $settingName has not been found in step ${step.name} ($stepId)");
    }
    step.model.operatorSettings.operatorRef.propertyValues[propIdx].value = value;

    return workflow;
  }
}
