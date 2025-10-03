import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webapp_components/components/counter_component.dart';
import 'package:webapp_components/components/workflow_task_component.dart';

import 'package:webapp_utils/services/workflow_data_service.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:webapp_components/components/action_table_component.dart';

import 'package:webapp_components/definitions/list_action.dart';
import 'package:webapp_components/extra/row_color_formatter.dart';

import 'package:webapp_components/screens/screen_base.dart';

import 'package:webapp_components/widgets/wait_indicator.dart';
import 'package:webapp_model/webapp_data_base.dart';

import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/mixin/progress_log.dart';

import 'package:webapp_ui_commons/styles/styles.dart';

import 'package:sci_tercen_model/sci_model.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:webapp_utils/services/app_user.dart';
import 'package:webapp_utils/services/project_data_service.dart';


mixin TaskManagerStateMixin<T extends StatefulWidget> on State<T>
    , ScreenBase, ProgressDialog {
  bool showAllWorkflows = false;
  bool running = false;
  DateTime? lastWorkflowListLoad;
  DateTime? lastTaskFetch;
  bool isFetchingTask = false;
  late final Timer workflowRefreshTimer;
  final Map<String, int> _offsetMaps = {};
  int _lastHash = 0;
  WebappTable _oldTable = WebappTable();

  @override
  String getScreenId() {
    return "TaskManagerScreen";
  }

  // CancelableOperation? emptyQueu;
  @override
  void dispose() {
    super.dispose();

    disposeScreen();
    // emptyQueu?.cancel();
    workflowRefreshTimer.cancel();
  }

  @override
  void refresh() {
    setState(() {});
  }

  bool workflowStatusCheck(WebappTable rowElements) {
    return rowElements["Status"].any((el) => el.toLowerCase() == "failed");
  }

  bool filterFinished(WebappTable rowElements) {
    return rowElements["Status"].first == "Finished";
  }

  bool filterUnfinished(WebappTable rowElements) {
    return rowElements["Status"].first == "Unfinished";
  }

  Future<void> checkWorkflowList() async {
    final comp = getComponent("tasks");

    if (comp != null && comp is ActionTableComponent) {
      var compLastLoad = comp.lastLoad;

      if (compLastLoad == null) {
        // Data table has not been loaded yet
        return;
      }

      if (lastWorkflowListLoad == null) {
        //Data table has been loaded for the first time
        lastWorkflowListLoad = compLastLoad;
        return;
      }

      if (compLastLoad.compareTo(lastWorkflowListLoad!) == 1) {
        //Data table has been reloaded since last check
        lastWorkflowListLoad = compLastLoad;
        //Will refresh here,
        print("Checking workflow list");
        return;
      }
    }
  }

  ActionTableComponent createFinishedWorkflowComponent() {
    var formatter = RowTextColorFormatter(workflowStatusCheck);
    return ActionTableComponent(
        "workflows",
        getScreenId(),
        "All Workflows",
        fetchWorkflows,
        [
          ListAction(Icon(Icons.info_outline, color: Styles()["buttonBgLight"]),
              workflowInfoWithError),
        ],
        hideColumns: ["Id"],
        rowFormatter: formatter,
        cache: false,
        shouldSave: false,
        rowFilters: [
          RowFilter(
              filter: filterFinished,
              iconOn: Icon(
                Icons.done_all,
                color: Colors.green[500],
              ),
              iconOff: Icon(Icons.done_all, color: Styles()["gray"]),
              tooltip: "Show only finished workflows"),
          RowFilter(
              filter: filterUnfinished,
              iconOn: Icon(
                Icons.auto_mode_outlined,
                color: Colors.green[500],
              ),
              iconOff: Icon(Icons.auto_mode_outlined, color: Styles()["gray"]),
              tooltip: "Show only unfinished workflows")
        ]);
  }

  ActionTableComponent createTasksComponent() {
    var comp = WorkflowTaskComponent(
        "tasks",
        getScreenId(),
        "Running Tasks",
        fetchTasks,
        [
          ListAction(
              Icon(Icons.stop_circle_rounded, color: Styles()["buttonBgLight"]),
              cancelTask,
              confirmationMessage:
                  "Are you sure you want to cancel this task?"),
        ],
        [
          ListAction(
              Icon(Icons.info_outline_rounded,
                  color: Styles()["buttonBgLight"]),
              workflowInfo)
        ],
        hideColumns: ["Id", "ProjectName"],
        widths: [3, 1, 1, 1],
        onEmptyQueu: onEmptyQueu);

    comp.markedForReload = true;
    return comp;
  }

  @override
  void initState() {
    super.initState();

    var countComp = CounterComponent();
    var taskList = createTasksComponent();
    var workflowList = createFinishedWorkflowComponent();

    addComponent("default", countComp);
    addComponent("default", taskList);
    // addComponent("default", toolbar);
    addComponent("default", workflowList);

    // initScreen(widget.modelLayer);

    workflowRefreshTimer =
        Timer.periodic(const Duration(milliseconds: 3000), (timer) async {
      final taskComp = getComponent("tasks") as WorkflowTaskComponent?;

      if (mounted && taskComp != null) {
        //Resetting
        if (await _hasRunningTasks()) {
          await taskComp.reload();
        } else {
          if (taskComp.dataTable.nRows > 0) {
            //Finished tasks
            taskComp.reset();
          }
        }
      }
    });
  }

  Future<void> reload(WebappTable values) async {
    var comp = getComponent("workflows") as ActionTableComponent;
    comp.reset();
    comp.init();

    refresh();
  }

  Future<void> cancelTask(WebappTable row) async {
    Fluttertoast.showToast(
        msg: "Cancelling task",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM_LEFT,
        webPosition: "left",
        webBgColor: "linear-gradient(to bottom, #aaaaff, #eeeeaff)",
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.lightBlue[100],
        textColor: Styles()["black"],
        fontSize: 16.0);

    await WorkflowDataService().cancelWorkflowTask(
        row["TaskId"].first,
        deleteWorkflow: row["TaskType"].first == "RunWorkflowTask");
  }

  Future<Widget> workflowSettingsInfoBox(String workflowId,
      {bool printError = false}) async {
    var factory = tercen.ServiceFactory();
    var workflow = await factory.workflowService.get(workflowId);

    var metaList = workflow.meta;

    var contentString = "General Settings:\n";

    for (var meta in metaList) {
      if (meta.key.startsWith("setting")) {
        contentString += meta.key.split(".").last;
        contentString += ": ";
        contentString += meta.value;
        contentString += "\n";
      }
    }

    if (printError) {
      var status =
          await WorkflowDataService().getWorkflowStatus(workflow);
      if (status["error"] != null && status["error"] != "") {
        contentString += "\nERROR INFORMATION";
        contentString += "\n\n";
        contentString += status["error"]!;
      }

      if (status["error.reason"] != null && status["error.reason"] != "") {
        contentString += "\nDetails";
        contentString += "\n";
        contentString += status["error.reason"]!;
      }
    }

    var urlParts = AppUser().projectUrl.split("/");
    urlParts.removeLast();
    urlParts.removeLast();
    var baseUrl = urlParts.join("/");
    var workflowLink = "$baseUrl/w/$workflowId";

    // contentString += "\nLink to workflow: $workflowLink";
    contentString += "\n";

    Widget linkWidget = InkWell(
        onTap: () {
          //  launchUrl(url, webOnlyWindowName: "_self");
          final Uri url = Uri.parse(workflowLink);
          launchUrl(url, webOnlyWindowName: "_blank");
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Link to Workflow",
              style: Styles()["textHref"],
            ),
            Icon(
              Icons.exit_to_app_outlined,
              color: Styles()["linkBlue"],
            )
          ],
        ));

    return SingleChildScrollView(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          contentString,
          style: Styles()["text"],
        ),
        linkWidget
      ],
    ));
  }

  Future<void> workflowInfoWithError(WebappTable row) async {
    showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(builder: (stfCtx, stfSetState) {
            return FutureBuilder(
                future:
                    workflowSettingsInfoBox(row["Id"].first, printError: true),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return AlertDialog(
                      title: Text(
                        "Workflow Information",
                        style: Styles()["textH2"],
                      ),
                      content: snapshot.data!,
                    );
                  } else {
                    return TercenWaitIndicator()
                        .waitingMessage(suffixMsg: "Loading information");
                  }
                });
          });
        });
  }

  Future<void> workflowInfo(WebappTable row) async {
    showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(builder: (stfCtx, stfSetState) {
            return FutureBuilder(
                future: workflowSettingsInfoBox(row["WorkflowId"].first),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return AlertDialog(
                      title: Text(
                        "Workflow Information",
                        style: Styles()["textH2"],
                      ),
                      content: snapshot.data!,
                    );
                  } else {
                    return TercenWaitIndicator()
                        .waitingMessage(suffixMsg: "Loading information");
                  }
                });
          });
        });
  }

  bool compareTables(WebappTable t1, WebappTable t2) {
    if (t1.nRows != t2.nRows || t1.nRows == 0 || t2.nRows == 0) {
      return false;
    }
    for (var col in ["Last Update", "Status"]) {
      for (var ri = 0; ri < t1.nRows; ri++) {
        if (t1[col][ri] != t2[col][ri]) {
          return false;
        }
      }
    }
    return true;
  }

  Future<WebappTable> fetchWorkflows() async {
    return await WorkflowDataService()
        .fetchWorkflowTable(useCache: false, fetchOnServer: true);
  }

  Future onEmptyQueu() async {
    var comp = getComponent("tasks") as WorkflowTaskComponent;
    comp.markedForReload = false;
    // try {
    //   Future.delayed(const Duration(milliseconds: 500), () async {
    //     print("Calling onEmptyQueu");
    // if (mounted) {
    //   final newTbl = await fetchWorkflows();
    //   final areEqual = compareTables(_oldTable, newTbl);

    //   if (!areEqual) {
    //     var comp = getComponent("workflows") as ActionTableComponent?;
    //     if (comp != null) {
    //       comp.reset();
    //       comp.dataTable = newTbl;
    //       _oldTable = newTbl;
    //       running = false;
    //       refresh();
    //     }
    //   }
    // }
    //   });
    // } catch (e) {
    //   print("Not on screen anymore...");
    // }
  }

  sci.TaskStateEvent _getLatestStepEvent(
      String stepId, List<sci.TaskStateEvent> events) {
    for (var ev in events) {
      final evStepId = ev.meta.firstWhere(
        (m) => m.key == "step.id",
        orElse: () => sci.Pair(),
      );
      if (evStepId.value == stepId) {
        return ev;
      }
    }

    return events.first;
  }

  List<sci.Task> _runningTasks = [];
  Future<bool> _hasRunningTasks() async {
    print("${DateTime.now().toIso8601String()} Fetching tasks");
    _runningTasks = (await tercen.ServiceFactory()
        .taskService
        .getTasks(["RunWorkflowTask", "RunComputationTask"]));

    return _runningTasks.isNotEmpty;
  }


  String _formatDate({required sci.Date date}){
    final difference = DateTime.now().difference(DateTime.parse(date.value));

    if(difference.inSeconds < 60 ){
      return "${difference.inSeconds}s ago";  
    }

    if(difference.inMinutes < 60 ){
      return "${difference.inMinutes}m ago";  
    }

    final minDiff = difference.inMinutes % 60;
    return "${difference.inHours}h${minDiff}m ago";  
  }

  Future<WebappTable> fetchTasks() async {
    print("${DateTime.now().toIso8601String()} Fetching tasks");
    var comp = getComponent("tasks") as WorkflowTaskComponent;

    final res = WebappTable();
    final factory = tercen.ServiceFactory();
    final tasks = _runningTasks;
    final List<String> taskIds = [];
    final List<String> taskTypes = [];
    final List<String> taskStates = [];
    final List<String> workflowIds = [];
    final List<String> lastUpdates = [];
    final List<String> workflowNames = [];
    final List<String> channelIds = [];
    final List<String> stepName = [];
    final List<String> projectId = [];
    final List<String> projectName = [];

    final currentHash = _runningTasks.map((t) => t.id).toList().hashCode;
    if( currentHash == _lastHash ){
      print("\tSkipping fetch, no changes detected");
      return _oldTable;
    }else{
      _lastHash = currentHash;
    }

    if (tasks.isNotEmpty) {
      print("\tTasks found: ${tasks.length}");
      running = true;
      for (var t in tasks.where((t) => t.kind == "RunWorkflowTask")) {
        //RunWorkflowTask are not really needed, but we add it to the lists to know there is still a workflow task running
        // (the list of events for the workflow tasks comes empty)
        try {
        final workflow = await WorkflowDataService()
            .fetch((t as sci.RunWorkflowTask).workflowId);
        final project = await ProjectDataService()
            .fetchProject(projectId: workflow.projectId);
        if (!t.state.isFinal) {
          taskIds.add(t.id);
          taskTypes.add("Workflow Task");
          workflowNames.add(workflow.name);
          workflowIds.add(workflow.id);
          stepName.add("");
          lastUpdates.add("");
          taskStates.add("");
          channelIds.add(t.channelId);
          projectId.add(project.id);
          projectName.add(project.name);
        }
        } catch (e) {
          //If workflow was deleted, but the task is still running, this can lead to error
          print("[ERROR] Error fetching workflow ${(t as sci.RunWorkflowTask).workflowId}: $e");
          continue;
        }
      }

      final uniqueChannelIds = tasks
          .where((task) => !task.state.isFinal)
          .map((t) => t.channelId)
          .toSet()
          .toList();

      // final List<Future<List<sci.Event>>> eventsPerChannelFutures = [];

      final List<List<sci.Event>> eventsPerChannel = [];
      for (var channelId in uniqueChannelIds) {
        final offset =
            _offsetMaps.containsKey(channelId) ? _offsetMaps[channelId]! : 0;

        final evList = await factory.eventService.findByChannelAndDate(
            startKey: [channelId, "0000"],
            endKey: [channelId, "9999"],
            skip: offset,
            useFactory: true);

        eventsPerChannel.add(evList);
      }

      for (var ci = 0; ci < eventsPerChannel.length; ci++) {
        final eventList = eventsPerChannel[ci];
        final channelId = uniqueChannelIds[ci];

        if (_offsetMaps.containsKey(channelId)) {
          _offsetMaps[channelId] = _offsetMaps[channelId]! + eventList.length;
        } else {
          _offsetMaps[channelId] = eventList.length;
        }
        final stateEvents = eventList
            .map((e) => e.get("event"))
            .whereType<sci.TaskStateEvent>()
            .where((e) => e.meta.isNotEmpty)
            .toList();

        if (stateEvents.isEmpty) {
          continue;
        }

        final uniqueStepIds = stateEvents
            .map((ev) => ev.meta.firstWhere((m) => m.key == "step.id").value)
            .toSet()
            .toList();
        final uniqueWorkflowIds = stateEvents
            .map(
                (ev) => ev.meta.firstWhere((m) => m.key == "workflow.id").value)
            .toSet()
            .toList();
        var workflow = sci.Workflow();
        try {
        workflow =
            await WorkflowDataService().fetch(uniqueWorkflowIds.first);
        } catch (e) {
          print("[ERROR] Error fetching workflow ${uniqueWorkflowIds.first}: $e");
          continue;
        }
        final steps = workflow.steps
            .where((step) => uniqueStepIds.contains(step.id))
            .toList();

        final project = await ProjectDataService()
            .fetchProject(projectId: workflow.projectId);
        final task = tasks.firstWhere((task) => task.channelId == channelId);
        for (var step in steps) {
          var latestEv = _getLatestStepEvent(step.id, stateEvents);

          if (!(latestEv.state.kind == "DoneState" ||
              latestEv.state.kind == "FailedState" ||
              latestEv.state.kind == "InitState" ||
              latestEv.state.kind == "CancelledState")) {
            running = true;
            comp.markedForReload = false;
            taskIds.add(latestEv.taskId);
            taskTypes.add(getTaskType(task));
            workflowNames.add(workflow.name);
            workflowIds.add(workflow.id);
            stepName.add(step.name);
            lastUpdates.add(_formatDate(date: latestEv.date));
            taskStates.add(latestEv.state.kind);
            channelIds.add(channelId);
            projectId.add(project.id);
            projectName.add(project.name);
          }
        }
      }
      
    }

    res.addColumn("TaskId", data: taskIds);
    res.addColumn("WorkflowId", data: workflowIds);
    res.addColumn("WorkflowName", data: workflowNames);
    res.addColumn("StepName", data: stepName);
    res.addColumn("TaskType", data: taskTypes);
    res.addColumn("LastUpdate", data: lastUpdates);
    res.addColumn("TaskState", data: taskStates);
    res.addColumn("ChannelId", data: channelIds);
    res.addColumn("ProjectId", data: projectId);
    res.addColumn("ProjectName", data: projectName);
    _oldTable = res;
    print("\tfinal task table rows: ${res.nRows}");

    return res;
  }

  String getTaskType(sci.Task task) {
    if (task.kind == "CubeQueryTask") {
      return "Setup";
    }
    return "Computing";
  }

  @override
  Widget build(BuildContext context) {
    return buildComponents(context);
  }
}
