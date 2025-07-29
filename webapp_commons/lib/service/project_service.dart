import 'package:flutter/foundation.dart';
import 'package:webapp_commons/model/id_label.dart';
import 'package:webapp_commons/utils/logger.dart';
import 'package:webapp_commons/utils/simple_cache.dart';
import 'package:webapp_commons/model/tree_node.dart';
import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
class ProjectService {
  // Singleton offering multiple functions to search, create, and manage projects.
  static final ProjectService _singleton = ProjectService._internal();

  factory ProjectService() {
    return _singleton;
  }

  ProjectService._internal();

  TreeNode<sci.ProjectDocument> _projectRoot = TreeNode<sci.ProjectDocument>(
    id: 'root',
    label: "",
    value: sci.ProjectDocument(),
    children: [], 
  );
  
  var _currentProject = sci.Project();
  bool get hasProject => _currentProject.id.isNotEmpty;
  String get projectId => _currentProject.id;
  String get projectName => _currentProject.name.isEmpty ? "No Project Loaded" : _currentProject.name;
  String get projectOwner => _currentProject.acl.owner;
  TreeNode<sci.ProjectDocument> get root => _projectRoot;

  var projectUpdate = ValueNotifier<String>("");


  void _buildTree(TreeNode<sci.ProjectDocument> parent, List<sci.ProjectDocument> allDocs, String parentFolderId) {
    // Find documents that belong to this folder
    final childDocs = allDocs
        .where((doc) => doc.folderId == parentFolderId)
        .where((doc) => doc.id.isNotEmpty && doc.name.isNotEmpty);
    
    // Create TreeNode for each document and add to parent
    for (final doc in childDocs) {
      final node = TreeNode<sci.ProjectDocument>(
        id: doc.id,
        label: doc.name,
        value: doc,
        children: [],
      );
      parent.children.add(node);
      
      // If it's a folder, recursively build its children
      if (doc.subKind == "FolderDocument") {
        _buildTree(node, allDocs, doc.id);
      }
    }
  }

  Future<void> loadProjectFiles(String projectId, {TreeNode<sci.ProjectDocument>? reloadRoot, bool includeHidden = false}) async {
    final factory = tercen.ServiceFactory();
    try {
      _currentProject = await factory.projectService.get(projectId);  
    } catch (e) {
      throw sci.ServiceError(500, "Load Project", "Unable to load project with id $projectId: ${e.toString()}");
    }
    
    final startFolder = reloadRoot == null ? "\u0fff" : reloadRoot.id;
    final endFolder = reloadRoot == null ? "" : reloadRoot.id;

    final allObjects = await factory.projectDocumentService.findProjectObjectsByFolderAndName( 
          startKey: [projectId, startFolder, "\u0fff"],
          endKey: [projectId, endFolder, ""], limit: 10000 );

    print("Found ${allObjects.length} objects in project $projectId");

    final projectObjectList  = allObjects.where((obj) => obj.isHidden == false || includeHidden ).where((obj) => obj.isDeleted == false);
    print("\t${projectObjectList.length} remaining after filtering hidden and deleted objects.");

    if( reloadRoot == null ){
      _projectRoot.children.clear();
      _buildTree(_projectRoot, projectObjectList.toList(), "");
    }else{
      final node = _projectRoot.getDescendantById(reloadRoot.id);
      if( node != null ) {
        node.children.clear();
        _buildTree(node, projectObjectList.toList(), reloadRoot.id);
      } else {
        Logger().log(
          level: Logger.WARN, 
          message: "ProjectService.loadProjectFiles: Node with id ${reloadRoot.id} not found in the tree."
        );
      }
    }

    // Notify listeners that the project has been updated
    projectUpdate.value = _currentProject.id;
  }

  //Fetch list of projects
  Future<List<IdLabel>> fetchProjects(String teamName, {bool useCache = true, bool filterByOwner = false}) async {
    final key = "projects_${teamName}_$filterByOwner";
    print("Fetching projects key $key");
    if( useCache && SimpleCache.hasCachedValue(key)){
      return SimpleCache.getCachedValue(key) as List<IdLabel>;
    }

    final factory = tercen.ServiceFactory();
    var projects = await factory.projectService.findByTeamAndIsPublicAndLastModifiedDate(
            startKey: [teamName, true, '0000'],
            endKey: [teamName, false, '9999'],
          );
    print("Found ${projects.length} projects for team $teamName");
    if (filterByOwner) {
      projects = projects.where((project) => project.acl.owner == teamName).toList();
    }
    print("After filter, found ${projects.length} projects for team $teamName");

    final projectList = projects.map((project) => IdLabel(
      id: project.id,
      rev: project.rev,
      label: project.name,
      kind: "project",
    )).toList();
    print("Got final list");


    if( useCache ){
      SimpleCache.addToCache(key, projectList);
    }

    return projectList;
  }


  Future<void> createProject(String name, String owner ) async {
    final newProject = sci.Project()
          ..name = name
          ..acl.owner = owner;
    final factory = tercen.ServiceFactory();  
    final obj = await factory.projectService.create(newProject);
    await loadProjectFiles(obj.id);
  }

  Future<bool> projectExists(String name, String owner) async {
    final factory = tercen.ServiceFactory();
    final projects = await factory.projectService.findByTeamAndIsPublicAndLastModifiedDate(
            startKey: [owner, true, '0000'],
            endKey: [owner, false, '9999'],
          );

    return projects.any((project) => project.name == name && project.acl.owner == owner);
  }
}