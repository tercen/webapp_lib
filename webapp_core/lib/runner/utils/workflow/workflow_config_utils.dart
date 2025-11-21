import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;

class WorkflowConfigUtils {
  static List<String> _getTableFactorNames(sci.CrosstabTable table) {
    List<String> factors = [];

    factors.addAll(
        table.graphicalFactors.map((e) => e.factor.name).where((e) => e != ""));

    return factors;
  }

  static List<String> getFactorNames(sci.Workflow workflow, String stepId) {
    List<String> factors = [];

    for (var stp in workflow.steps) {
      if (stp.id == stepId) {
        sci.DataStep dataStp = stp as sci.DataStep;
        for (var axis in dataStp.model.axis.xyAxis) {
          // Factors used in X and Y axes
          var facName = axis.xAxis.graphicalFactor.factor.name;
          if (facName != "") {
            factors.add(facName);
          }
          facName = axis.yAxis.graphicalFactor.factor.name;
          if (facName != "") {
            factors.add(facName);
          }
        }

        factors.addAll(WorkflowConfigUtils._getTableFactorNames(
            dataStp.model.columnTable));
        factors.addAll(
            WorkflowConfigUtils._getTableFactorNames(dataStp.model.rowTable));
      }
    }
    return factors;
  }

  //NEeded to handle wildcards
  static List<String> convertToStepFactors(
      List<String> reqFactors, List<String> stepFactors) {
    List<String> factors = [];

    for (var reqFactor in reqFactors) {
      if (!reqFactor.contains("*")) {
        factors.add(reqFactor);
      } else {
        if (reqFactor.startsWith("*") && reqFactor.endsWith("*")) {
          var fac = reqFactor.replaceAll("*", "");
          var convFac =
              stepFactors.firstWhere((e) => e.contains(fac), orElse: () => "");
          if (convFac != "") {
            factors.add(convFac);
          } else {
            factors.add(reqFactor);
          }
        } else if (reqFactor.startsWith("*")) {
          var fac = reqFactor.replaceAll("*", "");
          var convFac =
              stepFactors.firstWhere((e) => e.endsWith(fac), orElse: () => "");
          if (convFac != "") {
            factors.add(convFac);
          } else {
            factors.add(reqFactor);
          }
        } else {
          var fac = reqFactor.replaceAll("*", "");
          var convFac = stepFactors.firstWhere((e) => e.startsWith(fac),
              orElse: () => "");
          if (convFac != "") {
            factors.add(convFac);
          } else {
            factors.add(reqFactor);
          }
        }
      }
    }

    return factors;
  }

  static Future<sci.Workflow> copyTemplateFromLibrary(
      {required String templateUrl, required String projectId, String? workflowName,
        required String user, String? version}) async {
    final templateWorkflow = (await tercen.ServiceFactory()
        .documentService
        .getLibrary('', [], ["Workflow"], [], 0, -1))
        .where((wkf) => wkf.url.uri == templateUrl)
        .where((wkf) => version == null || wkf.version == version)
        .where((wkf) => workflowName == null || wkf.name == workflowName)
        .firstOrNull;

    if (templateWorkflow == null) {
      throw sci.ServiceError(404, "workflow.not.found",
          "Template $templateUrl has not been found in the library");
    }

    return await  copyToProject(projectId: projectId,
        workflowId: templateWorkflow.id, teamName: user);
  }


  static Future<sci.Workflow> copyToProject(
      {required String projectId,
        required String workflowId,
        String folderId = "",
        String? workflowName,
        required String teamName}) async {
    final  factory = tercen.ServiceFactory();

    var workflow = await tercen.ServiceFactory()
        .workflowService
        .copyApp(workflowId, projectId);

    workflow.folderId = folderId;
    workflow.name = workflowName ?? workflow.name;
    workflow.acl = (sci.Acl()..owner = teamName);
    workflow.isHidden = false;
    workflow.isDeleted = false;
    workflow.projectId = projectId;

    workflow.id = "";
    workflow.rev = "";

    workflow = await factory.workflowService.create(workflow);

    return workflow;
  }

}
