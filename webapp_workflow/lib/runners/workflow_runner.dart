import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:webapp_ui_commons/mixin/progress_log.dart';

import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:tson/tson.dart' as tson;
// import 'package:sci_base/value.dart';
import 'package:uuid/uuid.dart';
import 'package:webapp_utils/functions/string_utils.dart';
import 'package:webapp_utils/model/step_setting.dart';
import 'package:webapp_utils/services/app_user.dart';

enum TimestampType { full, short }

typedef PostRunCallback = Future<void> Function();
typedef PostRunIdCallback = Future<void> Function(sci.Workflow workflow);

class FilterConfig {
  final String filterName;
  final String stepId;
  final List<String> keys;
  final List<dynamic> values;
  final String boolOp;
  final List<sci.Pair> metas;
  final String comp;

  FilterConfig(
      {required this.filterName,
      required this.stepId,
      required this.keys,
      required this.values,
      required this.boolOp,
      required this.metas,
      this.comp = "equals"});
}

class WorkflowRunner with ProgressDialog {
  StreamSubscription<sci.TaskEvent>? workflowTaskSubscription;
  StreamSubscription? subscription;
  String? folderName;
  String? parentFolderId;

  final List<String> initStepIds = [];
  final List<sci.Pair> workflowMeta = [];

  final List<FilterConfig> filterConfigList = [];

  final List<sci.Pair> folderMeta = [];
  final Map<String, sci.NamedFilter> filterMap = {};
  final Map<String, sci.Relation> tableMap = {};
  final Map<String, String> tableDocumentMap = {};
  final Map<String, String> tableNameMap = {};
  final Map<String, String> gatherMap = {};
  final Map<String, String> multiDsMap = {};
  final Map<String, String> filterValueUpdate = {};
  final Map<String, String> stepEnv = {};

  final Map<String, String> xAxisCoord = {};
  final Map<String, String> yAxisCoord = {};

  final List<StepSetting> settings = [];
  final List<PostRunCallback> postRunCallbacks = [];

  final List<String> doNotRunList = [];

  String folderSuffix = "";
  String folderPrefix = "";
  String? folderId;
  String? workflowId;
  String workflowRename = "";
  String workflowIdentifier = "";
  String workflowSuffix = "";
  bool isRunningStep = false;

  String stepProgressMessage = "";

  var addTimestamp = true;
  var addTimestampToFolder = true;

  var isInit = false;

  final List<String> stepsToRemove = [];
  final List<sci.Pair> settingsByName = [];
  late String timestamp;
  final Map<String, List<String>> removeFilters = {};

  WorkflowRunner({var timestampType = TimestampType.full}) {
    if (timestampType == TimestampType.short) {
      timestamp = DateFormat("yyyy.MM.dd").format(DateTime.now());
    } else {
      timestamp = DateFormat("yyyy.MM.dd_HH:mm").format(DateTime.now());
    }
  }

  void removedNamedFilter(String name, String stepId) {
    if (removeFilters.containsKey(stepId)) {
      removeFilters[stepId]!.add(name);
    } else {
      removeFilters[stepId] = [name];
    }
  }

  final List<PostRunIdCallback> postRunIdCallbacks = [];

  // Function callback called after workflow is done. Workflow id is passed
  // TODO Make this the default. Always pass the workflow id
  void addIdPostRun(PostRunIdCallback callback) {
    postRunIdCallbacks.add(callback);
  }

  void addWorkflowMeta(String key, String value) {
    workflowMeta.add(sci.Pair.from(key, value));
  }

  void addFolderMeta(String key, String value) {
    folderMeta.add(sci.Pair.from(key, value));
  }

  void addTimestampToFolderName(bool val) {
    addTimestampToFolder = val;
  }

  void addTimestampToName(bool val) {
    addTimestamp = val;
  }

  void setParentFolderId(String folderId) {
    parentFolderId = folderId;
  }

  void doNotRun(String stepId) {
    doNotRunList.add(stepId);
  }

  void addXAxisCoord(String stepId, String coord) {
    xAxisCoord[stepId] = coord;
  }

  void addYAxisCoord(String stepId, String coord) {
    yAxisCoord[stepId] = coord;
  }

  // Future<void> reEnableSteps(sci.Workflow wkf) async {
  //   if (doNotRunList.isNotEmpty) {
  //     // var wkf = await WorkflowDataService()
  //         // .findWorkflowById(workflowId, useCache: false);
  //     for (var stepId in doNotRunList) {
  //       final stp = wkf.steps.where((step) => step is! sci.TableStep).firstWhere(
  //           (step) => step.id == stepId,
  //           orElse: () => sci.DataStep());
  //       if (stp.id != "") {
  //         stp.state.taskState = sci.InitState();
  //       }
  //     }

  //     final factory = tercen.ServiceFactory();
  //     await factory.workflowService.update(wkf);
  //   }
  // }

  /// Setting by name will search through the steps in a workflow looking for a matching name
  /// If it finds, then the value is set.
  /// Useful when the same setting repeats across steps (e.g. seed)
  void addSettingByName(String settingName, String settingValue) {
    settingsByName.add(sci.Pair.from(settingName, settingValue));
  }

  void changeFilterValue(String filterName, String factor, String newValue) {
    var key = "$filterName|@|$factor";
    filterValueUpdate[key] = newValue;
  }

  void setNewWorkflowName(String name) {
    workflowRename = name;
  }

  String getWorkflowId() {
    return workflowId ?? "";
  }

  void addSetting(StepSetting setting) {
    settings.add(setting);
  }

  void addFolderSuffix(String suf) {
    folderSuffix = "$folderSuffix$suf";
  }

  void addFolderPrefix(String pref) {
    folderPrefix = "$folderPrefix$pref";
  }

  void setStepRam(String stepId, double ramInGb) {
    stepEnv["${stepId}|@|ram"] = (ramInGb * 10e9).toStringAsFixed(0);
  }

  void addSettings(List<StepSetting> settings) {
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

  sci.FilterExpr createFilterExpr(String factorName, dynamic factorValue,
      {String comp = "equals"}) {
    var factorType = "string";
    if (factorValue is int) {
      factorType = "int";
    }
    if (factorValue is double) {
      factorType = "double";
    }

    sci.Factor filterFactor = sci.Factor()
      ..type = factorType
      ..name = factorName;
    var filterExpr = sci.FilterExpr()
      ..filterOp = comp
      ..stringValue = factorValue
      ..factor = filterFactor;

    // sci.Filter andFilter = sci.Filter()
    // ..logical = "and"
    // ..not = false;
    // andFilter.filterExprs.add(filterExpr);

    return filterExpr;
  }

  sci.RenameRelation createDocumentRelation(String documentId) {
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

  void addTableFromRelation(String stepId, sci.Relation relation,
      {String? name}) {
    tableMap[stepId] = relation;

    if (name != null && name != "") {
      tableNameMap[stepId] = name;
    }
  }

  void addTable(String stepId, sci.Table table, {String? name}) {
    var uuid = const Uuid();
    sci.InMemoryRelation rel = sci.InMemoryRelation()
      ..id = uuid.v4()
      ..inMemoryTable = table;
    tableMap[stepId] = rel;

    if (name != null && name != "") {
      tableNameMap[stepId] = name;
    }
  }

  void addTableDocument(String stepId, String documentId) {
    tableDocumentMap[stepId] = documentId;
  }

  void addDocument(String stepId, String documentId) {
    tableMap[stepId] = createDocumentRelation(documentId);
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

  List<String> getFactorNames(sci.Workflow workflow, String stepId) {
    List<String> factors = [];
    for (var stp in workflow.steps) {
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

  void setupFilters(sci.Workflow workflow) {
    for (var fc in filterConfigList) {
      final filterName = fc.filterName;
      final stepId = fc.stepId;
      final keys = fc.keys;
      final values = fc.values;
      final boolOp = fc.boolOp;
      final metas = fc.metas;
      final comp = fc.comp;

      var factors =
          convertToStepFactors(keys, getFactorNames(workflow, stepId));
      var filterKey = "$stepId$filterName";

      sci.Filter andFilter = sci.Filter()
        ..logical = boolOp
        ..not = false;

      for (var i = 0; i < factors.length; i++) {
        for (var j = 0; j < values[i].length; j++) {
          andFilter.filterExprs
              .add(createFilterExpr(factors[i], values[i][j], comp: comp));
        }
      }

      if (!filterMap.containsKey(filterKey)) {
        sci.NamedFilter namedFilter = sci.NamedFilter()
          ..logical = "or"
          ..not = false
          ..name = filterName;
        namedFilter.filterExprs.add(andFilter);

        for (var meta in metas) {
          namedFilter.meta.add(meta);
        }

        sci.Filters filters = sci.Filters()..removeNaN = true;
        filters.namedFilters.add(namedFilter);
        filterMap[filterKey] = namedFilter; //filters;
      } else {
        sci.NamedFilter namedFilter = filterMap[filterKey]!;
        namedFilter.filterExprs.add(andFilter);
        filterMap[filterKey] = namedFilter;
      }
    }
  }

  void addOrFilter(
      String filterName, String stepId, List<String> keys, List<dynamic> values,
      {List<sci.Pair> metas = const [], String comp = "equals"}) {
    final fc = FilterConfig(
        filterName: filterName,
        stepId: stepId,
        keys: keys,
        values: values,
        boolOp: "or",
        metas: metas,
        comp: comp);
    filterConfigList.add(fc);
  }

  void addAndFilter(
      String filterName, String stepId, List<String> keys, List<dynamic> values,
      {List<sci.Pair> metas = const [], String comp = "equals"}) {
    final fc = FilterConfig(
        filterName: filterName,
        stepId: stepId,
        keys: keys,
        values: values,
        boolOp: "and",
        metas: metas,
        comp: comp);
    filterConfigList.add(fc);
  }

  bool shouldResetStep(sci.Step step) {
    if (initStepIds.isEmpty) {
      return step.kind == "DataStep";
    } else {
      return initStepIds.contains(step.id);
    }
  }

  Future<sci.FolderDocument> createFolder(
      {String? namePrefix,
      String? folderName,
      String parentFolderId = "",
      bool random = false,
      int nameLength = 5}) async {
    var factory = tercen.ServiceFactory();
    String name = folderName ?? StringUtils.getRandomString(nameLength);

    if (random == false && folderName == null) {
      final DateFormat formatter = DateFormat('yyyyMMdd_hhmmss');

      name = formatter.format(DateTime.now());
    }

    if (namePrefix != null) {
      name = "$namePrefix$name";
    }

    sci.FolderDocument folder = sci.FolderDocument();
    folder.name = getFolderName();
    folder.acl.owner = AppUser().teamname;
    folder.projectId = AppUser().projectId;
    folder.folderId = parentFolderId;

    for (var meta in folderMeta) {
      folder.addMeta(meta.key, meta.value);
    }

    return await factory.folderService.create(folder);
  }

  String getWorkflowName(sci.Workflow workflow) {
    final DateFormat formatter = DateFormat('yyyyMMdd_hhmmss');
    workflowIdentifier = workflowIdentifier == "" ? "" : "$workflowIdentifier";

    workflowSuffix = workflowSuffix == "" ? "" : "_$workflowSuffix";

    var basename = workflowRename == "" ? workflow.name : workflowRename;

    var dateString = addTimestamp ? "_${formatter.format(DateTime.now())}" : "";
    return "$basename${workflowIdentifier}$dateString$workflowSuffix";
  }

  void addPostRun(PostRunCallback callback) {
    postRunCallbacks.add(callback);
  }

  Future<sci.Relation> loadDocumentInMemory(String docId) async {
    var factory = tercen.ServiceFactory();
    print("Checking: $docId");

    var sch = await factory.tableSchemaService.get(docId);
    var table = await factory.tableSchemaService.select(
        sch.id,
        sch.columns.where((e) => e != ".ci").map((e) => e.name).toList(),
        0,
        sch.nRows);

    // var uuid = const Uuid();
    var rrel = sci.RenameRelation();
    rrel.inNames.addAll(table.columns.map((e) => e.name).toList());
    rrel.outNames.addAll(table.columns.map((e) => e.name).toList());
    rrel.relation = sci.SimpleRelation()..id = sch.id;

    return rrel;
  }

  sci.DataStep updateFilterValues(sci.DataStep step) {
    // var key = "$filterName|@|$factor";
    // print("Updating filter values");
    for (var filter in step.model.filters.namedFilters) {
      var filters = filterValueUpdate.entries
          .where((e) => e.key.contains(filter.name))
          .toList();

      if (filters.isNotEmpty) {
        // print("\tWill update ${filters.length} filter on step ${step.name}");
        for (var f in filter.filterExprs) {
          var fExpr = f as sci.FilterExpr;
          // print("\t\t${fExpr.factor.name}");
          var filterExprs =
              filters.where((e) => e.key.contains(f.factor.name)).toList();
          if (filterExprs.isNotEmpty) {
            // print("\t\tUpdating");
            for (var fe in filterExprs) {
              // print("updating filter ${filter.name} value of step ${step.name}");
              fExpr.stringValue = fe.value;
            }
          }
        }
      }
    }
    return step;
  }

  void setFolderName(String name) {
    folderName = name;
  }

  String getFolderName() {
    if (folderName != null && folderName != "") {
      return folderName!;
    }

    var timeStr = addTimestampToFolder ? timestamp : "";
    return "${folderPrefix}${timeStr}${folderSuffix}";
  }

  sci.DataStep updateEnv(sci.DataStep step) {
    final envList = stepEnv.entries.where((e) => e.key.contains(step.id));
    if (envList.isNotEmpty) {
      for (var e in envList) {
        if (e.key.endsWith("ram")) {
          final ei = step.model.operatorSettings.environment.indexOf("ram");
          step.model.operatorSettings.environment[ei] =
              sci.Pair.from("ram", e.value);
        }
      }
    }

    return step;
  }

  Future<sci.Workflow> doSetup(BuildContext? context, sci.Workflow template,
      {bool inPlace = false, String? runId}) async {
    runId = runId ?? template.name;
    if (context != null) {
      openDialog(context, id: runId);
    }
    Stopwatch stopwatch = Stopwatch()..start();
    var factory = tercen.ServiceFactory();

    var runTitle = getWorkflowName(template);
    print(
        "\t\tdoSetup :: getWorkflowName :: ${stopwatch.elapsedMilliseconds} ms");
    stopwatch.reset();

    if (context != null) {
      log(runId, "Set up", dialogTitle: runTitle);
    }

    for (var entry in tableDocumentMap.entries) {
      tableMap[entry.key] = await loadDocumentInMemory(entry.value);
    }

    print(
        "\t\tdoSetup :: loadDocumentInMemory :: ${stopwatch.elapsedMilliseconds} ms");
    stopwatch.reset();

    //-----------------------------------------
    var workflow = sci.Workflow();
    // Copy template into project
    //-----------------------------------------
    if (inPlace) {
      workflow = template;
      //nsure saved
      workflow.rev = await factory.workflowService.update(workflow);
    } else {
      workflow = await factory.workflowService
          .copyApp(template.id, AppUser().projectId);
    }
    print("\t\tdoSetup :: copyApp :: ${stopwatch.elapsedMilliseconds} ms");
    stopwatch.reset();

    setupFilters(workflow);

    if (template.projectId == workflow.projectId) {
      // await factory.workflowService.delete(template.id, template.rev);
      // workflow.id = "";
      // workflow.rev = "";
    }

    for (var stepToRemove in stepsToRemove) {
      workflow = removeStepFromWorkflow(stepToRemove, workflow);
    }

    for (var meta in workflowMeta) {
      workflow.addMeta(meta.key, meta.value);
    }
    // addIdPostRun(reEnableSteps);

    // print(xAxisCoord);
    //-----------------------------------------
    // Step-specific setup
    //-----------------------------------------
    for (var stp in workflow.steps) {
      // print("Checking ${stp.name} (${stp.id})");
      if (shouldResetStep(stp)) {
        stp.state.taskState = sci.InitState();
        stp.state.taskId = "";
      }
      if (stp.state.taskState.isFinal) {
        continue;
      }
      if (stp.kind == "DataStep") {
        stp = updateFilterValues(stp as sci.DataStep);
        stp = updateEnv(stp);
        stp = updateOperatorSettings(stp, settings);
        stp = updateOperatorSettingsByName(stp, settingsByName);

        if (removeFilters.containsKey(stp.id)) {
          for (var filterName in removeFilters[stp.id]!) {
            var namedFilter =
                List<sci.NamedFilter>.from(stp.model.filters.namedFilters);
            namedFilter.removeWhere((filter) => filter.name == filterName);
            stp.model.filters.namedFilters.setValues(namedFilter);
          }
        }

        for (var mapEntry in filterMap.entries) {
          if (mapEntry.key.contains(stp.id)) {
            stp.model.filters.namedFilters.add(mapEntry.value);
          }
        }
      }

      if (doNotRunList.contains(stp.id)) {
        stp.state.taskState = sci.DoneState();
        stp.state.taskId = "";
      }

      if (multiDsMap.containsKey(stp.id)) {
        var tmpStp = stp as sci.DataStep;
        tmpStp.parentDataStepId = multiDsMap[stp.id]!;
      }

      if (tableMap.containsKey(stp.id)) {
        sci.TableStep tmpStp = stp as sci.TableStep;
        tmpStp.model.relation = tableMap[stp.id]!;
        tmpStp.state.taskState = sci.DoneState();

        if (tableNameMap.containsKey(stp.id)) {
          tmpStp.name = tableNameMap[stp.id]!;
        }

        stp = tmpStp;
      }

      if (gatherMap.containsKey(stp.id)) {
        (stp as sci.MeltStep).model.selectionPattern = gatherMap[stp.id]!;
      }

      if (xAxisCoord.containsKey(stp.id)) {
        //TODO set it on the step
        // print("Setting X axis coord for step ${stp.name} to ${xAxisCoord[stp.id]}");
        // print((stp as sci.DataStep).model.toJson());
        (stp as sci.DataStep)
            .model
            .axis
            .xyAxis
            .first
            .xAxis
            .graphicalFactor
            .factor
            .name = xAxisCoord[stp.id]!;
      }
      if (yAxisCoord.containsKey(stp.id)) {
        //TODO set it on the step
        (stp as sci.DataStep)
            .model
            .axis
            .xyAxis
            .first
            .yAxis
            .graphicalFactor
            .factor
            .name = yAxisCoord[stp.id]!;
      }
    }

    print(
        "\t\tdoSetup :: Step-specific setup :: ${stopwatch.elapsedMilliseconds} ms");
    stopwatch.reset();

    //-----------------------------------------
    // General workflow parameters
    //-----------------------------------------

    if (inPlace) {
      workflow.rev = await factory.workflowService.update(workflow);
      // workflow = await factory.workflowService.get(workflow.id);
    } else {
      if (folderId == null) {
        sci.FolderDocument folder = await createFolder(
            folderName: getFolderName(), parentFolderId: parentFolderId ?? "");
        workflow.folderId = folder.id;
      } else {
        workflow.folderId = folderId!;
      }
      workflow.name = getWorkflowName(workflow);
      workflow.acl = sci.Acl()..owner = AppUser().teamname;
      workflow.isHidden = false;
      workflow.isDeleted = false;

      workflow.id = "";
      workflow.rev = "";

      workflow = await factory.workflowService.create(workflow);
      print(
          "\t\tdoSetup :: createWorkflow :: ${stopwatch.elapsedMilliseconds} ms");
      stopwatch.reset();
    }

    if (context != null) {
      closeLog(id: runId);
    }

    return workflow;
  }

  String _linkToId(String id) {
    var idParts = id.split("-");
    idParts.removeLast();
    idParts.removeLast();
    return idParts.join("-");
  }

  List<String> _stepsToReset(
      sci.Workflow workflow, String currentStep, List<String> addedSteps) {
    final stepsToReset = [currentStep];
    final outLinks = workflow.links
        .where((link) => link.outputId.contains(currentStep))
        .where((link) => !addedSteps.contains(_linkToId(link.inputId)));
    for (var link in outLinks) {
      stepsToReset.add(_linkToId(link.inputId));
      addedSteps.add(link.inputId);
      stepsToReset
          .addAll(_stepsToReset(workflow, _linkToId(link.inputId), addedSteps));
    }

    return stepsToReset;
  }

  Future<sci.Workflow> doResetStep(BuildContext? context, sci.Workflow workflow,
      {String? runTitle,
      String? stepName,
      required String stepId,
      String? runId}) async {
    runId = runId ?? workflow.name;
    if (context != null) {
      openDialog(context, id: runId);
    }

    var runTitle = getWorkflowName(workflow);

    //-----------------------------------------
    // Task preparation and running
    //-----------------------------------------

    // for( var step in workflow.steps.whereType<sci.DataStep>() ){
    // print("${step.name} :: ${step.state.taskState.kind}");
    // }
    // print("...........................................");
    final idsToReset = _stepsToReset(workflow, stepId, []).toSet();
    // print("WILL RESET:");
    for (var id in idsToReset) {
      final stp = workflow.steps
          .firstWhere((step) => step.id == id, orElse: () => sci.DataStep());
      // print("\t${stp.name} :: $id");
    }
    for (var id in idsToReset) {
      final stp = workflow.steps
          .firstWhere((step) => step.id == id, orElse: () => sci.DataStep());
      if (stp.id != "") {
        stp.state.taskState = sci.InitState();
        stp.state.taskId = "";
      }
    }
    // final factory = tercen.ServiceFactory();
    // workflow = await factory.workflowService.get(workflow.id);
    // workflow = await runWorkflowTask(workflow, stepsToReset: [stepId], stepsToRun: []);

    // for( var step in workflow.steps.whereType<sci.DataStep>() ){
    // print("${step.name} :: ${step.state.taskState.kind}");
    // }

    log(runId, "$stepProgressMessage\n\n \nRunning final updates",
        dialogTitle: runTitle);

    final hasFailed = workflow.steps.whereType<sci.DataStep>().any((step) =>
        step.state.taskState.kind != "DoneState" &&
        step.state.taskState.kind != "InitState");
    if (!hasFailed) {
      for (var f in postRunCallbacks) {
        await f();
      }
      for (var f in postRunIdCallbacks) {
        await f(workflow);
      }
    }

    if (context != null) {
      // await Future.delayed(const Duration(milliseconds: 1000), () {
      // status.value = RunStatus.finished;
      closeLog(id: runId);
      // });
    }

    workflowId = workflow.id;
    // workflow = doneWorkflow;

    // final factory = tercen.ServiceFactory();
    // workflow = await factory.workflowService.get(workflow.id);

    return workflow;
  }

  Future<sci.Workflow> runWorkflowTask(
      BuildContext? context, sci.Workflow workflow,
      {String? runTitle,
      String? stepName,
      List<String>? stepsToRun,
      List<String>? stepsToReset,
      required String runId}) async {
    var factory = tercen.ServiceFactory();

    runTitle ??= workflow.name;
    //NEeds the steps2run, but only part of the sci_api_model, not client...
    sci.RunWorkflowTask workflowTask = sci.RunWorkflowTask()
      ..state = sci.InitState()
      ..owner = AppUser().teamname
      ..projectId = AppUser().projectId
      ..workflowId = workflow.id
      ..workflowRev = workflow.rev;

    // workflowTask.meta.add(sci.Pair.from("channel.persistent", "true"));

    if (stepsToRun != null) {
      // workflowTask.stepsToRun.clear();
      workflowTask.stepsToRun.addAll(stepsToRun);
    }

    if (stepsToReset != null) {
      // workflowTask.stepsToReset.clear();
      workflowTask.stepsToReset.addAll(stepsToReset);
    }

    workflowTask =
        await factory.taskService.create(workflowTask) as sci.RunWorkflowTask;

    workflow.addMeta("run.workflow.task.id", workflowTask.id);
    // workflow.addMeta("run.task.id", workflowTask.id);
    workflow.rev = await factory.workflowService.update(workflow);

    var taskStream = factory.eventService.channel(workflowTask.channelId);

    await factory.taskService.runTask(workflowTask.id);

    if (stepName == null) {
      updateStepProgress(workflow);
      if (context != null) {
        log(runId, stepProgressMessage, dialogTitle: runTitle);
      }
    } else {
      if (context != null) {
        log(runId, "Running ${stepName}", dialogTitle: runTitle);
      }
      // print("Running ${stepName}");
    }

    await for (var evt in taskStream) {
      if (evt is sci.PatchRecords) {
        // try {
        //   workflow = evt.apply(workflow);
        // } catch (e) {
        //   print("Failed to apply: ");
        //   print(evt.toJson());
        //   print(e);
        //   continue;
        // }

        // if (stepName == null) {
        //   updateStepProgress(workflow);
        //   log(stepProgressMessage, dialogTitle: runTitle);
        // }
      }
      if (evt is sci.TaskStateEvent) {
        if (evt.state.isFinal && evt.taskId == workflowTask.id) {
          break;
        }
      }
      if (evt is sci.TaskProgressEvent) {
        if (context != null) {
          if (stepName == null || stepName == "") {
            log(runId, "$stepProgressMessage\n\nTask Log\n${evt.message}",
                dialogTitle: runTitle);
          } else {
            log(runId, "Running ${stepName}\n\nTask Log\n${evt.message}",
                dialogTitle: runTitle);
          }
        }
      } else if (evt is sci.TaskLogEvent) {
        if (context != null) {
          if (stepName == null || stepName == "") {
            log(runId, "$stepProgressMessage\n\nTask Log\n${evt.message}",
                dialogTitle: runTitle);
          } else {
            log(runId, "Running ${stepName}\n\nTask Log\n${evt.message}",
                dialogTitle: runTitle);
          }
        }
      }
    }

    final patches = await factory.patchRecordService.findByChannelIdAndSequence(
        startKey: [workflowTask.channelId, 0],
        endKey: [workflowTask.channelId, 9999]);

    for (var patch in patches.reversed) {
      // print("Applying patch ${patch.oR}");
      workflow = patch.apply(workflow);
    }

    // print("Patching done");
    workflow.rev = await factory.workflowService.update(workflow);
    workflowId = workflow.id;

    return workflow;
  }

  Future<sci.Workflow> doRunStep(BuildContext? context, sci.Workflow workflow,
      String stepId, String? runId) async {
    runId = runId ?? "${workflow.name}_${stepId}";
    if (context != null) {
      openDialog(context, id: runId);
    }

    var runTitle = getWorkflowName(workflow);

    //-----------------------------------------
    // Task preparation and running
    //-----------------------------------------
    workflow =
        await runWorkflowTask(context, workflow, stepsToRun: [stepId], runId: runId);

    if (context != null) {
      log(runId, "$stepProgressMessage\n\n \nRunning final updates",
          dialogTitle: runTitle);
    }

    final hasFailed = workflow.steps.whereType<sci.DataStep>().any((step) =>
        step.state.taskState.kind != "DoneState" &&
        step.state.taskState.kind != "InitState");
    if (!hasFailed) {
      for (var f in postRunCallbacks) {
        await f();
      }
      for (var f in postRunIdCallbacks) {
        await f(workflow);
      }
    }

    if (context != null) {
      // await Future.delayed(const Duration(milliseconds: 500), () {
      closeLog(id: runId);
      // });
    }

    workflowId = workflow.id;

    final factory = tercen.ServiceFactory();
    workflow = await factory.workflowService.get(workflow.id);

    return workflow;
  }

  Future<sci.Workflow> doRun(BuildContext? context, sci.Workflow workflow,
      {String? runId}) async {
    runId = runId ?? workflow.name;
    if (context != null) {
      openDialog(context, id: runId);
    }

    var runTitle = getWorkflowName(workflow);

    //-----------------------------------------
    // Task preparation and running
    //-----------------------------------------
    workflow = await runWorkflowTask(context, workflow, runId: runId);

    log(runId, "$stepProgressMessage\n\n \nRunning final updates",
        dialogTitle: runTitle);

    final hasFailed = workflow.steps.whereType<sci.DataStep>().any((step) =>
        step.state.taskState.kind != "DoneState" &&
        step.state.taskState.kind != "InitState");
    if (!hasFailed) {
      for (var f in postRunCallbacks) {
        await f();
      }
      for (var f in postRunIdCallbacks) {
        await f(workflow);
      }
    }

    if (context != null) {
      // await Future.delayed(const Duration(milliseconds: 1000), () {
      // status.value = RunStatus.finished;
      closeLog(id: runId);
      // });
    }

    workflowId = workflow.id;
    // workflow = doneWorkflow;

    final factory = tercen.ServiceFactory();
    workflow = await factory.workflowService.get(workflow.id);

    return workflow;
  }

  Stream<sci.TaskEvent> workflowStream(String taskId) async* {
    var factory = tercen.ServiceFactory();
    bool startTask = true;
    var task = await factory.taskService.get(taskId);

    while (!task.state.isFinal) {
      var taskStream = factory.eventService
          .listenTaskChannel(task.id, startTask)
          .asBroadcastStream();

      startTask = false;
      await for (var evt in taskStream) {
        yield evt;
      }
      task = await factory.taskService.get(taskId);
    }
  }

  sci.DataStep updateOperatorSettingsByName(
      sci.DataStep stp, List<sci.Pair> settingsList) {
    for (var setting in settingsList) {
      var nProps = stp.model.operatorSettings.operatorRef.propertyValues.length;
      for (var i = 0; i < nProps; i++) {
        if (stp.model.operatorSettings.operatorRef.propertyValues[i].name
                .toLowerCase() ==
            setting.key.toLowerCase()) {
          stp.model.operatorSettings.operatorRef.propertyValues[i].value =
              setting.value;
        }
      }
    }
    return stp;
  }

  sci.DataStep updateOperatorSettings(
      sci.DataStep stp, List<StepSetting> settingsList) {
    for (var setting in settingsList) {
      if (stp.id == setting.stepId) {
        for (var i = 0;
            i < stp.model.operatorSettings.operatorRef.propertyValues.length;
            i++) {
          if (stp.model.operatorSettings.operatorRef.propertyValues[i].name ==
              setting.settingName) {
            stp.model.operatorSettings.operatorRef.propertyValues[i].value =
                setting.value;
          }
        }
      }
    }
    return stp;
  }

  List<sci.Step> getTopSteps(List<sci.Step> steps) {
    return steps.where((e) => e.inputs.isEmpty && e is! sci.GroupStep).toList();
  }

  List<sci.Step> getParents(sci.Step step, sci.Workflow workflow) {
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

  String getStepStatus(sci.Step stp, sci.Workflow workflow) {
    if (stp.state.taskState.kind == "DoneState") {
      return "Done.......";
    }

    var parents = getParents(stp, workflow);

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

  List<sci.Step> getChildren(sci.Step parent, sci.Workflow workflow) {
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
      var topSteps = getTopSteps(workflow.steps);
      for (var stp in topSteps) {
        stepProgressMessage += getStepStatus(stp, workflow);
        stepProgressMessage += "....";
        stepProgressMessage += stp.name;
        stepProgressMessage += "\n";
      }

      for (var stp in topSteps) {
        var children = getChildren(stp, workflow);
        for (var child in children) {
          updateStepProgress(workflow, step: child);
        }
      }
    } else {
      stepProgressMessage += getStepStatus(step, workflow);
      stepProgressMessage += "....";
      stepProgressMessage += step.name;
      stepProgressMessage += "\n";

      var children = getChildren(step, workflow);
      for (var child in children) {
        updateStepProgress(workflow, step: child);
      }
    }
  }
}
