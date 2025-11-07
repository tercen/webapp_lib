import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/functions/logger.dart';
import 'package:webapp_utils/services/app_user.dart';
import 'package:webapp_workflow/runners/workflow_runner.dart';
import 'package:webapp_workflow/services/task_manager.dart';
import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;


import 'package:uuid/uuid.dart';
//TODO Refactor PostRun callbacks to always receive and return a workflow
class WorkflowQueuRunner extends WorkflowRunner {
  WorkflowQueuRunner(
      {super.timestampType = TimestampType.full});



  @override
  Future<sci.Workflow> doRun(BuildContext? context, sci.Workflow workflow, {String? runId, List<String> stepsToRun = const [], List<String> stepsToReset = const[]}) async {
    try {
      return _doRun(context, workflow, stepsToRun: stepsToRun, stepsToReset: stepsToReset);
    } catch (e) {
      Logger().log(level: Logger.WARN, message: "WorkflowQueuRunner.doRun failed");
      return sci.Workflow();
    }
  }
  Future<sci.Workflow> _doRun(BuildContext? context, sci.Workflow workflow,{ List<String> stepsToRun = const [], List<String> stepsToReset = const[]}) async {
    var factory = tercen.ServiceFactory();
    //-----------------------------------------
    // Task preparation and running
    //-----------------------------------------
    sci.RunWorkflowTask workflowTask = sci.RunWorkflowTask()
      ..state = sci.InitState()
      ..owner = AppUser().teamname
      ..projectId = AppUser().projectId
      ..workflowId = workflow.id
      ..channelId = Uuid().v4()
      ..workflowRev = workflow.rev;

    if (stepsToRun.isNotEmpty) {
      workflowTask.stepsToRun.addAll(stepsToRun);
    }

    if (stepsToReset.isNotEmpty) {
      workflowTask.stepsToReset.addAll(stepsToReset);
    }
    // if( doNotRunList.isNotEmpty ){
    //   workflowTask.stepsToRun.addAll( workflow.steps
    //       .where((s) => !doNotRunList.contains(s.id))
    //       .map((s) => s.id)
    //       .toList());
    // }

    workflowTask.meta.add(sci.Pair.from("channel.persistent", "true"));

    workflowTask =
        await factory.taskService.create(workflowTask) as sci.RunWorkflowTask;

    workflow.addMeta("run.workflow.task.id", workflowTask.id);
    workflow.rev = await factory.workflowService.update(workflow);

    // Initialize TaskManager and register this workflow task
    await TaskManager().initialize();
    await TaskManager().registerWorkflowTask(
      workflow.id, 
      workflowTask.id, 
      workflowTask.channelId
    );

    var taskStream = factory.eventService.channel(workflowTask.channelId);

    await factory.taskService.runTask(workflowTask.id);


    // if( context != null ){
      // closeLog(id: this.id);
    // }
    Fluttertoast.showToast(
        msg: "Workflow ${workflow.name} sent to the queu",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM_LEFT,
        webPosition: "left",
        webBgColor: "linear-gradient(to bottom, #aaaaff, #eeeeaff)",
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.lightBlue[100],
        textColor: Styles()["black"],
        fontSize: 16.0);

    var errorInformation = {"error": "", "reason": ""};
    var hasFailed = false;

    await for (var evt in taskStream) {
      if (evt is sci.PatchRecords) {
        // try {
        workflow = evt.apply(workflow);  
        // } catch (e) {
          // print("Failed to apply: ");
          // print(evt.toJson());
          // continue;
        // }
        
        for (var pr in evt.rs) {
          if(  pr.d.isEmpty){
            continue;
          }
          // try {
            var prMap = jsonDecode(pr.d);
            if (prMap is Map &&
                prMap.keys.contains("kind") &&
                prMap["kind"] == "FailedState") {
              // print(evt.toJson());
              // print("Workflow failed ###");
              errorInformation["error"] = prMap["error"] as String;
              errorInformation["reason"] = prMap["reason"] as String;

              await factory.taskService.cancelTask(workflowTask.id);

              hasFailed = true;
            }
            
          // } catch (e) {
            // print(evt.toJson());
            // print(e.toString());
          // }
        }
      }
      if (evt is sci.TaskStateEvent) {
        if (evt.state.isFinal && evt.taskId == workflowTask.id) {
          break;
        }
      }

    }

    if (!hasFailed) {
      // Save the workflow
      workflow.rev = await factory.workflowService.update(workflow);  
      
      for (var f in postRunCallbacks) {
        await f();
      }

      workflow = await factory.workflowService.get(workflow.id);  

      for (var f in postRunIdCallbacks) {

        await f(workflow);
        //In case function updates workflow
        // try {        
          workflow = await factory.workflowService.get(workflow.id);  
        // } catch (e) {
          // print("Failed postRunIdCallback $f : $e");
          //Will generally trigger on task cancel
          // print("WORKFLOW ${workflow.id} not found");
          // return sci.Workflow();
        // }
      }
      
      // print("Applied post run id");

      if( postRunCallbacks.isNotEmpty || postRunIdCallbacks.isNotEmpty ){
        
        workflow.rev = await factory.workflowService.update(workflow);
        print("Updated workflow");
      }
      
    } else {
      //Update workflow with error info
      
      var currentWorkflow = await factory.workflowService.get(workflow.id);
      currentWorkflow.meta
          .add(sci.Pair.from("run.error", errorInformation["error"] as String));
      currentWorkflow.meta.add(sci.Pair.from(
          "run.error.reason", errorInformation["reason"] as String));
      workflow.rev = await factory.workflowService.update(currentWorkflow);
    }

    workflowId = workflow.id;
    
    return workflow;
  }
}
