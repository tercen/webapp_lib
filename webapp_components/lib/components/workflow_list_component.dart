import 'package:flutter/material.dart';

import 'package:webapp_components/components/action_list_component.dart';



import 'package:webapp_model/id_element_table.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

import 'package:webapp_components/widgets/wait_indicator.dart';

class WorkflowListComponent extends ActionListComponent {
  final String projectHref;
  bool showDone = false;

  WorkflowListComponent(super.id, super.groupId, super.componentLabel, super.dataFetchFunc, super.columnList, this.projectHref,
  {super.sortByLabel, super.collapsible, super.detailColumn = "", super.colWidths = const [], super.actions = const [], super.emptyMessage});

  
  @override
  Widget createToolbar() {
    var sep = const SizedBox(
      width: 15,
    );
    return Row(
      children: [
        wrapActionWidget(showDoneWidget()),
        sep,
        wrapActionWidget(filterActionWidget(), width: 200),
      ],
    );
  }


  Widget showDoneWidget(){
    var actionIcon = const Stack( children: [
      Icon(Icons.done_all_rounded),
      Icon(Icons.hide_source_rounded)
    ]);
    if( showDone ){
      actionIcon = const Stack( children: [
        Icon(Icons.done_all_rounded)
      ]);
    }
    var msgKey = showDone ? "Hide" : "Display";

    return InkWell(  
      onTap: (){
        showDone = !showDone;
        notifyListeners();
      },
      child: Tooltip( message: "$msgKey Successfully Finished Workfloes (Status: Done)", child: actionIcon ),
    );
  }



  @override
  Widget createWidget(BuildContext context, IdElementTable table) {
    expansionControllers.clear();
    var statusColName = table.colNames.firstWhere((e) => e.toLowerCase().contains("status"));

    List<Widget> wdgList = [];
    wdgList.add(createHeader());
    var rowIdx = 0;


    for (var ri in getSortedRowIdx(table) ) {
      var includeEntry = false;
      var values = [];
      for( var col in columnList ){
        var val = table.columns[col]![ri].label;
        includeEntry = includeEntry || shouldIncludeEntry(val);
        values.add(val);
      }
      var row = table.select([ri]);
      includeEntry = includeEntry && (showDone || (row[statusColName][0].label != "Done" && row[statusColName][0].label != "Unknown"));
      if (includeEntry  ) {
        
        Widget wdg = createEntry(values, actions, rowIdx, row );
        rowIdx++;

        if (collapsible == true) {
          // wdg = collapsibleWrap2(wdg, err);
        }
        wdgList.add(wdg);
      }
    }


    if( table.nRows() == 0 ){
      var emptyRow = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.all(50),
          child: Row(
            children: [
              TercenWaitIndicator().indicator,
              SizedBox(width: 10,),
              Text(emptyMessage, style: Styles()["textH2"],)
            ],
          )
          ,)
        ],
      );
      wdgList.add(emptyRow);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [createToolbar(), ...wdgList],
    );
  }



  @override
  Widget createEntry(List<dynamic> values, List<ListAction> actions, int rowIdx, IdElementTable rowValues){
    var isEven = rowIdx % 2 == 0;
    var textColor = rowValues[detailColumn].first.label == "" ? Styles()["black"] : Styles()["red"];
    
    List<Widget> cells = [];
    for( var i = 0; i < columnList.length; i++ ){
      var st = Styles()["text"].merge(TextStyle(color: textColor));

      cells.add(Expanded(
        flex: colWidths[i],
        child: Text(values[i], style: st),
        )
      );
    }
    
    List<Widget> actionWidgets = [];
    for( var i = 0; i < actions.length; i++ ){
      var isEnabled = actions[i].enabledCallback != null && actions[i].enabledCallback!( rowValues );
      var icon = actions[i].actionIcon;
      if( !isEnabled ){
        icon = Icon(icon.icon, color: const Color.fromARGB(255, 200, 200, 200));
      }else{
        icon = Icon(icon.icon, color: const Color.fromARGB(255, 255, 0, 0));
      }

      actionWidgets.add(
        InkWell(
          onTap: () async {
            if( isEnabled ){
              await (actions[i].callback!( rowValues ));
              notifyListeners();
            }            
          },
          child:  icon,
        )
      );
    }

    var actionCell = Expanded(
      flex: colWidths.last,
      child: Padding(padding: const EdgeInsets.fromLTRB(100, 0, 0, 0), child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: actionWidgets,
      ))
    );
    cells.add(actionCell);
    
    Widget row = Row(
      children: cells,
    );
    


    // rowValues
    row = errorWrap(rowIdx, row, rowValues[detailColumn].first.label, rowValues[detailColumn].first.id);


    return Container(
      color: isEven ? Styles()["evenRow"] : Styles()["oddRow"],
      constraints: const BoxConstraints(minHeight: 30),
      child: row);
  }

  Widget errorWrap( int i, Widget title, String errorMessage, String workflowId){
    expansionControllers.add(ExpansionTileController());
    var urlParts = projectHref.split("/");
    urlParts.removeLast();
    urlParts.removeLast();
    var baseUrl = urlParts.join("/");

      return ExpansionTile(
        key: GlobalKey(),
        title: title,
        dense: true,
        expandedAlignment: Alignment.topLeft,
        enabled: errorMessage != "",

        controller: expansionControllers.last,
        initiallyExpanded: expandedRows.contains(i),
        onExpansionChanged: (isExpanded) {
          if(isExpanded ){
            expandedRows.add(i);
          }else{
            expandedRows.remove(i);
          }
        },
        children: [
          Padding(padding: EdgeInsets.fromLTRB(20, 5, 20, 10),
          child:
          SelectableText("$errorMessage\n\nLink to Workflow:\n$baseUrl/w/$workflowId", style: Styles()["textFile"]) )
          ],
      );
    
    
  }
}