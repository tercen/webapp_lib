import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_workflow/runners/workflow_runner.dart';
import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;

typedef PostRunIdCallback = Future<void> Function(String workflowId);

class WorkflowQueuRunner extends WorkflowRunner {
  WorkflowQueuRunner(super.projectId, super.teamName, super.template,
      {super.timestampType = TimestampType.full, super.keepTemplate = false});
  final List<PostRunIdCallback> postRunIdCallbacks = [];

  void addIdPostRun(PostRunIdCallback callback) {
    postRunIdCallbacks.add(callback);
  }

  @override
  Future<sci.Workflow> doRun(BuildContext context) async {
    if (template.id == "") {
      throw Exception("Workflow not set in WorkflowRunner.");
    }

    var factory = tercen.ServiceFactory();

    await setupRun(context);
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

    workflow.addMeta("workflow.task.id", workflowTask.id);
    workflow.addMeta("run.task.id", workflowTask.id);
    await factory.workflowService.update(workflow);


    var taskStream = factory.eventService.channel(workflowTask.channelId);


    await factory.taskService.runTask(workflowTask.id);

    // workflow = await factory.workflowService.get(workflow.id);
    // workflow.addMeta("workflow.task.id", workflowTask.id);
    // workflow.addMeta("run.task.id", workflowTask.id);
    // await factory.workflowService.update(workflow);

    // var taskStream = workflowStream(workflowTask.id);

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
        }
      }
      if (evt is sci.TaskStateEvent) {
        if (evt.state.isFinal && evt.taskId == workflowTask.id) {
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

    // await factory.workflowService.update(workflow);
    // var currentWorkflow = await factory.workflowService.get(workflow.id);

    if (!hasFailed) {
      for (var f in postRunCallbacks) {
        await f();
      }

      for (var f in postRunIdCallbacks) {
        await f(workflow.id);
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

    return workflow;
  }
}
