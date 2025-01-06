import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_client/sci_client.dart';


class FolderNode {
  final Document document;

  bool isFolder;
  FolderNode? parent;
  List<FolderNode> children = [];

  FolderNode(this.document, this.isFolder);

  void addParent(FolderNode node){
    parent = node;
  }


  String getPath({bool full = false}){
    if( parent != null && full == true ){
      var parentPath = parent!.getPath(full: full);
      if( parentPath != ""){
        return "$parentPath/${document.name}";
      }else{
        return document.name;
      }
      
    }else{
      return document.name;
    }
  }

  bool isSiblingOf( String id ){
    if( parent == null ){
      return false;
    }else{
      return parent!.children.any((e) => e.document.id == id);
    }
  }

  bool isDescendantOrSiblingOf( String id ){

    if( parent == null ){
      return false;
    }else{
      return parent!.document.id == id || parent!.isDescendantOf(id);
    }

    
  }

  bool isDescendantOf( String id ){
    if( parent == null ){
      return false;
    }else{
      return parent!.document.id == id || parent!.isDescendantOf(id);
    }

    
  }

  FolderNode? getNodeInDescendantsByDocId( String objectId   ){

    if( document.id == objectId){
      return this;
    }

    for( var child in children ){
      FolderNode? node = child.getNodeInDescendantsByDocId(  objectId);
      if( node != null ){
        return node;
      }
    }
  

    return null;
  }

  FolderNode? getNodeInDescendants( String parentFolderId, {String objectId = ""}  ){
    if( isFolder ) {
      if( document.id == parentFolderId){
        if( objectId == "" ){
          return this;
        }else{
          for( var child in children ){
            if( child.document.id == objectId){
              return child;
            }
          }
        }
        
      }

      for( var child in children ){
        FolderNode? node = child.getNodeInDescendants(parentFolderId, objectId: objectId);
        if( node != null ){
          return node;
        }
      }
    }

    return null;
  }

  List<ProjectDocument> getProjectDocuments( {bool recursive = false}  ){
    List<ProjectDocument> docs = [];

    docs.addAll( children.where((e) => e.isFolder == false).map((e) => e.document).toList().cast<ProjectDocument>() );

    if( recursive == true ){
      for( var child in children ){
        docs.addAll( child.getProjectDocuments(recursive: recursive));
      }
    }

    return docs;
  }

  List<FolderDocument> getFolderDocuments( {bool recursive = false}  ){
    List<FolderDocument> docs = [];

    docs.addAll( children.where((e) => e.isFolder == true).map((e) => e.document).toList().cast<FolderDocument>() );

    if( recursive == true ){
      for( var child in children ){
        docs.addAll( child.getFolderDocuments(recursive: recursive));
      }
    }

    return docs;
  }

  static List<FolderDocument> getFolders( String parentFolderId, FolderNode node, {recursive = false} ){
    List<FolderDocument> docList = [];
    var parentNode = node.getNodeInDescendants(parentFolderId);
    if( parentNode != null ){
      docList.addAll(parentNode.getFolderDocuments(recursive: recursive));
    }

    return docList;
  }

  static List<ProjectDocument> getDocuments( String parentFolderId, FolderNode node, {recursive = false} ){
    List<ProjectDocument> docList = [];
    var parentNode = node.getNodeInDescendants(parentFolderId);
    if( parentNode != null ){
      docList.addAll(parentNode.getProjectDocuments(recursive: recursive));
    }

    return docList;
  }

  List<FolderNode> getDescendants({bool folders = true, bool documents = true}){
    List<FolderNode> nodes = [];
    
    var onlyFolders = folders == true && documents == false;
    var onlyDocuments = folders == false && documents == true;
    var foldersDocuments = folders == true && documents == true;
    nodes.addAll(children.where((e) => foldersDocuments == true || (onlyFolders == true && e.isFolder == true) || (onlyDocuments == true && e.isFolder == false) ));

    for( var child in children ){
      nodes.addAll(child.getDescendants(folders: folders, documents: documents));
    }

    return nodes;
  }

  @Deprecated("TODO: traverse from root node with filters")
  static List<FolderNode> getDocumentNodes( String parentFolderId, FolderNode node, {recursive = false} ){
    List<FolderNode> nodeList = [];
    var parentNode = node.getNodeInDescendants(parentFolderId);
    if( parentNode != null ){
      nodeList.addAll(parentNode.getDescendants(folders: false, documents: true));
    }
    return nodeList;
  }

  void printStructure({FolderNode? root, int level = 0}){
    FolderNode node = root ?? this;
    String tab = "";
    for( int i =0; i<level; i++){
      tab = "$tab\t";
    }

    String docType = "[D]";
    if( node.document is FolderDocument ){
      docType = "[F]";
    }

    print("$tab * $docType ${node.document.name}");

    for( var c in node.children ){
      node.printStructure(root: c, level: level+1);
    }
    
  }



}
