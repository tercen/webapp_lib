import 'dart:convert';

import 'package:flutter/services.dart';


import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_client/sci_client.dart';

import 'package:webapp_model/id_element_table.dart';

import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_utils/functions/formatter_utils.dart';

import 'package:webapp_utils/functions/logger.dart';


import 'package:webapp_utils/mixin/data_cache.dart';


import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:webapp_utils/model/workflow_setting.dart';
import 'package:webapp_utils/services/project_data_service.dart';

class WorkflowDataService with DataCache {
  static final WorkflowDataService _singleton = WorkflowDataService._internal();

  factory WorkflowDataService() {
    return _singleton;
  }

  WorkflowDataService._internal();

  // final List<WorkflowInfo> _requiredWorkflows = [];
  final Map<String, Workflow> _installedWorkflows = {};
  List<WorkflowSetting> workflowSettings = [];
  // bool infoLoaded = false;

  Future<void> init({String reposJsonPath = ""}) async {
    // if( reposJsonPath == ""){
    //   return;
    // }
    // String settingsStr = await rootBundle.loadString(reposJsonPath);
    // try {
    //   final jsonString = JsonString(settingsStr);
    //   final repoInfoMap = jsonString.decodedValueAsMap;

    //   for (int i = 0; i < repoInfoMap["repos"].length; i++) {
    //     Map<String, dynamic> jsonEntry = repoInfoMap["repos"][i];

    //     WorkflowInfo workflow = WorkflowInfo(jsonEntry["iid"],
    //         jsonEntry["name"], jsonEntry["url"], jsonEntry["version"]);

    //     _requiredWorkflows.add(workflow);

    //     infoLoaded = true;
    //   }
    // } on Exception catch (e) {
    //   print('Invalid JSON: $e');
    // }

    // await readWorkflowsFromLib();
  }

  void addWorkflow(String iid, Workflow workflow) {
    _installedWorkflows[iid] = workflow;
  }

  List<Workflow> getTemplates() {
    return _installedWorkflows.values.toList();
  }

  Workflow getWorkflow(String key) {
    if (!_installedWorkflows.containsKey(key)) {
      throw ServiceError(500, "Failed to find workflow with key '$key'");
    }
    return _installedWorkflows[key]!;
  }

  Future<List<sci.Document>> readWorkflowsDocumentsFromLib(
      {String? team, String? user}) async {
    List<String> teamList = user == null || user.isEmpty ? [] : [user];
    if (team != null && team.isNotEmpty) {
      teamList.add(team);
    }

    var factory = tercen.ServiceFactory();

    var libObjs = await factory.documentService
        .getLibrary('', [], ["Workflow"], [], 0, -1);

    Logger().log(level: Logger.FINE, message: "Reading workflows from library");
    Logger().log(level: Logger.FINER, message: "\tFound ${libObjs.length} workflows");

    // var workflows = await factory.workflowService.list(libObjs.map((o) => o.id).toList());
    return libObjs;
  }

  // Future<Map<String, Workflow>> readWorkflowsFromLib() async {

  //   if (installedWorkflows.isNotEmpty) {
  //     return installedWorkflows;
  //   }

  //   if (!infoLoaded) {
  //     await init();
  //   }
  //   var factory = tercen.ServiceFactory();

  //   var libObjs = await factory.documentService
  //       .getLibrary('', [], ["Workflow"], [], 0, -1);

  //   var reqWkfs = _getRequiredWorkflowsIds(libObjs);

  //   var workflows = await factory.workflowService.list(reqWkfs[0]);

  //   for (var i = 0; i < workflows.length; i++) {
  //     Logger().log(
  //         level: Logger.INFO,
  //         message: " Adding ${workflows[i].name} to ${reqWkfs[1][i]} ");
  //     installedWorkflows[reqWkfs[1][i]] = workflows[i];
  //   }

  //   return installedWorkflows;
  // }

  // String _isInRepoFile(Document libObj) {
  //   for (var info in _requiredWorkflows) {

  //     var isCorrectVersion = info.version == "NONE" || info.version == libObj.version;
  //     // print("${info.url == libObj.url.uri} :::: $isCorrectVersion");
  //     if (info.url == libObj.url.uri && isCorrectVersion) {
  //       return info.iid;
  //     }
  //   }

  //   return "";
  // }

  // bool _allWorkflowsInstalled(List<String> iids) {
  //   for (var wi in _requiredWorkflows) {
  //     if (!iids.contains(wi.iid)) {
  //       return false;
  //     }
  //   }
  //   return true;
  // }

  // List<List<String>> _getRequiredWorkflowsIds(List<Document> libObjs) {
  //   List<String> ids = [];
  //   List<String> iids = [];
  //   print("Checking library for required workflows");
  //   for (var obj in libObjs) {
  //     print("\tChecking ${obj.url.uri}");
  //     var iid = _isInRepoFile(obj);
  //     // print("IID: $iid");

  //     if (iid != "") {
  //       print("\tFound");
  //       ids.add(obj.id);
  //       iids.add(iid);
  //     }
  //   }

  //   if (!_allWorkflowsInstalled(iids)) {
  //     print("Did not find all needed workflows");
  //     throw  sci.ServiceError(1, "Missing Required Templates", missingTemplateErrorMessage(iids));
  //   }
  //   return [ids, iids];
  // }

  // String missingTemplateErrorMessage(List<String> foundIids){
  //   var err = "The following templates or versions were not found in any of your library teams:\n";

  //   for( var info in _requiredWorkflows ){
  //     if( !foundIids.contains( info.iid)){
  //       err = "$err\n* ${info.url} (version ${info.version})";
  //     }
  //   }
  //   return err;
  // }

  Future<void> loadWorkflowSettings() async {
    Logger().log(level: Logger.FINE, message: "Loading workflow settings");
    if (workflowSettings.isNotEmpty) {
      Logger().log(level: Logger.FINER, message: "Workflow settings already loaded");
      return;
    }
    var factory = tercen.ServiceFactory();

    for (var template in _installedWorkflows.values) {
      Logger().log(level: Logger.FINER, message: "Loading settings for ${template.name}");
      var dataSteps = template.steps
          .whereType<DataStep>()
          .where((step) =>
              step.model.operatorSettings.operatorRef.operatorId != "")
          .toList();
      var opIds = dataSteps
          .map((step) => step.model.operatorSettings.operatorRef)
          .where((opRef) => opRef.name != "File Downloader")
          .map((opRef) => opRef.operatorId)
          .toList();
      
      var opRefs = dataSteps
          .map((step) => step.model.operatorSettings.operatorRef)
          .toList();

      for(var opRef in opRefs){
        Logger().log(level: Logger.ALL, message: "\tOperator: ${opRef.name} (${opRef.version}) :: ${opRef.operatorId}");
      }
      
      var operators = await factory.operatorService.list(opIds);

      List<int>.generate(operators.length, (i) => i).map((i) {});
      for (var i = 0; i < operators.length; i++) {
        var step = dataSteps[i];
        var op = operators[i];
        workflowSettings.addAll(op.properties.map((prop) {
          if (prop is EnumeratedProperty) {
            var kind = prop.isSingleSelection ? "ListSingle" : "ListMultiple";
            return WorkflowSetting(step.name, step.id, prop.name,
                prop.defaultValue, kind, prop.description,
                isSingleSelection: prop.isSingleSelection,
                opOptions: prop.values);
          }
          if (prop is BooleanProperty) {
            return WorkflowSetting(step.name, step.id, prop.name,
                prop.defaultValue.toString(), "boolean", prop.description);
          }
          if (prop is DoubleProperty) {
            return WorkflowSetting(step.name, step.id, prop.name,
                prop.defaultValue.toString(), "double", prop.description);
          }
          if (prop is StringProperty) {
            return WorkflowSetting(step.name, step.id, prop.name,
                prop.defaultValue, "string", prop.description);
          }

          return WorkflowSetting(
              step.name, step.id, prop.name, "", "string", prop.description);
        }));
      }
    }
    workflowSettings = workflowSettings.toSet().toList();
  }

  bool isFileSchema(Schema sch) {
    for (var col in sch.columns) {
      if (col.name.contains("mimetype")) {
        return true;
      }
    }
    return false;
  }

  List<SimpleRelation> getSimpleRelations(Relation relation) {
    List<SimpleRelation> l = [];

    switch (relation.kind) {
      case "SimpleRelation":
        l.add(relation as SimpleRelation);
        break;
      case "CompositeRelation":
        CompositeRelation cr = relation as CompositeRelation;
        List<JoinOperator> joList = cr.joinOperators;
        l.addAll(getSimpleRelations(cr.mainRelation));
        for (var jo in joList) {
          l.addAll(getSimpleRelations(jo.rightRelation));
        }
        break;
      case "RenameRelation":
        RenameRelation rr = relation as RenameRelation;
        l.addAll(getSimpleRelations(rr.relation));
        break;

      default:
    }

    return l;
  }

    Future<WebappTable> fetchWorkflowImagesByWorkflowId(String workflowId,
      {List<String> contentTypes = const ["image"],
      List<String> excludedFiles = const [],
      List<String> nameFilter = const [],
      List<String> includeStepId = const [],
      bool force = false}) async {
        var factory = tercen.ServiceFactory();
      var wkf = await factory.workflowService.get(workflowId);    
        return fetchWorkflowImages(wkf, contentTypes: contentTypes, excludedFiles: excludedFiles, nameFilter: nameFilter, includeStepId: includeStepId, force: force);
      }
      


  Future<WebappTable> fetchWorkflowImages(Workflow wkf,
      {List<String> contentTypes = const ["image"],
      List<String> excludedFiles = const [],
      List<String> nameFilter = const [],
      List<String> includeStepId = const [],
      bool force = false}) async {
    var key = "${wkf.id}_${contentTypes.join("_")}";
    if (excludedFiles.isNotEmpty) {
      key = "${key}_${excludedFiles.join("_")}";
    }

    if (hasCachedValue(key) && !force) {
      return getCachedValue(key);
    }

    List<String> workflowNames = [];
    List<String> stepNames = [];
    List<String> filenames = [];
    List<String> bytes = [];
    List<String> contentTypeList = [];

    var factory = tercen.ServiceFactory();

    List<Relation> rels = [];
    Map<String, List<String>> stepRelationMap = {};
    for (var stp in wkf.steps) {
      var shouldIncludeStep =
          includeStepId.isEmpty || includeStepId.contains(stp.id);
      if (stp.kind == "DataStep" && shouldIncludeStep) {
        DataStep dStp = stp as DataStep;
        var relList = getSimpleRelations(dStp.computedRelation);
        rels.addAll(relList);
        stepRelationMap[dStp.id] = relList.map((e) => e.id).toList();
      }
    }

    var schList =
        await factory.tableSchemaService.list(rels.map((e) => e.id).toList());


    for (var sch in schList) {
      var step = getRelationStep(wkf, stepRelationMap, sch.id);
      if (isFileSchema(sch)) {
        var mimetypeIdx =
            sch.columns.indexWhere((c) => c.name.contains("mimetype"));

        var nameIdx = sch.columns.indexWhere((c) => c.name.contains("name"));

        var tbl = await factory.tableSchemaService.select(
            sch.id,
            [sch.columns[nameIdx].name, sch.columns[mimetypeIdx].name],
            0,
            sch.nRows);
        List<String> uniqueAddedNames = [];
        Table contentTable = Table();
        var isDev = Uri.base.hasPort && Uri.base.port > 10000;

        if (isDev) {
          // Avoid CORS issue with downloading image through browser request
          contentTable = await factory.tableSchemaService.select(
              sch.id, [sch.columns[nameIdx].name, ".content"], 0, sch.nRows);

          List<Pair> uniqueNameType = [];
          for (var i = 0; i < tbl.nRows; i++) {
            var name = tbl.columns[0].values[i];
            var cType = tbl.columns[1].values[i];

            if (!uniqueNameType.any((e) => e.key == name)) {
              uniqueNameType.add(Pair.from(name, cType));
            }
          }

          for (var nameContent in uniqueNameType) {
            var isCorrectType = (contentTypes
                .any((contentType) => nameContent.value.contains(contentType)));

            var filterInclude = nameFilter.isEmpty ||
                nameFilter.any((name) => nameContent.key.contains(name));

            if (!excludedFiles.contains(nameContent.key) &&
                filterInclude &&
                isCorrectType) {
              uniqueAddedNames.add(nameContent.key);
              workflowNames.add(wkf.name);
              stepNames.add(step.get("name"));
              filenames.add(nameContent.key);
              // var ct = tbl.columns[1].values[i];

              contentTypeList.add(nameContent.value);

              var bStr = "";

              for (var i = 0; i < tbl.nRows; i++) {
                
                var tname = tbl.columns[0].values[i];
                if (nameContent.key == tname) {
                  var newBStr = String.fromCharCodes(
                      base64Decode(contentTable.columns[1].values[i]));
                  bStr = "$bStr$newBStr";
                }
              }
              bytes.add(bStr);
            }
          
          }
          
        } else {
          for (var i = 0; i < tbl.nRows; i++) {
            if (contentTypes.any((contentType) =>
                tbl.columns[1].values[i].contains(contentType))) {
              var fname = tbl.columns[0].values[i];
              var filterInclude = nameFilter.isEmpty ||
                  nameFilter.any((name) => fname.contains(name));
              if (!excludedFiles.contains(fname) && filterInclude) {
                if (!uniqueAddedNames.contains(fname)) {
                  uniqueAddedNames.add(fname);
                  workflowNames.add(wkf.name);
                  stepNames.add(step.get("name"));
                  filenames.add(fname);
                  var ct = tbl.columns[1].values[i];

                  contentTypeList.add(ct);

                  var bytesStream = factory.tableSchemaService
                      .getFileMimetypeStream(sch.id, tbl.columns[0].values[i]);
                  var imgBytes = await bytesStream.toList();

                  bytes.add(
                      String.fromCharCodes(Uint8List.fromList(imgBytes[0])));
                }
              }
            }
          }
        }
      }
    }


    var tbl = WebappTable()
      ..addColumn("workflowName", data: workflowNames)
      ..addColumn("filename", data: filenames)
      ..addColumn("step", data: stepNames)
      ..addColumn("data", data: bytes)
      ..addColumn("contentType", data: contentTypeList);
    addToCache(key, tbl);

    return tbl;
  }

  Step getRelationStep(
      Workflow wkf, Map<String, List<String>> stepRelationMap, String schId) {
    String stepId = "";
    var entries =
        List<MapEntry<String, List<String>>>.from(stepRelationMap.entries);
    for (var e in entries) {
      if (e.value.contains(schId)) {
        stepId = e.key;
      }
    }

    if (stepId == "") {
      return Step();
    }

    var stp = wkf.steps.firstWhere((e) => e.id == stepId);

    return stp;
  }

  Future<WebappTable> fetchImageData(WebappTable workflowImageTable) async {
    assert(workflowImageTable.colNames.contains("workflow"));
    assert(workflowImageTable.colNames.contains("image"));

    var uniqueWorkflowIds = workflowImageTable["workflow"].toSet().toList();
    var uniqueStepIds = workflowImageTable["image"].toSet().toList();

    var outTbl = WebappTable();
    var factory = tercen.ServiceFactory();
    var workflows = await factory.workflowService.list(uniqueWorkflowIds);
    for (var w in workflows) {
      var newTbl = await fetchWorkflowImages(w,
          includeStepId: uniqueStepIds, force: true);
      if (outTbl.colNames.isEmpty) {
        outTbl = newTbl;
      } else {
        outTbl.append(newTbl);
      }
    }

    return outTbl;
  }

  bool canCancelWorkflow(IdElementTable row) {
    return row["status"][0].label != "Done" &&
        row["status"][0].label != "Failed" &&
        row["status"][0].label != "Unknown";
  }

  Future<void> cancelWorkflow(IdElementTable row) async {
    var workflowId = row["name"][0].id;

    var factory = tercen.ServiceFactory();
    var workflow = await factory.workflowService.get(workflowId);

    var taskId = workflow.meta.firstWhere((e) => e.key == "run.task.id").value;
    await factory.taskService.cancelTask(taskId);

    await factory.workflowService.delete(workflow.id, workflow.rev);
  }

  Future<List<Workflow>> fetchWorkflowsRemote(String projectId) async {
    var factory = tercen.ServiceFactory();
    var projObjs = await factory.projectDocumentService
        .findProjectObjectsByLastModifiedDate(
            startKey: [projectId, '0000'], endKey: [projectId, '9999']);
    var workflowIds = projObjs
        .where((e) => e.subKind == "Workflow")
        .map((e) => e.id)
        .toList();

    return await factory.workflowService.list(workflowIds);
  }


  Future<Workflow> fetchWorkflow(String id) async {
    var factory = tercen.ServiceFactory();
    return factory.workflowService.get(id);
  }

  Future<List<Workflow>> fetchProjectWorkflows(
      List<Document> projectFiles) async {
    var workflowIds = projectFiles
        .where((e) => e.subKind == "Workflow")
        .map((e) => e.id)
        .toList();
    var factory = tercen.ServiceFactory();

    return workflowIds.isEmpty
        ? []
        : await factory.workflowService.list(workflowIds);
  }

  Future<void> updateFile(Document document, String text) async {
    var factory = tercen.ServiceFactory();
    var downloadStream = factory.fileService.download(document.id);
    var fileBytes = await downloadStream.toList();

    var readmeTxt = utf8.decode(fileBytes[0]);

    var notes = text.split("\n").map((e) => "> $e").join("  \n");
    notes += "  \n\n";
    notes = "## Run Notes  \n$notes";
    readmeTxt = notes + readmeTxt;

    var doc = await factory.fileService.get(document.id);
    Stream<List> dataStream =
        Stream.fromIterable(Iterable.castFrom([utf8.encode(readmeTxt)]));
    factory.fileService.upload(doc, dataStream);
  }

  Future<void> cancelWorkflowTask(String taskId,
      {bool deleteWorkflow = false}) async {
    var factory = tercen.ServiceFactory();
    var workflowId = "";
    if (deleteWorkflow) {
      var task = await factory.taskService.get(taskId);
      if (task is RunWorkflowTask) {
        workflowId = task.workflowId;
      }
    }
    await factory.taskService.cancelTask(taskId);
    if (deleteWorkflow && workflowId != "") {
      var workflow = await factory.workflowService.get(workflowId);
      await factory.workflowService.delete(workflow.id, workflow.rev);
    }
  }

  Future<WebappTable> fetchWorkflowTasks() async {
    var res = WebappTable();

    var factory = tercen.ServiceFactory();
    var tasks = await factory.taskService.getTasks(["RunWorkflowTask"]);
    var compTasks = tasks.whereType<sci.RunWorkflowTask>();
    var workflowIds = compTasks.map((task) => task.workflowId).toList();
    var workflows = await factory.workflowService.list(workflowIds);

    res.addColumn("Id", data: compTasks.map((w) => w.id).toList());
    res.addColumn("Name", data: workflows.map((w) => w.name).toList());
    res.addColumn("WorkflowIds", data: workflows.map((w) => w.id).toList());
    res.addColumn("Last Update",
        data: workflows
            .map((w) => DateFormatter.formatShort(w.lastModifiedDate))
            .toList());

    return res;
  }

  Future<Map<String, String>> getWorkflowStatus(sci.Workflow workflow) async {
    var meta = workflow.meta;
    var results = {"status": "", "error": "", "finished": "true"};
    results["status"] = "Unknown";

    if( workflow.steps.any((e) => e.state.taskState is sci.FailedState)){
        results["status"] = "Failed";
        results["error"] = meta
            .firstWhere((e) => e.key.contains("run.error"),
                orElse: () => sci.Pair.from("", ""))
            .value;
        if (meta.any((e) => e.key == "run.error.reason")) {
          
          var reason = meta.firstWhere((e) => e.key == "run.error.reason").value;
          results["error"] = reason != "" ? reason : "No details provided";
        } else {
          results["error"] =
              "${results["error"]}\n\nNo Error Details were Provided.";
        }
    }else if( !workflow.steps.whereType<sci.DataStep>().map((step) => step.state.taskState is sci.DoneState).any((state) => state == false) ) {
      results["status"] = "Finished";
    }else{
      results["status"] = "Running";
    }

    return results;
  }


  Future<WebappTable> fetchWorkflowTable(String projectId) async {
    var key = projectId;
    if (hasCachedValue(key)) {
      return getCachedValue(key);
    } else {
      var workflowService = WorkflowDataService();
      var workflows = (await workflowService.fetchWorkflowsRemote(projectId))
          .toList();

      var res = WebappTable();

      List<String> status = [];
      List<String> error = [];

      for (var w in workflows) {
        // var sw = await workflowService.getWorkflowStatus(w);
        var sw = await getWorkflowStatus(w);
        
        status.add(sw["status"]! );
        error.add(sw["error"]!);
      }

      res.addColumn("Id", data: workflows.map((w) => w.id).toList());
      res.addColumn("Name", data: workflows.map((w) => w.name).toList());
      res.addColumn("Status", data: status);
      // res.addColumn("Error", data: error);
      res.addColumn("Last Update",
          data: workflows
              .map((w) => DateFormatter.formatShort(w.lastModifiedDate))
              .toList());

      return res;
    }
  }


  Future<WebappTable> fetchWorkflowImagesSummary( String workflowId ) async {
    var factory = tercen.ServiceFactory();
    var wkf = await factory.workflowService.get(workflowId);    

    return fetchWorkflowImages(wkf, contentTypes: ["image", "text"]);
  }

  Future<void> updateReadme( 
       String workflowId, String text) async {
    var factory = tercen.ServiceFactory();

  
    var readmeDocument =  ProjectDataService().getProjectFiles().firstWhere(
        (e) => e.getMeta("WORKFLOW_ID") == workflowId,
        orElse: () => sci.Document());

    if (readmeDocument.id == "") {
      print("Readme not found for workflow id $workflowId");
    } else {
      var downloadStream = factory.fileService.download(readmeDocument.id);
      var fileBytes = await downloadStream.toList();

      var readmeTxt = utf8.decode(fileBytes[0]);

      var notes = text.split("\n").map((e) => "> $e").join("  \n");
      notes += "  \n\n";
      notes = "## Run Notes  \n$notes";
      readmeTxt = notes + readmeTxt;

      var doc = await factory.fileService.get(readmeDocument.id);
      Stream<List> dataStream =
          Stream.fromIterable(Iterable.castFrom([utf8.encode(readmeTxt)]));
      factory.fileService.upload(doc, dataStream);
    }
  }
}
