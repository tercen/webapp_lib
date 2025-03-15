import 'dart:async';
import 'package:flutter/material.dart';

import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_client/sci_client.dart';

// import 'package:webapp_model/id_element.dart';
// import 'package:webapp_model/id_element_table.dart';
import 'package:webapp_model/model/view_state.dart';
import 'package:webapp_model/settings/required_template.dart';
import 'package:webapp_ui_commons/webapp_base.dart';
import 'package:webapp_utils/functions/logger.dart';
import 'package:webapp_utils/services/file_data_service.dart';
import 'package:webapp_utils/services/settings_data_service.dart';
import 'package:webapp_utils/services/workflow_data_service.dart';
import 'package:webapp_utils/services/user_data_service.dart';
import 'package:webapp_utils/services/project_data_service.dart';
import 'package:json_string/json_string.dart';

class WebAppDataBase with ChangeNotifier {
  final WebAppBase app;
  WebAppDataBase(this.app);

  // final WorkflowStepsMapper stepsMapper = WorkflowStepsMapper();

  // final Map<String, List<IdElement>> _model = {};
  ViewState _model = ViewState(objects: []);
  // final Map<String, List<String>> _model = {};

  final WorkflowDataService workflowService = WorkflowDataService();
  final SettingsDataService settingsService = SettingsDataService();
  final FileDataService fileService = FileDataService();
  final UserDataService userService = UserDataService();
  final ProjectDataService projectService = ProjectDataService();

  Timer? saveTimer;

  bool shouldReload = false;
  bool isInit = false;

  // String get gtToken => app.gtToken;

  // IdElement get project => IdElement(app.projectId, app.projectName);
  // IdElement get username => IdElement(app.username, app.username);
  // IdElement get teamname => IdElement(app.teamname, app.teamname);

  void printModel() {
    print(_model);
  }

  Future<void> init(String projectId, String projectName, String username,
      {String reposJsonPath = "",
      String settingFilterFile = "",
      String stepMapperJsonFile = ""}) async {
    clear();

    await projectService.loadFolderStructure(projectId);

    await Future.wait([
      // workflowService.init(reposJsonPath: reposJsonPath),
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

  Future<void> loadModel() async {
    if (app.projectId != "") {
      var projectId = app.projectId;
      var user = app.username;

      var folder = await projectService
          .getOrCreateFolder(projectId, user, ".tercen", parentId: "");
      var viewFile = await projectService.getOrCreateFile(
          projectId, user, "${user}_view_05",
          parentId: folder.id);
      var navFile = await projectService.getOrCreateFile(
          projectId, user, "${user}_nav_05",
          parentId: folder.id);

      var contentString = projectService.getFileContent(viewFile);

      if (contentString != "" && contentString != "{}") {
        _model =
            ViewState.fromJson(JsonString(contentString).decodedValueAsMap);
      }

      contentString = projectService.getFileContent(navFile);
      if (contentString != "" && contentString != "{}") {
        app.loadPersistentData(JsonString(contentString).decodedValueAsMap);
      }
    }
  }

  Future<void> saveModel() async {
    if (app.projectId != "") {
      var projectId = app.projectId;
      var user = app.username;
      var folder = await projectService
          .getOrCreateFolder(projectId, user, ".tercen", parentId: "");

      var viewFile = await projectService.getOrCreateFile(
          projectId, user, "${user}_view_05",
          parentId: folder.id);

      var navFile = await projectService.getOrCreateFile(
          projectId, user, "${user}_nav_05",
          parentId: folder.id);

      await Future.wait([
        projectService.updateFileContent(viewFile, _model.toJson()),
        projectService.updateFileContent(navFile, app.getPersistentData())
      ]);
    }
  }

  String buildKey(String key, String groupKey) {
    return "${groupKey}_$key";
  }

  // String getFirstOrEmpty(String key, String groupKey) {
  //   key = buildKey(key, groupKey);

  //   if (_model.containsKey(key)) {
  //     var result = _model[key]!;
  //     if (result.isNotEmpty) {
  //       return result.first;
  //     }
  //   }

  //   return "";
  // }

  String? getData(String key, String groupKey) {
    key = buildKey(key, groupKey);

    if (_model.hasKey(key)) {
      return _model[key];
    }

    return null;
  }

  void clearData(String key, String groupKey) {
    // key = buildKey(key, groupKey);
    // if (_model.containsKey(key)) {
    //   _model.remove(key);
    // }
  }

  void setData(String key, String groupKey, String value) {
    key = buildKey(key, groupKey);
    _model[key] = value;
  }

  // void addData(String key, String groupKey, String value,
  //     {bool multiple = false}) {
  //   key = buildKey(key, groupKey);

  //   if( multiple && _model.hasKey(key)){
  //     _model[key].add(value);
  //   }else{
  //     _model[key] = [value];
  //   }

  // }
  // void setData(String key, String groupKey, IdElement value,
  //     {bool multiple = false}) {
  //   key = buildKey(key, groupKey);

  //   if (_model.containsKey(key) && multiple) {
  //     var vals = List<IdElement>.from(_model[key]!);
  //     vals.add(value);
  //     _model[key] = vals;
  //   } else {
  //     _model[key] = [value];
  //   }
  // }

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

  Future<void> createOrLoadProject(
      String projectId, String projectName, String username) async {
    var project =
        await projectService.doCreateProject(projectId, projectName, username);

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

  // Future<IdElementTable> fetchWorkflowImagesSummary(
  //     List<String> parentKeys, String groupId) async {
  //   // var workflowEl = getData(parentKeys.first, groupId).first;

  //   // var factory = tercen.ServiceFactory();
  //   // var wkf = await factory.workflowService.get(workflowEl.id);

  //   // return workflowService
  //   //     .fetchWorkflowImages(wkf, contentTypes: ["image", "text"]);
  //   return IdElementTable();
  // }

  // Future<IdElementTable> fetchWorkflowImagesByWorkflow(Workflow workflow,
  //     {List<String> contentTypes = const ["image"],
  //     List<String> excludedFiles = const []}) async {
  //   return workflowService.fetchWorkflowImages(workflow,
  //       contentTypes: contentTypes, excludedFiles: excludedFiles);
  // }

  // Future<IdElementTable> fetchWorkflowSummary(IdElement workflowEl) async {
  //   var factory = tercen.ServiceFactory();
  //   var wkf = await factory.workflowService.get(workflowEl.id);
  //   return workflowService.fetchWorkflowImages(wkf,
  //       contentTypes: ["text"], nameFilter: ["Summary"]);
  // }

  Future<void> checkMissingWorkflows() async {
    var requiredWorkflows = settingsService.requiredWorkflows;
    Logger().log(
        level: Logger.INFO,
        message: "Reading workflows for ${app.teamname} / ${app.username}");
    var installedWorkflowsDocuments =
        await workflowService.readWorkflowsDocumentsFromLib();

    List<RequiredTemplate> missing = [];

    List<Pair> workflowsToFetch = [];
    for (var reqWkf in requiredWorkflows) {
      var workflow = installedWorkflowsDocuments.firstWhere(
        (wkf) => reqWkf.url == wkf.url.uri && reqWkf.version == wkf.version,
        orElse: () => Document(),
      );
      if (workflow.id == "") {
        missing.add(reqWkf);
      } else {
        workflowsToFetch.add(Pair.from(reqWkf.iid, workflow.id));
      }
    }

    if (missing.isNotEmpty) {
      throw ServiceError(
          500, "Missing Template", buildMissingTemplateErrorMessage(missing));
    } else {
      var factory = tercen.ServiceFactory();
      var workflows = await factory.workflowService
          .list(workflowsToFetch.map((wkfPair) => wkfPair.value).toList());

      for (var wkfPair in workflowsToFetch) {
        var workflow = workflows.firstWhere((w) => w.id == wkfPair.value);
        workflowService.addWorkflow(wkfPair.key, workflow);
      }
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
