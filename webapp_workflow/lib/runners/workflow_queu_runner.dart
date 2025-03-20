import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_workflow/runners/workflow_runner.dart';
import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;

typedef PostRunIdCallback = Future<void> Function(String workflowId);

class WorkflowQueuRunner extends WorkflowRunner {
  WorkflowQueuRunner(super.projectId, super.teamName, super.template);
  final List<PostRunIdCallback> postRunIdCallbacks = [];

  void addIdPostRun(PostRunIdCallback callback) {
    postRunIdCallbacks.add(callback);
  }

  @override
  Future<sci.Workflow> doRun(BuildContext context) async {
    if (template.id == "") {
      throw Exception("Workflow not set in WorkflowRunner.");
    }

    // Fluttertoast.showToast(
    //     msg: "Workflow is being prepared",
    //     toastLength: Toast.LENGTH_LONG,
    //     gravity: ToastGravity.BOTTOM_LEFT,
    //     webPosition: "left",
    //     webBgColor: "linear-gradient(to bottom, #aaaaff, #eeeeaff)",
    //     timeInSecForIosWeb: 2,
    //     backgroundColor: Colors.lightBlue[100],
    //     textColor: Styles()["black"],
    //     fontSize: 16.0
    // );

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

    var taskStream = factory.eventService.channel(workflowTask.channelId);

    await factory.taskService.runTask(workflowTask.id);

    workflow.addMeta("workflow.task.id", workflowTask.id);
    workflow.addMeta("run.task.id", workflowTask.id);
    await factory.workflowService.update(workflow);

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

    try {
      var hasFailed = false;
      await for (var evt in taskStream) {
        if (evt is sci.PatchRecords) {
          workflow = evt.apply(workflow);
          for( var pr in evt.rs ){
            var prMap = jsonDecode(pr.d);

            if( prMap is Map && prMap.keys.contains("kind") && prMap["kind"] == "FailedState"){
              print("Workflow failed ###");
              workflow.meta
                  .add(sci.Pair.from("run.error", prMap["error"] as String));
              workflow.meta
                  .add(sci.Pair.from("run.error.reason", prMap["error"] as String));
              await factory.taskService.cancelTask(workflowTask.id);
              await factory.workflowService.update(workflow);
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
            if (evt.state is sci.DoneState) {
              // var runningWorkflow =
              // await factory.workflowService.get(workflow.id);
              //TODO update number of steps finished
            }
          }
        }

        if( hasFailed ){
          break;
        }
      }
      // var doneWorkflow = await factory.workflowService.get(workflow.id);
      // if( !hasFailed )
      // for (var stp in workflow.steps) {
      //   stp.state.taskState.throwIfNotDone();
      // }
    } catch (e) {
      print("Workflow failed: $e");
      workflow.meta
          .add(sci.Pair.from("run.error", (e as sci.ServiceError).error));
      workflow.meta.add(
          sci.Pair.from("run.error.reason", (e as sci.ServiceError).reason));
      await factory.workflowService.update(workflow);
    }

    for (var f in postRunCallbacks) {
      await f();
    }

    for (var f in postRunIdCallbacks) {
      await f(workflow.id);
    }

    workflowId = workflow.id;

    return workflow;
  }
}
