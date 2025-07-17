import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webapp_components/components/fetch_component.dart';
import 'package:webapp_components/abstract/serializable_component.dart';
import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/extra/infobox.dart';

import 'package:webapp_components/mixins/infobox_component.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:webapp_utils/functions/logger.dart';

typedef TileBuilderCallback = Widget Function(
    BuildContext context, HierarchyNode node, WebappTable row,
    {bool isEven, bool bold});

enum SelectionBehavior { none, single, multiLeaf, multi }
 
class SelectionNode {
  int level;
  String value;

  SelectionNode(this.level, this.value);

  @override
  bool operator ==(Object other) {
    if (other is! SelectionNode) {
      return false;
    }

    if (level != other.level) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => "${level.toString()}_$value".hashCode;

  @override
  String toString() {
    return "$level: $value";
  }

  String toMapString() {
    return "{'level':'$level', 'value':'$value'}";
  }

  static SelectionNode fromMapString(String json) {
    var valMap = jsonDecode(json);
    return SelectionNode(int.parse(valMap['level']), valMap['value']);
  }
}


class HierarchyNode {
  final String id;
  final String label;
  final int level;
  final String columnName;
  final String selectionColumnName;
  final HierarchyNode? parent;
  final List<HierarchyNode> children = [];

  HierarchyNode(this.id, this.label, this.level, this.columnName, this.selectionColumnName, {this.parent});

  void addChild(HierarchyNode child) {
    children.add(child);
  }

  @override
  bool operator ==(Object other) {
    return other is HierarchyNode && id == other.id;
  }

  @override
  String toString() {
    var s = "ROOT";
    for( var child in children ){
      s = "$s\n${printNode(child)}";
    }
    return s;
  }

  String printNode(node) {
    
    var tab = "";
    for (var i = 0; i < node.level; i++) {
      tab += "....";
    }
    var s = "$tab${node.label} (${node.id})";
    for( var child in node.children ){
      s = "$s\n${printNode(child)}";
    }
    return s;
  }

  List<HierarchyNode> getDescendants(){
    final descendants = <HierarchyNode>[];
    for( var child in children ){
      descendants.add(child);
      descendants.addAll(child.getDescendants());
    }
    return descendants;
  }

  WebappTable selectTableRow( WebappTable table,  List<String> vals, List<String> columns){
    final selColumns = <String>[];
    final selVals = <String>[];

    for( var i =0; i < vals.length; i++ ){
      selColumns.add(columns[i]);
      selVals.add(vals[i]);
    }
    return table.selectByColValue(
      selColumns,
      selVals
    );
  }


  List<HierarchyNode> createLevelNodes( int level, WebappTable table, List<String> columnHierarchy, List<String> selectionHierarchy, {HierarchyNode? parent}  ){
    if( level >= columnHierarchy.length ){
      return [];
    }

    final selectionCols = selectionHierarchy.isEmpty ? columnHierarchy : selectionHierarchy;
    final levelNodes = <HierarchyNode>[];
    final addedIds = <String>[];

    var pNode = parent;
    final vals = <String>[];
    while (pNode != null) {
      if (pNode.level >= 0) {  // Only collect IDs from valid data levels
        vals.insert(0, pNode.id);  // Maintain order: root to current
      }
      pNode = pNode.parent;
    }
    final levelTable = parent == null ? table : selectTableRow( table,  vals, selectionCols.getRange(0, level+1).toList());// table.selectByColValue([selectionHierarchy[level-1]], [parent.id]);

    for( var i = 0; i < levelTable.nRows; i++ ){
      final row = levelTable.select([i]);
      final id = row[selectionCols[level]].first;
      final label = row[columnHierarchy[level]].first;
      
      if( !addedIds.contains(id) ){
        addedIds.add(id);
        final newNode = HierarchyNode(id, label, level, columnHierarchy[level], selectionCols[level], parent: parent);
        newNode.children.addAll(
          newNode.createLevelNodes(level + 1, table, columnHierarchy, selectionHierarchy, parent: newNode)
        );
        levelNodes.add(newNode);
      }

    }

    return levelNodes;
  }

  static HierarchyNode fromTable(WebappTable table, List<String> columnHierarchy, {List<String>? selectionHierarchy} ){
    final selectionCols = selectionHierarchy ?? columnHierarchy;
    final rootNode = HierarchyNode("root", "root", -1, "", "");

    rootNode.children.addAll(rootNode.createLevelNodes(
      0,
      table,
      columnHierarchy,
      selectionCols,
    ));

    return rootNode;
  }
  
  @override
  int get hashCode => id.hashCode;
  

  String toStringMap(){
    return "{'id':'$id', 'label':'$label', 'level':$level, 'columnName':'$columnName', 'selectionColumnName':'$selectionColumnName', 'parent':${parent?.id ?? "null"}}";
  }

  static HierarchyNode fromMapString(String json) {
    var valMap = jsonDecode(json);
    return HierarchyNode(
      valMap['id'],
      valMap['label'],
      valMap['level'],
      valMap['columnName'],
      valMap['selectionColumnName'],
      parent: valMap['parent'] != null ? HierarchyNode.fromMapString(valMap['parent']) : null,
    );
  }

}

class HierarchySelectableListComponent extends FetchComponent
    implements SerializableComponent {
  final ScrollController scrollController = ScrollController();
  List<HierarchyNode> selectedNodes = [];

  final List<InfoBoxBuilder?> infoBoxBuilderList;
  List<String> infoBoxCols;

  final SelectionBehavior selectionBehavior;

  HierarchyNode hierarchyRoot = HierarchyNode("root", "root", -1, "", "");

  final List<String> columnHierarchy;
  final List<String>? selectionHierarchy;
  final List<String> hideColumns;
  final List<String> expandedLevels = [];

  late TileBuilderCallback nonLeafCallback;
  late TileBuilderCallback leafCallback;
  int maxLevel = 0;
  final bool shouldSave;
  final bool expanded;
  final double maxHeight;
  final String emptyMessage;
  final bool selectFirst;
  final Future Function(WebappTable rowTable, bool selected)? onChange;
  Function? delayedSelection;

  HierarchySelectableListComponent(
      super.id, super.groupId, super.componentLabel, super.dataFetchCallback,
      {cache = true,
      this.selectionBehavior = SelectionBehavior.none,
      this.expanded = true,
      this.columnHierarchy = const [],
      this.hideColumns = const [],
      this.infoBoxBuilderList = const [],
      this.maxHeight = 0,
      this.emptyMessage = "No data available",
      this.shouldSave = false,
      this.selectFirst = false,
      this.onChange,
      this.selectionHierarchy,
      this.infoBoxCols = const []}) {
    useCache = cache;

    maxLevel = columnHierarchy.length - 1;

    if( infoBoxCols.isEmpty && infoBoxBuilderList.length == 1 ){
      infoBoxCols = [columnHierarchy.last];
    }

    if( infoBoxBuilderList.length != infoBoxCols.length ){
      throw sci.ServiceError(500,
          "The infoBoxBuilderList must have the same length as the infoBoxCols.");
    }

    if( infoBoxBuilderList.isNotEmpty &&  infoBoxBuilderList.length < columnHierarchy.length){
      for( var i = infoBoxBuilderList.length; i < columnHierarchy.length; i++ ){
        infoBoxBuilderList.insert(0, null);
        infoBoxCols.insert(0, "");
      }
    }

    if (selectionBehavior == SelectionBehavior.single ||
        selectionBehavior == SelectionBehavior.multi ||
        selectionBehavior == SelectionBehavior.multiLeaf) {
      leafCallback = selectableLeafRowBuilder;
    } else {
      leafCallback = nonSelectableRowBuilder;
    }

    if (selectionBehavior == SelectionBehavior.multi) {
      nonLeafCallback = selectableLeafRowBuilder;
    } else {
      nonLeafCallback = nonSelectableRowBuilder;
    }

    if( selectionHierarchy != null && selectionHierarchy!.length != columnHierarchy.length ){
      throw sci.ServiceError(500,
          "The selection hierarchy must have the same length as the column hierarchy.");
    }
  }

  List<String> get columns => selectionHierarchy ?? columnHierarchy;
  //TODO Add reset

  List<HierarchyNode> getLevelNodes(int level, {String? parentId}) {
    return hierarchyRoot.getDescendants().where((node) => node.level == level).where((node) => parentId == null || node.parent?.id == parentId ).toList();
  }

  Widget infoBoxIcon(InfoBoxBuilder infoBoxBuilder, dynamic value, BuildContext context, {String? title}) {
    return IconButton(
      alignment: Alignment.center,
      padding: EdgeInsets.all(0),
        onPressed: () async {
          showDialog(
              context: context,
              builder: (dialogContext) {
                return StatefulBuilder(builder: (stfCtx, stfSetState) {
                  infoBoxBuilder.notifier.addListener(() {
                    stfSetState(() {});
                  });
                  return infoBoxBuilder.build(context, value, titleOverride: title);
                });
              });
        },
        icon: const Icon(Icons.info_outline));
  }

  Widget buildInfoBoxIcon(InfoBoxBuilder infoBoxBuilder, dynamic value, BuildContext context,
      {String? title, double iconCellWidth = 50}) {
    Widget infoBoxWidget = Container();
    double infoBoxWidth = 5;
    
    infoBoxWidget = infoBoxIcon(infoBoxBuilder, value, context, title: title);
    infoBoxWidth =iconCellWidth ;
    
    return SizedBox(
      width: infoBoxWidth,
      child: infoBoxWidget,
    );
  }

  @override
  WebappTable postLoad(WebappTable table){
    if( table.nRows > 0 ){
      hierarchyRoot = HierarchyNode.fromTable(
        table,
        columnHierarchy,
        selectionHierarchy: selectionHierarchy,
      );

      
      if(selectFirst &&  delayedSelection == null){
        select(hierarchyRoot.children.first);
        notifyListeners();
      }
      
    }else{
      hierarchyRoot.children.clear();
    }
    if( delayedSelection != null ){
      delayedSelection!();
      delayedSelection = null;
    }
    return table;
  }

  @override
  Widget createWidget(BuildContext context) {
    for (var col in columnHierarchy) {
      if (!dataTable.columns.containsKey(col)) {
        print(
            "[WARNING] Column $col is not present in the hierarchical list. Returning blank.");
        return Container();
      }
    }
    if (maxHeight == 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: buildWidgetTree(context),
      );
    } else {
      final screenHeight = MediaQuery.of(context).size.height;
      final height = screenHeight * maxHeight;
      return LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: height, // only scroll if content exceeds this
            ),
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: true, // Always show the scrollbar
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: buildWidgetTree(context),
                ),
              ),
            ),
          );
        },
      );
    }

  }

  @override
  Future<void> init() async {
    if (!isInit) {
      super.init();
      if (expanded) {
        expandedLevels.addAll(columnHierarchy);
      }
    }
  }

  @override
  Widget buildEmptyTable() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 0, 10),
        child: Text(emptyMessage, style: Styles()["text"]));
  }

  @override
  Widget buildContent(BuildContext context) {
    return build(context);
  }

  Widget nonSelectableRowBuilder(
      BuildContext context,HierarchyNode node, WebappTable rowEls,
      {bool isEven = true, bool bold = false}) {
    var clr = isEven ? Colors.white : Color.fromARGB(255, 240, 248, 255);
    var offset = node.level * 25 as double;
    
    // Check if this node has children to show chevron
    bool hasChildren = node.children.isNotEmpty;
    
    return Container(
      color: clr,
      width: double.infinity,
      height: 30,
      child: Padding(
        padding: EdgeInsets.only(left:  offset),
        child: Row(
          children: [
            // Chevron icon next to content (only if has children)
            if (hasChildren)
              Icon(
                expandedLevels.contains(node.id) 
                    ? Icons.remove 
                    : Icons.add,
                size: 16,
              ),
            if (hasChildren) SizedBox(width: 4),
            infoBoxBuilderList.isNotEmpty && infoBoxBuilderList[node.level] != null
                ? infoBoxIcon(infoBoxBuilderList[node.level]!, rowEls[infoBoxCols[node.level]].first, context)
                : Container(),
            Text(
              node.label,
              style: bold ? Styles()["textH2"] : Styles()["text"],
            ),
          ],
        ),
      ),
    );
  }

  bool isSelected(HierarchyNode node) {
    return selectedNodes.contains(node);
  }

  void select(HierarchyNode node) {
    if (!isSelected(node)) {
      print("Selecting node: ${node.id} at level ${node.level}");
      selectedNodes.add(node);
    }
  }

  void deselect(HierarchyNode node) {
    selectedNodes.remove(node);
  }

  

  void selectChildren(HierarchyNode node) {
    for( var child in node.children ){
      select(child);
      selectChildren(child);
    }
    // if (level < maxLevel) {
    //   var clickedValue = clickedRow[columns[level]].first;
    //   var children =
    //       dataTable.selectByColValue([columns[level]], [clickedValue]);

    //   for (var i = 0; i < children.nRows; i++) {
    //     var row = children.select([i]);
    //     var selectedNode =
    //         SelectionNode(level + 1, row[columns[level + 1]].first);
    //     select(selectedNode);
    //     selectChildren(row, level + 1);
    //   }
    // }
  }

  void deselectChildren(HierarchyNode node) {
    for( var child in node.children ){
      deselect(child);
      deselectChildren(child);
    }
  }

  void selectFather(HierarchyNode node) {
    // if (level > 0) {
      // var parentVal = clickedRow[columns[level - 1]].first;
      // var parentNode = SelectionNode(level - 1, parentVal);
      if( node.parent != null ){
        select(node.parent!);
        selectFather(node.parent!);
      }
      
      
    // }
  }

  void checkSiblings(HierarchyNode node) {
    final parentNode = node.parent;
    if( parentNode != null ){
      if(!parentNode.children.every((child) => isSelected(child))){
        deselect(parentNode);
      }
    }

  }

  Widget buildSelectableEntry(
      BuildContext context, HierarchyNode node, WebappTable row,
      {bool bold = false}) {
    // var colName = columns[level];
    // var clickedRow = dataTable.selectByColValue([colName], row[colName] );
    // var selectedNode = SelectionNode(level, row[colName].first);

    
    var textWdg = Text(
      node.label,
      style: bold ? Styles()["textH2"] : Styles()["text"],
    );

    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
              value: isSelected(node),
              checkColor: Styles()["black"],
              side: WidgetStateBorderSide.resolveWith((states) => BorderSide(
                    color: Styles()["black"],
                    width: 1.5,
                  )),
              fillColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                return Styles()["clear"];
              }),
              onChanged: (value) {
                if (value == true) {
                  if (selectionBehavior == SelectionBehavior.single) {
                    selectedNodes.clear();
                  }

                  select(node);

                  if (selectionBehavior == SelectionBehavior.multi) {
                    selectFather(node);
                    selectChildren(node);
                  }
                  if( onChange != null ){
                    // dataTable.selectByColValue([columns[node.level]], dataTable[columns[node.level]]);
                    onChange!(selectTableRow(node), true);
                  }
                  
                } else {
                  deselect(node);

                  if (selectionBehavior == SelectionBehavior.multi) {
                    checkSiblings(node);
                    deselectChildren(node);
                  }
                  if( onChange != null ){
                    onChange!(selectTableRow(node), false);
                  }
                }
                notifyListeners();
              }),
          const SizedBox(
            width: 5,
          ),
          infoBoxBuilderList.isNotEmpty && infoBoxBuilderList[node.level] != null
              ? infoBoxIcon(infoBoxBuilderList[node.level]!, row[infoBoxCols[node.level]].first, context)
              : Container(),
          textWdg
        ],
      ),
    );
  }

  WebappTable selectTableRow( HierarchyNode node ){
    final selColumns = <String>[];
    final selVals = <String>[];


    
    var lvlNode = node;
    while( lvlNode.level >= 0){
      selColumns.add(lvlNode.selectionColumnName);
      selVals.add(lvlNode.id);
      lvlNode = lvlNode.parent ?? HierarchyNode("root", "root", -1, "", "");
    }

    return dataTable.selectByColValue(
      selColumns,
      selVals
    );
  }

  WebappTable selectedAsTable() {
    final tbl = WebappTable();

    for( var col in dataTable.colNames ){
      tbl.addColumn(col, data: <String>[]);
    }

    for( var node in selectedNodes ){
      final row = selectTableRow(node);
      if( row.nRows > 0 ){
        for( var col in dataTable.colNames ){
          tbl[col].add(row[col].first);
        }
      }
      
    }

    // var level = maxLevel;

    // var originalColNames = dataTable.colNames;
    // var colNameIndex = originalColNames.indexOf(columns[maxLevel]);

    // var nodes = selectedNodes
    //     .where((node) => node.level == level)
    //     .map((node) => node.id)
    //     .toList();

    // var rows =
    //     dataTable.where((row) => nodes.contains(row[colNameIndex])).toList();

    
    // for (int i = 0; i < originalColNames.length; i++) {
    //   tbl.addColumn(originalColNames[i],
    //       data: rows.map((row) => row[i]).toList());
    // }

    return tbl;
  }

  Widget selectableLeafRowBuilder(
      BuildContext context,  HierarchyNode node, WebappTable rowVals,
      {bool isEven = true, bool bold = false}) {
    var clr = isEven ? Colors.white : Color.fromARGB(255, 240, 248, 255);
    var offset = node.level * 25 as double;
    
    return Container(
      color: clr,
      width: double.infinity,
      height: 30,
      child: Padding(
        padding: EdgeInsets.only(left: offset + 50),
        child: buildSelectableEntry(context, node, rowVals),
      ),
    );
  }

  List<Widget> buildWidgetTree(BuildContext context) {
    var globalCounter = {"count": 0}; // Use a map so it's passed by reference
    return createWidgets(context, 0, globalCounter: globalCounter);
  }

  Widget createTabulatedEntry(int level, Widget wdg, {bool isEven = false}) {
    // Pass the indentation level to the widget itself
    return wdg;
  }

  // List<String> getLevelList(int level, String? parent) {
  //   if (level == 0 || parent == null) {
  //     return dataTable[columnHierarchy[level]].toSet().toList();
  //   } else {
  //     return dataTable
  //         .selectByColValue(
  //             [columns[level - 1]], [parent])[columnHierarchy[level]]
  //         .toSet()
  //         .toList();
  //   }
  // }

  List<Widget> createWidgets(BuildContext context, int level,
      {String? parentId, Map<String, int>? globalCounter}) {
    List<Widget> wdg = [];
    final levelNodes = getLevelNodes(level, parentId: parentId );
    globalCounter ??= {"count": 0};

    for (var ri = 0; ri < levelNodes.length; ri++) {
      final node = levelNodes[ri];
      final currentIndex = globalCounter["count"]!;
      globalCounter["count"] = currentIndex + 1;

      if (node.children.isEmpty && level == maxLevel) { //Leaf
        wdg.add(createTabulatedEntry(
            level,
            leafCallback(
                context,
                node,
                isEven: currentIndex % 2 == 0,
                dataTable.select([ri])),
            isEven: currentIndex % 2 == 0));
      } else {
        wdg.add(createTabulatedEntry(
            level,
            Theme(
              data: Theme.of(context).copyWith(
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                listTileTheme: ListTileTheme.of(context).copyWith(
                  // hoverColor: Colors.transparent,
                  // focusColor: Colors.transparent,
                  selectedColor: Colors.transparent,
                ),
              ),
              child: ExpansionTile(
                shape: const Border(),
                controlAffinity: ListTileControlAffinity.trailing,
                backgroundColor: Colors.transparent,
                collapsedBackgroundColor: Colors.transparent,
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                trailing: SizedBox.shrink(), // Hide the default chevron
                initiallyExpanded: expandedLevels.contains(levelNodes[ri].id),
                onExpansionChanged: (expanded) {
                  if (expanded) {
                    if (!expandedLevels.contains(node.id)) {
                      expandedLevels.add(node.id);
                    }
                  } else {
                    expandedLevels.remove(node.id);
                  }
                  notifyListeners(); // Trigger rebuild to update icons
                },
                title: nonLeafCallback(
                    context,
                    node,
                    isEven: currentIndex % 2 == 0,
                    dataTable.select([ri]),
                    bold: true),
                children:
                    createWidgets(context, level + 1, parentId: node.id, globalCounter: globalCounter),
              ),
            ),
            isEven: currentIndex % 2 == 0));
      }
    }

    return wdg;
  }


  

  void setSelected(String value, String? column){
    if( isInit ){
      _setSelected(value, column);
    }else{
      delayedSelection =  () => _setSelected(value, column);
    }
  }

  void _setSelected(String value, String? column){
    final node = hierarchyRoot.getDescendants().where((node) => column == null || node.selectionColumnName == column) .firstWhere((node) => node.id == value, orElse: () => hierarchyRoot);

    if( node.level == -1 ){
      Logger().log(level: Logger.WARN, message: "_setSelected: Node with id $value not found in hierarchy.");
      return;
    }

    if( selectionBehavior == SelectionBehavior.single) {
      selectedNodes.clear();
    }

    select(node);
    notifyListeners();
  }

  @override
  void reset() {
    selectedNodes.clear();
    super.reset();
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.list;
  }

  @override
  getComponentValue() {
    return selectedAsTable();
  }

  @override
  String getStateValue() {
    List<String> stateValues = [];

    for (var node in selectedNodes) {
      stateValues.add(node.toStringMap());
    }
    return stateValues.join("|@|");
  }

  @override
  bool isFulfilled() {
    return selectedNodes.isNotEmpty;
  }

  @override
  void setComponentValue(value) {}

  @override
  void setStateValue(String value) {
    var nodeStrings = value.split("|@|");
    for (var v in nodeStrings) {
      selectedNodes.add(HierarchyNode.fromMapString(v));
    }
  }

  @override
  bool shouldSaveState() {
    return shouldSave;
  }
}
