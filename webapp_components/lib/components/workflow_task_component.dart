import 'package:flutter/material.dart';

import 'package:webapp_components/components/action_table_component.dart';

import 'package:webapp_components/definitions/list_action.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/functions/formatter_utils.dart';
import 'package:webapp_utils/functions/list_utils.dart';

import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_model/sci_model.dart' as sci;
import 'package:webapp_utils/services/workflow_data_service.dart';

class WorkflowTaskComponent extends ActionTableComponent {
  List<String> runningTasks = [];
  List<String> workflowTasks = [];

  WebappTable initTable = WebappTable();

  final List<ListAction> workflowActions;

  WorkflowTaskComponent(super.id, super.groupId, super.componentLabel,
      super.dataFetchCallback, super.actions, this.workflowActions,
      {super.excludeColumns, super.hideColumns});

  @override
  Widget createWidget(BuildContext context) {
    var table = dataTable;
    List<Widget> tableRows = [];

    for (var workflowTaskId in workflowTasks) {
      var idx = initTable["Id"].indexOf(workflowTaskId);

      var workflowName = initTable["Name"][idx];
      var tableLabel = Align(
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Text(
              "Tasks for  $workflowName",
              style: Styles()["textH2"],
            ),
            const SizedBox(
              width: 10,
            ),
            IconButton(
                onPressed: () {
                  workflowActions.first.callAction(
                      [initTable["WorkflowIds"][idx]],
                      context: context);
                },
                icon: workflowActions.first.getIcon(params: []))
          ],
        ),
      );

      tableRows.add(const SizedBox(
        height: 20,
      ));
      tableRows.add(tableLabel);
      tableRows.add(buildWorkflowTable(workflowTaskId, table, context));
      tableRows.add(const SizedBox(
        height: 20,
      ));
    }

    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tableRows);
  }

  Widget buildWorkflowTable(
      String workflowId, WebappTable table, BuildContext context) {
    // dataTable = table;
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

  Future<void> processTaskEvent(String channelId) async {
    var factory = tercen.ServiceFactory();
    var taskStream = factory.eventService.channel(channelId);
    await for (var evt in taskStream) {
      if (evt is sci.TaskStateEvent) {
        if (evt.state.isFinal) {
          runningTasks.remove(evt.taskId);
        } else {
          runningTasks.add(evt.taskId);
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
    if (hasCachedValue(workflowId)) {
      return getCachedValue(workflowId);
    } else {
      var workflowService = WorkflowDataService();
      var workflow = await workflowService.fetchWorkflow(workflowId);
      addToCache(workflowId, workflow);
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
    List<String> taskId = [];
    List<String> taskType = [];
    List<String> taskDuration = [];
    List<String> taskStatus = [];
    List<String> taskStep = [];

    if (runningTasks.isNotEmpty) {
      var tasks = await factory.taskService.list(runningTasks);
      var workflowTasks = tasks.whereType<sci.RunWorkflowTask>();
      var nonWorkflowTasks =
          tasks.where((task) => task is! sci.RunWorkflowTask);

      List<sci.Workflow> workflows = [];
      for (var ct in workflowTasks) {
        var workflowId = ct.workflowId;
        workflows.add(await getCachedWorkflow(workflowId));
        taskStep.add("");
        taskId.add(ct.id);
        taskType.add(ct.kind);
        taskDuration.add(DateFormatter.format(ct.lastModifiedDate));
        taskStatus.add(ct.state.kind);
      }
      for (var ct in nonWorkflowTasks) {
        taskStep.add(getStepName(ct.id, workflows));
        taskId.add(ct.id);
        taskType.add(ct.kind);
        taskDuration.add(DateFormatter.format(ct.lastModifiedDate));
        taskStatus.add(ct.state.kind);
      }
    }

    dataTable = WebappTable();
    dataTable.addColumn("Id", data: taskId);
    dataTable.addColumn("Type", data: taskType);
    // Only "workflow" steps have meta information about the step
    // dataTable.addColumn("Step", data: taskStep);
    dataTable.addColumn("Status", data: taskStatus);
    dataTable.addColumn("Last Modified", data: taskDuration);
  }

  @override
  Future<bool> loadTable() async {
    if (!isInit) {
      runningTasks.clear();
      var factory = tercen.ServiceFactory();

      initTable = await dataFetchCallback();

      workflowTasks = initTable["Id"].where((e) => e != "").toList();
      runningTasks.addAll(workflowTasks);

      await loadTaskTable();

      var tasks = await factory.taskService.list(workflowTasks);

      for (var task in tasks) {
        runningTasks.add(task.id);
        processTaskEvent(task.channelId);
      }
    }
    return true;
  }
}
