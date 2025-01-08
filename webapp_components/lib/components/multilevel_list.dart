
import 'package:flutter/material.dart';
import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/definitions/functions.dart';
import 'package:webapp_components/abstract/multi_value_component.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_model/id_element_table.dart';
import 'package:webapp_components/components/hierarchy_list.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_components/mixins/leaf_selection_list.dart';
import 'package:webapp_components/widgets/wait_indicator.dart';

class LeafSelectableListComponent extends HierarchyList with ChangeNotifier, ComponentBase, LeafSelectionList implements MultiValueComponent {
  final DataFetchCallback dataFetchFunc;

  final List<String> hierarchy;
  final List<IdElement> selected = [];
  late IdElementTable dataTable;
  final Map<String,String> levelTitles;

  LeafSelectableListComponent(id, groupId, componentLabel, this.hierarchy, this.dataFetchFunc, {infoBoxBuilder, this.levelTitles = const {}} ){
    super.id = id;
    super.groupId = groupId;
    super.componentLabel = componentLabel;
    super.infoBoxBuilder = infoBoxBuilder;
   
  }




  @override
  void reset(){
    super.selectedElements.clear();
  }  

  @override
  List<IdElement> getValue() {
    return super.selectedElements;
  }

  IdElementTable getValueAsTable(){
    IdElementTable tbl = IdElementTable();

    for( var col in columnHierarchy){
      tbl.addColumn(col);
    }
    
   
    for( var i = 0; i < dataTable.nRows(); i++){
      var values = dataTable.getValuesByRow(i, cols: columnHierarchy);

      bool isLineSelected = true;
      for( var v in values ){
        isLineSelected = isLineSelected && selected.contains(v);
      }
      if(isLineSelected){
        for( var ci = 0; ci < columnHierarchy.length; ci++ ){
          tbl.columns[columnHierarchy[ci]]!.add(values[ci]);
        }
      }
    }

    return tbl;
  }


  @override
  bool isFulfilled() {
    return getValue().isNotEmpty;
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.list;
  }
  

  void selectListener(){
    // print(selectedElements);
    // setValue(selectedElements);
    // notifyListeners();
  }


  Widget createWidget(BuildContext context, IdElementTable table ){
    for( var col in hierarchy ){
      if( !table.columns.containsKey(col)){
        print("[WARNING] Column $col is not present in the hierarchical list. Returning blank.");
        return Container();
      }
    }

    load(table, hierarchy, selectedElements, infoBoxBuilder: super.infoBoxBuilder);
    // levelList = LeafSelectionList(table, columnHierarchy, _selected, levelTitles: levelTitles);
    // addListener(selectListener);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: buildWidgetTree(context),
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    for( var ancestor in ancestors ){
      if( !ancestor.isActive() || !ancestor.isFulfilled() ){
        return const SizedBox(height: 1, width: 1,);
      }
    }

    return FutureBuilder(
      future: dataFetchFunc(getParentIds(), getGroupId()) as Future<dynamic>?, 
      builder: (context, snapshot){
        if( snapshot.hasData && snapshot.data != null){
          dataTable = snapshot.data;
          return createWidget(context, snapshot.data);
        }else if( snapshot.hasError ){
          print("ERROR");
          print(snapshot.error);
          throw Exception(snapshot.error);
        }else{
          return TercenWaitIndicator().waitingMessage(suffixMsg: "Loading Table..."); // Load message
        }

      });

  }
  
  @override
  void setValue(List<IdElement> value) {
    for( var v in value ){
      if( !selected.contains(v)){
        selected.add(v);
      }
    }
  }


}