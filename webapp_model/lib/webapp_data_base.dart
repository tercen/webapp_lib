import 'dart:async';
import 'package:flutter/material.dart';

import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_client/sci_client.dart';



import 'package:webapp_model/id_element.dart';
import 'package:webapp_model/id_element_table.dart';
import 'package:webapp_ui_commons/webapp_base.dart';
import 'package:webapp_utils/functions/project_utils.dart';
import 'package:webapp_utils/functions/workflow_steps_mapper.dart';
import 'package:webapp_utils/services/settings_data_service.dart';
import 'package:webapp_utils/services/workflow_data_service.dart';





class WebAppDataBase with ChangeNotifier {
  final WebAppBase app;
  WebAppDataBase(this.app);

  final WorkflowStepsMapper stepsMapper = WorkflowStepsMapper();
  
  final Map<String, List<IdElement>> _model = {};

  final WorkflowDataService workflowService = WorkflowDataService();
  final SettingsDataService settingsService = SettingsDataService();

  Timer? _saveTimer;
  
  bool shouldReload = false;
  bool isInit = false;

  // String get gtToken => app.gtToken;

  IdElement get project => IdElement(app.projectId, app.projectName);
  IdElement get username => IdElement(app.username, app.username);
  IdElement get teamname => IdElement(app.teamname, app.teamname);

  void printModel(){
    print(_model);
  }


  Future<void> init(String projectId, String projectName, String username, {List<String> settingFiles = const [], String stepMapperJsonFile = ""} ) async{
    _model.clear();
    
    await Future.wait([
      workflowService.init(),
      ProjectUtils().loadFolderStructure(projectId),
      settingsService.loadSettings(settingFiles, settingFiles),
      stepsMapper.loadSettingsFile(stepMapperJsonFile)
    ]);

    await _loadModel();

    _saveTimer ??= Timer.periodic( const Duration(seconds: 5), (timer){
      _saveModel();
    });

    isInit = true;    
    
  }

  
  //==================================================
  // State Files Management
  //==================================================
  Map _idElMapToJson(Map idElMap) {
    Map<String, List> jsonMap = {};
    for( var entry in idElMap.entries ){
      
      jsonMap[entry.key] = entry.value.map((e) => e.toString()).toList();

    }
    return jsonMap;
  } 

  Map<String, List<IdElement>> _jsonToIdElMap(Map jsonMap) {
    Map<String, List<IdElement>> idElMap = {};
    for( var entry in jsonMap.entries ){
      idElMap[entry.key] = entry.value.map<IdElement>((e) => IdElement(e.split("IdElement").first, e.split("IdElement").last)  ).toList();
    }
    return idElMap;
  } 

  Future<void> _loadModel() async {
    var projectId = app.projectId;
    var user = app.username;
    
    var folder = await  ProjectUtils().getOrCreateFolder(projectId, user, ".tercen", parentId: "");
    var viewFile = await ProjectUtils().getOrCreateFile(projectId, user, "${user}_view", parentId: folder.id);
    var navFile = await ProjectUtils().getOrCreateFile(projectId, user, "${user}_nav", parentId: folder.id);

    _model.addAll(  _jsonToIdElMap(ProjectUtils().getFileContent(viewFile) ) );
    app.loadPersistentData( _jsonToIdElMap(ProjectUtils().getFileContent(navFile) ) );
    

  }

  Future<void> _saveModel() async{
    var projectId = app.projectId;
    var user = app.username;
    var folder = await  ProjectUtils().getOrCreateFolder(projectId, user, ".tercen", parentId: "");
    var viewFile = await ProjectUtils().getOrCreateFile(projectId, user, "${user}_view", parentId: folder.id);
    var navFile = await ProjectUtils().getOrCreateFile(projectId, user, "${user}_nav", parentId: folder.id);

    await Future.wait([
      ProjectUtils().updateFileContent(viewFile, _idElMapToJson(_model)),
      ProjectUtils().updateFileContent(navFile, _idElMapToJson(app.getPersistentData()))
    ]);
  }


  String _buildKey( String key, String groupKey ){
    return "${groupKey}_$key";
  }

  IdElement getFirstOrEmpty( String key, String groupKey ){
    key = _buildKey(key, groupKey);
    

    if( _model.containsKey(key)){
      var result = _model[key]!;
      if( result.isNotEmpty ){
        return result.first;
      }
    }

    return IdElement("", "");
  }


  List<IdElement> getData( String key, String groupKey ){
    key = _buildKey(key, groupKey);
    List<IdElement> result = [];

    if( _model.containsKey(key)){
      result = _model[key]!;
    }

    return result;
  }


  void clearData( String key, String groupKey ){
    key = _buildKey(key, groupKey);
    if( _model.containsKey(key)){
      _model.remove(key);
    }
  }


  void setData( String key, String groupKey, IdElement value, {bool multiple = false} ){
    key = _buildKey(key, groupKey);

    if( _model.containsKey(key) && multiple){
      var vals = List<IdElement>.from(_model[key]!);
      vals.add(value);
      _model[key] = vals;
    }else{
      _model[key] = [value];
    }

  }


  
  Workflow getWorkflow(String key){
    
    if( !workflowService.installedWorkflows.containsKey(key)){
      throw Exception("Failed to find workflow with key '$key'");
    }
    return workflowService.installedWorkflows[key]!;
  }

  Future<Workflow> fetchWorkflow(String id) async{
    
    var factory = tercen.ServiceFactory();
    return factory.workflowService.get(id);
  }




  Future<void> projectFilesUpdated() async{
    ProjectUtils().loadFolderStructure( app.projectId ).then((value) => notifyListeners());
  }


  Future<void> reloadProjectFiles() async{
    await ProjectUtils().loadFolderStructure( app.projectId ).then((value) => notifyListeners());
  }

  List<Document> getProjectFiles(){
    return ProjectUtils().folderTreeRoot.getDescendants(folders: true, documents: true).map((e) => e.document).toList();
  }

  Future<IdElementTable> fetchWorkflowImagesSummary( List<String> parentKeys, String groupId ) async {
    var workflowEl = getData(parentKeys.first, groupId).first;
    
    var factory = tercen.ServiceFactory();
    var wkf = await factory.workflowService.get(workflowEl.id);

    return workflowService.fetchWorkflowImages(wkf, contentTypes: ["image", "text"]);
  }

  Future<IdElementTable> fetchWorkflowImagesByWorkflow( Workflow workflow, {List<String> contentTypes = const ["image"], List<String> excludedFiles = const []} ) async {
    return workflowService.fetchWorkflowImages(workflow, contentTypes: contentTypes, excludedFiles: excludedFiles);
  }

  Future<IdElementTable> fetchWorkflowSummary(IdElement workflowEl) async {
      var factory = tercen.ServiceFactory();
      var wkf = await factory.workflowService.get(workflowEl.id);
      return workflowService.fetchWorkflowImages(wkf, contentTypes: ["text"], nameFilter: ["Summary"]);
  }
  
}