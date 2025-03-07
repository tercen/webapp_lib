import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_workflow/runners/workflow_runner.dart';
import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;

typedef PostRunIdCallback = Future<void> Function(String workflowId);
class WorkflowQueuRunner extends WorkflowRunner{
  WorkflowQueuRunner(super.projectId, super.teamName, super.template);
  final List<PostRunIdCallback> postRunIdCallbacks = [];

  void addIdPostRun(PostRunIdCallback callback ){
    postRunIdCallbacks.add(callback);

  }

  @override
  Future<sci.Workflow> doRun(BuildContext context) async {
    if( template.id == ""){
      throw Exception("Workflow not set in WorkflowRunner.");
    }

    var factory = tercen.ServiceFactory();

    

    for( var entry in tableDocumentMap.entries ){
      tableMap[entry.key] = await loadDocumentInMemory(entry.value);
    }

    //-----------------------------------------
    // Copy template into project
    //-----------------------------------------
    var workflow =
        await factory.workflowService.copyApp(template.id, projectId);

    for (var stepToRemove in stepsToRemove) {
      workflow = removeStepFromWorkflow(stepToRemove, workflow);
    }

    //-----------------------------------------
    // Step-specific setup
    //-----------------------------------------
    for (var stp in workflow.steps) {
      if (stp.kind == "DataStep") {
        stp = updateOperatorSettings(stp as sci.DataStep, settings);
      }

      if (shouldResetStep(stp)) {
        stp.state.taskState = sci.InitState();
        stp.state.taskId = "";
      }

      if (multiDsMap.containsKey(stp.id)) {
        var tmpStp = stp as sci.DataStep;
        tmpStp.parentDataStepId = multiDsMap[stp.id]!;
      }

      if (filterMap.containsKey(stp.id)) {
        sci.DataStep dataStp = stp as sci.DataStep;
        dataStp.model.filters.namedFilters.add(filterMap[stp.id]!);
        // dataStp.model.filters = filterMap[stp.id]!;
      }

      if (tableMap.containsKey(stp.id)) {
        sci.TableStep tmpStp = stp as sci.TableStep;
        tmpStp.model.relation = tableMap[stp.id]!;
        tmpStp.state.taskState = sci.DoneState();

        if( tableNameMap.containsKey(stp.id)){
          tmpStp.name = tableNameMap[stp.id]!;
        }

        stp = tmpStp;
      }

      if (gatherMap.containsKey(stp.id)) {
        (stp as sci.MeltStep).model.selectionPattern = gatherMap[stp.id]!;
      }
    }

    //-----------------------------------------
    // General workflow parameters
    //-----------------------------------------
    if (folderId == null) {
      sci.FolderDocument folder = await createFolder(projectId, teamName);
      workflow.folderId = folder.id;
    } else {
      workflow.folderId = folderId!;
    }

    workflow.name = getWorkflowName(workflow);

    workflow.meta.add(sci.Pair.from("team.init", teamName ));
    
    
    workflow.acl = sci.Acl()..owner = teamName;
    workflow.id = "";
    workflow.rev = "";

    workflow.isHidden = false;
    workflow.isDeleted = false;
    
    workflow = await factory.workflowService.create(workflow);
    
    workflowId = workflow.id;

    //-----------------------------------------
    // Task preparation and running
    //-----------------------------------------
    sci.RunWorkflowTask workflowTask = sci.RunWorkflowTask()
      ..state = sci.InitState()
      ..owner = teamName
      ..projectId = projectId
      ..workflowId = workflow.id
      ..workflowRev = workflow.rev;

    workflowTask =
        await factory.taskService.create(workflowTask) as sci.RunWorkflowTask;

    Fluttertoast.showToast(
        msg: "Workflow ${workflow.name} started",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM_LEFT,
        webPosition: "left",
        webBgColor: "linear-gradient(to bottom, #aaaaff, #eeeeaff)",
        timeInSecForIosWeb: 5,
        backgroundColor: Colors.lightBlue[100],
        textColor: Styles()["black"],
        fontSize: 16.0
    );


    workflow = await factory.workflowService.get(workflow.id);
    workflow.meta.add(sci.Pair.from("run.task.id", workflowTask.id));
    await factory.workflowService.update(workflow);
    
    var taskStream = workflowStream(workflowTask.id);
    await for (var evt in taskStream) {
      if (evt is sci.TaskProgressEvent) {
        
      } else if (evt is sci.TaskLogEvent) {

      } else {
        if (evt is sci.TaskStateEvent) {
          if (evt.state is sci.DoneState) {
            // var runningWorkflow =
                // await factory.workflowService.get(workflow.id);
            //TODO update number of steps finished
          }
        }
      }
    }
    var doneWorkflow = await factory.workflowService.get(workflow.id);

    try {
      for (var stp in doneWorkflow.steps) {
        stp.state.taskState.throwIfNotDone();
      }  
    } catch (e) {
      doneWorkflow.meta.add(sci.Pair.from("run.error", (e as sci.ServiceError).error));
      doneWorkflow.meta.add(sci.Pair.from("run.error.reason", (e as sci.ServiceError).reason));
      await factory.workflowService.update(doneWorkflow);
    }
    

    for (var f in postRunCallbacks) {
      await f();
    }

    for (var f in postRunIdCallbacks) {
      await f(doneWorkflow.id);
    }


    workflowId = doneWorkflow.id;

    return doneWorkflow;
  }
}