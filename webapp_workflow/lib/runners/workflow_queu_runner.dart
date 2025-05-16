import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/services/app_user.dart';
import 'package:webapp_workflow/runners/workflow_runner.dart';
import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;



class WorkflowQueuRunner extends WorkflowRunner {
  WorkflowQueuRunner( super.template,
      {super.timestampType = TimestampType.full, super.keepTemplate = false});


  @override
  Future<sci.Workflow> doRunStep(BuildContext? context, String stepId, {bool doSetup = true, bool inPlace = false}) async {
    var factory = tercen.ServiceFactory();

    if( doSetup ){
      if( context != null ){
        log("Sending analysis to queu", dialogTitle: "Preparing Workflow");
      }
      await setupRun(context, inPlace: inPlace);
    }
    
    List<String> stepsToRestore = [];

    for (var stp in workflow.steps) {
      if (!(stp is sci.TableStep ||
          stp.state.taskState is sci.DoneState ||
          stp.state.taskState is sci.FailedState)) {
        if (stp.id == stepId) {
          stp.state.taskState = sci.InitState();
        } else {
          stp.state.taskState = sci.DoneState();
          stepsToRestore.add(stp.id);
        }
      }
    }

    await factory.workflowService.update(workflow);

    //-----------------------------------------
    // Task preparation and running
    //-----------------------------------------
        sci.RunWorkflowTask workflowTask = sci.RunWorkflowTask()
      ..state = sci.InitState()
      ..owner = AppUser().teamname
      ..projectId = AppUser().projectId
      ..workflowId = workflow.id
      ..workflowRev = workflow.rev;

    workflowTask =
        await factory.taskService.create(workflowTask) as sci.RunWorkflowTask;

    var taskStream = factory.eventService.channel(workflowTask.channelId);

    workflow.addMeta("workflow.task.id", workflowTask.id);
    workflow.addMeta("run.task.id", workflowTask.id);
    await factory.workflowService.update(workflow);


    await factory.taskService.runTask(workflowTask.id);


    if( context != null ){
      closeLog();
    }
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
        workflow = evt.apply(workflow);
        for (var pr in evt.rs) {
          if(  pr.d.isEmpty){
            continue;
          }
          try {
            var prMap = jsonDecode(pr.d);
            if (prMap is Map &&
                prMap.keys.contains("kind") &&
                prMap["kind"] == "FailedState") {
              print(evt.toJson());
              print("Workflow failed ###");
              errorInformation["error"] = prMap["error"] as String;
              errorInformation["reason"] = prMap["reason"] as String;

              await factory.taskService.cancelTask(workflowTask.id);

              hasFailed = true;
            }
            
          } catch (e) {
            print(evt.toJson());
            print(e.toString());
            
          }

        }
      }
      if (evt is sci.TaskStateEvent) {
        if (evt.state.isFinal && evt.taskId == workflowTask.id) {
          print("FINISHED WORKFLOW ${workflow.name}");
          break;
        }
      }
      if (evt is sci.TaskProgressEvent) {
      } else if (evt is sci.TaskLogEvent) {
      } else {
        if (evt is sci.TaskStateEvent) {
          if (evt.state is sci.DoneState) {}
        }
      }

      if (hasFailed) {
        break;
      }
    }


    for (var stp in workflow.steps) {
      if (stepsToRestore.contains(stp.id) && !doNotRunList.contains(stp.id) ) {
        stp.state.taskState = sci.InitState();
      }
    }

    
    if(!hasFailed){
      for (var f in postRunCallbacks) {
        await f();
      }
      for (var f in postRunIdCallbacks) {
        await f(workflow.id);
      }
    }else {
      //Update workflow with error info
      var currentWorkflow = await factory.workflowService.get(workflow.id);
      currentWorkflow.meta
          .add(sci.Pair.from("run.error", errorInformation["error"] as String));
      currentWorkflow.meta.add(sci.Pair.from(
          "run.error.reason", errorInformation["reason"] as String));
    }

    await factory.workflowService.update(workflow);
    workflowId = workflow.id;
    workflow = await factory.workflowService.get(workflow.id);

    return workflow;
  }


  @override
  Future<sci.Workflow> doRun(BuildContext? context, {bool setup = true, bool inPlace = false}) async {
    if (template.id == "") {
      throw Exception("Workflow not set in WorkflowRunner.");
    }

    var factory = tercen.ServiceFactory();
   
    if( setup == true ){
      if( context != null ){
        log("Sending analysis to queu", dialogTitle: "Preparing Workflow");
      }
      await setupRun(context, inPlace: inPlace);
    }else{
      workflow = template;
    }
    //-----------------------------------------
    // Task preparation and running
    //-----------------------------------------
    sci.RunWorkflowTask workflowTask = sci.RunWorkflowTask()
      ..state = sci.InitState()
      ..owner = AppUser().teamname
      ..projectId = AppUser().projectId
      ..workflowId = workflow.id
      ..workflowRev = workflow.rev;

    workflowTask =
        await factory.taskService.create(workflowTask) as sci.RunWorkflowTask;

    var taskStream = factory.eventService.channel(workflowTask.channelId);

    workflow.addMeta("workflow.task.id", workflowTask.id);
    workflow.addMeta("run.task.id", workflowTask.id);
    await factory.workflowService.update(workflow);


    await factory.taskService.runTask(workflowTask.id);


    if( context != null ){
      closeLog();
    }
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
    print("Start reading stream");
    await for (var evt in taskStream) {
      if (evt is sci.PatchRecords) {
        print(evt.toJson());
        workflow = evt.apply(workflow);
        for (var pr in evt.rs) {
          if(  pr.d.isEmpty){
            continue;
          }
          try {
            var prMap = jsonDecode(pr.d);
            if (prMap is Map &&
                prMap.keys.contains("kind") &&
                prMap["kind"] == "FailedState") {
              print(evt.toJson());
              print("Workflow failed ###");
              errorInformation["error"] = prMap["error"] as String;
              errorInformation["reason"] = prMap["reason"] as String;

              await factory.taskService.cancelTask(workflowTask.id);

              hasFailed = true;
            }
            
          } catch (e) {
            print(evt.toJson());
            print(e.toString());
          }
        }
      }
      if (evt is sci.TaskStateEvent) {
        if (evt.state.isFinal && evt.taskId == workflowTask.id) {
          print("FINISHED WORKFLOW ${workflow.name}");
          break;
        }
      }
      if (evt is sci.TaskProgressEvent) {
      } else if (evt is sci.TaskLogEvent) {
      } else {
        if (evt is sci.TaskStateEvent) {
          if (evt.state is sci.DoneState) {}
        }
      }

      if (hasFailed) {
        break;
      }
    }


    print("Workflow run done $hasFailed");
    // workflow = await factory.workflowService.get(workflow.id);
    // await factory.workflowService.update(workflow);

    if (!hasFailed) {
      for (var f in postRunCallbacks) {
        await f();
        //In case function updates workflow
        workflow = await factory.workflowService.get(workflow.id);
      }

      for (var f in postRunIdCallbacks) {
        await f(workflow.id);
        //In case function updates workflow
        workflow = await factory.workflowService.get(workflow.id);
      }
    } else {
      //Update workflow with error info
      
      var currentWorkflow = await factory.workflowService.get(workflow.id);
      currentWorkflow.meta
          .add(sci.Pair.from("run.error", errorInformation["error"] as String));
      currentWorkflow.meta.add(sci.Pair.from(
          "run.error.reason", errorInformation["reason"] as String));
      await factory.workflowService.update(currentWorkflow);
    }

    workflowId = workflow.id;
    workflow = await factory.workflowService.get(workflow.id);
    return workflow;
  }
}
