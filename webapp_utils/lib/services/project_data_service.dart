import 'dart:convert';
import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_client/sci_client.dart';
import 'package:webapp_utils/cache_object.dart';
import 'package:webapp_utils/folder_node.dart';
import 'package:webapp_utils/functions/logger.dart';
import 'package:webapp_utils/services/app_user.dart';


class ProjectDataService {

  static final ProjectDataService _singleton = ProjectDataService._internal();
  final CacheObject cache = CacheObject();
  factory ProjectDataService() {
    return _singleton;
  }
  
  ProjectDataService._internal();
  bool structureLoaded = false;
  final FolderNode folderTreeRoot = FolderNode(FolderDocument(), true);




  Future<void> loadFolderStructure({String? folderId}) async {
    if (AppUser().projectId != "") {
      List<sci.ProjectDocument> allObjects = await _fetchProjectObjects(reloadRoot: folderId);
      
      List<FolderDocument> allFolders = [];
      List<ProjectDocument> allDocs = [];
      
      for (var obj in allObjects) {

        if (obj.kind == "FolderDocument") {
          
          allFolders.add(obj as FolderDocument);
        } else {
          // print("\t${obj.name}");
          allDocs.add(obj as ProjectDocument);
        }
      }

      if (folderId == null || folderId.isEmpty) {
        folderTreeRoot.children.clear();
        folderTreeRoot.children =
            _buildChildrenList(folderTreeRoot, allFolders, true);
        folderTreeRoot.children =
            _buildChildrenList(folderTreeRoot, allDocs, false);
        structureLoaded = true;
        // print("After full reload");
        // folderTreeRoot.printStructure();
      } else {
        _updatePartialTree(folderId, allFolders, allDocs);
        // print("After partial update");
        // folderTreeRoot.printStructure();
      }
    }
  }


  Future<void> loadFolderStructureOLD() async {
    if (AppUser().projectId != "") {
      List<dynamic> results = await Future.wait([
        _fetchRemoteFolderDocuments("", recursive: true),
        _fetchRemoteFolders("",  recursive: true)
      ]);
      List<ProjectDocument> allDocs = results[0];
      List<FolderDocument> allFolders = results[1];

      folderTreeRoot.children.clear();
      folderTreeRoot.children =
          _buildChildrenList(folderTreeRoot, allFolders, true);
      folderTreeRoot.children =
          _buildChildrenList(folderTreeRoot, allDocs, false);
      structureLoaded = true;
    }
  }

  Future<List<sci.ProjectDocument>> _fetchProjectObjects({String? reloadRoot}) async {
    final startFolder = "\ufff0"; //reloadRoot == null ? "\ufff0" : reloadRoot;
    final endFolder = reloadRoot == null ? "" : reloadRoot;

    return  await tercen.ServiceFactory().projectDocumentService.findProjectObjectsByFolderAndName( 
          startKey: [AppUser().projectId, startFolder, "\ufff0"],
          endKey: [AppUser().projectId, endFolder, ""], limit: 10000, useFactory: true);
  }

  void _updatePartialTree(String folderId, List<FolderDocument> allFolders, List<ProjectDocument> allDocs) {
    FolderNode? targetNode = _findNodeById(folderTreeRoot, folderId);
    if (targetNode != null) {
      targetNode.children.clear();
      targetNode.children = _buildChildrenList(targetNode, allFolders, true);
      targetNode.children = _buildChildrenList(targetNode, allDocs, false);
    }
  }

  FolderNode? _findNodeById(FolderNode node, String id) {
    if (node.document.id == id) {
      return node;
    }
    for (var child in node.children) {
      var found = _findNodeById(child, id);
      if (found != null) {
        return found;
      }
    }
    return null;
  }
  FolderDocument? getFolder(String name, {String? parentId}) {
    var candidateFolders = _getDocuments(name, true, parentId: parentId);

    if (candidateFolders.isNotEmpty) {
      return candidateFolders.first as FolderDocument;
    } else {
      return null;
    }
  }

  Future<FolderDocument> getOrCreateFolder(
       String name,
      {String? parentId}) async {
    var candidateFolders = _getDocuments(name, true, parentId: parentId);

    if (candidateFolders.isNotEmpty) {
      return candidateFolders.first as FolderDocument;
    }

    var factory = tercen.ServiceFactory();
    var folder = FolderDocument();
    folder.name = name;
    folder.isHidden = false;
    folder.projectId = AppUser().projectId;
    folder.folderId = parentId ?? "";
    folder.acl = Acl()..owner = AppUser().teamname != "" ? AppUser().teamname : AppUser().username;

    folder = await factory.folderService.create(folder);

    await loadFolderStructure();

    return folder;
  }

  List<ProjectDocument> getFolderDocuments(String folderId, 
      {bool recursive = false}) {
    List<ProjectDocument> docs = [];

    docs.addAll(FolderNode.getDocuments(folderId, folderTreeRoot,
        recursive: recursive));
    return docs;
  }

  Future<FileDocument> getOrCreateFile(
      String name,
      {String? parentId, String contentType = "application/json"}) async {
    var factory = tercen.ServiceFactory();
    var candidateFolders = _getDocuments(name, false, parentId: parentId);

    if (candidateFolders.isNotEmpty) {
      //Folder exists. If more than one combination of name + parentId exists, return the first found
      return await factory.fileService.get(candidateFolders.first.id);
    }

    var doc = FileDocument();

    doc.name = name;
    doc.isHidden = false;
    doc.folderId = parentId ?? "";
    doc.projectId = AppUser().projectId;
    doc.acl = Acl()..owner = AppUser().teamname;
    doc.metadata.contentType = "application/json";
    doc.dataUri = "";
    doc = setFileContent(doc, {});
    doc = await factory.fileService.create(doc);

    await loadFolderStructure();

    return doc;
  }

  String getFileContent(FileDocument fileDoc) {
    if (fileDoc.hasMeta("file.content")) {
      return fileDoc.getMeta("file.content")!;
    } else {
      return "";
    }
  }

  Future<void> updateFileContent(FileDocument fileDoc, Map content) async {
    var factory = tercen.ServiceFactory();
    fileDoc = setFileContent(fileDoc, content);
    // ignore: invalid_return_type_for_catch_error
    await factory.fileService.update(fileDoc).catchError((e) => Logger()
        .log(level: Logger.WARN, message: "Unable to update model state file"));
    ;
  }

  List<Document> getProjectFiles() {
    if (!structureLoaded) {
      Logger().log(message: "Project file structure has not been loaded");
    }

    return folderTreeRoot
        .getDescendants(folders: true, documents: true)
        .map((e) => e.document)
        .toList();
  }

  Future<List<ProjectDocument>> _fetchRemoteFolderDocuments(
      String folderId, 
      {bool recursive = false}) async {
    List<ProjectDocument> docs = [];
    var factory = tercen.ServiceFactory();
    var folderObjects = await factory.projectDocumentService
        .findProjectObjectsByFolderAndName(
            startKey: [AppUser().projectId, folderId, "\ufff0"],
            endKey: [AppUser().projectId, folderId, ""]);
    for (var obj in folderObjects) {
      if (obj.subKind == "FolderDocument") {
        if (recursive == true) {
          docs.addAll(await _fetchRemoteFolderDocuments(obj.id, 
              recursive: recursive));
        }
      } else {
        docs.add(obj);
      }
    }

    return docs;
  }

  List<FolderNode> _buildChildrenList(
      FolderNode node, List<Document> docs, bool isFolder) {
    List<FolderNode> children = node.children;
    if (isFolder) {
      
      children.addAll(docs
          .cast<FolderDocument>()
          .where((e) => e.folderId == node.document.id)
          .map((e) => FolderNode(e, isFolder)));
    } else {
      // print("ADDING DOCS TO ${node.document.name}");
      children.addAll(docs
          .cast<ProjectDocument>()
          .where((e) => e.folderId == node.document.id)
          .map((e) => FolderNode(e, isFolder)));
    }
    // for( var d in docs){
    //     print("\t${d.name} ");
    //   }
    for (var child in children) {
      child.parent = node;
      child.children = _buildChildrenList(child, docs, isFolder);
    }

    return children;
  }

  Future<List<FolderDocument>> _fetchRemoteFolders(
      String folderId, 
      {bool recursive = false}) async {
    List<FolderDocument> docs = [];
    var factory = tercen.ServiceFactory();
    var folderObjects = await factory.folderService
        .findFolderByParentFolderAndName(
            startKey: [AppUser().projectId, folderId, "\ufff0"],
            endKey: [AppUser().projectId, folderId, ""]);

    for (var obj in folderObjects) {
      docs.add(obj);
      if (recursive == true) {
        docs.addAll(
            await _fetchRemoteFolders(obj.id, recursive: recursive));
      }
    }

    return docs;
  }

  List<Document> _getDocuments(String name, bool isFolder, {String? parentId}) {
    // print("Searching for $name");
    var candidateFolderNodes = folderTreeRoot
        .getDescendants(folders: true, documents: true)
        .where((e) => e.document.name.trim() == name.trim());

    if (parentId != null && candidateFolderNodes.isNotEmpty) {
      if (isFolder) {
        candidateFolderNodes = candidateFolderNodes
            .where((e) => (e.document as FolderDocument).folderId == parentId);
      } else {
        candidateFolderNodes = candidateFolderNodes
            .where((e) => (e.document as ProjectDocument).folderId == parentId);
      }
    }

    return candidateFolderNodes.map((e) => e.document).toList();
  }

  FileDocument setFileContent(FileDocument fileDoc, dynamic content) {
    if (content is Map) {
      fileDoc.addMeta("file.content", json.encode(content));
    } else if (content is String) {
      fileDoc.addMeta("file.content", content);
    } else {
      throw Exception("Unsupported file content type");
    }

    return fileDoc;
  }

  Future<Project> fetchProject({required String projectId}) async{
    if( cache.hasCachedValue(projectId)){
      return cache.getCachedValue(projectId);
    }else{
      final factory = tercen.ServiceFactory();
      final proj = await factory.projectService.get(projectId);
      cache.addToCache(projectId, proj);
      return proj;
    }
    
    
  }

  Future<Project> getProjectByName(String projectName, {String? owner}) async{
    final factory = tercen.ServiceFactory();
 
    final allProjects = await Future.wait([
      factory.projectService.findByIsPublicAndLastModifiedDate(startKey: [true, "0000"], endKey: [true, "9999"]),
      factory.projectService.findByIsPublicAndLastModifiedDate(startKey: [false, "0000"], endKey: [false, "9999"])
    ]);

    var projects = allProjects[0];
    projects.addAll(allProjects[1]);
    
    return projects.firstWhere((proj) => proj.name == projectName && (owner == null || proj.acl.owner == owner), orElse: () => Project());
  }

  Future<Project> doCreateProject(
      String projectName, String team,
      {String appName = "", String appVersion = ""}) async {
    var factory = tercen.ServiceFactory();

    var project = Project();

    // try {
    //   project = await factory.projectService.get(projectId);
    //   return project;
    // } catch (e) {
    //   //Ignore for now. Project not found, so must create one
    // }

    project.name = projectName;
    project.acl.owner = team;

    project.meta.add(Pair.from("APP_URL", appName));
    project.meta.add(Pair.from("APP_VERSION", appVersion));

    project = await factory.projectService.create(project);

    return project;
  }
}
