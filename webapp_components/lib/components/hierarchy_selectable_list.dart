
import 'package:flutter/material.dart';
import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/definitions/functions.dart';
import 'package:webapp_components/abstract/multi_value_component.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_model/id_element_table.dart';
import 'package:webapp_components/components/hierarchy_list.dart';
import 'package:webapp_components/mixins/checkbox_herarchical_list.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_components/widgets/wait_indicator.dart';


//FIXME Error when reordering
class HierarchySelectableListComponent extends  HierarchyList with ChangeNotifier, ComponentBase, CheckboxHerarchicalList  implements MultiValueComponent {
  // late CheckboxHierarchyList chList ;
  final DataFetchCallback dataFetchFunc;

  final List<String> colHierarchy = [];
  // final List<IdElement> _selected = [];
  late IdElementTable dataTable;

  HierarchySelectableListComponent(id, groupId, componentLabel, hierarchy, this.dataFetchFunc ){
    super.id = id;
    super.groupId = groupId;
    super.componentLabel = componentLabel;
    colHierarchy.addAll(hierarchy);
    
  }




  @override
  void reset(){
    super.selectedElements.clear();
    // throw UnimplementedError("Reset method of ComponentBase must be overriden");
  }  

  @override
  List<IdElement> getValue() {
    return  super.selectedElements;
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
        isLineSelected = isLineSelected && selectedElements.contains(v);
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
    setValue(selectedElements);
    notifyListeners();
  }


  Widget createWidget(BuildContext context, IdElementTable table ){
    for( var col in colHierarchy ){
      if( !table.columns.containsKey(col)){
        print("[WARNING] Column $col is not present in the hierarchical list. Returning blank.");
        return Container();
      }
    }

    load(table, colHierarchy, selectedElements);
    // chList = CheckboxHierarchyList(table, columnHierarchy, _selected);
    // chList.addListener(selectListener);

    // addListener(selectListener);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: buildWidgetTree(context),
    );
  }

  @override
  Widget buildContent(BuildContext context) {
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
          return TercenWaitIndicator().waitingMessage(suffixMsg: " Loading Table");
        }

      });

  }
  
  @override
  void setValue(List<IdElement> value) {
    
    for( var v in value ){
      if( !selectedElements.contains(v)){
        selectedElements.add(v);
      }
    }
  }
}