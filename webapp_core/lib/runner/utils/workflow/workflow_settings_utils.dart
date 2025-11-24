import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
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

  static Future<sci.Workflow> setOperator({required sci.Workflow workflow,
    required String operatorUrl, String operatorVersion = "latest",
  required String stepId}) async {
    final step = workflow.steps.whereType<sci.DataStep>().where((step) => step.id == stepId).firstOrNull;
    if( step == null ){
      throw sci.ServiceError(404, "step.not.found", "Step $stepId not found in workflow ${workflow.name} (${workflow.id})");
    }


    final operatorList = (await tercen.ServiceFactory()
        .documentService
        .getLibrary('', [], ["Operator"], [], 0, -1))
        .where((op) => op.url.uri == operatorUrl)
        .toList();

    sci.Document? selectedOperator;

    if( operatorVersion.isEmpty || operatorVersion != "latest"){
      throw sci.ServiceError(400, "invalid.operator.version", "operatorVersion must be: (a) a semVer version. (b) a commit id; or (c) latest");
    }

    if (operatorVersion != "latest") {
      // Match specific version
      selectedOperator = operatorList
          .where((op) => op.version == operatorVersion)
          .firstOrNull;

      if (selectedOperator == null) {
        throw sci.ServiceError(404, "operator.version.not.found",
            "Operator $operatorUrl version $operatorVersion not found");
      }
    } else {
      // Get latest operator in library
      operatorList.sort((a, b) {
        final dateA = DateTime.parse(a.lastModifiedDate.value);
        final dateB = DateTime.parse(b.lastModifiedDate.value);
        return dateB.compareTo(dateA); // Most recent first
      });

      selectedOperator = operatorList.first;
    }

    final opObject = await tercen.ServiceFactory().operatorService.get(selectedOperator.id);
    final opRef = sci.OperatorRef()
      ..operatorId = opObject.id
      ..version = opObject.version
      ..operatorKind = opObject.kind
      ..operatorSpec = opObject.operatorSpec
      ..url = opObject.url;

    step.model.operatorSettings.operatorRef = opRef;
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
