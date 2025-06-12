// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';

// import 'package:webapp_components/components/action_bar_component.dart';
// import 'package:webapp_components/components/action_table_component.dart';
// import 'package:webapp_components/components/workflow_task_component.dart';

// import 'package:webapp_components/definitions/list_action.dart';

// import 'package:webapp_components/screens/screen_base.dart';

// import 'package:webapp_components/widgets/wait_indicator.dart';
// import 'package:webapp_model/webapp_data_base.dart';

// import 'package:webapp_model/webapp_table.dart';
// import 'package:webapp_ui_commons/mixin/progress_log.dart';

// import 'package:webapp_ui_commons/styles/styles.dart';
// import 'package:webapp_utils/functions/formatter_utils.dart';

// import 'package:sci_tercen_model/sci_model.dart' as sci;
// import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
// import 'package:webapp_utils/services/app_user.dart';

// class TaskManagerScreen extends StatefulWidget {
//   final WebAppDataBase modelLayer;
//   const TaskManagerScreen(this.modelLayer, {super.key});

//   @override
//   State createState() => TaskManagerScreenState();
// }

// class TaskManagerScreenState extends State<TaskManagerScreen>
//     with ScreenBase, ProgressDialog {
//   @override
//   String getScreenId() {
//     return "TaskManagerScreen";
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     disposeScreen();
//   }

//   @override
//   void refresh() {
//     setState(() {});
//   }

//   bool showAllWorkflows = false;

//   ActionTableComponent createFinishedWorkflowComponent() {
//     return ActionTableComponent(
//         "workflows",
//         getScreenId(),
//         "Finished Workflows",
//         fetchWorkflows,
//         [
//           ListAction(Icon(Icons.info_outline, color: Styles()["buttonBgLight"]),
//               workflowInfoWithError),
//         ],
//         hideColumns: ["Id"],
//         useCache: false);
//   }

//   ActionTableComponent createTasksComponent() {
//     return WorkflowTaskComponent(
//         "tasks", getScreenId(), "Running Tasks", fetchTasks, [
//       ListAction(
//           Icon(Icons.stop_circle_rounded, color: Styles()["buttonBgLight"]),
//           cancelTask,
//           confirmationMessage: "Are you sure you want to cancel this task?"),
//     ], [
//       ListAction(
//           Icon(Icons.info_outline_rounded, color: Styles()["buttonBgLight"]),
//           workflowInfo)
//     ],
//         hideColumns: [
//           "Id"
//         ]);
//   }

//   @override
//   void initState() {
//     super.initState();

//     var toolbar = ActionBarComponent("actionBar", getScreenId(), [
//       ListAction(Icon(Icons.refresh, color: Styles()["buttonBgLight"]), reload,
//           buttonLabel: "Refresh", description: "Reload list of workflows"),
//     ]);

//     var workflowList = createFinishedWorkflowComponent();

//     var taskList = createTasksComponent();

//     addComponent("default", toolbar);
//     addComponent("default", workflowList);
//     addComponent("default", taskList);

//     initScreen(widget.modelLayer);
//   }

//   Future<void> reload(List<String> values) async {
//     var comp = getComponent("workflows") as ActionTableComponent;
//     comp.reset();
//     comp.init();

//     var taskComp = getComponent("tasks") as ActionTableComponent;
//     taskComp.reset();
//     taskComp.init();

//     refresh();
//   }

//   Future<void> cancelTask(List<String> row) async {
//     Fluttertoast.showToast(
//         msg: "Cancelling task",
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.BOTTOM_LEFT,
//         webPosition: "left",
//         webBgColor: "linear-gradient(to bottom, #aaaaff, #eeeeaff)",
//         timeInSecForIosWeb: 1,
//         backgroundColor: Colors.lightBlue[100],
//         textColor: Styles()["black"],
//         fontSize: 16.0);

//     await widget.modelLayer.workflowService
//         .cancelWorkflowTask(row.first, deleteWorkflow: true);
//   }

//   Future<Widget> workflowSettingsInfoBox(String workflowId,
//       {bool printError = false}) async {
//     var factory = tercen.ServiceFactory();
//     var workflow = await factory.workflowService.get(workflowId);

//     Widget content = Container();

//     var metaList = workflow.meta;

//     var contentString = "\n\nGeneral Settings:\n";

//     for (var meta in metaList) {
//       if (meta.key.startsWith("setting")) {
//         contentString += meta.key.split(".").last;
//         contentString += ": ";
//         contentString += meta.value;
//         contentString += "\n";
//       }
//     }

//     if (printError) {
//       var status =
//           await widget.modelLayer.workflowService.getWorkflowStatus(workflow);
//       if (status["error"] != null && status["error"] != "") {
//         contentString += "\nERROR INFORMATION";
//         contentString += "\n\n";
//         contentString += status["error"]!;
//       }
//     }

//     content = Text(
//       contentString,
//       style: Styles()["text"],
//     );
//     return content;
//   }

//   Future<void> workflowInfoWithError(List<String> row) async {
//     showDialog(
//         context: context,
//         builder: (dialogContext) {
//           return StatefulBuilder(builder: (stfCtx, stfSetState) {
//             return FutureBuilder(
//                 future: workflowSettingsInfoBox(row.first, printError: true),
//                 builder: (context, snapshot) {
//                   if (snapshot.hasData && snapshot.data != null) {
//                     return AlertDialog(
//                       title: Text(
//                         "Workflow Information",
//                         style: Styles()["textH2"],
//                       ),
//                       content: snapshot.data!,
//                     );
//                   } else {
//                     return TercenWaitIndicator()
//                         .waitingMessage(suffixMsg: "Loading information");
//                   }
//                 });
//           });
//         });
//   }

//   Future<void> workflowInfo(List<String> row) async {
//     showDialog(
//         context: context,
//         builder: (dialogContext) {
//           return StatefulBuilder(builder: (stfCtx, stfSetState) {
//             return FutureBuilder(
//                 future: workflowSettingsInfoBox(row.first),
//                 builder: (context, snapshot) {
//                   if (snapshot.hasData && snapshot.data != null) {
//                     return AlertDialog(
//                       title: Text(
//                         "Workflow Information",
//                         style: Styles()["textH2"],
//                       ),
//                       content: snapshot.data!,
//                     );
//                   } else {
//                     return TercenWaitIndicator()
//                         .waitingMessage(suffixMsg: "Loading information");
//                   }
//                 });
//           });
//         });
//   }

//   Future<WebappTable> fetchWorkflows() async {
//     return await widget.modelLayer.workflowService
//         .fetchWorkflowTable();
//   }

//   Future<WebappTable> fetchTasks() async {
//     var res = WebappTable();

//     var factory = tercen.ServiceFactory();
//     var tasks = await factory.taskService.getTasks(["RunWorkflowTask"]);
//     var compTasks = tasks.whereType<sci.RunWorkflowTask>();
//     var workflowIds = compTasks.map((task) => task.workflowId).toList();
//     var workflows = await factory.workflowService.list(workflowIds);

//     res.addColumn("Id", data: compTasks.map((w) => w.id).toList());
//     res.addColumn("Name", data: workflows.map((w) => w.name).toList());
//     res.addColumn("WorkflowIds", data: workflows.map((w) => w.id).toList());
//     res.addColumn("Last Update",
//         data: workflows
//             .map((w) => DateFormatter.formatShort(w.lastModifiedDate))
//             .toList());

//     return res;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return buildComponents(context);
//   }
// }
