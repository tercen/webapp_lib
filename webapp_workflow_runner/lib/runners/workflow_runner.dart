import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:kumo_analysis_app/model/model_holder.dart';
// import 'package:kumo_analysis_app/model/data/settings.dart';

// import 'package:kumo_analysis_app/util/mixins/progress_log.dart';
// import 'package:kumo_analysis_app/util/util.dart';
// import 'package:kumo_analysis_app/webapp.dart';
// import 'package:kumo_analysis_app/webapp_data.dart';
// import 'package:sci_tercen_client/sci_client.dart' as sci;
// import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
// import 'package:tson/tson.dart' as tson;
// import 'package:sci_base/value.dart';
// import 'package:uuid/uuid.dart';

enum RunStatus { init, running, finished, fail }

typedef PostRunCallback = Future<void> Function();

class WorkflowRunner with ProgressDialog {
  StreamSubscription<sci.TaskEvent>? workflowTaskSubscription;
  
  final String projectId;
  final String teamName;
  final sci.Workflow template;
  
  final List<String> initStepIds = [];
  final Map<String, sci.Filters> filterMap = {};
  final Map<String, sci.Relation> tableMap = {};
  final Map<String, String> tableNameMap = {};
  final Map<String, String> gatherMap = {};
  final Map<String, String> multiDsMap = {};
  
  final List<SettingsEntry> settings = [];
  final List<PostRunCallback> postRunCallbacks = [];

  final Value status = ValueHolder<RunStatus>(RunStatus.init);

  String folderSuffix = "";
  String? folderId;
  String? workflowId;
  String workflowRename = "";
  String workflowIdentifier = "";
  String workflowSuffix = "";
  String stepProgressMessage = "";

  final List<String> stepsToRemove = [];

  

  WorkflowRunner( this.projectId, this.teamName, this.template) {
    // if( templateKey != ""){
    //   template = modelLayer.getWorkflow(key)  .installedWorkflows[templateKey]!;
    // }else{
    //   template = sci.Workflow();
    // }


  }

  void setNewWorkflowName( String name ){
    workflowRename = name;
  }

  String getWorkflowId() {
    return workflowId ?? "";
  }

  void addSetting(SettingsEntry setting) {
    settings.add(setting);
  }

  void addFolderSuffix(String suf){
    folderSuffix = "$folderSuffix$suf";
  }

  void addSettings(List<SettingsEntry> settings) {
    settings.addAll(settings);
  }

  void setMultiDataStep(String leftStepId, String rightStepId) {
    multiDsMap[leftStepId] = rightStepId;
  }

  void resetSteps(List<String> ids) {
    initStepIds.clear();
    initStepIds.addAll(ids);
  }

  void setWorkflowIdentifier(String id) {
    workflowIdentifier = id;
  }

  void setWorkflowSuffix(String suff) {
    workflowSuffix = suff;
  }

  void setFolder(String id) {
    folderId = id;
  }

  sci.FilterExpr createFilterExpr(String factorName, String factorValue) {
    sci.Factor filterFactor = sci.Factor()
      ..type = "string"
      ..name = factorName;
    var filterExpr = sci.FilterExpr()
      ..filterOp = "equals"
      ..stringValue = factorValue
      ..factor = filterFactor;

    // sci.Filter andFilter = sci.Filter()
    // ..logical = "and"
    // ..not = false;
    // andFilter.filterExprs.add(filterExpr);

    return filterExpr;
  }

  sci.RenameRelation _createDocumentRelation(String documentId) {
    var uuid = const Uuid();
    sci.Table tbl = sci.Table()..nRows = 1;
    sci.Column col = sci.Column()
      ..name = "documentId"
      ..type = "string"
      ..id = "documentId"
      ..nRows = 1
      ..size = -1
      ..values = tson.CStringList.fromList([uuid.v4()]);

    tbl.columns.add(col);

    col = sci.Column()
      ..name = ".documentId"
      ..type = "string"
      ..id = ".documentId"
      ..nRows = 1
      ..size = -1
      ..values = tson.CStringList.fromList([documentId]);

    tbl.columns.add(col);

    sci.InMemoryRelation rel = sci.InMemoryRelation()
      ..id = uuid.v4()
      ..inMemoryTable = tbl;
    sci.RenameRelation rr = sci.RenameRelation();
    rr.inNames.addAll(["documentId", ".documentId"]);
    rr.outNames.addAll(["documentId", ".documentId"]);
    rr.relation = rel;
    rr.id = "rename_${rel.id}";
    return rr;
  }

  void addTable(String stepId, sci.Table table, {String? name }) {
    var uuid = const Uuid();
    sci.InMemoryRelation rel = sci.InMemoryRelation()
      ..id = uuid.v4()
      ..inMemoryTable = table;
    tableMap[stepId] = rel;

    if( name != null && name != ""){
      tableNameMap[stepId] = name;
    }
  }

  void addDocument(String stepId, String documentId) {
    tableMap[stepId] = _createDocumentRelation(documentId);
  }

  void addGatherStepPattern(String stepId, String pattern) {
    gatherMap[stepId] = pattern;
  }

  void removeStep(String id) {
    stepsToRemove.add(id);
  }

  sci.Workflow removeStepFromWorkflow(String stepId, sci.Workflow workflow) {
    List<sci.Step> steps = List.from(workflow.steps);
    List<String> toRemoveIds = [stepId];

    while (toRemoveIds.isNotEmpty) {
      for (var id in toRemoveIds) {
        var idx = steps.indexWhere((stp) => stp.id == id);
        if (idx > -1) {
          steps.removeAt(idx);
        }
      }

      workflow.steps.clear();
      workflow.steps.addAll(steps);

      var links = workflow.links.toList();
      var idxToRemoveLinks = [];
      for (var i = 0; i < links.length; i++) {
        if (toRemoveIds.contains(links[i].inputId.split("-i-")[0])) {
          idxToRemoveLinks.add(i);
        }
        if (toRemoveIds.contains(links[i].outputId.split("-o-")[0])) {
          idxToRemoveLinks.add(i);
        }
      }
      for (var i in idxToRemoveLinks.reversed) {
        links.removeAt(i);
      }
      workflow.links.clear();
      workflow.links.addAll(links);
      toRemoveIds.clear();
      for (var step in steps) {
        var l = links.indexWhere((e) => e.inputId.contains(step.id));
        if (l == -1 && step.kind != "TableStep") {
          toRemoveIds.add(step.id);
        }
      }
    }

    return workflow;
  }

  List<String> getTableFactorNames(sci.CrosstabTable table) {
    List<String> factors = [];

    factors.addAll(
        table.graphicalFactors.map((e) => e.factor.name).where((e) => e != ""));

    return factors;
  }

  List<String> getFactorNames(String stepId) {
    List<String> factors = [];
    for (var stp in template.steps) {
      if (stp.id == stepId) {
        sci.DataStep dataStp = stp as sci.DataStep;
        for (var axis in dataStp.model.axis.xyAxis) {
          // Factors used in X and Y axes
          var facName = axis.xAxis.graphicalFactor.factor.name;
          if (facName != "") {
            factors.add(facName);
          }
          facName = axis.yAxis.graphicalFactor.factor.name;
          if (facName != "") {
            factors.add(facName);
          }
        }

        factors.addAll(getTableFactorNames(dataStp.model.columnTable));
        factors.addAll(getTableFactorNames(dataStp.model.rowTable));
      }
    }
    return factors;
  }

  List<String> convertToStepFactors(
      List<String> reqFactors, List<String> stepFactors) {
    List<String> factors = [];

    for (var reqFactor in reqFactors) {
      if (!reqFactor.contains("*")) {
        factors.add(reqFactor);
      } else {
        if (reqFactor.startsWith("*") && reqFactor.endsWith("*")) {
          var fac = reqFactor.replaceAll("*", "");
          var convFac =
              stepFactors.firstWhere((e) => e.contains(fac), orElse: () => "");
          if (convFac != "") {
            factors.add(convFac);
          } else {
            factors.add(reqFactor);
          }
        } else if (reqFactor.startsWith("*")) {
          var fac = reqFactor.replaceAll("*", "");
          var convFac =
              stepFactors.firstWhere((e) => e.endsWith(fac), orElse: () => "");
          if (convFac != "") {
            factors.add(convFac);
          } else {
            factors.add(reqFactor);
          }
        } else {
          var fac = reqFactor.replaceAll("*", "");
          var convFac = stepFactors.firstWhere((e) => e.startsWith(fac),
              orElse: () => "");
          if (convFac != "") {
            factors.add(convFac);
          } else {
            factors.add(reqFactor);
          }
        }
      }
    }

    return factors;
  }

  void addAndFilter(String stepId, List<String> keys, List<dynamic> values) {
    var factors = convertToStepFactors(keys, getFactorNames(stepId));

    sci.Filter andFilter = sci.Filter()
      ..logical = "and"
      ..not = false;

    for (var i = 0; i < factors.length; i++) {
      for (var j = 0; i < values.length; i++) {
        andFilter.filterExprs
            .add(createFilterExpr(factors[i], values[i][j] as String));
      }
    }

    if (!filterMap.containsKey(stepId)) {
      sci.NamedFilter tubeSpecFilter = sci.NamedFilter()
        ..logical = "or"
        ..not = false
        ..name = "Keep only";
      tubeSpecFilter.filterExprs.add(andFilter);

      sci.Filters filters = sci.Filters()..removeNaN = true;
      filters.namedFilters.add(tubeSpecFilter);
      filterMap[stepId] = filters;
    } else {
      sci.Filters filters = filterMap[stepId]!;
      filters.namedFilters[0].filterExprs.add(andFilter);
      filterMap[stepId] = filters;
    }
  }

  bool shouldResetStep(sci.Step step) {
    if (initStepIds.isEmpty) {
      return step.kind == "DataStep";
    } else {
      return initStepIds.contains(step.id);
    }
  }

  Future<sci.FolderDocument> createFolder(String projectId, String owner,
      {String? namePrefix,
      String? folderName,
      String parentFolderId = "",
      bool random = false,
      int nameLength = 5}) async {
    var factory = tercen.ServiceFactory();
    String name = folderName ?? getRandomString(nameLength);

    if (random == false && folderName == null) {
      final DateFormat formatter = DateFormat('yyyyMMdd_hhmmss');

      name = formatter.format(DateTime.now());
    }

    if (namePrefix != null) {
      name = "$namePrefix$name";
    }

    sci.FolderDocument folder = sci.FolderDocument();
    folder.name = "$name$folderSuffix";
    folder.acl.owner = owner;
    folder.projectId = projectId;
    folder.folderId = parentFolderId;

    return await factory.folderService.create(folder);
  }


  String getWorkflowName(sci.Workflow workflow){
    final DateFormat formatter = DateFormat('yyyyMMdd_hhmmss');
    workflowIdentifier =
        workflowIdentifier == "" ? "" : "$workflowIdentifier";

    workflowSuffix = workflowSuffix == "" ? "" : "_$workflowSuffix";
    
    var basename = workflowRename == "" ? workflow.name : workflowRename;


    return    "$basename$workflowIdentifier${formatter.format(DateTime.now())}$workflowSuffix";
  }


  void addPostRun(PostRunCallback callback ){
    postRunCallbacks.add(callback);

  }

  Future<sci.Workflow> doRun(BuildContext context) async {
    if( template.id == ""){
      throw Exception("Workflow not set in WorkflowRunner.");
    }

    status.value = RunStatus.running;
    var factory = tercen.ServiceFactory();

    var runTitle = getWorkflowName(template);

    openDialog(context);

    log("Set up", dialogTitle: runTitle);



    //-----------------------------------------
    // Copy template into project
    //-----------------------------------------
    var workflow =
        await factory.workflowService.copyApp(template.id, projectId);

    for (var stepToRemove in stepsToRemove) {
      workflow = removeStepFromWorkflow(stepToRemove, workflow);
    }

    //-----------------------------------------
    // Step-specific setup
    //-----------------------------------------
    for (var stp in workflow.steps) {
      if (stp.kind == "DataStep") {
        stp = updateOperatorSettings(stp as sci.DataStep, settings);
      }

      if (shouldResetStep(stp)) {
        stp.state.taskState = sci.InitState();
        stp.state.taskId = "";
      }

      if (multiDsMap.containsKey(stp.id)) {
        var tmpStp = stp as sci.DataStep;
        tmpStp.parentDataStepId = multiDsMap[stp.id]!;
      }

      if (filterMap.containsKey(stp.id)) {
        sci.DataStep dataStp = stp as sci.DataStep;
        dataStp.model.filters = filterMap[stp.id]!;
      }

      if (tableMap.containsKey(stp.id)) {
        sci.TableStep tmpStp = stp as sci.TableStep;
        tmpStp.model.relation = tableMap[stp.id]!;
        tmpStp.state.taskState = sci.DoneState();

        if( tableNameMap.containsKey(stp.id)){
          tmpStp.name = tableNameMap[stp.id]!;
        }

        stp = tmpStp;
      }

      if (gatherMap.containsKey(stp.id)) {
        (stp as sci.MeltStep).model.selectionPattern = gatherMap[stp.id]!;
      }
    }

    //-----------------------------------------
    // General workflow parameters
    //-----------------------------------------
    if (folderId == null) {
      sci.FolderDocument folder = await createFolder(projectId, teamName);
      workflow.folderId = folder.id;
    } else {
      workflow.folderId = folderId!;
    }

    workflow.name = getWorkflowName(workflow);
        
    
    workflow.acl = sci.Acl()..owner = teamName;
    workflow.id = "";
    workflow.rev = "";

    workflow.isHidden = false;
    workflow.isDeleted = false;

    workflow = await factory.workflowService.create(workflow);

    workflowId = workflow.id;

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

    updateStepProgress(workflow);

    var taskStream = workflowStream(workflowTask.id);

    log(stepProgressMessage, dialogTitle: runTitle);

    await for (var evt in taskStream) {
      if (evt is sci.TaskProgressEvent) {
        log("$stepProgressMessage\n\nTask Log\n${evt.message}",
            dialogTitle: runTitle);
      } else if (evt is sci.TaskLogEvent) {
        log("$stepProgressMessage\n\nTask Log\n${evt.message}",
            dialogTitle: runTitle);
      } else {
        if (evt is sci.TaskStateEvent) {
          if (evt.state is sci.DoneState) {
            var runningWorkflow =
                await factory.workflowService.get(workflow.id);
            updateStepProgress(runningWorkflow);
            log("$stepProgressMessage\n\n \n ", dialogTitle: runTitle);
          }
        }
      }
    }

    var doneWorkflow = await factory.workflowService.get(workflow.id);

    for (var stp in doneWorkflow.steps) {
      stp.state.taskState.throwIfNotDone();
    }

    log("$stepProgressMessage\n\n \nRunning final updates", dialogTitle: runTitle);    
    for (var f in postRunCallbacks) {
      await f();
    }

    // await handler.reloadProjectFiles();

    // if (notificationKey != null) {
      // handler.sendProjectFileUpdateNotification(notificationKey!);
    // }

    await Future.delayed(const Duration(milliseconds: 1000), () {
      status.value = RunStatus.finished;
      closeLog();
    });

    workflowId = doneWorkflow.id;

    return doneWorkflow;
  }




  Stream<sci.TaskEvent> workflowStream(String taskId) async* {
    var factory = tercen.ServiceFactory();
    bool startTask = true;
    var task = await factory.taskService.get(taskId);

    while (!task.state.isFinal) {
      var taskStream = factory.eventService
          .listenTaskChannel(taskId, startTask)
          .asBroadcastStream();

      startTask = false;
      await for (var evt in taskStream) {
        yield evt;
      }
      task = await factory.taskService.get(taskId);

    }

  }

  sci.DataStep updateOperatorSettings(
      sci.DataStep stp, List<SettingsEntry> settingsList) {
    for (var setting in settingsList) {
      if (stp.id == setting.stepId) {
        for (var i = 0;
            i < stp.model.operatorSettings.operatorRef.propertyValues.length;
            i++) {
          if (stp.model.operatorSettings.operatorRef.propertyValues[i].name ==
              setting.settingName) {
            stp.model.operatorSettings.operatorRef.propertyValues[i].value =
                setting.textValue;
          }
        }
      }
    }
    return stp;
  }

  List<sci.Step> _getTopSteps(List<sci.Step> steps) {
    return steps.where((e) => e.inputs.isEmpty).toList();
  }

  List<sci.Step> _getParents(sci.Step step, sci.Workflow workflow) {
    List<sci.Step> parents = [];
    var links = workflow.links;

    for (var link in links) {
      if (step.inputs.map((e) => e.id).toList().contains(link.inputId)) {
        for (var s in workflow.steps) {
          if (s.outputs.map((e) => e.id).toList().contains(link.outputId)) {
            parents.add(s);
          }
        }
      }
    }

    return parents;
  }

  String _getStepStatus(sci.Step stp, sci.Workflow workflow) {
    if (stp.state.taskState.kind == "DoneState") {
      return "Done.......";
    }

    var parents = _getParents(stp, workflow);

    bool allParentsDone = true;
    for (var parent in parents) {
      if (parent.state.taskState.kind != "DoneState") {
        allParentsDone = false;
      }
    }

    if (allParentsDone) {
      return "Running..";
    } else {
      return "...............";
    }
  }

  List<sci.Step> _getChildren(sci.Step parent, sci.Workflow workflow) {
    List<sci.Step> children = [];
    var links = workflow.links;

    for (var link in links) {
      if (parent.outputs.map((e) => e.id).toList().contains(link.outputId)) {
        for (var s in workflow.steps) {
          if (s.inputs.map((e) => e.id).toList().contains(link.inputId)) {
            children.add(s);
          }
        }
      }
    }

    return children;
  }

  void updateStepProgress(sci.Workflow workflow, {sci.Step? step}) {
    if (step == null) {
      stepProgressMessage = "";
      var topSteps = _getTopSteps(workflow.steps);
      for (var stp in topSteps) {
        stepProgressMessage += _getStepStatus(stp, workflow);
        stepProgressMessage += "....";
        stepProgressMessage += stp.name;
        stepProgressMessage += "\n";
      }

      for (var stp in topSteps) {
        var children = _getChildren(stp, workflow);
        for (var child in children) {
          updateStepProgress(workflow, step: child);
        }
      }
    } else {
      stepProgressMessage += _getStepStatus(step, workflow);
      stepProgressMessage += "....";
      stepProgressMessage += step.name;
      stepProgressMessage += "\n";

      var children = _getChildren(step, workflow);
      for (var child in children) {
        updateStepProgress(workflow, step: child);
      }
    }
  }
}
