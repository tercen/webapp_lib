
import 'package:flutter/material.dart';





import 'package:webapp_components/screens/screen_base.dart';

import 'package:webapp_model/webapp_data_base.dart';

import 'package:webapp_ui_commons/mixin/progress_log.dart';
import 'package:webapp_ui_commons/mixin/task_manager_state.dart';



class TaskManagerScreen extends StatefulWidget {
  final WebAppDataBase modelLayer;
  const TaskManagerScreen(this.modelLayer, {super.key});

  @override
  State createState() => TaskManagerScreenState();
}

class TaskManagerScreenState extends State<TaskManagerScreen> 
    with ScreenBase, ProgressDialog, TaskManagerStateMixin<TaskManagerScreen> {
  // bool showAllWorkflows = false;
  // bool running = false;
  // DateTime? lastWorkflowListLoad;
  // DateTime? lastTaskFetch;
  // bool isFetchingTask = false;
  // late final Timer workflowRefreshTimer;
  // final Map<String, int> _offsetMaps = {};

  @override
  void initState() {
    super.initState();
    initScreen(widget.modelLayer);
  }
}
