import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/multi_value_component.dart';
import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_ui_commons/styles/styles.dart';


class MultiCheckComponent with ChangeNotifier, ComponentBase implements MultiValueComponent {
  final List<IdElement> options = [];
  final List<IdElement> selected = [];
  final int columns;

  MultiCheckComponent(id, groupId, componentLabel, {this.columns = 5}){
    super.id = id;
    super.groupId = groupId;
    super.componentLabel = componentLabel;
  }

  void select(IdElement el){
    
    if( !selected.contains(el)){
      selected.add(el);
    }
  }

  void deselect(IdElement el){
    selected.remove(el);
  }

  Widget checkBox( String id, String name, bool isSelected, {Function? onClick}) {
    bool isSelected = selected.contains(IdElement(id, name));
    var checkIcon = IconButton(
      onPressed: () {
        isSelected ?
        deselect(IdElement(id, name)) :
        select(IdElement(id, name)) ;

        notifyListeners();
        if( onClick != null ){
          onClick();
        }
      },
      icon: isSelected
          ? const Icon(Icons.check_box_outlined)
          : const Icon(Icons.check_box_outline_blank));

    return Row(children: [
      checkIcon,
      Text(name, style: Styles.text,)
    ],);
}


  Widget buildCheckTable(){
        int nCols = options.length > columns ? columns : options.length;
    int nRows = (options.length / columns).ceil();

    int idx = 0;
    List<TableRow> tableRows = [];
    for( var ri = 0; ri < nRows; ri++ ){
      
      List<Widget> rowWidgets = [];
      for( var ci = 0; ci < nCols; ci++ ){  
        if( idx < options.length ){
          rowWidgets.add(checkBox( options[idx].id, options[idx].label, true));
          idx++;
        }else{
          rowWidgets.add(Container());
        }
      }

      tableRows.add(TableRow(children: rowWidgets));
    } 
    return Table( children: tableRows, );


  }



  @override
  Widget buildContent(BuildContext context) {
    return buildCheckTable();
  }

  void setOptions(List<IdElement> optList) {
    options.clear();
    options.addAll(optList);
  }


  @override
  getValue() {
    return selected;
  }

  @override
  bool isFulfilled() {
    return getValue().isNotEmpty;
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.simple;
  }
  
  @override
  void setValue(List<IdElement> value) {
    selected.clear();
    selected.addAll(value);
  }

  @override
  void reset(){
    selected.clear();
  }
}
