import 'package:flutter/services.dart';
import 'package:json_string/json_string.dart';

import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_client/sci_client.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_model/id_element_table.dart';


import 'package:webapp_utils/functions/logger.dart';
import 'package:webapp_utils/functions/workflow_utils.dart';
import 'package:webapp_utils/mixin/data_cache.dart';
import 'package:webapp_utils/model/workflow_info.dart';



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
    print("Reading workflows from library (${libObjs.length})");

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
      if (info.url == libObj.url.uri && info.version == libObj.version) {
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
    for (var obj in libObjs) {
      var iid = _isInRepoFile(obj);
      if (iid != "") {
        ids.add(obj.id);
        iids.add(iid);
      }
    }

    if (!_allWorkflowsInstalled(iids)) {
      throw Exception("ERR_MISSING_TEMPLATE");
    }
    return [ids, iids];
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
      List<String> nameFilter = const []}) async {
    var key = "${wkf.id}_${contentTypes.join("_")}";
    if (excludedFiles.isNotEmpty) {
      key = "${key}_${excludedFiles.join("_")}";
    }

    if (hasCachedValue(key)) {
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
      if (stp.kind == "DataStep") {
        DataStep dStp = stp as DataStep;
        // print("Adding schemas for ${dStp.computedRelation.}");
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
        for (var i = 0; i < tbl.nRows; i++) {
          if (contentTypes.any((contentType) =>
              tbl.columns[1].values[i].contains(contentType))) {
            var fname = tbl.columns[0].values[i];
            var filterInclude = nameFilter.isEmpty ||
                nameFilter.any((name) => fname.contains(name));
            if (!excludedFiles.contains(fname) && filterInclude) {
              if (!uniqueAddedNames.contains(fname)) {
                uniqueAddedNames.add(fname);
                var bytesStream = factory.tableSchemaService
                    .getFileMimetypeStream(sch.id, tbl.columns[0].values[i]);
                var imgBytes = await bytesStream.toList();

                workflowNames.add(IdElement("", wkf.name));
                stepNames.add(step);
                filenames.add(IdElement("", fname));
                var ct = tbl.columns[1].values[i];
                contentTypeList.add(IdElement("", ct));

                bytes.add(IdElement(
                    "", String.fromCharCodes(Uint8List.fromList(imgBytes[0]))));
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
}
