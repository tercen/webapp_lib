import 'dart:convert';

import 'package:webapp_utils/folder_node.dart';
import 'package:sci_tercen_client/sci_client.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:webapp_utils/logger.dart';

class ProjectUtils {
  final FolderNode folderTreeRoot = FolderNode(FolderDocument(), true);
  bool structureLoaded = false;

  static final ProjectUtils _singleton = ProjectUtils._internal();

  factory ProjectUtils() {
    return _singleton;
  }

  ProjectUtils._internal();

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

  Future<FolderDocument> getOrCreateFolder(
      String projectId, String owner, String name,
      {String? parentId}) async {
    var candidateFolders = _getDocuments(name, true, parentId: parentId);

    if (candidateFolders.isNotEmpty) {
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

  Future<FileDocument> getOrCreateFile(
      String projectId, String owner, String name,
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
    doc.projectId = projectId;
    doc.acl = Acl()..owner = owner;
    doc.metadata.contentType = "application/json";
    doc.dataUri = "";
    doc = setFileContent(doc, {});
    doc = await factory.fileService.create(doc);

    await loadFolderStructure(projectId);

    return doc;
  }

  dynamic getFileContent(FileDocument fileDoc) {
    if (fileDoc.metadata.contentType == "application/json") {
      return json.decode(fileDoc.getMeta("file.content")!);
    } else {
      return fileDoc.getMeta("file.content")!;
    }
  }

  Future<void> updateFileContent(FileDocument fileDoc, Map content) async {
    var factory = tercen.ServiceFactory();
    fileDoc = setFileContent(fileDoc, content);
    // ignore: invalid_return_type_for_catch_error
    await factory.fileService.update(fileDoc).catchError((e) => Logger()
        .log(level: Logger.INFO, message: "Unable to update model state file"));
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

  List<Document> _getDocuments(String name, bool isFolder, {String? parentId}) {
    var candidateFolderNodes = folderTreeRoot
        .getDescendants(folders: true, documents: true)
        .where((e) => e.document.name == name);

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


}
