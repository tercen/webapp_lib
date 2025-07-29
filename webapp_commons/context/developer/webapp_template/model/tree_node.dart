import '../utils/logger.dart';

class TreeNode<T> {
  final String id;
  final String label;
  final T value;
  final List<TreeNode<T>> children;
  final TreeNode<T>? parent;

  TreeNode(
      {required this.id,
      this.label = "",
      required this.value,
      this.children = const [],
      this.parent});

  List<TreeNode<T>> getDescendants() {
    List<TreeNode<T>> descendants = [];
    for (var child in children) {
      descendants.add(child);
      descendants.addAll(child.getDescendants());
    }
    return descendants;
  }

  TreeNode<T>? getDescendantById(String id) {
    List<TreeNode<T>> descendants = [];
    for (var child in children) {
      descendants.add(child);
      descendants.addAll(child.getDescendants());
    }

    return descendants.where(
      (descendant) => descendant.id == id).firstOrNull;
  }

  @override
  String toString() {
    return 'Tree(value: $value, children: $children)';
  }

  TreeNode<T> getRoot() {
    TreeNode<T> current = this;
    while (current.parent != null) {
      current = current.parent!;
    }
    return current;
  }


  void addChild(TreeNode<T> child) {
    final rootNode = getRoot();
    final node = rootNode.getDescendantById(child.id);
    if( node != null) {
      children.add(child);  
    }else{
      Logger().log(
        level: Logger.WARN,
        message: "Child with id ${child.id} already exists in the tree and was not added again."
      );
    }
  }
}
