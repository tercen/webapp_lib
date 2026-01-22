import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
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
  Future<sci.Workflow> doRun(BuildContext context, {List<String> stepsToRun = const []}) async {
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
      ..channelId = Uuid().v4()
      ..workflowRev = workflow.rev;

    if( stepsToRun.isNotEmpty ){
      workflowTask.stepsToRun.addAll(stepsToRun);
    }

    workflowTask =
        await factory.taskService.create(workflowTask) as sci.RunWorkflowTask;


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


      var hasFailed = false;
      var needsSync = true;
      await for (var evt in taskStream) {
        if (needsSync) {
          // First event received - server has started, fetch current state
          workflow = await factory.workflowService.get(workflow.id);
          needsSync = false;
        }

        // print(evt.toJson());
        if (evt is sci.PatchRecords) {
          print("Received PatchRecord");
          try {
            workflow = evt.apply(workflow);
            for (var pr in evt.rs) {
              var prMap = jsonDecode(pr.d);
              if (prMap is Map &&
                  prMap.keys.contains("kind") &&
                  prMap["kind"] == "FailedState") {
                print(evt.toJson());
                print("Workflow failed ###");
                workflow.meta
                    .add(sci.Pair.from("run.error", prMap["error"] as String));
                workflow.meta.add(
                    sci.Pair.from("run.error.reason", prMap["reason"] as String));
                await factory.taskService.cancelTask(workflowTask.id);
                // await factory.workflowService.update(workflow);
                hasFailed = true;
              }
            }

          } catch (e, stackTrace) {
            //Handles server mismatch (cases where workflow is saved remotely)
            try {
              workflow = await factory.workflowService.get(workflow.id);
              workflow = evt.apply(workflow);
              for (var pr in evt.rs) {
                var prMap = jsonDecode(pr.d);
                if (prMap is Map &&
                    prMap.keys.contains("kind") &&
                    prMap["kind"] == "FailedState") {
                  print(evt.toJson());
                  print("Workflow failed ###");
                  workflow.meta
                      .add(sci.Pair.from("run.error", prMap["error"] as String));
                  workflow.meta.add(
                      sci.Pair.from("run.error.reason", prMap["reason"] as String));
                  await factory.taskService.cancelTask(workflowTask.id);
                  hasFailed = true;
                }
              }
            } catch (e2, stackTrace2) {
              print('DEBUG: Workflow type: ${workflow.runtimeType}');
              print('DEBUG: Workflow has meta: ${workflow.toJson().containsKey("meta")}');
              print("DEBUG: Error applying patch: $e");
              print("DEBUG: Stack trace: $stackTrace");
            }
          }
          if(workflow.steps.every((stp) => stp.state.taskState.isFinal )){
            break;
          }
        }
        print(evt.toJson());
        if (evt is sci.TaskStateEvent) {
          if (evt.state.isFinal && evt.taskId == workflowTask.id) {
            break;
          }
        }

        if (hasFailed) {
          break;
        }
      }
      print("Done with task stream");
    await factory.workflowService.update(workflow);
    workflow = await factory.workflowService.get(workflow.id);

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
