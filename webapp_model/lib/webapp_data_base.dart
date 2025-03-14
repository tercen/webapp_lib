import 'dart:async';
import 'package:flutter/material.dart';

import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_client/sci_client.dart';

import 'package:webapp_model/id_element.dart';
import 'package:webapp_model/id_element_table.dart';
import 'package:webapp_model/settings/required_template.dart';
import 'package:webapp_ui_commons/webapp_base.dart';
import 'package:webapp_utils/functions/logger.dart';
import 'package:webapp_utils/services/file_data_service.dart';
import 'package:webapp_utils/services/settings_data_service.dart';
import 'package:webapp_utils/services/workflow_data_service.dart';
import 'package:webapp_utils/services/user_data_service.dart';
import 'package:webapp_utils/services/project_data_service.dart';

class WebAppDataBase with ChangeNotifier {
  final WebAppBase app;
  WebAppDataBase(this.app);

  // final WorkflowStepsMapper stepsMapper = WorkflowStepsMapper();

  final Map<String, List<IdElement>> _model = {};

  final WorkflowDataService workflowService = WorkflowDataService();
  final SettingsDataService settingsService = SettingsDataService();
  final FileDataService fileService = FileDataService();
  final UserDataService userService = UserDataService();
  final ProjectDataService projectService = ProjectDataService();

  Timer? saveTimer;

  bool shouldReload = false;
  bool isInit = false;

  // String get gtToken => app.gtToken;

  IdElement get project => IdElement(app.projectId, app.projectName);
  IdElement get username => IdElement(app.username, app.username);
  IdElement get teamname => IdElement(app.teamname, app.teamname);

  void printModel() {
    print(_model);
  }

  Future<void> init(String projectId, String projectName, String username,
      {String reposJsonPath = "",
      String settingFilterFile = "",
      String stepMapperJsonFile = ""}) async {
    clear();

    await Future.wait([
      // workflowService.init(reposJsonPath: reposJsonPath),
      projectService.loadFolderStructure(projectId),
      settingsService.loadTemplateConfig(reposJsonPath),
      settingsService.loadSettingsFilter(settingFilterFile),
      settingsService.loadWorkflowStepMapper(stepMapperJsonFile)      
    ]);

    //Those need to be in order
    await checkMissingWorkflows();
    await workflowService.loadWorkflowSettings();
    await loadModel();

    saveTimer ??= Timer.periodic(const Duration(seconds: 5), (timer) {
      saveModel();
    });

    isInit = true;
  }

  //==================================================
  // State Files Management
  //==================================================
  void clear() {
    _model.clear();
  }

  Map _idElMapToJson(Map idElMap) {
    Map<String, List> jsonMap = {};
    for (var entry in idElMap.entries) {
      jsonMap[entry.key] = entry.value.map((e) => e.toString()).toList();
    }
    return jsonMap;
  }

  Map<String, List<IdElement>> _jsonToIdElMap(Map jsonMap) {
    Map<String, List<IdElement>> idElMap = {};
    for (var entry in jsonMap.entries) {
      idElMap[entry.key] = entry.value
          .map<IdElement>((e) =>
              IdElement(e.split("IdElement").first, e.split("IdElement").last))
          .toList();
    }
    return idElMap;
  }

  Future<void> loadModel() async {
    if (app.projectId != "") {
      var projectId = app.projectId;
      var user = app.username;

      var folder = await projectService
          .getOrCreateFolder(projectId, user, ".tercen", parentId: "");
      var viewFile = await projectService.getOrCreateFile(
          projectId, user, "${user}_view_04",
          parentId: folder.id);
      var navFile = await projectService.getOrCreateFile(
          projectId, user, "${user}_nav_04",
          parentId: folder.id);

      _model.addAll(_jsonToIdElMap(projectService.getFileContent(viewFile)));
      app.loadPersistentData(
          _jsonToIdElMap(projectService.getFileContent(navFile)));
    }
  }

  Future<void> saveModel() async {
    if (app.projectId != "") {
      var projectId = app.projectId;
      var user = app.username;
      var folder = await projectService
          .getOrCreateFolder(projectId, user, ".tercen", parentId: "");
      var viewFile = await projectService.getOrCreateFile(
          projectId, user, "${user}_view_04",
          parentId: folder.id);
      var navFile = await projectService.getOrCreateFile(
          projectId, user, "${user}_nav_04",
          parentId: folder.id);

      await Future.wait([
        projectService.updateFileContent(viewFile, _idElMapToJson(_model)),
        projectService.updateFileContent(
            navFile, _idElMapToJson(app.getPersistentData()))
      ]);
    }
  }

  String buildKey(String key, String groupKey) {
    return "${groupKey}_$key";
  }

  IdElement getFirstOrEmpty(String key, String groupKey) {
    key = buildKey(key, groupKey);

    if (_model.containsKey(key)) {
      var result = _model[key]!;
      if (result.isNotEmpty) {
        return result.first;
      }
    }

    return IdElement("", "");
  }

  List<IdElement> getData(String key, String groupKey) {
    key = buildKey(key, groupKey);
    List<IdElement> result = [];

    if (_model.containsKey(key)) {
      result = _model[key]!;
    }

    return result;
  }

  void clearData(String key, String groupKey) {
    key = buildKey(key, groupKey);
    if (_model.containsKey(key)) {
      _model.remove(key);
    }
  }

  void setData(String key, String groupKey, IdElement value,
      {bool multiple = false}) {
    key = buildKey(key, groupKey);

    if (_model.containsKey(key) && multiple) {
      var vals = List<IdElement>.from(_model[key]!);
      vals.add(value);
      _model[key] = vals;
    } else {
      _model[key] = [value];
    }
  }

  //==================================================
  // Project File State Check
  //==================================================
  bool hasProject() {
    return app.projectId != "";
  }

  //-------------------------------------------------------------
  //DATA FETCH Functions
  //-------------------------------------------------------------

  Future<List<String>> fetchUserList() async {
    return await userService.fetchUserList(app.username);
  }

  Future<void> createOrLoadProject(IdElement projectEl, String username) async {
    var project = await projectService.doCreateProject(projectEl, username);

    app.projectId = project.id;
    app.projectName = project.name;
    app.username = username;
    app.teamname = project.acl.owner;
    await init(app.projectId, app.projectName, username);
  }

  Future<void> projectFilesUpdated() async {
    projectService
        .loadFolderStructure(app.projectId)
        .then((value) => notifyListeners());
  }

  Future<void> reloadProjectFiles() async {
    await projectService
        .loadFolderStructure(app.projectId)
        .then((value) => notifyListeners());

    app.navMenu.project = app.projectName;
    app.navMenu.user = app.username;
    app.navMenu.team = app.teamname;
  }

  List<Document> getProjectFiles() {
    return projectService.folderTreeRoot
        .getDescendants(folders: true, documents: true)
        .map((e) => e.document)
        .toList();
  }

  Future<IdElementTable> fetchWorkflowImagesSummary(
      List<String> parentKeys, String groupId) async {
    var workflowEl = getData(parentKeys.first, groupId).first;

    var factory = tercen.ServiceFactory();
    var wkf = await factory.workflowService.get(workflowEl.id);

    return workflowService
        .fetchWorkflowImages(wkf, contentTypes: ["image", "text"]);
  }

  Future<IdElementTable> fetchWorkflowImagesByWorkflow(Workflow workflow,
      {List<String> contentTypes = const ["image"],
      List<String> excludedFiles = const []}) async {
    return workflowService.fetchWorkflowImages(workflow,
        contentTypes: contentTypes, excludedFiles: excludedFiles);
  }

  Future<IdElementTable> fetchWorkflowSummary(IdElement workflowEl) async {
    var factory = tercen.ServiceFactory();
    var wkf = await factory.workflowService.get(workflowEl.id);
    return workflowService.fetchWorkflowImages(wkf,
        contentTypes: ["text"], nameFilter: ["Summary"]);
  }

  Future<void> checkMissingWorkflows() async {
    var requiredWorkflows = settingsService.requiredWorkflows;
    Logger().log(level: Logger.INFO, message: "Reading workflows for ${app.teamname} / ${app.username}");
    var installedWorkflows = await workflowService
        .readWorkflowsFromLib2();

    print("Found the following workflows:");
    for( var w in installedWorkflows ){
      print("\t${w.name} :: ${w.version} :: ${w.url.uri}");
      print(w.toJson());
    }
    List<RequiredTemplate> missing = [];

    for (var reqWkf in requiredWorkflows) {
      var workflow = installedWorkflows.firstWhere(
        (wkf) => reqWkf.url == wkf.url.uri && reqWkf.version == wkf.version,
        orElse: () => Workflow(),
      );
      if (workflow.id == "") {
        missing.add(reqWkf);
      } else {
        workflowService.addWorkflow(reqWkf.iid, workflow);
      }
    }

    if (missing.isNotEmpty) {
      throw ServiceError(500, "Missing Template", buildMissingTemplateErrorMessage(missing));
    }
  }

  String buildMissingTemplateErrorMessage(List<RequiredTemplate> missingList) {
    var errMessage = "The following required templates are not installed:\n";

    for (var missing in missingList) {
      errMessage = "${errMessage}\n";
      errMessage = "${errMessage}*${missing.url} [${missing.version}]";
    }

    return errMessage;
  }

  Future<List<Workflow>> fetchProjectWorkflows(String projectId) async {
    var projectFiles = projectService.getProjectFiles();
    return workflowService.fetchProjectWorkflows(projectFiles);
  }

  Future<void> updateTextFile(String workflowId, String text,
      {String lowerFileName = "readme"}) async {

    var document = projectService.getProjectFiles().firstWhere(
        (e) =>
            e.getMeta("WORKFLOW_ID") == workflowId &&
            e.name.toLowerCase().contains(lowerFileName),
        orElse: () => Document());

    if (document.id == "") {
      print(
          "File name containing ${lowerFileName} not found for workflow id $workflowId");
    } else {
      workflowService.updateFile(document, text);
    }
  }
}
