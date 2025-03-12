import 'dart:collection';

import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_components/abstract/multi_value_component.dart';
import 'package:webapp_components/abstract/single_value_component.dart';
import 'package:webapp_model/id_element.dart';
import 'package:sci_tercen_client/sci_client.dart';


mixin class ComponentBase {
  late final String id;
  late final String groupId;
  late final String componentLabel;
 
  final List<Pair> _metaList = [];

  final List<Component> ancestors = [];

  String getKey(){
    var key = "${getId()}_${getGroupId()}";
    for( var comp in ancestors ){
      if( comp is SingleValueComponent ){
        key = "$key${comp.getValue().id}";
      }

      if( comp is MultiValueComponent ){
        var vals = comp.getValue();
        for( var val in vals ){
          key = "$key${val.id}";
        }
      }
    }

    return key;
  }

  void addParent(Component parent) {
    parent.addListener((){
      reset();
    });
    ancestors.add(parent);
  }

  String getId(){
    return id;
  }

  String getGroupId(){
    return groupId;
  }

  void reset(){
    throw Exception("Reset not implemented. [$id, $groupId, $componentLabel]");
  }

  bool isActive() {
    var parentsActive = true;
    for( var parent in ancestors ){
      parentsActive = parentsActive && (parent.isActive() && parent.isFulfilled());
    }
    return true && parentsActive;
  }


  String label() {
    return componentLabel;
  }

  List<String> getParentIds(){
    return ancestors.map((e) => e.getId()).toList();
  }

  Map<String, List<IdElement>> getAncestorValues(){
    Map<String, List<IdElement>> vals = {};

    for( var ancestor in ancestors ){
      if( ancestor is SingleValueComponent   ){
        vals[ancestor.getId()] = [ancestor.getValue()];
      }
      if( ancestor is MultiValueComponent ){
        vals[ancestor.getId()] = ancestor.getValue();
      }
      
    }
    return vals;
  }


  List<Pair> get meta => UnmodifiableListView(_metaList);

  bool hasMeta(String key){
    return _metaList.any((m) => m.key == key);
  }

  void addMeta(String key, String value){
    if( !hasMeta(key)){
      _metaList.add(Pair.from(key, value));
    }else{
      // TODO define behavior here
    }
  }

}