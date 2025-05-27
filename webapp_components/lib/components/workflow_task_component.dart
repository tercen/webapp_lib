import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:webapp_components/components/action_table_component.dart';

import 'package:webapp_components/definitions/list_action.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/cache_object.dart';
import 'package:webapp_utils/functions/formatter_utils.dart';
import 'package:webapp_utils/functions/list_utils.dart';

import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_model/sci_model.dart' as sci;
import 'package:webapp_utils/functions/logger.dart';
import 'package:webapp_utils/services/workflow_data_service.dart';
import 'package:async/async.dart';

class RunningTask {
  String taskId;
  String workflowId;
  RunningTask(this.taskId, this.workflowId);

  @override
  int get hashCode => taskId.hashCode;

  @override
  bool operator ==(Object other) {
    final eqObject = other is RunningTask;
    final otherR = other as RunningTask;
    final eqTask = taskId == otherR.taskId;
    final eqWorkflow = workflowId == otherR.workflowId;
    return eqObject && eqTask && eqWorkflow;
  }
}

class WorkflowTaskComponent extends ActionTableComponent {
  List<RunningTask> runningTasks = [];

  Future Function()? onEmptyQueu;
  final List<ListAction> workflowActions;
  bool firstEmpty = true;

  List<CancelableOperation> futures = [];
  CacheObject workflowCache = CacheObject();

  WorkflowTaskComponent(super.id, super.groupId, super.componentLabel,
      super.dataFetchCallback, super.actions, this.workflowActions,
      {super.excludeColumns, super.hideColumns, this.onEmptyQueu}) {
    hideColumns = [".key", "IsWorkflowTask", "Workflow Name", "Workflow Id"];
  }

  @override
  void dispose() {
    super.dispose();
    for (var f in futures) {
      f.cancel();
    }
  }

  @override
  Widget buildEmptyTable() {
    if (firstEmpty == true && onEmptyQueu != null) {
      onEmptyQueu!();
      firstEmpty = false;
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Center(
        child: Text("No running tasks", style: Styles()["text"]),
      ),
    );
  }

  @override
  Widget createWidget(BuildContext context) {
    firstEmpty = true;
    var table = dataTable;

    List<Widget> tableRows = [];

    final wkfTaskTable = table.selectByColValue(["Type"], ["Workflow"]);

    for (var ri = 0; ri < wkfTaskTable.nRows; ri++) {
      final row = wkfTaskTable.select([ri]);
      final assocTasksTable =
          table.selectByColValue(["Workflow Id"], [row["Workflow Id"].first]);

      final workflowName = row["Workflow Name"].first;
      final tableLabel = Align(
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Text(
              "Tasks for $workflowName",
              style: Styles()["textH2"],
            ),
            const SizedBox(
              width: 10,
            ),
            IconButton(
                onPressed: () {
                  workflowActions.first
                      .callAction([row["Workflow Id"].first], context: context);
                },
                icon: workflowActions.first.getIcon(params: []))
          ],
        ),
      );

      tableRows.add(const SizedBox(
        height: 20,
      ));
      tableRows.add(tableLabel);
      tableRows.add(buildWorkflowTable(assocTasksTable, context));
      tableRows.add(const SizedBox(
        height: 20,
      ));
    }

    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tableRows);
  }

  Widget buildWorkflowTable(WebappTable table, BuildContext context) {
    var nRows = table.nRows;

    colNames = table.colNames
        .where((colName) => shouldIncludeColumn(colName))
        .toList();

    var colNamesWithStatus =
        colNames.where((colName) => shouldDisplayColumn(colName)).toList();

    List<TableRow> rows = [];
    rows.add(createTableHeader(colNamesWithStatus));

    var indices = List<int>.generate(nRows, (i) => i);
    if (sortDirection != "" && sortingCol != "") {
      indices = ListUtils.getSortedIndices(table.columns[sortingCol]!);

      if (sortDirection == "desc") {
        indices = indices.reversed.toList();
      }
    }

    for (var si = 0; si < indices.length; si++) {
      var ri = indices[si];
      var key = table.columns[".key"]![ri];
      var rowEls = colNames.map((col) => table.columns[col]![ri]).toList();
      // await
      rows.add(createTableRow(context, rowEls, key, actions, rowIndex: si));
    }

    Map<int, TableColumnWidth> colWidths = infoBoxBuilder == null
        ? const {0: FixedColumnWidth(30)}
        : {0: const FixedColumnWidth(30), 1: const FixedColumnWidth(50)};

    var tableWidget = Table(
      columnWidths: colWidths,
      children: rows,
    );

    return tableWidget;
  }

  Future<void> processTaskEvent(String channelId, String workflowId) async {
    var factory = tercen.ServiceFactory();
    var taskStream = factory.eventService.channel(channelId);
    await for (var evt in taskStream) {
      if (evt is sci.TaskStateEvent) {
        if (evt.state.isFinal) {
          runningTasks.remove(RunningTask(evt.taskId, workflowId));
        } else {
          if (!runningTasks.contains(RunningTask(evt.taskId, workflowId))) {
            runningTasks.add(RunningTask(evt.taskId, workflowId));
          }
        }

        runningTasks = runningTasks.toSet().toList();
        await loadTaskTable();
        notifyListeners();
      }
    }
  }

  @override
  Future<void> init() async {
    await super.init();
    await loadTable();
    // await loadTaskTable();

    notifyListeners();
  }

  Future<sci.Workflow> getCachedWorkflow(String workflowId) async {
    if (workflowCache.hasCachedValue(workflowId)) {
      return workflowCache.getCachedValue(workflowId);
    } else {
      var workflowService = WorkflowDataService();
      var workflow = await workflowService.findWorkflowById(workflowId);

      // var workflow = await workflowService.findWorkflowById(workflowId);
      workflowCache.addToCache(workflowId, workflow);
      return workflow;
    }
  }

  String getStepName(String taskId, List<sci.Workflow> workflowList) {
    var stepName = "";

    for (var w in workflowList) {
      stepName = w.steps
          .whereType<sci.DataStep>()
          .firstWhere((step) => step.state.taskId == taskId,
              orElse: () => sci.DataStep())
          .name;
      if (stepName.isNotEmpty) {
        break;
      }
    }

    return stepName;
  }

  Future<void> loadTaskTable() async {
    var factory = tercen.ServiceFactory();
    List<String> keys = [];
    List<String> taskId = [];
    List<String> taskType = [];
    List<String> taskDuration = [];
    List<String> taskStatus = [];
    List<String> taskStep = [];
    List<String> workflowIds = [];
    List<String> workflowNames = [];

    if (runningTasks.isNotEmpty) {
      var tasks = await factory.taskService
          .list(runningTasks.map((e) => e.taskId).toList());

      for (var taskIdInfo in runningTasks) {
        final ct = tasks.firstWhere((task) => task.id == taskIdInfo.taskId,
            orElse: () => sci.Task());
        if (ct.id == "") {
          continue;
        }

        var workflowId = taskIdInfo.workflowId;
        var wkf = await getCachedWorkflow(workflowId);
        keys.add(const Uuid().v4());
        taskStep.add("");
        taskId.add(ct.id);
        taskType.add(formatTaskType(ct.kind));
        taskDuration.add(
            DateFormatter.formatLong(ct.lastModifiedDate, shortYear: true));
        taskStatus.add(formatState(ct.state.kind));
        workflowIds.add(workflowId);
        workflowNames.add(wkf.name);
      }
    }

    dataTable = WebappTable();
    dataTable.addColumn(".key", data: keys);
    dataTable.addColumn("Id", data: taskId);
    dataTable.addColumn("Type", data: taskType);
    dataTable.addColumn("IsWorkflowTask",
        data: taskType
            .map((t) => t == "Workflow")
            .map((e) => e.toString())
            .toList());
    // Only "workflow" steps have meta information about the step
    // dataTable.addColumn("Step", data: taskStep);
    dataTable.addColumn("Status", data: taskStatus);
    dataTable.addColumn("Last Modified", data: taskDuration);
    dataTable.addColumn("Workflow Id", data: workflowIds);
    dataTable.addColumn("Workflow Name", data: workflowNames);
  }

  String formatTaskId(String id) {
    return "...${id.substring(id.length - 5)}";
  }

  String formatTaskType(String task) {
    switch (task) {
      case 'RunWorkflowTask':
        return "Workflow";
      case 'RunComputationTask':
        return "Step Task";
      case 'CubeQueryTask':
        return "Step Setup";
      default:
        return task;
    }
  }

  String formatState(String state) {
    return state.replaceAll("State", "");
  }

  @override
  void reset() async {
    for (var f in futures) {
      await f.cancel();
    }

    runningTasks.clear();
    super.reset();
  }

  @override
  Future<bool> loadTable() async {
    if (!isInit) {
      runningTasks.clear();
      var factory = tercen.ServiceFactory();

      final initTable = await dataFetchCallback();
      final taskIds = initTable["Id"].where((e) => e != "").toList();

      var tasks = await factory.taskService.list(taskIds);

      runningTasks.addAll(tasks
          .whereType<sci.RunWorkflowTask>()
          .map((el) => RunningTask(el.id, el.workflowId)));
      runningTasks = runningTasks.toSet().toList();

      //Start listening to worklfow task channel
      for (var task in tasks.whereType<sci.RunWorkflowTask>()) {
        futures.add(CancelableOperation.fromFuture(
            processTaskEvent(task.channelId, task.workflowId),
            onCancel: () => Logger().log(
                level: Logger.FINER, message: "Process task was cancelled")));
      }

      await loadTaskTable();
    }
    return true;
  }
}
