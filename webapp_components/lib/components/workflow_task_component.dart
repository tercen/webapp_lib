import 'dart:async';

import 'package:flutter/material.dart';

import 'package:webapp_components/components/action_table_component.dart';

import 'package:webapp_components/definitions/list_action.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_model/sci_model.dart' as sci;

import 'package:async/async.dart';

class WorkflowTaskComponent extends ActionTableComponent {
  Future Function()? onEmptyQueu;
  final List<ListAction> workflowActions;
  bool firstEmpty = true;

  List<CancelableOperation> futures = [];
  CancelableOperation? _reloadOp;
  bool markedForReload = false;

  final Set<String> _channelsOnListen = {};
  final List<String> _processedEvents = [];
  final List<String> _closedChannels = [];
  final List<double> widths;

  WorkflowTaskComponent(super.id, super.groupId, super.componentLabel,
      super.dataFetchCallback, super.actions, this.workflowActions,
      {super.excludeColumns, super.hideColumns, this.onEmptyQueu, this.widths = const []}) {
    super.useCache = false;
    hideColumns = [
      "TaskId",
      "WorkflowId",
      "WorkflowName",
      "ChannelId",
      "ProjectId",
      "ProjectName",
      ...super.hideColumns ?? []
    ];
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

  // @override
  // void reset() {
  //   super.reset();
  //   selected.clear();
  // }

  Future reload() async {
    dataTable = await dataFetchCallback();
    markedForReload = false;
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    if (dataTable.nRows == 0 && _channelsOnListen.isEmpty) {
      return buildEmptyTable();
    } else {
      return createWidget(context);
    }
  }

  List<String> get _uniqueWorkflowIds {
    if (dataTable.isEmpty) {
      // Should never be the case
      return [];
    }

    final wkfTbl = dataTable.selectByColValue(["TaskType"], ["Workflow Task"]);

    return wkfTbl["WorkflowId"].toSet().where((e) => e.isNotEmpty).toList();
  }

  void _updateTaskState(String taskId, String newState){
    for( var ri = 0; ri < 0; ri++){
      if(dataTable["TaskId"][ri] == taskId){
        dataTable["TaskState"][ri] = newState;
        notifyListeners();
        break;
      }
    }
  }

  Future<void> _listenToChannel(
      {required String channelId, required String taskType, required taskId}) async {
    if (!_channelsOnListen.contains(channelId) || _closedChannels.contains(channelId)) {
      return;
    }
    var factory = tercen.ServiceFactory();
    var taskStream = factory.eventService.channel(channelId);
    await for (var evt in taskStream) {
      if (evt is sci.TaskStateEvent) {
        final evtId = "${evt.id}_${evt.date.value}_${evt.state.kind}";
        if( !_processedEvents.contains(evtId)){
        // _updateTaskState(taskId, evt.state.kind);
        if (evt.state.isFinal ) {

          _channelsOnListen.remove(channelId);
          _closedChannels.add(channelId);
          if (taskType == "RunWorkflowTask") {
            onEmptyQueu!();
          }
        }
          _processedEvents.add(evtId);
          markedForReload = true;
        
        _updateTaskState(taskId, evt.state.kind);
        
        
        
          // print("Triggering reload for $evtId");
          
          // reload();
          // await _reloadOp?.cancel();
          // _reloadOp = CancelableOperation.fromFuture(reload(), onCancel: () => print("Cancelling previous reload"),);
        }
      }else{
        print("Event type: ${evt.kind}");
      }
    }
  }

  List<double> _updateColumnWidths(
      {required List<double> widths, required List<String> displayEls}) {
    if (widths.isEmpty) {
      widths.addAll(displayEls.map((el) => el.length.toDouble()));
    } else {
      var tmp = displayEls.map((el) => el.length.toDouble()).toList();

      for (var k = 0; k < widths.length; k++) {
        widths[k] = widths[k] + tmp[k];
      }
    }

    return widths;
  }

  Widget _buildTaskList(BuildContext context, WebappTable taskTable) {
    // final wdgList = <Widget>[];
    if (taskTable.nRows == 0) {
      return Container();
    }
    List<TableRow> rows = [];

    var colNames = taskTable.colNames
        .where((colName) => shouldIncludeColumn(colName))
        .where((col) => hideColumns == null || !hideColumns!.contains(col));

    rows.add(createTableHeader(colNames.toList()));

    var cWidths = List<double>.from(widths);

    for (var ri = 0; ri < taskTable.nRows; ri++) {
      var tableRow = taskTable.select([ri]);
      _listenToChannel(
          channelId: tableRow["ChannelId"].first,
          taskType: tableRow["TaskType"].first,
          taskId: tableRow["TaskId"].first);
      if (tableRow["TaskType"].first == "RunWorkflowTask") {
        continue;
      }

      var tr = createTableRow(context, tableRow, "not_used", actions,
          displayCols: colNames.toList(), rowIndex: ri);
      rows.add(tr);

      var displayEls = colNames.map((col) => taskTable[col][ri]).toList();

      if( cWidths.isEmpty ){
        cWidths = _updateColumnWidths(widths: cWidths, displayEls: displayEls);
      }
      
    }

    var totalWidth = cWidths.reduce((a, b) => a + b);
    final relativeWidth = cWidths.map((w) => (w / totalWidth) * 0.95).toList(); 

    Map<int, TableColumnWidth> colWidths = infoBoxBuilder == null
        ? {0: const FixedColumnWidth(5)}
        : {0: const FixedColumnWidth(50)};

    for (var k = 0; k < relativeWidth.length; k++) {
      colWidths[k + 1] = FractionColumnWidth(relativeWidth[k]);
    }

    colWidths[relativeWidth.length + 1] =
        const FractionColumnWidth(0.03); // Actions

    var tableWidget = Table(
      columnWidths: colWidths,
      children: rows,
    );
    return tableWidget;
  }

  Widget _buildWorkflowTaskTable(BuildContext context, String workflowId) {
    final wkfTbl = dataTable.selectByColValue(["WorkflowId"], [workflowId]);
    final tbl =
        wkfTbl.selectBySingleColValues("TaskType", ["Setup", "Computing"]);

    return Column(
      children: [
        _buildWorkflowTableTop(context, row: wkfTbl),
        tbl.nRows > 0 ? _buildTaskList(context, tbl) : Container(),
        const SizedBox(
          height: 25,
        )
      ],
    );
  }

  Widget _buildWorkflowTableTop(BuildContext context,
      {required WebappTable row}) {
    final workflowName = row["WorkflowName"].first;
    final projectName = row["ProjectName"].first;

    final workflowTableTop = Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tasks for $workflowName",
                  style: Styles()["textH2"],
                ),
                Text(
                  "In: $projectName",
                  style: Styles()["text"],
                ),
                const SizedBox(
                  height: 5,
                ),
              ]),
          const SizedBox(
            width: 10,
          ),
          IconButton(
              onPressed: () {
                workflowActions.first.callAction(row, context: context);
              },
              icon: workflowActions.first.getIcon())
        ],
      ),
    );

    return workflowTableTop;
  }

  @override
  Widget createWidget(BuildContext context) {
    firstEmpty = true;
    final workflowIds = _uniqueWorkflowIds;
    var taskTables = <Widget>[];
    for (var workflowId in workflowIds) {
      taskTables.add(_buildWorkflowTaskTable(context, workflowId));
    }

    return Column(
      children: taskTables,
    );
  }

  @override
  Future<void> init() async {
    await super.init();
    await loadTable();

    notifyListeners();
  }
}
