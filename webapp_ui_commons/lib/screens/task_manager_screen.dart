// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:webapp_components/components/action_list_component.dart';
// import 'package:webapp_components/components/workflow_list_component.dart';
// import 'package:webapp_components/screens/screen_base.dart';
// import 'package:webapp_model/webapp_data_base.dart';

// import 'package:webapp_ui_commons/mixin/progress_log.dart';

// import 'package:webapp_model/id_element_table.dart';
// import 'package:webapp_model/id_element.dart';

// import 'package:sci_tercen_model/sci_model.dart' as sci;

// class TaskManagerScreen extends StatefulWidget {
//   final WebAppDataBase modelLayer;
//   const TaskManagerScreen(this.modelLayer, {super.key});

//   @override
//   State<TaskManagerScreen> createState() => _TaskManagerScreenState();
// }

// class _TaskManagerScreenState extends State<TaskManagerScreen>
//     with ScreenBase, ProgressDialog {

//   Timer? refreshTimer;
//   bool firstRefresh = true;
//   List<sci.Workflow> currentList = [];
//   List<String> currentStatus = [];

//   @override
//   String getScreenId() {
//     return "TaskManagerScreen";
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     disposeScreen();
//     if( refreshTimer != null ){
//       refreshTimer!.cancel();
//     }
//   }

//   @override
//   void refresh() {
//     setState(() {});
//   }

//   @override
//   void initState() {
//     super.initState();
    
//     var workflowComponent = WorkflowListComponent("workflowList", getScreenId(), "Workflows", 
//           fetchWorkflows, ["name", "status", "date"],  widget.modelLayer.app.projectHref,
//           actions: [
//             ListAction(const Icon(Icons.cancel), widget.modelLayer.workflowService.cancelWorkflow, enabledCallback: widget.modelLayer.workflowService.canCancelWorkflow)
//           ],
//           emptyMessage: "Retrieving Tasks",
//           colWidths: [40, 10, 10],
//           detailColumn: "error");
//     addComponent("default", workflowComponent);

    

//     initScreen(widget.modelLayer);

//     refreshTimer = Timer.periodic( const Duration(seconds: 1), (timer) async {
//       if( await refreshWorkflowList()){
//         refresh();
//       }
//     });
//   }



//   Future<IdElementTable> fetchWorkflows( List<String> parentKeys, String groupId ) async {
//     var workflows = List<sci.Workflow>.from( currentList );

//     List<IdElement> nameCol = [];
//     List<IdElement> statusCol = [];
//     List<IdElement> dateCol = [];
//     List<IdElement> errorCol = [];

//     final dateFormatter =  DateFormat('yyyy/MM/dd hh:mm');
    
//     for( var w in workflows ){
//       var dt = DateTime.parse(w.lastModifiedDate.value);
//       var stMap =  await widget.modelLayer.workflowService.getWorkflowStatus(w);
//       nameCol.add(IdElement(w.id, w.name));
//       statusCol.add(IdElement(w.id, stMap["status"]!));
//       dateCol.add(IdElement(w.id, dateFormatter.format(dt)));
//       errorCol.add(IdElement(w.id, stMap["error"]!));

//     }
//     var tbl = IdElementTable()
//       ..addColumn("name", data: nameCol)
//       ..addColumn("status", data: statusCol)
//       ..addColumn("date", data: dateCol)
//       ..addColumn("error", data: errorCol);

//     return tbl;
//   }



//   Future<bool> refreshWorkflowList() async {
//     var workflowList = await widget.modelLayer.workflowService.fetchWorkflowsRemote(widget.modelLayer.project.id);

//     List<String> statusList = [];

//     for( var w in workflowList ){
//       var stMap = await widget.modelLayer.workflowService.getWorkflowStatus(w);
//       statusList.add( stMap["status"]!);
//     }
    
//     if( workflowList.length != currentList.length ){
//       currentList = workflowList;
//       currentStatus = statusList;
//       return true;  
//     }else{
//       for( var i = 0; i < workflowList.length; i++ ){
//         if( workflowList[i].id != currentList[i].id || currentStatus[i] != statusList[i] ){
//           currentList = workflowList;
//           currentStatus = statusList;
//           return true;  
//         }
//       }
//     }

//     return false;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return buildComponents(context);
//   }
// }