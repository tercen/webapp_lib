import 'dart:convert';
import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_client/sci_client.dart';
import 'package:webapp_core/runner/utils/cache_object.dart';

class ProjectDataService {
  static final ProjectDataService _singleton = ProjectDataService._internal();

  factory ProjectDataService() {
    return _singleton;
  }

  ProjectDataService._internal();

  Future<List<sci.ProjectDocument>> fetchProjectObjects(
      {required String projectId,
      String? folderId,
      bool recursive = false,
      bool useCache = true,
      bool includeFolders = true,
      bool includeDocuments = true}) async {
    final startFolder = folderId == null
        ? ""
        : folderId; //"\ufff0"; //reloadRoot == null ? "\ufff0" : reloadRoot;
    final endFolder = recursive ? "\ufff0" : folderId;
    final key = "fetchProjectObjects_${projectId}_${startFolder}_${endFolder}${includeFolders}${includeDocuments}";

    if (useCache && CacheObject().hasCachedValue(key)) {
      return CacheObject().getCachedValue(key);
    } else {
      final objList = await tercen.ServiceFactory()
          .projectDocumentService
          .findProjectObjectsByFolderAndName(
              startKey: [projectId, startFolder, "\ufff0"],
              endKey: [projectId, endFolder, ""],
              limit: 10000,
              useFactory: true);

      if( !includeFolders ){
        objList.removeWhere((obj) => obj is sci.FolderDocument);
      }

      if( !includeDocuments ){
        objList.retainWhere((obj) => obj is sci.FolderDocument);
      }

      if (useCache) {
        CacheObject().addToCache(key, objList);
      }

      return objList;
    }
  }

  Future<FolderDocument> getOrCreateFolder(
      {required String projectId,
      required String folderName,
      String parentFolderId = "",
      required String owner,
      bool useCache = true}) async {
    final key = "getOrCreateFolder_${folderName}_${parentFolderId}_$owner";

    if (useCache && CacheObject().hasCachedValue(key)) {
      return CacheObject().getCachedValue(key);
    } else {
      var folder = sci.FolderDocument();
      if (parentFolderId.isEmpty) {
        folder = await tercen.ServiceFactory()
            .folderService
            .getOrCreate(projectId, folderName);
      } else {
        final parentFolder =
            await tercen.ServiceFactory().folderService.get(parentFolderId);
        folder = await tercen.ServiceFactory()
            .folderService
            .getOrCreate(projectId, "${parentFolder.pathFromRoot}/$folderName");
      }

      if (useCache) {
        CacheObject().addToCache(key, folder);
      }
      return folder;
    }
  }

  Future<FolderDocument> fetchFolder({required String folderId, bool useCache = true}) async {
    final key = "fetchFolder_$folderId";
    if( useCache && CacheObject().hasCachedValue(key)){
      return CacheObject().getCachedValue(key);
    }else{
      final folder = await tercen.ServiceFactory().folderService.get(folderId);
      if (useCache) {
        CacheObject().addToCache(key, folder);
      }
      return folder;
    }
  }



  Future<FileDocument> getOrCreateFile(
      {required projectId, required String owner, required String name, String parentId = "", String contentType = "application/json", dynamic fileContent = "", bool useCache = true}) async {
    final key = "getOrCreateFile_${name}_${parentId}";

    if( useCache && CacheObject().hasCachedValue(key)){
      return CacheObject().getCachedValue(key);
    }else{
      final objList = await fetchProjectObjects(projectId: projectId, folderId: parentId, recursive: false, includeFolders: false);
      var doc = sci.FileDocument();
      if(objList.any((obj) => obj.name == name)){
        var fd = objList.firstWhere((obj) => obj.name == name);
        if(  fd is! sci.FileDocument ){
            throw sci.ServiceError(500, "file.name.conflict", "A project object with name $name already exists but it is not a FileDocument :: ${fd.kind}");
        }
        doc = fd;
      }else{
         doc.name = name;
          doc.isHidden = false;
          doc.folderId = parentId;
          doc.projectId = projectId;
          doc.acl = (Acl()..owner = owner);
          doc.metadata.contentType = contentType;
          doc.dataUri = "";

          doc = setFileContent(doc, fileContent);
          doc = await tercen.ServiceFactory().fileService.create(doc);
      }
      if(useCache){
        CacheObject().addToCache(key, doc);
      }

      return doc;
    }
  }

  String getFileContent({required FileDocument fileDoc}) {
    if (fileDoc.hasMeta("file.content")) {
      return fileDoc.getMeta("file.content")!;
    } else {
      return "";
    }
  }

  Future<void> updateFileContent({required FileDocument fileDoc, required Map content}) async {
    var factory = tercen.ServiceFactory();
    fileDoc = setFileContent(fileDoc, content);
    // ignore: invalid_return_type_for_catch_error
    await factory.fileService.update(fileDoc);
    ;
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

  Future<Project> fetchProject({required String projectId, bool useCache = true}) async {
    final key = "fetchProject_$projectId";
    if (useCache && CacheObject().hasCachedValue(key)) {
      return CacheObject().getCachedValue(key);
    } else {
      final proj = await tercen.ServiceFactory().projectService.get(projectId);
      if( useCache ){
        CacheObject().addToCache(key, proj);
      }
      
      return proj;
    }
  }

  Future<Project?> fetchProjectByName({required String projectName, required String owner, bool useCache = true}) async {
    final key = "fetchProjectByName_${projectName}${owner}";
    
    if (useCache && CacheObject().hasCachedValue(key)) {
      return CacheObject().getCachedValue(key);
      }else{
        final projects = await tercen.ServiceFactory().projectService.findByTeamAndIsPublicAndLastModifiedDate(
          startKey: [owner, false, "0000"], endKey: [owner, true, "9999"]);


     projects.retainWhere(
        (proj) =>
            proj.name == projectName &&
             proj.acl.owner == owner);
          final proj = projects.firstOrNull;
          if( useCache ){
            CacheObject().addToCache(key, proj);
          }
          return proj;
      }

  }

  Future<Project> createProject({required String name, required String owner,
      List<sci.Pair> metas = const []}) async {
    var factory = tercen.ServiceFactory();

    final project = Project()
    ..name = name
    ..acl = (Acl()..owner = owner);

    for( var meta in metas ){
      project.meta.add(meta);  
    }

    return await factory.projectService.create(project);
  }
}
