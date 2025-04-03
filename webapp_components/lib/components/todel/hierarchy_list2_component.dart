// import 'package:flutter/material.dart';
// import 'package:webapp_components/abstract/serializable_component.dart';
// import 'package:webapp_components/definitions/component.dart';
// import 'package:webapp_components/mixins/component_base.dart';
// import 'package:webapp_components/mixins/component_cache.dart';
// import 'package:webapp_components/mixins/state_component.dart';

// import 'package:webapp_components/mixins/infobox_component.dart';
// import 'package:webapp_components/widgets/wait_indicator.dart';
// import 'package:webapp_model/webapp_table.dart';
// import 'package:webapp_ui_commons/styles/styles.dart';

// typedef TileBuilderCallback2 = Widget
//     Function(BuildContext context, String name, int level, {bool isEven});

// enum SelectionBehavior { none, single, multi }

// class HierarchyListComponent2
//     with
//         ChangeNotifier,
//         ComponentBase,
//         ComponentCache,
//         ComponentInfoBox,
//         StateComponent
//     implements SerializableComponent {
//   List<String> selectedElements = [];

//   WebappTable dataTable = WebappTable();
//   final SelectionBehavior selectionBehavior;
//   // late int maxDepth;
//   final bool nonLeafSelectable;

//   bool isInit = false;
//   final List<String> columnHierarchy;
//   final List<String> expandedLevels = [];

//   Future<WebappTable> Function() dataFetchCallback;

//   late TileBuilderCallback2 nonLeafCallback;
//   late TileBuilderCallback2 leafCallback;
//   int maxLevel = 0;
//   HierarchyListComponent2(id, groupId, componentLabel, this.dataFetchCallback,
//       {cache = true,
//       this.selectionBehavior = SelectionBehavior.none,
//       this.columnHierarchy = const [],
//       this.nonLeafSelectable = false}) {
//     super.id = id;
//     super.groupId = groupId;
//     super.componentLabel = componentLabel;
//     useCache = cache;

//     maxLevel = this.columnHierarchy.length - 1;
//     nonLeafCallback = leafRowBuilder;
//     leafCallback = nonLeafRowBuilder;
//   }

//   Future<bool> loadTable() async {
//     if (!isInit) {
//       busy();
//       var cacheKey = getKey();
//       if (hasCachedValue(cacheKey)) {
//         dataTable = getCachedValue(cacheKey);
//       } else {
//         dataTable = await dataFetchCallback();
//         var idx = List<int>.generate(dataTable.nRows, (i) => i);
//         List<String> keys = [];
//         for (var i in idx) {
//           keys.add(columnHierarchy
//               .map((col) => dataTable[col][i])
//               .join()
//               .hashCode
//               .toString());
//         }
//         dataTable.addColumn(".key", data: keys);
//         addToCache(cacheKey, dataTable);
//       }
//       idle();
//     }
//     return true;
//   }

//   Widget createWidget(BuildContext context) {
//     for (var col in columnHierarchy) {
//       if (!dataTable.columns.containsKey(col)) {
//         print(
//             "[WARNING] Column $col is not present in the hierarchical list. Returning blank.");
//         return Container();
//       }
//     }

//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: buildWidgetTree(context),
//     );
//   }

//   @override
//   Widget buildContent(BuildContext context) {
//     if (isBusy) {
//       return SizedBox(
//           height: 100,
//           child: TercenWaitIndicator()
//               .waitingMessage(suffixMsg: "  Loading Table"));
//     } else {
//       if (dataTable.nRows == 0) {
//         return Container();
//       } else {
//         return createWidget(context);
//       }
//     }
//   }

//   bool isSelected(String key) {
//     return (dataTable.selectByColValue([".key"], [key])).nRows > 0;
//   }

//   Row nonLeafRowBuilder(BuildContext context, String name, int level,
//       {bool isEven = true}) {
//     return Row(
//       children: [
//         SizedBox(width: 50, child: Text("NONLEAF: $name")),
//         Container(
//           height: 20,
//           color: isEven ? Styles()["evenRow"] : Styles()["oddRow"],
//           child: Text(
//             name,
//             style: Styles()["text"],
//           ),
//         )
//       ],
//     );
//   }

//   Row leafRowBuilder(BuildContext context, String name, int level,
//       {bool isEven = true}) {
//     return Row(
//       children: [
//         SizedBox(width: 50, child: Text("LEAF: $name")),
//         Container(
//           height: 20,
//           color: isEven ? Styles()["evenRow"] : Styles()["oddRow"],
//           child: Text(
//             name,
//             style: Styles()["text"],
//           ),
//         )
//       ],
//     );
//   }

//   // Row checkboxRowWidget(
//   //     BuildContext context, String key, String name, int row, int level,
//   //     {bool isEven = true}) {
//   //   var isElSelected = isSelected(key);

//   //   return Row(
//   //     children: [
//   //       SizedBox(
//   //           width: 50,
//   //           child: checkBoxWidget(id, name, row, level, isElSelected)),
//   //       Container(
//   //         height: 20,
//   //         color: isEven ? Styles()["evenRow"] : Styles()["oddRow"],
//   //         child: Text(
//   //           name,
//   //           style: Styles()["text"],
//   //         ),
//   //       )
//   //     ],
//   //   );
//   // }

//   List<Widget> buildWidgetTree(BuildContext context) {
//     return createWidgets(context, 0);
//   }

//   Widget createTabulatedEntry(int level, Widget wdg, {bool isEven = false}) {
//     var clr = isEven ? Styles()["evenRow"] : Styles()["oddRow"];
//     var row = Row(mainAxisSize: MainAxisSize.min, children: [
//       Container(
//         constraints: BoxConstraints(minWidth: level * 50),
//       ),
//       Flexible(child: wdg)
//     ]);

//     return Container(
//       color: clr,
//       child: row,
//     );
//   }

//   List<String> getLevelList(int level, String? parent) {
//     if (level == 0 || parent == null) {
//       return dataTable[columnHierarchy[level]].toSet().toList();
//     } else {
//       return dataTable
//           .selectByColValue(
//               [columnHierarchy[level - 1]], [parent])[columnHierarchy[level]]
//           .toSet()
//           .toList();
//     }
//   }

//   List<Widget> createWidgets(BuildContext context, int level,
//       {String? parentId}) {

//     List<Widget> wdg = [];
//     List<String> levelList = getLevelList(level, parentId);

//     var levelColumn = columnHierarchy[level];
//     for (var ri = 0; ri < levelList.length; ri++) {
//       if (level == maxLevel) {
//         wdg.add(createTabulatedEntry(level,
//             leafCallback(context, levelList[ri], level, isEven: ri % 2 == 0),
//             isEven: ri % 2 == 0));
//       } else {
//         wdg.add(createTabulatedEntry(
//             level,
//             ExpansionTile(
//               initiallyExpanded: expandedLevels.contains(levelColumn),
//               title: nonLeafCallback(context, levelList[ri], level, isEven: ri % 2 == 0),
//               children: createWidgets(context, level + 1, parentId: levelList[ri]),
//             ),
//             isEven: ri % 2 == 0));
//       }

     
//     }

//     return wdg;
//   }

//   // final List<List<String>> hierarchicalList = [];

//   // bool multiSelection = true;

//   // late TileBuilderCallback nonLeafCallback;
//   // late TileBuilderCallback leafCallback;

//   // void clearLists() {
//   //   columnHierarchy.clear();
//   //   expandedLevels.clear();
//   //   hierarchicalList.clear();
//   // }

//   // void load(WebappTable elementTable, List<String> hierarchy,
//   //     List<String> selection,
//   //     {Map<String, String> titles = const {}}) {
//   //   selectedElements = selection;
//   //   multiSelection = true;

//   //   for (var titleEntry in titles.entries) {
//   //     var colIdx = hierarchy.indexOf(titleEntry.key);
//   //     if (colIdx > 0) {
//   //       List<String> proxyCol = [];
//   //       for (var ri = 0; ri < elementTable.nRows; ri++) {
//   //         proxyCol.add(titleEntry.value);
//   //       }
//   //       String colKey = "${titleEntry.key}_TITLE";
//   //       expandedLevels.add(colKey);
//   //       elementTable.addColumn(colKey, data: proxyCol);
//   //       columnHierarchy.insert(colIdx, colKey);
//   //     }
//   //   }

//   //   table = elementTable;
//   //   columnHierarchy.addAll(hierarchy);

//   //   for (var colName in hierarchy) {
//   //     List<String> els = table[colName]!;
//   //     hierarchicalList.add(els);
//   //   }
//   //   maxDepth = hierarchicalList.length - 1;
//   // }

//   // List<int> findIndices(List l, String value) {
//   //   List<int> indices = [];

//   //   for (var i = 0; i < l.length; i++) {
//   //     if (l[i] == value) {
//   //       indices.add(i);
//   //     }
//   //   }

//   //   return indices;
//   // }

//   // void deselect(String id) {
//   //   var tmpEls =
//   //       List<IdElement>.from(selectedElements.where((e) => e.id != id));
//   //   selectedElements.clear();
//   //   selectedElements.addAll(tmpEls);
//   // }

//   // void select(String id, String name) {
//   //   if (!multiSelection) {
//   //     selectedElements.clear();
//   //   }
//   //   selectedElements.add(IdElement(id, name));
//   // }

//   // List<IdElement> getSelectionParentByChildColumn(String colName) {
//   //   int level = columnHierarchy.indexWhere((e) => e == colName);

//   //   if (level == -1) {
//   //     throw Exception(
//   //         "Column $colName not found in HierarchyList.getSelectionParent");
//   //   }
//   //   int parentLevel = level - 1;

//   //   if (parentLevel < 0) {
//   //     return [];
//   //   }

//   //   var parentElements = table.columns[table.colNames[parentLevel]]!;
//   //   var childElements = table.columns[table.colNames[level]]!;

//   //   var nRows = table.nRows();

//   //   List<IdElement> els = [];
//   //   for (var ri = 0; ri < nRows; ri++) {
//   //     if (isSelected(childElements[ri])) {
//   //       els.add(parentElements[ri]);
//   //     }
//   //   }

//   //   return els;
//   // }

//   // List<Widget> createWidgets(BuildContext context, int level,
//   //     {String? parentId}) {
//   //   List<String> addedIds = [];
//   //   List<Widget> wdg = [];
//   //   List<String> levelList = hierarchicalList[level];

//   //   var levelColumn = columnHierarchy[level];
//   //   for (var ri = 0; ri < levelList.length; ri++) {
//   //     var idEl = levelList[ri];
//   //     // CHeck if belongs to parent
//   //     if (level > 0) {
//   //       var pId = hierarchicalList[level - 1][ri].id;
//   //       if (parentId != null && pId != parentId) {
//   //         continue;
//   //       }
//   //     }

//   //     if (!addedIds.contains(idEl.id)) {
//   //       addedIds.add(idEl.id);

//   //       if (level == maxDepth) {
//   //         wdg.add(createTabulatedEntry(
//   //             level,
//   //             leafCallback(context, idEl.id, idEl.label, ri, level,
//   //                 isEven: ri % 2 == 0),
//   //             isEven: ri % 2 == 0));
//   //       } else {
//   //         wdg.add(createTabulatedEntry(
//   //             level,
//   //             ExpansionTile(
//   //               initiallyExpanded: expandedLevels.contains(levelColumn),
//   //               title: nonLeafCallback(context, idEl.id, idEl.label, ri, level,
//   //                   isEven: ri % 2 == 0),
//   //               children: createWidgets(context, level + 1, parentId: idEl.id),
//   //             ),
//   //             isEven: ri % 2 == 0));
//   //       }
//   //     }
//   //   }

//   //   return wdg;
//   // }

//   // List<IdElement> getAllChildren(int parentLevel, String parentId) {
//   //   List<IdElement> children = [];

//   //   if (parentLevel < maxDepth) {
//   //     var parentList = hierarchicalList[parentLevel];
//   //     var childList = hierarchicalList[parentLevel + 1];

//   //     for (var i = 0; i < childList.length; i++) {
//   //       if (parentList[i].id == parentId) {
//   //         children.add(childList[i]);
//   //       }
//   //     }
//   //   }

//   //   return children;
//   // }

//   // bool isSelected(IdElement el) {
//   //   for (var e in selectedElements) {
//   //     if (e.id == el.id) {
//   //       return true;
//   //     }
//   //   }
//   //   return false;
//   // }

//   // Widget createTabulatedEntry(int level, Widget wdg, {bool isEven = false}) {
//   //   var clr = isEven ? Styles()["evenRow"] : Styles()["oddRow"];
//   //   var row = Row(mainAxisSize: MainAxisSize.min, children: [
//   //     Container(
//   //       constraints: BoxConstraints(minWidth: level * 50),
//   //     ),
//   //     Flexible(child: wdg)
//   //   ]);

//   //   return Container(
//   //     color: clr,
//   //     child: row,
//   //   );
//   // }

//   // List<Widget> buildWidgetTree(BuildContext context) {
//   //   return createWidgets(context, 0);
//   // }
//   // @override
//   // Widget buildContent(BuildContext context) {
//   //   // TODO: implement buildContent
//   //   throw UnimplementedError();
//   // }

//   @override
//   ComponentType getComponentType() {
//     // TODO: implement getComponentType
//     throw UnimplementedError();
//   }

//   @override
//   getComponentValue() {
//     // TODO: implement getComponentValue
//     throw UnimplementedError();
//   }

//   @override
//   String getStateValue() {
//     // TODO: implement getStateValue
//     throw UnimplementedError();
//   }

//   @override
//   bool isFulfilled() {
//     // TODO: implement isFulfilled
//     throw UnimplementedError();
//   }

//   @override
//   void setComponentValue(value) {
//     // TODO: implement setComponentValue
//   }

//   @override
//   void setStateValue(String value) {
//     // TODO: implement setStateValue
//   }

//   @override
//   bool shouldSaveState() {
//     // TODO: implement shouldSaveState
//     throw UnimplementedError();
//   }
// }
