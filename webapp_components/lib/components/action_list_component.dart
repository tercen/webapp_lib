// import 'dart:async';

// import 'package:flutter/material.dart';



// import 'package:webapp_model/id_element_table.dart';
// import 'package:webapp_components/components/list_component.dart';
// import 'package:webapp_ui_commons/styles/styles.dart';
// import 'package:webapp_utils/functions/list_utils.dart';

// import 'package:webapp_components/widgets/wait_indicator.dart';

// typedef CheckActionCallback = bool Function( IdElementTable row );
// typedef RowActionCallback = Future<void> Function( IdElementTable row ) ;
// class ListAction{
//   Icon actionIcon;
//   CheckActionCallback? enabledCallback;
//   RowActionCallback? callback;

//   ListAction(this.actionIcon, this.callback, {this.enabledCallback});
// }

// class ActionListComponent extends ListComponent {
//   final List<dynamic> widgetExportContent = [];
//   final List<String> columnList;
//   final String detailColumn;
//   final List<ListAction> actions;
//   final List<int> expandedRows = [];
//   final String emptyMessage;


//   List<int> colWidths = [];

//   String sortingCol = "";
//   String sortingDirection = "";

//   ActionListComponent(String super.id, String super.groupId,
//       String super.componentLabel, super.dataFetchFunc, this.columnList, 
//       {super.sortByLabel, super.collapsible, this.detailColumn = "", this.colWidths = const [], this.actions = const [], this.emptyMessage = "No Data"}){
//         if( colWidths.isEmpty ){
//           var eqWidth =  (100/columnList.length+1).floor();
//           colWidths = [];
//           for( var i = 0; i < columnList.length+1; i ++ ){
//             colWidths.add(eqWidth);
//           }
//         }
//       }


//   @override
//   Widget createToolbar() {
//     var sep = const SizedBox(
//       width: 15,
//     );
//     return Row(
//       children: [
//         wrapActionWidget(expandAllActionWidget()),
//         sep,
//         wrapActionWidget(collapseAllActionWidget()),
//         sep,
//         wrapActionWidget(filterActionWidget(), width: 200),
//       ],
//     );
//   }

//   Widget createSortableHeader( String headerName ){
//     Widget sortIcon = Container();

//     if( sortingCol == headerName ){
//       if( sortingDirection == "asc"){
//         sortIcon = const Icon(Icons.arrow_drop_up);
//       }
//       if( sortingDirection == "desc"){
//         sortIcon = const Icon(Icons.arrow_drop_down);
//       }
//     }
//     return Container( 
//         constraints: const BoxConstraints(minHeight: 50),
//         child:Row(
//           children: [
//             Text(headerName.toUpperCase(), style: Styles()["textH2"],),
//             sortIcon
//           ],
//         ));
//   }

//   void rotateSorting(String col){
//     if( sortingCol == col ){
//       if( sortingDirection == "desc"){
//         sortingDirection = "";
//         sortingCol = "";
//       }

//       if( sortingDirection == "asc"){
//         sortingDirection = "desc";
//       }
//     }else{
//       sortingCol = col;
//       sortingDirection = "asc";
//     }
//   }

//   Widget createHeader(){
//     List<Widget> headerCells = [];
//     for( var i = 0; i < columnList.length; i++ ){
//       headerCells.add(
//         Expanded(
//         flex: colWidths[i],
//         child: InkWell(
//           onTap: () {
//             rotateSorting(columnList[i]);
//             notifyListeners();
//           },
//           child: createSortableHeader(columnList[i]),
//         )
//       )
//       );
//     }

//     var actionCell =  Expanded(
//       flex: colWidths.last,
//       child: Center(child:Text("ACTIONS", style: Styles()["textH2"]))
//     );
//     headerCells.add(actionCell);
//     return Row(
//       children: headerCells,
//     );

//   }
  
//   Widget createEntry(List<dynamic> values, List<ListAction> actions, int rowIdx, IdElementTable rowValues){
//     var isEven = rowIdx % 2 == 0;
//     // var textColor = rowValues[detailColumn].first.label == "" ? Styles.black : Color.fromARGB(255, 255, 37, 37);
    
//     List<Widget> cells = [];
//     for( var i = 0; i < columnList.length; i++ ){
//       // var st = Styles.text.merge(TextStyle(color: textColor));
//       var st = Styles()["text"];

//       cells.add(Expanded(
//         flex: colWidths[i],
//         child: Text(values[i], style: st),
//         )
//       );
//     }
    
//     List<Widget> actionWidgets = [];
//     for( var i = 0; i < actions.length; i++ ){
//       var isEnabled = actions[i].enabledCallback != null && actions[i].enabledCallback!( rowValues );
//       var icon = actions[i].actionIcon;
//       if( !isEnabled ){
//         icon = Icon(icon.icon, color: const Color.fromARGB(255, 200, 200, 200));

//       }

//       actionWidgets.add(
//         InkWell(
//           onTap: () async {
//             if( isEnabled ){
//               await (actions[i].callback!( rowValues ));
//               notifyListeners();
//             }            
//           },
//           child:  icon,
//         )
//       );
//     }

//     var actionCell = Expanded(
//       flex: colWidths.last,
//       child: Padding(padding: const EdgeInsets.fromLTRB(100, 0, 0, 0), child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: actionWidgets,
//       ))
//     );
//     cells.add(actionCell);
    
//     Widget row = Row(
//       children: cells,
//     );


//     row = collapsibleWrap2(rowIdx, row, rowValues[detailColumn].first.label);


//     return Container(
//       color: isEven ? Styles()["evenRow"] : Styles()["oddRow"],
//       constraints: const BoxConstraints(minHeight: 30),
//       child: row);
//   }


//   List<int> getSortedRowIdx(IdElementTable tbl){
//     var idxList =  List<int>.generate(tbl.nRows(), (i) => i);
//     if( sortingCol != ""){
//       var values = tbl.columns[sortingCol]!.map((e) => e.label).toList();
      
//       var sortedIndices = ListUtils.getSortedIndices(values );

//       if( sortingDirection == "desc"){
//         sortedIndices = sortedIndices.reversed.toList();
//       }
//       idxList = sortedIndices;
      
//     }
//     return idxList;
//   }

//   @override
//   Widget createWidget(BuildContext context, IdElementTable table) {
//     expansionControllers.clear();

//     List<Widget> wdgList = [];
//     wdgList.add(createHeader());
//     var rowIdx = 0;


//     for (var ri in getSortedRowIdx(table) ) {
//       var includeEntry = false;
//       var values = [];
//       for( var col in columnList ){
//         var val = table.columns[col]![ri].label;
//         includeEntry = includeEntry || shouldIncludeEntry(val);
//         values.add(val);
//       }

//       if (includeEntry) {
//         var row = table.select([ri]);
//         Widget wdg = createEntry(values, actions, rowIdx, row );
//         rowIdx++;

//         if (collapsible == true) {
//           // wdg = collapsibleWrap2(wdg, err);
//         }
//         wdgList.add(wdg);
//       }
//     }


//     if( table.nRows() == 0 ){
//       var emptyRow = Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Padding(padding: const EdgeInsets.all(50),
//           child: Text(emptyMessage, style: Styles()["textH2"],),)
//         ],
//       );
//       wdgList.add(emptyRow);
//     }

//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [createToolbar(), ...wdgList],
//     );
//   }

  
//   Widget collapsibleWrap2( int i, Widget title, String errorMessage){
//     expansionControllers.add(ExpansionTileController());

//       return ExpansionTile(
//         key: GlobalKey(),
//         title: title,
//         dense: true,
//         expandedAlignment: Alignment.topLeft,
//         enabled: errorMessage != "",

//         controller: expansionControllers.last,
//         initiallyExpanded: expandedRows.contains(i),
//         onExpansionChanged: (isExpanded) {
//           if(isExpanded ){
//             expandedRows.add(i);
//           }else{
//             expandedRows.remove(i);
//           }
//         },
//         children: [SelectableText(errorMessage, style: Styles()["textFile"]) ],
//       );
    
    
//   }

  


//   @override
//   Widget buildContent(BuildContext context) {
//     return FutureBuilder(
//       future: dataFetchFunc(getParentIds(), getGroupId()) as Future<dynamic>?, 
//       builder: (context, snapshot){
//         if( snapshot.hasData && snapshot.data != null){
//           return createWidget(context, snapshot.data);
//         }else if( snapshot.hasError ){
//           print("ERROR");
//           print(snapshot.error);
//           throw Exception(snapshot.error);
//         }else{
//           return TercenWaitIndicator().waitingMessage(suffixMsg: "  Loading List"); // Load message
//         }

//       });
//     }
// }
