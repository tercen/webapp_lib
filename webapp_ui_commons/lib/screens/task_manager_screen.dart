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
import 'package:webapp_ui_commons/mixin/task_manager_state.dart';

import 'package:webapp_ui_commons/styles/styles.dart';

import 'package:sci_tercen_model/sci_model.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:webapp_utils/services/app_user.dart';
import 'package:webapp_utils/services/project_data_service.dart';

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
