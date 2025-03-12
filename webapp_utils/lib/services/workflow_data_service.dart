import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:json_string/json_string.dart';

import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_client/sci_client.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_model/id_element_table.dart';


import 'package:webapp_utils/functions/logger.dart';
import 'package:webapp_utils/functions/project_utils.dart';
import 'package:webapp_utils/functions/workflow_utils.dart';
import 'package:webapp_utils/mixin/data_cache.dart';
import 'package:webapp_utils/model/workflow_info.dart';

import 'package:sci_tercen_client/sci_client.dart' as sci;


class WorkflowDataService with DataCache {
  static final WorkflowDataService _singleton = WorkflowDataService._internal();
  
  factory WorkflowDataService() {
    return _singleton;
  }
  
  WorkflowDataService._internal();
  
  final List<WorkflowInfo> _requiredWorkflows = [];
  final Map<String, Workflow> installedWorkflows = {};
  bool infoLoaded = false;

  Future<void> init({String reposJsonPath = ""}) async {
    if( reposJsonPath == ""){
      return;
    }
    String settingsStr = await rootBundle.loadString(reposJsonPath);
    try {
      final jsonString = JsonString(settingsStr);
      final repoInfoMap = jsonString.decodedValueAsMap;

      for (int i = 0; i < repoInfoMap["repos"].length; i++) {
        Map<String, dynamic> jsonEntry = repoInfoMap["repos"][i];

        WorkflowInfo workflow = WorkflowInfo(jsonEntry["iid"],
            jsonEntry["name"], jsonEntry["url"], jsonEntry["version"]);

        _requiredWorkflows.add(workflow);

        infoLoaded = true;
      }
    } on Exception catch (e) {
      print('Invalid JSON: $e');
    }

    await readWorkflowsFromLib();
  }

  Future<Map<String, Workflow>> readWorkflowsFromLib() async {
    if (installedWorkflows.isNotEmpty) {
      return installedWorkflows;
    }

    if (!infoLoaded) {
      await init();
    }
    var factory = tercen.ServiceFactory();

    var libObjs = await factory.documentService
        .getLibrary('', [], ["Workflow"], [], 0, -1);
    
    var reqWkfs = _getRequiredWorkflowsIds(libObjs);

    var workflows = await factory.workflowService.list(reqWkfs[0]);

    for (var i = 0; i < workflows.length; i++) {
      Logger().log(
          level: Logger.INFO,
          message: " Adding ${workflows[i].name} to ${reqWkfs[1][i]} ");
      installedWorkflows[reqWkfs[1][i]] = workflows[i];
    }

    return installedWorkflows;
  }

  String _isInRepoFile(Document libObj) {
    for (var info in _requiredWorkflows) {
      
      var isCorrectVersion = info.version == "NONE" || info.version == libObj.version;
      // print("${info.url == libObj.url.uri} :::: $isCorrectVersion");
      if (info.url == libObj.url.uri && isCorrectVersion) {
        return info.iid;
      }
    }

    return "";
  }

  bool _allWorkflowsInstalled(List<String> iids) {
    for (var wi in _requiredWorkflows) {
      if (!iids.contains(wi.iid)) {
        return false;
      }
    }
    return true;
  }

  List<List<String>> _getRequiredWorkflowsIds(List<Document> libObjs) {
    List<String> ids = [];
    List<String> iids = [];
    print("Checking library for required workflows");
    for (var obj in libObjs) {
      print("\tChecking ${obj.url.uri}");
      var iid = _isInRepoFile(obj);
      // print("IID: $iid");

      if (iid != "") {
        print("\tFound");
        ids.add(obj.id);
        iids.add(iid);
      }
    }

    if (!_allWorkflowsInstalled(iids)) {
      print("Did not find all needed workflows");
      throw  sci.ServiceError(1, "Missing Required Templates", missingTemplateErrorMessage(iids));
    }
    return [ids, iids];
  }

  String missingTemplateErrorMessage(List<String> foundIids){
    var err = "The following templates or versions were not found in any of your library teams:\n";

    for( var info in _requiredWorkflows ){
      if( !foundIids.contains( info.iid)){
        err = "$err\n* ${info.url} (version ${info.version})";
      }
    }
    return err;
  }

  bool _isFileSchema(Schema sch) {
    for (var col in sch.columns) {
      if (col.name.contains("mimetype")) {
        return true;
      }
    }
    return false;
  }

  List<SimpleRelation> _getSimpleRelations(Relation relation) {
    List<SimpleRelation> l = [];

    switch (relation.kind) {
      case "SimpleRelation":
        l.add(relation as SimpleRelation);
        break;
      case "CompositeRelation":
        CompositeRelation cr = relation as CompositeRelation;
        List<JoinOperator> joList = cr.joinOperators;
        l.addAll(WorkflowUtils.getSimpleRelations(cr.mainRelation));
        for (var jo in joList) {
          l.addAll(WorkflowUtils.getSimpleRelations(jo.rightRelation));
        }
      case "RenameRelation":
        RenameRelation rr = relation as RenameRelation;
        l.addAll(WorkflowUtils.getSimpleRelations(rr.relation));

      //
      default:
    }

    return l;
  }

  Future<IdElementTable> fetchWorkflowImages(Workflow wkf,
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

    List<IdElement> workflowNames = [];
    List<IdElement> stepNames = [];
    List<IdElement> filenames = [];
    List<IdElement> bytes = [];
    List<IdElement> contentTypeList = [];

    var factory = tercen.ServiceFactory();
    //TODO Make a single API call to list by building the full id list
    List<Relation> rels = [];
    Map<String, List<String>> stepRelationMap = {};
    for (var stp in wkf.steps) {
      var shouldIncludeStep = includeStepId.isEmpty || includeStepId.contains(stp.id);
      if (stp.kind == "DataStep" && shouldIncludeStep) {
        DataStep dStp = stp as DataStep;
        var relList = _getSimpleRelations(dStp.computedRelation);
        rels.addAll(relList);
        stepRelationMap[dStp.id] = relList.map((e) => e.id).toList();
      }
    }

    var schList =
        await factory.tableSchemaService.list(rels.map((e) => e.id).toList());
    
    for (var sch in schList) {
      var step = _getRelationStep(wkf, stepRelationMap, sch.id);
      if (_isFileSchema(sch)) {
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
        

        if( isDev ){
          // Avoid CORS issue with downloading image through browser request
          contentTable = await factory.tableSchemaService.select(sch.id, [sch.columns[nameIdx].name,  ".content"], 0, sch.nRows);

          List<Pair> uniqueNameType = [];
          for (var i = 0; i < tbl.nRows; i++){
            var name = tbl.columns[0].values[i];
            var cType = tbl.columns[1].values[i];

            if(!uniqueNameType.any((e) => e.key == name)){
              uniqueNameType.add(Pair.from(name, cType));
            }
          }

          

          for( var nameContent in uniqueNameType ){
            var isCorrectType = (contentTypes.any((contentType) =>
                nameContent.value.contains(contentType))) ;

            var filterInclude = nameFilter.isEmpty ||
                  nameFilter.any((name) => nameContent.key.contains(name));

            if (!excludedFiles.contains(nameContent.key) && filterInclude && isCorrectType) {
              uniqueAddedNames.add(nameContent.key);
              workflowNames.add(IdElement("", wkf.name));
              stepNames.add(step);
              filenames.add(IdElement("", nameContent.key));

              var bStr = "";
              for (var i = 0; i < tbl.nRows; i++){
                var tname = tbl.columns[0].values[i];
                if( nameContent.key == tname){
                  var newBStr = String.fromCharCodes( base64Decode( contentTable.columns[1].values[i]) );
                  bStr = "$bStr$newBStr";
                }
              }
              bytes.add(IdElement("", bStr));
            }
          }
        }else{
          for (var i = 0; i < tbl.nRows; i++) {
            if (contentTypes.any((contentType) =>
                tbl.columns[1].values[i].contains(contentType))) {
              var fname = tbl.columns[0].values[i];
              var filterInclude = nameFilter.isEmpty ||
                  nameFilter.any((name) => fname.contains(name));
              if (!excludedFiles.contains(fname) && filterInclude) {
                if (!uniqueAddedNames.contains(fname)) {
                  uniqueAddedNames.add(fname);
                  workflowNames.add(IdElement("", wkf.name));
                  stepNames.add(step);
                  filenames.add(IdElement("", fname));
                  var ct = tbl.columns[1].values[i];

                  contentTypeList.add(IdElement("", ct));

                    


                  var bytesStream = factory.tableSchemaService
                      .getFileMimetypeStream(sch.id, tbl.columns[0].values[i]);
                  var imgBytes = await bytesStream.toList();

                  

                  bytes.add(IdElement(
                      "", String.fromCharCodes(Uint8List.fromList(imgBytes[0]))));
                
                }
              }
            }
          }
       
        }

      }
    }

    IdElementTable tbl = IdElementTable()
      ..addColumn("workflowName", data: workflowNames)
      ..addColumn("filename", data: filenames)
      ..addColumn("step", data: stepNames)
      ..addColumn("data", data: bytes)
      ..addColumn("contentType", data: contentTypeList);
    addToCache(key, tbl);

    return tbl;
  }


  IdElement _getRelationStep(
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
      return IdElement("", "");
    }

    var stp = wkf.steps.firstWhere((e) => e.id == stepId);

    return IdElement(stp.id, stp.name);
  }

  
  Future<IdElementTable> fetchImageData(IdElementTable workflowImageTable ) async {
    assert(workflowImageTable.colNames.contains("workflow"));
    assert(workflowImageTable.colNames.contains("image"));

    var uniqueWorkflowIds = workflowImageTable["workflow"].map((e) => e.id).toSet().toList();
    var uniqueStepIds = workflowImageTable["image"].map((e) => e.id).toSet().toList();

    var outTbl = IdElementTable();
    var factory = tercen.ServiceFactory();
    var workflows = await  factory.workflowService.list(uniqueWorkflowIds);
    for( var w in workflows ){
      var newTbl = await fetchWorkflowImages(w, includeStepId: uniqueStepIds, force: true);
      if( outTbl.colNames.isEmpty ){
        outTbl = newTbl;
      }else{
        outTbl.append(newTbl);
      }
    }

    return outTbl;
  }

  bool canCancelWorkflow(IdElementTable row){
    return row["status"][0].label != "Done" && row["status"][0].label != "Failed" && row["status"][0].label != "Unknown";
  }

  Future<void> cancelWorkflow(IdElementTable row) async {

    
    var workflowId = row["name"][0].id;


    var factory = tercen.ServiceFactory();
    var workflow = await factory.workflowService.get(workflowId);

    var taskId = workflow.meta.firstWhere((e) => e.key == "run.task.id").value;
    await factory.taskService.cancelTask(taskId);
    
    await factory.workflowService.delete(workflow.id, workflow.rev);
    
    
  }

  Future<List<Workflow>> fetchWorkflowsRemote(String projectId) async{
    var factory = tercen.ServiceFactory();
    var projObjs = await factory.projectDocumentService.findProjectObjectsByLastModifiedDate(startKey: [projectId, '0000'], endKey: [projectId, '9999']);
    var workflowIds = projObjs.where((e) => e.subKind == "Workflow").map((e) => e.id).toList();

    return await factory.workflowService.list(workflowIds);
  }


  Future<Map<String, String>> getWorkflowStatus(Workflow workflow) async {
    var meta = workflow.meta;
    var results = {"status":"", "error":"", "finished":"true"};
    results["status"] = "Unknown";
    

    if(meta.any((e) => e.key == "run.task.id")){

      var factory = tercen.ServiceFactory();

      List<String> currentOnQueuWorkflow = [];
      List<String> currentOnQueuStep = [];
      List<State> currentOnQueuStatus = [];
      var compTasks = await factory.taskService.getTasks(["RunComputationTask"]);
        for( var ct in compTasks ){
          if( ct is RunComputationTask){
            for( var p in ct.environment ){
              if( p.key == "workflow.id"){
                currentOnQueuWorkflow.add(p.value);
              }
              if( p.key == "step.id"){
                currentOnQueuStep.add(p.value);
                currentOnQueuStatus.add(ct.state);
              }
            }
          }
        }
      
      var isRunning = currentOnQueuWorkflow.contains(workflow.id);
      var isFail = workflow.steps.any((e) => e.state.taskState is FailedState );


      if( isFail ){
        results["status"] = "Failed";
        results["error"] = meta.firstWhere((e) => e.key.contains("run.error"), orElse: () => Pair.from("", "")).value;
        if( meta.any((e) => e.key == "run.error.reason")){
          results["error"] = meta.firstWhere((e) => e.key == "run.error.reason").value;
        }else{
          results["error"] = "${results["error"]}\n\nNo Error Details were Provided.";
        }
        results["finished"] = isRunning ? "false" : "true";
      }else{
        var status = isRunning ? "Running" : "Pending";
        var allInit = true;
        var allDone = true;
        results["finished"] = isRunning ? "false" : "true";
        bool isAllPending = true;
        for( var s in workflow.steps ){
          for( var i = 0; i < currentOnQueuStep.length; i++ ){
            if( currentOnQueuStep[i] == s.id && currentOnQueuWorkflow[i] == workflow.id ){
              if( currentOnQueuStatus[i] is! PendingState ){
                isAllPending = false;
              }
              status = currentOnQueuStatus[i] is PendingState ? "Pending" : "Running";
            }
          }

          if( status == "Pending" && !isAllPending ){
            status = "Running";
          }
         
          allInit = allInit && (s.state.taskState is InitState);
          allDone = allDone && (s.state.taskState is DoneState);
        }
        if( allInit  ){
          status = "Not Started";
        }
        if( allDone ){
          status = "Done";
        }
        results["status"] = status;
      }
    }
    return results;
  }

  Workflow getWorkflow(String key) {
    if (!installedWorkflows.containsKey(key)) {
      throw Exception("Failed to find workflow with key '$key'");
    }
    return installedWorkflows[key]!;
  }

  Future<Workflow> fetchWorkflow(String id) async {
    var factory = tercen.ServiceFactory();
    return factory.workflowService.get(id);
  }

  Future<List<Workflow>> fetchProjectWorkflows(String projectId) async {
    var projectFiles = ProjectUtils().getProjectFiles();

    var workflowIds = projectFiles
        .where((e) => e.subKind == "Workflow")
        .map((e) => e.id)
        .toList();
    var factory = tercen.ServiceFactory();

    return workflowIds.isEmpty
        ? []
        : await factory.workflowService.list(workflowIds);
  }
}
