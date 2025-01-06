import 'package:webapp_utils/folder_node.dart';
import 'package:sci_tercen_client/sci_client.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:webapp_utils/logger.dart';

class ProjectFunctions {
  final FolderNode folderTreeRoot = FolderNode(FolderDocument(), true);
  bool structureLoaded = false;

  static final ProjectFunctions _singleton = ProjectFunctions._internal();

  factory ProjectFunctions() {
    return _singleton;
  }

  ProjectFunctions._internal();

  Future<void> loadFolderStructure(String projectId) async {

    if (projectId != "") {
      List<dynamic> results = await Future.wait([
        _fetchRemoteFolderDocuments("", projectId, recursive: true),
        _fetchRemoteFolders("", projectId, recursive: true)
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


  Future<FolderDocument> getOrCreateFolder(String projectId, String owner, String name, {String? parentId}) async {
    var candidateFolders = _getDocuments(name, true, parentId: parentId);

    if( candidateFolders.isNotEmpty ){
      return candidateFolders.first as FolderDocument;
    }

    var factory = tercen.ServiceFactory();
    var folder = FolderDocument();
    folder.name = name;
    folder.isHidden = false;
    folder.projectId = projectId;
    folder.folderId = parentId ?? "";
    folder.acl = Acl()..owner = owner;

    folder = await factory.folderService.create(folder);

    await loadFolderStructure(projectId);

    return folder;
  }



  List<Document> getProjectFiles(){
    if( !structureLoaded){
      Logger().log(message: "Project file structure has not been loaded");
    }

    return folderTreeRoot.getDescendants(folders: true, documents: true).map((e) => e.document).toList();
  }

  Future<List<ProjectDocument>> _fetchRemoteFolderDocuments(
      String folderId, String projectId,
      {bool recursive = false}) async {
    List<ProjectDocument> docs = [];
    var factory = tercen.ServiceFactory();
    var folderObjects = await factory.projectDocumentService
        .findProjectObjectsByFolderAndName(
            startKey: [projectId, folderId, "\ufff0"],
            endKey: [projectId, folderId, ""]);
    for (var obj in folderObjects) {
      if (obj.subKind == "FolderDocument") {
        if (recursive == true) {
          docs.addAll(await _fetchRemoteFolderDocuments(obj.id, projectId,
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
      children.addAll(docs
          .cast<ProjectDocument>()
          .where((e) => e.folderId == node.document.id)
          .map((e) => FolderNode(e, isFolder)));
    }

    for (var child in children) {
      child.parent = node;
      child.children = _buildChildrenList(child, docs, isFolder);
    }

    return children;
  }

  Future<List<FolderDocument>> _fetchRemoteFolders(
      String folderId, String projectId,
      {bool recursive = false}) async {
    List<FolderDocument> docs = [];
    var factory = tercen.ServiceFactory();
    var folderObjects = await factory.folderService
        .findFolderByParentFolderAndName(
            startKey: [projectId, folderId, "\ufff0"],
            endKey: [projectId, folderId, ""]);

    for (var obj in folderObjects) {
      docs.add(obj);
      if (recursive == true) {
        docs.addAll(
            await _fetchRemoteFolders(obj.id, projectId, recursive: recursive));
      }
    }

    return docs;
  }

  List<Document> _getDocuments(String name, bool isFolder, {String? parentId}){
    var candidateFolderNodes = folderTreeRoot.getDescendants(folders: true, documents: true).where((e) => e.document.name == name);

    if( parentId != null && candidateFolderNodes.isNotEmpty ){
      if( isFolder ){
        candidateFolderNodes = candidateFolderNodes.where((e) => (e.document as FolderDocument).folderId == parentId);
      }else{
        candidateFolderNodes = candidateFolderNodes.where((e) => (e.document as ProjectDocument).folderId == parentId);
      }
    }    

    return candidateFolderNodes.map((e) => e.document).toList();
  }
}
