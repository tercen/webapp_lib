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


  List<TreeNode<sci.ProjectDocument>> _buildTree(TreeNode<sci.ProjectDocument> parent, List<sci.ProjectDocument> docList, {String folderId = ""}) {
    try {
      print("Building tree for folderId: '$folderId', docList length: ${docList.length}");
      
      final objects = docList.where((obj) => obj.folderId == folderId);
      print("Found ${objects.length} objects with folderId '$folderId'");
      
      // Add null safety checks
      final validObjects = objects.where((doc) => 
        doc.id.isNotEmpty && 
        doc.name.isNotEmpty
      );
      print("${validObjects.length} objects passed validation");
      
      parent.children.addAll(validObjects.map((doc) => TreeNode<sci.ProjectDocument>(
        id: doc.id,
        label: doc.name,
        value: doc,
        children: [],
      )));

      parent.children.forEach((child) {
        if (child.value.subKind == "FolderDocument" && child.value.id.isNotEmpty) {
          print("Processing folder: ${child.value.name} (id: ${child.value.id})");
          child.children.addAll(_buildTree(child, docList, folderId: child.value.id));  
        }
      });

      print("Built tree node with ${parent.children.length} children");
      return parent.children;
    } catch (e) {
      print("Error in _buildTree: $e");
      Logger().log(
        level: Logger.ERROR,
        message: "Error in _buildTree for folderId '$folderId': $e"
      );
      rethrow;
    }
  }

  Future<void> loadProjectFiles(String projectId, {TreeNode? reloadRoot, bool includeHidden = false}) async {
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
      _projectRoot.children.addAll( _buildTree(_projectRoot, projectObjectList.toList()));
    }else{
      final node = _projectRoot.getDescendantById(reloadRoot.id);
      if( node != null ) {
        node.children.clear();
        node.children.addAll( _buildTree(node, projectObjectList.toList(), folderId: reloadRoot.id));
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